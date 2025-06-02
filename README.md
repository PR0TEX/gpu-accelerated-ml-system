# gpu-accelerated-ml-system


## installing helm:

https://helm.sh/docs/intro/install/

## installing kubeai:

```
helm repo add kubeai https://www.kubeai.org && helm repo update
helm install kubeai kubeai/kubeai --wait --timeout 10m
```


## port forwarding for kubeai:

```
kubectl port-forward svc/open-webui 8080:80
```

The ui should be available on http://localhost:8080


## serving model

```
kubectl apply -f cpu-model.yaml
```

This will create a model resource, which will pull the model specified in the manifest and create a pod serving that model. After the pod is created, the model should be visible in kubeai UI.
