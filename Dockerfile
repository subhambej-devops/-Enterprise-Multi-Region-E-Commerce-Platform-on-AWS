FROM python:3.12-slim AS runtime

ARG SERVICE=catalog
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    SERVICE_NAME=${SERVICE} \
    PORT=8080 \
    WEB_CONCURRENCY=2

WORKDIR /app

RUN groupadd --system app && useradd --system --gid app --home-dir /app app

COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY ecommerce_platform ./ecommerce_platform
COPY services ./services

USER app
EXPOSE 8080

CMD ["sh", "-c", "gunicorn --workers ${WEB_CONCURRENCY} --bind 0.0.0.0:${PORT} ecommerce_platform.wsgi:application"]
