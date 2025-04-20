from fastapi import FastAPI, HTTPException, Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from pydantic import BaseModel
import boto3
import logging
import os
import time

from datetime import datetime, timezone
from typing import Dict, Any, Optional

DYNAMODB_ENDPOINT=os.getenv("DYNAMODB_ENDPOINT", None)
DYNAMODB_TABLE=os.getenv("DYNAMODB_TABLE", "inventory")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - [%(name)s - %(levelname)s - %(message)s",
)

logger = logging.getLogger(__name__)

# Define Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP Requests Count', ['method', 'endpoint', 'status_code', 'service'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP Request Latency', ['method', 'endpoint', 'service'])
REQUESTS_IN_PROGRESS = Gauge('http_requests_in_progress', 'HTTP Requests currently in progress', ['method', 'endpoint', 'service'])
DATABASE_OPERATION_LATENCY = Histogram('database_operation_duration_seconds', 'Database Operation Latency', ['operation', 'table', 'service'])
INVENTORY_CHECK_COUNTER = Counter('inventory_check_total', 'Total Inventory Check Operations', ['result', 'service'])
ORDERS_PROCESSED = Counter('orders_processed_total', 'Total Orders Processed', ['status', 'service'])
ORDER_PROCESSING_DURATION = Histogram('processor_request_duration_seconds', 'Order Processing Duration', ['endpoint', 'service'])

# Prometheus middleware
class PrometheusMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        method = request.method
        path = request.url.path
        service = "order-processor"
        
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

app = FastAPI(title="Order Processor")
app.add_middleware(PrometheusMiddleware)

dynamodb = boto3.resource(
    "dynamodb", endpoint_url=DYNAMODB_ENDPOINT)

inventory_table = dynamodb.Table(DYNAMODB_TABLE)


class OrderRequest(BaseModel):
    product_id: str
    quantity: int
    customer_id: str


class ProcessedOrder(BaseModel):
    status: str
    total_price: int
    processed_at: str


class InventoryRepository:
    def __init__(self):
        self.table = inventory_table

    async def check_and_update_inventory(
        self, product_id: str, quantity: int
    ) -> Optional[int]:
        try:
            start_time = time.time()
            response = self.table.get_item(Key={"product_id": product_id})
            duration = time.time() - start_time
            DATABASE_OPERATION_LATENCY.labels(operation='get_item', table='inventory', service='order-processor').observe(duration)
    
            item = response.get("Item")
            if not item or item["stock"] < quantity:
                logger.error(
                    f"Insufficient stock for product {product_id}",
                )
                INVENTORY_CHECK_COUNTER.labels(result='insufficient_stock', service='order-processor').inc()
                return None
    
            start_time = time.time()
            self.table.update_item(
                Key={"product_id": product_id},
                UpdateExpression="SET stock = stock - :quantity",
                ExpressionAttributeValues={":quantity": quantity},
            )
            duration = time.time() - start_time
            DATABASE_OPERATION_LATENCY.labels(operation='update_item', table='inventory', service='order-processor').observe(duration)
            
            INVENTORY_CHECK_COUNTER.labels(result='success', service='order-processor').inc()
            return int(item["price"] * quantity)
    
        except Exception as e:
            logger.error(
                f"Inventory operation failed: {str(e)}",
            )
            INVENTORY_CHECK_COUNTER.labels(result='error', service='order-processor').inc()
            raise HTTPException(
                status_code=500, detail="Inventory operation failed"
            )



@app.on_event("startup")
async def startup_event():
    logger.info("Application started")


@app.post("/process-order", response_model=ProcessedOrder)
async def process_order(order: OrderRequest, request: Request):
    process_start_time = time.time()
    
    logger.info(
        f"Processing order for product {order.product_id}",
    )

    repository = InventoryRepository()
    total_price = await repository.check_and_update_inventory(
        order.product_id, order.quantity 
    )

    if total_price is None:
        ORDERS_PROCESSED.labels(status='failed', service='order-processor').inc()
        raise HTTPException(status_code=400, detail="Insufficient inventory")

    process_duration = time.time() - process_start_time
    ORDER_PROCESSING_DURATION.labels(endpoint='/process-order', service='order-processor').observe(process_duration)
    ORDERS_PROCESSED.labels(status='confirmed', service='order-processor').inc()

    return ProcessedOrder(
        status="confirmed",
        total_price=total_price,
        processed_at=datetime.now(timezone.utc).isoformat(),
    )


@app.get("/health")
async def health_check():
    try:
        inventory_table.scan(Limit=1)

        return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=503, detail=f"Database is unhealthy: {str(e)}")


@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
