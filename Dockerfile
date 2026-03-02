FROM python:3.13-alpine AS builder

WORKDIR /app

RUN apk add --no-cache \
    gcc \
    musl-dev \
    libpq-dev

COPY requirements.txt .
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


FROM python:3.13-alpine AS production

RUN apk add --no-cache libpq

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN addgroup -S appuser && adduser -S appuser -G appuser

WORKDIR /app

COPY --chown=appuser:appuser . .

RUN mkdir -p /app/staticfiles /app/media && \
    chown -R appuser:appuser /app/staticfiles /app/media && \
    chmod 1777 /tmp

USER appuser

RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["gunicorn", "config.wsgi:application", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "3", \
     "--timeout", "120", \
     "--worker-tmp-dir", "/tmp", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]