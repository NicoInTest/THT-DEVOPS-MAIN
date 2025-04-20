THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_DIR      := $(dir $(realpath $(THIS_MAKEFILE)))

# Default environment is devopstht unless overridden
ENVIRONMENT ?= devopstht
# Get AWS account ID if not provided
AWS_ACCOUNT_ID ?= $(shell aws sts get-caller-identity --query Account --output text)

.PHONY: bootstrap
bootstrap:
	@@cd $(THIS_DIR) && chmod +x bootstrap_remote_state.sh && AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) ./bootstrap_remote_state.sh

.PHONY: tf-init
tf-init:
	@@cd $(THIS_DIR) && chmod +x deploy.sh && AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) ENVIRONMENT=$(ENVIRONMENT) ./deploy.sh init

.PHONY: tf-plan
tf-plan:
	@@cd $(THIS_DIR) && chmod +x deploy.sh && AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) ENVIRONMENT=$(ENVIRONMENT) ./deploy.sh plan

.PHONY: tf-apply
tf-apply:
	@@cd $(THIS_DIR) && chmod +x deploy.sh && AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) ENVIRONMENT=$(ENVIRONMENT) ./deploy.sh apply

.PHONY: tf-destroy
tf-destroy:
	@@cd $(THIS_DIR) && chmod +x deploy.sh && AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) ENVIRONMENT=$(ENVIRONMENT) ./deploy.sh destroy

.PHONY: tf-ecr-init
tf-ecr-init:
	@@cd $(THIS_DIR)/../../ecr/terraform && chmod +x deploy.sh && AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) ENVIRONMENT=$(ENVIRONMENT) ./deploy.sh init

.PHONY: tf-ecr-plan
tf-ecr-plan:
	@@cd $(THIS_DIR)/../../ecr/terraform && chmod +x deploy.sh && AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) ENVIRONMENT=$(ENVIRONMENT) ./deploy.sh plan

.PHONY: tf-ecr-apply
tf-ecr-apply:
	@@cd $(THIS_DIR)/../../ecr/terraform && chmod +x deploy.sh && AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) ENVIRONMENT=$(ENVIRONMENT) ./deploy.sh apply

.PHONY: tf-ecr-destroy
tf-ecr-destroy:
	@@cd $(THIS_DIR)/../../ecr/terraform && chmod +x deploy.sh && AWS_ACCOUNT_ID=$(AWS_ACCOUNT_ID) ENVIRONMENT=$(ENVIRONMENT) ./deploy.sh destroy

.PHONY: tf-graph
tf-graph:
	@@cd $(THIS_DIR) && terraform graph -type=plan

	