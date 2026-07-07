FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    ENVIRONMENT=dev \
    HOST=0.0.0.0 \
    PORT=19211 \
    DB_URL=sqlite:data/db/zhenxun.db \
    CACHE_MODE=NONE

RUN apt-get update && \
    apt-get install -y --no-install-recommends git curl ca-certificates build-essential && \
    python -m pip install --upgrade pip uv playwright==1.57.0 && \
    playwright install --with-deps chromium && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /root/.cache/pip

WORKDIR /zhenxun

COPY scaffold /opt/zhenxun-scaffold
COPY start-zhenxun.sh /usr/local/bin/start-zhenxun

RUN chmod +x /usr/local/bin/start-zhenxun

EXPOSE 19211

CMD ["start-zhenxun"]
