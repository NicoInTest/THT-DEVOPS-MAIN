# service_a/src/main.py
from fastapi import FastAPI, HTTPException, Request, Response
import dns.resolver
from starlette.middleware.base import BaseHTTPMiddleware
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
import time

from pydantic import BaseModel
import boto3
import httpx
import os
import uuid
import logging
from datetime import datetime
from typing import Optional, Dict, Any
from decimal import Decimal
import random


def resolve_srv(endpoint):
    srvInfo = {}
    srv_records=dns.resolver.query(endpoint, 'SRV')
    srv = random.choice(srv_records)
    srvInfo['weight']   = srv.weight
    srvInfo['host']     = str(srv.target).rstrip('.')
    srvInfo['port']     = srv.port
    srvInfo['priority'] = srv.priority
    
    return f"http://{srvInfo['host']}:{srvInfo['port']}"
    

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - [- %(name)s - %(levelname)s - %(message)s",
)

logger = logging.getLogger(__name__)

# Define Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP Requests Count', ['method', 'endpoint', 'status_code', 'service'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP Request Latency', ['method', 'endpoint', 'service'])
REQUESTS_IN_PROGRESS = Gauge('http_requests_in_progress', 'HTTP Requests currently in progress', ['method', 'endpoint', 'service'])
DATABASE_OPERATION_LATENCY = Histogram('database_operation_duration_seconds', 'Database Operation Latency', ['operation', 'table', 'service'])
ORDERS_CREATED = Counter('orders_created_total', 'Total Orders Created', ['service'])
PROCESSOR_REQUEST_LATENCY = Histogram('processor_request_duration_seconds', 'Order Processor Request Latency', ['endpoint', 'service'])

# Prometheus middleware
class PrometheusMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        method = request.method
        path = request.url.path
        service = "order-api"
        
        # Skip metrics endpoint to avoid infinite recursion
        if path == "/metrics":
            return await call_next(request)
        
        REQUESTS_IN_PROGRESS.labels(method=method, endpoint=path, service=service).inc()
        start_time = time.time()
        
        try:
            response = await call_next(request)
            status_code = response.status_code
            REQUEST_COUNT.labels(method=method, endpoint=path, status_code=status_code, service=service).inc()
            return response
        except Exception as e:
            REQUEST_COUNT.labels(method=method, endpoint=path, status_code=500, service=service).inc()
            raise e
        finally:
            duration = time.time() - start_time
            REQUEST_LATENCY.labels(method=method, endpoint=path, service=service).observe(duration)
            REQUESTS_IN_PROGRESS.labels(method=method, endpoint=path, service=service).dec()

app = FastAPI(title="Order API Gateway")
app.add_middleware(PrometheusMiddleware)

SRV_ENDPOINT = os.getenv("SRV_ENDPOINT", None)
DYNAMODB_ENDPOINT = os.getenv("DYNAMODB_ENDPOINT", None)

DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE", "orders")

ORDER_PROCESSOR_URL = os.getenv("ORDER_PROCESSOR_URL", "http://localhost:8001")

dynamodb = boto3.resource("dynamodb", endpoint_url=DYNAMODB_ENDPOINT)
orders_table = dynamodb.Table(DYNAMODB_TABLE)


class Order(BaseModel):
    product_id: str
    quantity: int
    customer_id: str


class OrderResponse(BaseModel):
    order_id: str
    product_id: str
    quantity: int
    customer_id: str
    status: str
    processed_at: str
    created_at: str
    total_price: Optional[int] = None


class OrderRepository:
    def __init__(self):
        self.table = orders_table

    async def create_order(self, order_data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            start_time = time.time()
            response = self.table.put_item(Item=order_data)
            duration = time.time() - start_time
            DATABASE_OPERATION_LATENCY.labels(operation='put_item', table='orders', service='order-api').observe(duration)
            return order_data
        except Exception as e:
            logger.error(f"Failed to create order: {str(e)}")
            raise HTTPException(status_code=500, detail="Database operation failed")

    async def get_order(self, order_id: str) -> Optional[Dict[str, Any]]:
        try:
            start_time = time.time()
            response = self.table.get_item(Key={"order_id": order_id})
            duration = time.time() - start_time
            DATABASE_OPERATION_LATENCY.labels(operation='get_item', table='orders', service='order-api').observe(duration)
            return response.get("Item")
        except Exception as e:
            logger.error(f"Failed to get order: {str(e)}")
            raise HTTPException(status_code=500, detail="Database operation failed")


@app.on_event("startup")
async def startup_event():
    logger.info("Application started")


@app.post("/orders/", response_model=OrderResponse)
async def create_order(order: Order, request: Request):
    try:
        async with httpx.AsyncClient() as client:
            processor_start_time = time.time()
            response = await client.post(
                f"{ORDER_PROCESSOR_URL}/process-order",
                json=order.dict(),
                timeout=5.0,
            )
            processor_duration = time.time() - processor_start_time
            PROCESSOR_REQUEST_LATENCY.labels(endpoint='/process-order', service='order-api').observe(processor_duration)

            if response.status_code == 200:
                processed_order = response.json()
                order.quantity=Decimal(str(order.quantity))
                order_data = {
                    "order_id": str(uuid.uuid4()),
                    **order.dict(),
                    **processed_order,
                    "created_at": datetime.utcnow().isoformat(),
                }

                repository = OrderRepository()
                stored_order = await repository.create_order(order_data)
                ORDERS_CREATED.labels(service='order-api').inc()
                return OrderResponse(**stored_order)
            else:
                logger.error(
                    f"Order Processor returned error: {response.text}",
                )
                raise HTTPException(
                    status_code=response.status_code, detail=response.text
                )

    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Order Processor timeout")
    except Exception as e:
        logger.error(
            f"Order processing failed: {str(e)}",
        )
        raise HTTPException(status_code=500, detail="Order processing failed")


@app.get("/orders/{order_id}", response_model=OrderResponse)
async def get_order(order_id: str, request: Request):

    repository = OrderRepository()

    order = await repository.get_order(order_id)

    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    return OrderResponse(**order)


@app.get("/health")
async def health_check():
    try:
        global ORDER_PROCESSOR_URL

        orders_table.scan(Limit=1)

        if SRV_ENDPOINT: 
            ORDER_PROCESSOR_URL = resolve_srv(SRV_ENDPOINT)

        async with httpx.AsyncClient() as client:
            response = await client.get(f"{ORDER_PROCESSOR_URL}/health", timeout=2.0)
            if response.status_code != 200:
                raise HTTPException(status_code=503, detail="Orders Processor unhealthy")

        return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=503, detail=f"Service unhealthy: {str(e)}")


@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)

