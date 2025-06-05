FROM nvidia/cuda:12.3.2-base-ubuntu22.04

RUN apt-get update && apt-get install -y \
    python3 python3-pip git curl && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip && \
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 && \
    pip install transformers datasets accelerate

WORKDIR /app
COPY train.py .

CMD ["python3", "train.py"]
