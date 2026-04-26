install-helm:
	sudo snap install helm --classic
	helm dependency build
	helm upgrade --install argocd . \
  --namespace argocd \
  --create-namespace \
  --values values.yaml


install-argocd:
	cd platform/argocd
	helm dependency update
	helm upgrade --install argocd . \
  --namespace argocd \
  --create-namespace \
  --values values.yaml

install-kyverno:
	cd platform/kyverno
	helm dependency update
	helm upgrade --install kyverno . \
  --namespace kyverno \
  --create-namespace \
  --values values.yaml


install-chaos-mesh:
	helm dependency build
	helm upgrade --install chaos-mesh . \
  --namespace chaos-mesh \
  --create-namespace \
  --values values.yaml