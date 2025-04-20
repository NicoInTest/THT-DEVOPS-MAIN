# scripts/init-dynamodb.py
import boto3
import time
import logging
from botocore.exceptions import ClientError

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def wait_for_dynamodb(dynamodb):
    """Wait for DynamoDB to become available"""
    retries = 0
    while retries < 10:
        try:
            tables = dynamodb.tables.all()
            logger.info(f"DynamoDB is available with {tables}")
            return True
        except Exception as e:
            logger.info(str(e))
            logger.info(f"Waiting for DynamoDB... ({retries}/10)")
            retries += 1
            time.sleep(5)
    return False


def create_orders_table(dynamodb):
    """Create orders table"""
    try:
        table = dynamodb.create_table(
            TableName="orders",
            KeySchema=[{"AttributeName": "order_id", "KeyType": "HASH"}],
            AttributeDefinitions=[
                {"AttributeName": "order_id", "AttributeType": "S"}
            ],
            BillingMode="PAY_PER_REQUEST",
        )
        logger.info("Created orders table")
        return table
    except ClientError as e:
        if e.response["Error"]["Code"] == "ResourceInUseException":
            logger.info("Orders table already exists")
        else:
            raise


def create_inventory_table(dynamodb):
    """Create inventory table"""
    try:
        table = dynamodb.create_table(
            TableName="inventory",
            KeySchema=[{"AttributeName": "product_id", "KeyType": "HASH"}],
            AttributeDefinitions=[
                {"AttributeName": "product_id", "AttributeType": "S"}
            ],
            BillingMode="PAY_PER_REQUEST",
        )
        logger.info("Created inventory table")
        return table
    except ClientError as e:
        if e.response["Error"]["Code"] == "ResourceInUseException":
            logger.info("Inventory table already exists")
        else:
            raise


def seed_inventory_data(dynamodb):
    """Seed initial inventory data"""
    table = dynamodb.Table("inventory")
    items = [
        {
            "product_id": "PROD001",
            "name": "Sample Product 1",
            "price": 29,
            "stock": 100,
        },
        {
            "product_id": "PROD002",
            "name": "Sample Product 2",
            "price": 49,
            "stock": 50,
        },
    ]

    for item in items:
        table.put_item(Item=item)
    logger.info("Seeded inventory data")


def main():
    import os 
    DDB_ENDPOINT=os.getenv("DDB_ENDPOINT", "http://dynamodb-local:8000")

    dynamodb = boto3.resource(
        "dynamodb",
        endpoint_url=DDB_ENDPOINT,
        region_name="us-west-2",
        aws_access_key_id="local",
        aws_secret_access_key="local",
    )

    if not wait_for_dynamodb(dynamodb):
        logger.error("DynamoDB did not become available")
        return

    create_orders_table(dynamodb)
    create_inventory_table(dynamodb)
    seed_inventory_data(dynamodb)
    logger.info("Initialization complete")


if __name__ == "__main__":
    main()
