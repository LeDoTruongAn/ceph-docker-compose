#!/bin/bash

# Check if the .env file exists
if [ -f .env ]; then
    # Load environment variables from .env
    source .env
    echo "Environment variables loaded from .env"
else
    echo "No .env file found"
fi


# Get the operating system type
OS=$(uname -s)

# Define the Docker Compose command based on the OS
if [ "$OS" = "Darwin" ]; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif [ "$OS" = "Linux" ]; then
    # shellcheck disable=SC2034
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "Unsupported operating system: $OS"
    exit 1
fi

