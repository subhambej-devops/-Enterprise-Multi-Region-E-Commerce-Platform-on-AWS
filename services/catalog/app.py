from ecommerce_platform.service import json_response, method_not_allowed

PRODUCTS = [
    {
        "id": "sku-1001",
        "name": "Travel Backpack",
        "category": "bags",
        "price": 129.99,
        "inventory": 4200,
    },
    {
        "id": "sku-1002",
        "name": "Noise Cancelling Headphones",
        "category": "electronics",
        "price": 249.00,
        "inventory": 1700,
    },
    {
        "id": "sku-1003",
        "name": "Running Shoes",
        "category": "footwear",
        "price": 149.50,
        "inventory": 3100,
    },
]


def list_products(method: str, environ: dict[str, str]):
    if method != "GET":
        return method_not_allowed("GET")
    return json_response({"items": PRODUCTS, "count": len(PRODUCTS)})


ROUTES = {
    "/catalog/items": list_products,
}

