from huggingface_hub import HfApi, Repository
import os
import shutil

# Define variables
model_path = "/app/model"
repo_name = "your-username/your-model-name"
local_repo_dir = "/tmp/local_model_repo"
token = "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"
# Create repo on HF (skip if already created)
api = HfApi()
api.create_repo(name=repo_name.split("/")[-1], token=token, exist_ok=True)

# Clone the repo locally
repo_url = api.get_repo_url(repo_name, token=token)
repo = Repository(local_dir=local_repo_dir, clone_from=repo_url, use_auth_token=token)

# Copy model files
shutil.copytree(model_path, local_repo_dir, dirs_exist_ok=True)

# Push to hub
repo.push_to_hub(commit_message="Initial model push from pod")
