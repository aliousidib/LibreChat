#!/bin/bash

# Stop and remove existing containers
docker stop librechat-frontend librechat-api mongodb meilisearch vectordb rag_api 2>/dev/null
docker rm librechat-frontend librechat-api mongodb meilisearch vectordb rag_api 2>/dev/null

# Remove existing network
docker network rm librechat-net 2>/dev/null

# Create network
docker network create librechat-net

# Build and start all services
docker compose up --build -d

# Check the status of all containers
echo "Checking container status..."
docker ps

# Follow the logs
echo "Following logs... (Ctrl+C to exit)"
docker compose logs -f 