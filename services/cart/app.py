from datetime import UTC, datetime

from ecommerce_platform.service import json_response, method_not_allowed


def get_cart(method: str, environ: dict[str, str]):
    if method != "GET":
        return method_not_allowed("GET")
    return json_response(
        {
            "cart_id": "cart-demo",
            "updated_at": datetime.now(UTC).isoformat(),
            "items": [
                {"sku": "sku-1001", "quantity": 1},
                {"sku": "sku-1003", "quantity": 2},
            ],
        }
    )


ROUTES = {
    "/cart": get_cart,
}

