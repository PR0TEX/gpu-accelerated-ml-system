from huggingface_hub import HfApi, upload_folder
import os

token = "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"  # or hardcode it
model_path = "/app/model"
repo_name = "pr0tex/model-250"

# Create repo (safe if it exists)
api = HfApi()
api.create_repo(repo_id=repo_name, token=token, exist_ok=True)

# Upload folder to Hub
upload_folder(
    folder_path=model_path,
    repo_id=repo_name,
    repo_type="model",
    token=token,
    commit_message="Initial model upload from pod"
)
