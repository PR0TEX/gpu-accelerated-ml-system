#!/bin/bash

install_nvidia_toolkit() {
    apt install -y curl
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg --yes &&
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list


    sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
    apt update
    apt install -y nvidia-container-toolkit nvidia-container-runtime cuda-drivers-fabricmanager-535 nvidia-headless-535-server nvidia-utils-535-server
}

install_kubectl() {
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
}

setup_gpu_on_k3s() {
    curl -sfL http://get.k3s.io | K3S_URL=https://10.1.0.21:6443 sh -s -
    nvidia-ctk runtime configure --runtime=containerd
    ctr image pull docker.io/nvidia/cuda:12.3.2-base-ubuntu22.04
    ctr run --rm --gpus 0 -t docker.io/nvidia/cuda:12.3.2-base-ubuntu22.04 cuda-12.3.2-base-ubuntu22.04 nvidia-smi
    kubectl apply -f nvidia-runtimeclass.yaml
    kubectl apply -f nvidia-device-plugin.yaml 
}

install_nvidia_toolkit

if command -v kubectl &>/dev/null; then
    echo "Kubectl already installed"
else
    install_kubectl
fi

setup_gpu_on_k3s