IMAGE = 111111111111.dkr.ecr.eu-west-1.amazonaws.com/time
TAG   = 0.0.1

.PHONY: build
build:
	@docker build -t $(IMAGE):$(TAG) .

.PHONY: push
push:
	@docker push $(IMAGE):$(TAG)
