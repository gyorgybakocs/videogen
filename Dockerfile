FROM nvidia/cuda:12.6.1-base-ubuntu22.04

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip \
    ffmpeg git build-essential \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.in ./
RUN pip3 install --no-cache-dir -U pip pip-tools \
 && python3 -m piptools compile -o requirements.txt requirements.in \
 && pip3 install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd --create-home --shell /bin/bash appuser \
 && chown -R appuser:appuser /app
USER appuser

ENV PYTHONPATH=/app

ENTRYPOINT ["tail", "-f", "/dev/null"]
