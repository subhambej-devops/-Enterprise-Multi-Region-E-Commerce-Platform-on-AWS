from __future__ import annotations

import os
from wsgiref.simple_server import make_server

from ecommerce_platform.service import create_application


def main() -> None:
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8080"))
    app = create_application()
    with make_server(host, port, app) as server:
        print(f"serving {os.getenv('SERVICE_NAME', 'catalog')} on http://{host}:{port}")
        server.serve_forever()


if __name__ == "__main__":
    main()

