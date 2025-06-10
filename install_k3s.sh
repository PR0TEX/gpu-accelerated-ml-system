#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

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

install_helm() {
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    sudo chmod 700 get_helm.sh
    sudo $SCRIPT_DIR/get_helm.sh
    sudo rm $SCRIPT_DIR/get_helm.sh
}

setup_gpu_on_k3s() {
    export K3S_KUBECONFIG_MODE="644"
    curl -sfL http://get.k3s.io | sh -

    nvidia-ctk runtime configure --runtime=containerdWarning: resource runtimeclasses/nvidia is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.

    echo "[INFO]  Configuring, please wait..."
    sleep 5s
    echo "[INFO]  Done!"

    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    VAR_NAME="KUBECONFIG"
    VAR_VALUE="/etc/rancher/k3s/k3s.yaml"

    PROFILE_FILE="$HOME/.bashrc"

    if ! grep -q "export $VAR_NAME=" "$PROFILE_FILE"; then
        echo "export $VAR_NAME=\"$VAR_VALUE\"" >> "$PROFILE_FILE"
        echo "Added export $VAR_NAME=\"$VAR_VALUE\" to $PROFILE_FILE"
    else
        echo "$VAR_NAME is already set in $PROFILE_FILE"
    fi
    
    kubectl create ns gpu-setup
    kubectl apply -f $SCRIPT_DIR/nvidia-runtimeclass.yaml -n gpu-setup
    kubectl apply -f $SCRIPT_DIR/nvidia-device-plugin.yaml

    NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

    LABEL_KEY="node-type"
    LABEL_VALUE="gpu"

    kubectl label node "$NODE_NAME" "$LABEL_KEY=$LABEL_VALUE" --overwrite
}

setup_kubeai() {
    helm repo add kubeai https://www.kubeai.org 
    helm repo update
    helm install -f $SCRIPT_DIR/kubeai/helm-values.yaml kubeai kubeai/kubeai -n kubeai --create-namespace --wait --timeout 10m

    kubectl apply -f $SCRIPT_DIR/kubeai/cpu-model.yaml -n kubeai
    kubectl apply -f $SCRIPT_DIR/kubeai/gpu-model.yaml -n kubeai
    kubectl port-forward svc/open-webui -n kubeai 3000:80 &
}

setup_mlflow() {
    kubectl apply -f $SCRIPT_DIR/ml/mlflow -n mlflow
    kubectl port-forward svc/mlflow-service -n mlflow 5000:5000 &
}

setup_mlflow_autoregister() { 
    kubectl apply -f $SCRIPT_DIR/mlflow-autoregister -n mlflow-autoregister
}

setup_grafana_prometheus() {
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
        --namespace monitoring --create-namespace--watch
        -f $SCRIPT_DIR/monitoring/grafana/prometheus-values.yaml

    kubectl apply -f $SCRIPT_DIR/monitoring/grafana/dcgm-exporter.yaml -n monitoring
    
    kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3001:80 &
    kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090 &
}

setup_kubernetes_dashboard() {
    helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
    helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

    kubectl apply -f $SCRIPT_DIR/monitoring/kubernetes-dashboard  -n kubernetes-dashboard

    kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 &
    kubectl -n kubernetes-dashboard create token admin-user > $SCRIPT_DIR/kubernetes-dashboard-token.txt
}

setup_argo() {
    curl -sSL -o argocd-linux-amd64.gz https://github.com/argoproj/argo-workflows/releases/download/v3.6.10/argo-linux-amd64.gz
    gunzip argocd-linux-amd64.gz
    sudo mv argocd-linux-amd64 /usr/local/bin/argo
}

setup_argo_pipeline() {
    kubectl apply -f $SCRIPT_DIR/pipeline/setup-argo -n argo
    argo submit argo/train-llm.yaml -n argo
}

install_nvidia_toolkit

if command -v kubectl &>/dev/null; then
    echo "Kubectl already installed"
else
    install_kubectl
fi

if command helm version &>/dev/null; then
    echo "Helm already installed"
else
    install_helm
fi

setup_gpu_on_k3s
setup_kubeai
setup_mlflow
setup_mlflow_autoregister
setup_grafana_prometheus
setup_kubernetes_dashboard
setup_argo
setup_argo_pipeline
