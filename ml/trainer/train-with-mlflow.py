from transformers import AutoModelForCausalLM, AutoTokenizer, Trainer, TrainingArguments, DataCollatorForLanguageModeling
from datasets import load_dataset
import torch
import mlflow
import mlflow.pytorch
import os

# Set up MLflow tracking
mlflow.set_tracking_uri("http://mlflow-service.default.svc.cluster.local:5000")  # adjust namespace if needed
mlflow.set_experiment("llm-finetuning")

model_name = "distilgpt2"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name).to("cuda")

print("Loading dataset...")
dataset = load_dataset("tatsu-lab/alpaca", split="train")
dataset = dataset.map(lambda e: tokenizer(e['text'], truncation=True, padding='max_length', max_length=128), batched=True)

print("Starting training...")
training_args = TrainingArguments(
    output_dir="./model",
    per_device_train_batch_size=2,
    num_train_epochs=1,
    logging_dir="./logs",
    save_steps=100,
    save_total_limit=2,
    logging_steps=10,
    fp16=True,
    report_to=[]  # prevent reporting to wandb/hub/etc.
)

data_collator = DataCollatorForLanguageModeling(tokenizer=tokenizer, mlm=False)

with mlflow.start_run():
    # Log hyperparameters
    mlflow.log_param("model_name", model_name)
    mlflow.log_param("epochs", training_args.num_train_epochs)
    mlflow.log_param("batch_size", training_args.per_device_train_batch_size)

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=dataset,
        data_collator=data_collator
    )

    trainer.train()

    # Optional: manually log metrics (e.g., final loss)
    metrics = trainer.evaluate()
    for key, value in metrics.items():
        mlflow.log_metric(key, value)

    # Save and log model
    trainer.save_model("./model")
    mlflow.pytorch.log_model(model, "model")

print("Training complete and logged to MLflow.")
