FROM python:3.11-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-slim

LABEL org.opencontainers.image.title="A Book Of Life To Rebuild The World — API"
LABEL org.opencontainers.image.licenses="MIT"

RUN useradd -m -u 1000 abook
WORKDIR /app

COPY --from=builder /install /usr/local
COPY --chown=abook:abook scripts/ ./scripts/
COPY --chown=abook:abook domains/ ./domains/
COPY --chown=abook:abook sidecars/ ./sidecars/
COPY --chown=abook:abook schemas/ ./schemas/
COPY --chown=abook:abook manifest.toml .

USER abook

RUN python scripts/validate.py && python scripts/build_index.py

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"

CMD ["python", "scripts/serve.py"]
