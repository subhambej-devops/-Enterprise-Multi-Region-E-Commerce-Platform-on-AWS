from datetime import UTC, datetime

from ecommerce_platform.service import json_response, method_not_allowed


def quote(method: str, environ: dict[str, str]):
    if method != "GET":
        return method_not_allowed("GET")
    return json_response(
        {
            "subtotal": 428.99,
            "shipping": 0,
            "tax": 34.32,
            "total": 463.31,
            "currency": "USD",
        }
    )


def create_order(method: str, environ: dict[str, str]):
    if method != "POST":
        return method_not_allowed("POST")
    return json_response(
        {
            "order_id": "ord-demo-10001",
            "status": "accepted",
            "created_at": datetime.now(UTC).isoformat(),
        },
        status="202 Accepted",
    )


ROUTES = {
    "/checkout/quote": quote,
    "/checkout/orders": create_order,
}

