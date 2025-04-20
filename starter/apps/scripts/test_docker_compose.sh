#!/bin/bash

SERVER_ENDPOINT=${SERVER_ENDPOINT:-"http://localhost:8001"}
echo "Calling endpoint ${SERVER_ENDPOINT}"
ORDER=$(
  curl -s -X POST $SERVER_ENDPOINT/orders/ \
    -H "Content-Type: application/json" \
    -d @- <<'EOF'
{
    "product_id": "PROD001",
    "quantity": 1,
    "customer_id": "CUST001"
}
EOF
)
echo "$ORDER"
ORDER_ID=$(echo $ORDER | python -m json.tool | grep order_id | tr -d '"' | tr -d ', ' | cut -d ':' -f 2)

echo "$ORDER_ID"
curl -X GET ${SERVER_ENDPOINT}/orders/$ORDER_ID
