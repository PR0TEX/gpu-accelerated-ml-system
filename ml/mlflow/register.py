import mlflow
from transformers import AutoModelForCausalLM, AutoTokenizer
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--model_dir", default="./model")
args = parser.parse_args()

mlflow.set_tracking_uri("http://mlflow-tracking-server:5000")
mlflow.set_experiment("llm-finetune")

with mlflow.start_run():
    mlflow.log_param("model_name", "distilgpt2")
    mlflow.log_param("epochs", 1)
    mlflow.log_artifacts(args.model_dir, artifact_path="model")

    # Optional: register model formally (works only with local or DB-backed registry)
    mlflow.pytorch.log_model(
        pytorch_model=AutoModelForCausalLM.from_pretrained(args.model_dir),
        artifact_path="model",
        registered_model_name="DistilGPT2-Finetuned"
    )
    print("Model registered in MLflow.")
