FROM nvidia/cuda:12.3.2-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip git && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir \
        torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 && \
    python3 -m pip install --no-cache-dir \
        transformers datasets accelerate && \
    apt-get remove -y git && \
    apt-get autoremove -y && \
    apt-get clean

WORKDIR /app
COPY train.py .

CMD ["python3", "train.py"]
