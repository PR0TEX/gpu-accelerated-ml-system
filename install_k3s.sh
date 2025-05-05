#!/bin/bash

# install_prerequisites() {
#     apt-get update
#     apt install curl nvidia-container-toolkit nvidia-container-runtime cuda-drivers-fabricmanager-535 nvidia-headless-535-server nvidia-utils-535-server 

# }

install_docker() {
    # Add Docker's official GPG key:
    apt-get update
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_nvidia_toolkit() {
    apt-get update
    apt install -y curl
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg &&
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
        sed 's#deb https://#deb &#91;signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list


    sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
    apt-get update
    apt install -y nvidia-container-toolkit cuda-drivers-fabricmanager-535 nvidia-headless-535-server nvidia-utils-535-server
    ubuntu-drivers install
    # apt install nvidia-container-runtime 
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

# install_prerequisites
install_docker
install_nvidia_toolkit

if command -v kubectl &>/dev/null; then
    echo "Kubectl already installed"
else
    install_kubectl
fi

setup_gpu_on_k3s