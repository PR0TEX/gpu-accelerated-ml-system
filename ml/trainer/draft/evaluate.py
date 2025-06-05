from datasets import load_metric
rouge = load_metric("rouge")

predictions = ["the capital of France is Paris"]
references = ["Paris is the capital of France"]

score = rouge.compute(predictions=predictions, references=references)
print(score)
