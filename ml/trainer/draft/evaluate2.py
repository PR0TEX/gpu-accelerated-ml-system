from transformers import AutoModelForCausalLM, AutoTokenizer
from datasets import load_dataset, load_metric
import torch

# Load fine-tuned model and tokenizer
model = AutoModelForCausalLM.from_pretrained("model").to("cuda")
tokenizer = AutoTokenizer.from_pretrained("model")
rouge = load_metric("rouge")

# Load or define evaluation set
dataset = [
    {
        "prompt": "What is the capital of France?",
        "expected": "Paris"
    },
    {
        "prompt": "Translate 'good night' to Spanish.",
        "expected": "Buenas noches"
    },
    # add more...
]

preds = []
refs = []

for sample in dataset:
    inputs = tokenizer.encode(sample["prompt"], return_tensors="pt").to("cuda")
    outputs = model.generate(inputs, max_length=50)
    prediction = tokenizer.decode(outputs[0], skip_special_tokens=True)

    preds.append(prediction)
    refs.append(sample["expected"])

score = rouge.compute(predictions=preds, references=refs)
