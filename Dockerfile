# ===== Builder Stage =====
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 AS builder

ARG PYTHON_VERSION=3.10
ARG VENV_DIR=/opt/venv

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="$VENV_DIR/bin:$PATH"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-venv \
    git \
    ffmpeg \
    build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN python${PYTHON_VERSION} -m venv $VENV_DIR

COPY requirements.in .
RUN pip install --no-cache-dir pip-tools
RUN pip-compile requirements.in
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app
WORKDIR /app

# if we have setup.py
# RUN pip install -e.

# ===== Final Stage =====
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ENV VENV_DIR=/opt/venv
ENV PATH="$VENV_DIR/bin:$PATH"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --create-home appuser
USER appuser
WORKDIR /home/appuser/app

COPY --from=builder $VENV_DIR $VENV_DIR
COPY --from=builder /app .

CMD ["./run.sh"]
