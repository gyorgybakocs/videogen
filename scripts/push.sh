#!/bin/bash
set -e

IMAGE_NAME=$1

source ./scripts/login.sh

if [ -n "${DOCKER_TOKEN}" ]; then
    echo "🔑 Docker login for ${DOCKER_USER}..."
    echo "${DOCKER_TOKEN}" | docker login -u "${DOCKER_USER}" --password-stdin
    echo "✅ Docker login complete!"
else
    echo "⚠️  No Docker token provided, skipping docker login."
    exit 1
fi

docker push ${IMAGE_NAME}

if [ $? -ne 0 ]; then
    echo "Could not upload the image!"
    exit 1
fi

echo "🎉 Image was uploaded successfully to DockerHubra!"
