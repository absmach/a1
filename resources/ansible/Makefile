.PHONY: ping
ping: ## Run ansible playbook to ping all hosts playbooks/ping.yaml
	ansible-playbook playbooks/ping.yaml

.PHONY: setup
setup: ## Run ansible playbook to setup the BeagleBone-V Fire playbooks/setup.yaml
	ansible-playbook playbooks/setup.yaml

.PHONY: setup-magistrala
setup-magistrala: ## Run ansible playbook to setup magistrala on the BeagleBone-V Fire playbooks/setup-magistrala.yaml
	ansible-playbook playbooks/setup-magistrala.yaml

help: ## Show this help message
	@which awk > /dev/null || (echo "awk not found. Please install it from https://www.gnu.org/software/gawk/manual/gawk.html" && exit 1)
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
