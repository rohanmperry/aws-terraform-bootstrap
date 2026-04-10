TERRAFORM_DIR := terraform

.PHONY: init plan apply destroy fmt check-env

check-env:
ifndef GITHUB_ORG
	$(error GITHUB_ORG is not set. Usage: make <target> GITHUB_ORG=your-org)
endif

init:
	terraform -chdir=$(TERRAFORM_DIR) init

plan: check-env
	terraform -chdir=$(TERRAFORM_DIR) plan -var="github_org=$(GITHUB_ORG)"

apply: check-env
	terraform -chdir=$(TERRAFORM_DIR) apply -var="github_org=$(GITHUB_ORG)"

destroy: check-env
	terraform -chdir=$(TERRAFORM_DIR) destroy -var="github_org=$(GITHUB_ORG)"

fmt:
	terraform -chdir=$(TERRAFORM_DIR) fmt -recursive
