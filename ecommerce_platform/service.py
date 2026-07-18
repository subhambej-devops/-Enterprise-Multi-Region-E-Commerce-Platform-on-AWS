from __future__ import annotations

import importlib
import json
import os
import threading
import time
from contextlib import contextmanager, nullcontext
from dataclasses import dataclass
from typing import Callable, Iterable

try:
    from opentelemetry import trace
    from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
    from opentelemetry.sdk.resources import Resource
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor
except ImportError:  # Local tests can run before runtime dependencies are installed.
    trace = None
    OTLPSpanExporter = None
    Resource = None
    TracerProvider = None
    BatchSpanProcessor = None

HeaderList = list[tuple[str, str]]
RouteHandler = Callable[[str, dict[str, str]], "Response"]


@dataclass(frozen=True)
class Response:
    status: str
    headers: HeaderList
    body: bytes


@dataclass(frozen=True)
class ServiceDefinition:
    name: str
    routes: dict[str, RouteHandler]


class EcommerceApplication:
    def __init__(self, definition: ServiceDefinition) -> None:
        self.definition = definition
        self.region = first_non_empty(
            os.getenv("PLATFORM_REGION"),
            os.getenv("AWS_REGION"),
            "local",
        )
        self.version = first_non_empty(os.getenv("SERVICE_VERSION"), "dev")
        self.started_at = time.time()
        self._request_count = 0
        self._lock = threading.Lock()
        self._tracer = configure_tracing(definition.name, self.region)

    def __call__(self, environ: dict[str, str], start_response: Callable) -> Iterable[bytes]:
        path = environ.get("PATH_INFO", "/")
        method = environ.get("REQUEST_METHOD", "GET").upper()
        request_id = first_non_empty(
            environ.get("HTTP_X_REQUEST_ID"),
            environ.get("HTTP_X_AMZN_TRACE_ID"),
            str(time.time_ns()),
        )

        with self._lock:
            self._request_count += 1

        with start_span(self._tracer, method, path, request_id) as span:
            response = self._dispatch(method, path, environ)
            set_span_attribute(span, "http.response.status_code", int(response.status.split()[0]))

        headers = [*response.headers, ("X-Request-Id", request_id)]
        start_response(response.status, headers)
        return [response.body]

    def _dispatch(self, method: str, path: str, environ: dict[str, str]) -> Response:
        if path == "/":
            return json_response(
                {
                    "service": self.definition.name,
                    "region": self.region,
                    "version": self.version,
                    "links": sorted(["/healthz", "/readyz", "/metrics", *self.definition.routes.keys()]),
                }
            )
        if path == "/healthz":
            return json_response(
                {
                    "status": "ok",
                    "service": self.definition.name,
                    "region": self.region,
                    "version": self.version,
                    "uptime_seconds": int(time.time() - self.started_at),
                }
            )
        if path == "/readyz":
            return json_response({"status": "ready", "service": self.definition.name})
        if path == "/metrics":
            return metrics_response(
                service=self.definition.name,
                region=self.region,
                uptime_seconds=int(time.time() - self.started_at),
                request_count=self._request_count,
            )
        if path in self.definition.routes:
            return self.definition.routes[path](method, environ)
        return json_response({"error": "not found", "path": path}, status="404 Not Found")


def load_service(service_name: str | None = None) -> ServiceDefinition:
    name = first_non_empty(service_name, os.getenv("SERVICE_NAME"), "catalog")
    if not name.replace("-", "").replace("_", "").isalnum():
        raise ValueError(f"Invalid service name: {name!r}")

    module = importlib.import_module(f"services.{name}.app")
    routes = getattr(module, "ROUTES")
    return ServiceDefinition(name=name, routes=routes)


def create_application(service_name: str | None = None) -> EcommerceApplication:
    return EcommerceApplication(load_service(service_name))


def json_response(payload: object, status: str = "200 OK") -> Response:
    body = json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8") + b"\n"
    return Response(
        status=status,
        headers=[
            ("Content-Type", "application/json"),
            ("Content-Length", str(len(body))),
        ],
        body=body,
    )


def method_not_allowed(allowed: str = "GET") -> Response:
    body = json.dumps({"error": "method not allowed", "allowed": allowed}).encode("utf-8") + b"\n"
    return Response(
        status="405 Method Not Allowed",
        headers=[
            ("Content-Type", "application/json"),
            ("Allow", allowed),
            ("Content-Length", str(len(body))),
        ],
        body=body,
    )


def metrics_response(service: str, region: str, uptime_seconds: int, request_count: int) -> Response:
    body_text = "\n".join(
        [
            "# HELP ecommerce_service_uptime_seconds Service uptime in seconds.",
            "# TYPE ecommerce_service_uptime_seconds gauge",
            f'ecommerce_service_uptime_seconds{{service="{escape_label(service)}",region="{escape_label(region)}"}} {uptime_seconds}',
            "# HELP ecommerce_http_requests_total Total HTTP requests handled by the service.",
            "# TYPE ecommerce_http_requests_total counter",
            f'ecommerce_http_requests_total{{service="{escape_label(service)}",region="{escape_label(region)}"}} {request_count}',
            "",
        ]
    )
    body = body_text.encode("utf-8")
    return Response(
        status="200 OK",
        headers=[
            ("Content-Type", "text/plain; version=0.0.4"),
            ("Content-Length", str(len(body))),
        ],
        body=body,
    )


def first_non_empty(*values: str | None) -> str:
    for value in values:
        if value and value.strip():
            return value.strip()
    return ""


def escape_label(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


_TRACING_CONFIGURED = False


def configure_tracing(service_name: str, region: str):
    global _TRACING_CONFIGURED
    if (
        trace is None
        or os.getenv("OTEL_SDK_DISABLED", "").lower() == "true"
        or not os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
    ):
        return None
    if not _TRACING_CONFIGURED:
        resource = Resource.create(
            {
                "service.name": service_name,
                "service.namespace": "enterprise-commerce",
                "cloud.provider": "aws",
                "cloud.region": region,
            }
        )
        provider = TracerProvider(resource=resource)
        provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
        trace.set_tracer_provider(provider)
        _TRACING_CONFIGURED = True
    return trace.get_tracer(service_name)


def start_span(tracer, method: str, path: str, request_id: str):
    if tracer is None:
        return nullcontext(None)
    return traced_request(tracer, method, path, request_id)


@contextmanager
def traced_request(tracer, method: str, path: str, request_id: str):
    with tracer.start_as_current_span(f"{method} {path}") as span:
        set_span_attribute(span, "http.request.method", method)
        set_span_attribute(span, "url.path", path)
        set_span_attribute(span, "http.request.header.x_request_id", request_id)
        yield span


def set_span_attribute(span, key: str, value: object) -> None:
    if span is not None:
        span.set_attribute(key, value)
