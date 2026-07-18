SERVICES := catalog cart checkout
IMAGE_REGISTRY ?= enterprise-commerce
IMAGE_TAG ?= local
PYTHON ?= python

.PHONY: test
test:
	$(PYTHON) -m unittest discover -s tests

.PHONY: docker-build
docker-build:
	for service in $(SERVICES); do \
		docker build --build-arg SERVICE=$$service -t $(IMAGE_REGISTRY)/$$service:$(IMAGE_TAG) .; \
	done

.PHONY: terraform-fmt
terraform-fmt:
	terraform fmt -recursive terraform

.PHONY: helm-lint
helm-lint:
	helm lint helm/ecommerce
