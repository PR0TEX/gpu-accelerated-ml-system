# gpu-accelerated-ml-system


## installing helm:

https://helm.sh/docs/intro/install/

## installing kubeai:


### fresh install:
```
helm repo add kubeai https://www.kubeai.org && helm repo update
helm install -f kubeai/helm-values.yaml kubeai kubeai/kubeai --wait --timeout 10m
```

### applying the custom resource profile:
If you ran the above, you can skip this step.

You only need to do this if the profile doesn't exist in the helm manifest. You can check by running:

```
helm get manifest kubeai
```

Save to file for easier search, ctrl+f "any-cuda-gpu". If it's there, you're good to go.
```
helm get manifest kubeai > some-file.yaml
```


To actually apply the profile:
```
helm upgrade -f kubeai/helm-values.yaml kubeai kubeai/kubeai
```

## port forwarding for kubeai:

```
kubectl port-forward svc/open-webui 8080:80
```

The ui should be available on http://localhost:8080


## serving model

```
kubectl apply -f kubeai/cpu-model.yaml
```

or

```
kubectl apply -f kubeai/gpu-model.yaml
```

This will create a model resource, which will pull the model specified in the manifest and create a pod serving that model. After the pod is created, the model should be visible in kubeai UI.

NOTE: You might need to send a request to the model in the UI for the pod to start creating. We should fix this so the pod is created automatically if possible.
