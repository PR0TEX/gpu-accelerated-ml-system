from fastapi import FastAPI, Request
from pydantic import BaseModel
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

app = FastAPI()


model_name = "distilgpt2" 
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name).to("cuda")

class Prompt(BaseModel):
    prompt: str

@app.post("/generate")
def generate(prompt: Prompt):
    inputs = tokenizer.encode(prompt.prompt, return_tensors="pt").to("cuda")
    outputs = model.generate(inputs, max_length=100, do_sample=True)
    result = tokenizer.decode(outputs[0], skip_special_tokens=True)
    return {"response": result}
