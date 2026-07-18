import json
import unittest

from ecommerce_platform.service import create_application


def call_wsgi(app, path: str, method: str = "GET"):
    captured = {}

    def start_response(status, headers):
        captured["status"] = status
        captured["headers"] = dict(headers)

    body = b"".join(
        app(
            {
                "REQUEST_METHOD": method,
                "PATH_INFO": path,
                "HTTP_X_REQUEST_ID": "test-request",
            },
            start_response,
        )
    )
    captured["body"] = body
    return captured


class ServiceTestCase(unittest.TestCase):
    def test_health_endpoint(self):
        app = create_application("catalog")
        response = call_wsgi(app, "/healthz")
        self.assertEqual(response["status"], "200 OK")
        self.assertEqual(json.loads(response["body"])["status"], "ok")

    def test_catalog_items(self):
        app = create_application("catalog")
        response = call_wsgi(app, "/catalog/items")
        payload = json.loads(response["body"])
        self.assertEqual(response["status"], "200 OK")
        self.assertGreaterEqual(payload["count"], 1)

    def test_cart(self):
        app = create_application("cart")
        response = call_wsgi(app, "/cart")
        payload = json.loads(response["body"])
        self.assertEqual(response["status"], "200 OK")
        self.assertEqual(payload["cart_id"], "cart-demo")

    def test_checkout_order_requires_post(self):
        app = create_application("checkout")
        response = call_wsgi(app, "/checkout/orders")
        self.assertEqual(response["status"], "405 Method Not Allowed")
        self.assertEqual(response["headers"]["Allow"], "POST")

    def test_checkout_order_accepts_post(self):
        app = create_application("checkout")
        response = call_wsgi(app, "/checkout/orders", method="POST")
        self.assertEqual(response["status"], "202 Accepted")

    def test_metrics_endpoint(self):
        app = create_application("catalog")
        response = call_wsgi(app, "/metrics")
        self.assertEqual(response["status"], "200 OK")
        self.assertIn(b"ecommerce_http_requests_total", response["body"])


if __name__ == "__main__":
    unittest.main()

