.PHONY: all build run shell logs stop clean provision help

IMAGE_NAME := bgds/bgds
IMAGE_TAG  := svd-base-1.0
CONTAINER_NAME := svd-app-container
GPU_DEVICE := all

export IMAGE_NAME
export IMAGE_TAG
export CONTAINER_NAME
export GPU_DEVICE

all: build

init:
	@echo "Initialize the server..."
	@bash ./scripts/server_init.sh

build:
	@echo "Build docker image: $(IMAGE_NAME):$(IMAGE_TAG)..."
	@docker compose -f docker-compose-build.yml build

push:
	@echo "Push docker image: $(IMAGE_NAME):$(IMAGE_TAG)..."
	@bash ./scripts/push.sh $(IMAGE_NAME):$(IMAGE_TAG)

provision:
	@echo "download models and some necessary things..."
	@bash ./scripts/provision.sh ./models

up:
	@echo "run container: $(CONTAINER_NAME)..."
	@docker compose -f docker-compose.yml up -d

logs:
	@echo "logs from $(CONTAINER_NAME) ..."
	@docker compose logs -f $(SERVICE_NAME)

down:
	@docker compose down
