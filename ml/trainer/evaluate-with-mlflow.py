from transformers import AutoModelForCausalLM, AutoTokenizer
from datasets import load_metric
import mlflow
import torch
import os

# Set tracking URI and experiment
mlflow.set_tracking_uri("http://mlflow-service.default.svc.cluster.local:5000")
mlflow.set_experiment("llm-finetuning")

# Start MLflow run
with mlflow.start_run(run_name="evaluation"):

    model_path = "model"
    mlflow.log_param("evaluation_model_path", model_path)

    # Load model and tokenizer
    model = AutoModelForCausalLM.from_pretrained(model_path).to("cuda")
    tokenizer = AutoTokenizer.from_pretrained(model_path)

    rouge = load_metric("rouge")

    # Evaluation set
    dataset = [
        {
            "prompt": "What is the capital of France?",
            "expected": "Paris"
        },
        {
            "prompt": "Translate 'good night' to Spanish.",
            "expected": "Buenas noches"
        }
        # Add more examples as needed
    ]

    preds = []
    refs = []

    for sample in dataset:
        inputs = tokenizer.encode(sample["prompt"], return_tensors="pt").to("cuda")
        outputs = model.generate(inputs, max_length=50)
        prediction = tokenizer.decode(outputs[0], skip_special_tokens=True)

        preds.append(prediction)
        refs.append(sample["expected"])

    # Compute and log metrics
    score = rouge.compute(predictions=preds, references=refs)
    mlflow.log_metric("rouge1", score["rouge1"].mid.fmeasure)
    mlflow.log_metric("rougeL", score["rougeL"].mid.fmeasure)

    # Optional: Save predictions to file and log as artifact
    os.makedirs("outputs", exist_ok=True)
    with open("outputs/predictions.txt", "w") as f:
        for p, r in zip(preds, refs):
            f.write(f"Prompt → {p.strip()}\nExpected → {r.strip()}\n\n")
    mlflow.log_artifact("outputs/predictions.txt")

    print("Evaluation complete and logged to MLflow.")
