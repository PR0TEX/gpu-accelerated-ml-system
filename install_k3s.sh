#!/bin/bash

install_nvidia_toolkit() {
    sudo apt-get install -y curl
    sudo curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg --yes &&
        sudo curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
        sudo sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list


    sudo sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit nvidia-container-runtime cuda-drivers-fabricmanager-535 nvidia-headless-535-server nvidia-utils-535-server 
}

install_kubectl() {
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
}

setup_gpu_on_k3s() {
    export K3S_KUBECONFIG_MODE="644"
    curl -sfL http://get.k3s.io | sh -

    nvidia-ctk runtime configure --runtime=containerdWarning: resource runtimeclasses/nvidia is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.

    echo "[INFO]  Configuring, please wait..."
    sleep 5s
    echo "[INFO]  Done!"

    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    
    kubectl create ns gpu-setup
    kubectl apply -f $SCRIPT_DIR/nvidia-runtimeclass.yaml -n gpu-setup
    kubectl apply -f $SCRIPT_DIR/nvidia-device-plugin.yaml
    kubectl apply -f $SCRIPT_DIR/init-pod.yaml -n gpu-setup
}

install_nvidia_toolkit

if command -v kubectl &>/dev/null; then
    echo "Kubectl already installed"
else
    install_kubectl
fi

setup_gpu_on_k3s
