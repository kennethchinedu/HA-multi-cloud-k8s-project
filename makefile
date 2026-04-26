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


install-policy-reporter:
	helm repo add policy-reporter https://kyverno.github.io/policy-reporter && \
	helm repo update && \
	helm upgrade --install policy-reporter policy-reporter/policy-reporter \
		--namespace policy-reporter \
		--create-namespace \
		--set kyvernoPlugin.enabled=true \
		--set target.slack.minimumSeverity="medium"
