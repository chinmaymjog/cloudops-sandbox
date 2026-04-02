FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY pyproject.toml README.md /app/
COPY ai_dev_orchestrator /app/ai_dev_orchestrator

RUN pip install --no-cache-dir .

CMD ["uvicorn", "ai_dev_orchestrator.main:app", "--host", "0.0.0.0", "--port", "8000"]
