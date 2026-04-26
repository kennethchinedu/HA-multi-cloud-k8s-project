install-helm:
	sudo snap install helm --classic

install-argocd:
	cd platform/argocd && helm dependency update && helm upgrade --install argocd . \
		--namespace argocd \
		--create-namespace \
		--values values.yaml

install-kyverno:
	cd platform/kyverno && helm dependency update && helm upgrade --install kyverno . \
		--namespace kyverno \
		--create-namespace \
		--values values.yaml

install-chaos-mesh:
	cd platform/chaos-mesh && helm dependency update && helm upgrade --install chaos-mesh . \
		--namespace chaos-mesh \
		--create-namespace \
		--values values.yaml
