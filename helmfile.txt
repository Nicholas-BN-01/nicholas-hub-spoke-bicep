Ingress Deployment through Helm:
    - helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx --create-namespace -f Helm_Ingress/values.yaml

Resources Deployment through Kustomizations
    - kubectl apply -k Kube_Components/base/
