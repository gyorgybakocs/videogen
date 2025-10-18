.PHONY: all build run shell logs stop clean provision help

IMAGE_NAME := my-ai-app
IMAGE_TAG  := latest
CONTAINER_NAME := my-ai-app-container
GPU_DEVICE := all

all: build

build:
	@echo "build docker image: $(IMAGE_NAME):$(IMAGE_TAG)..."
	@docker compose -f docker-compose-build.yml build

provision:
	@echo "download models and some necessary things..."
	@mkdir -p./models
	@bash ./scripts/provision.sh ./models

up:
	@echo "run container: $(CONTAINER_NAME)..."
	@docker compose -f docker-compose.yml up -d

logs:
	@echo "logs from $(CONTAINER_NAME) ..."
	@docker compose logs -f $(SERVICE_NAME)

down:
	@docker compose down
