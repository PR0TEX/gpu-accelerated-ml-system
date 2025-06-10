FROM python:3.10-slim

RUN pip install huggingface_hub gitpython
WORKDIR /app
COPY push-model.py .

ENTRYPOINT ["python", "/app/push.py"]
