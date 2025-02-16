#!/bin/bash

# Stop and remove existing containers
docker stop librechat mongodb meilisearch vectordb rag_api 2>/dev/null
docker rm librechat mongodb meilisearch vectordb rag_api 2>/dev/null

# Remove existing network
docker network rm librechat-net 2>/dev/null

# Ensure config file exists
if [ ! -f "librechat.yaml" ]; then
    echo "Creating librechat.yaml from example file..."
    cp librechat.example.yaml librechat.yaml
fi

# Verify config file exists
if [ ! -f "librechat.yaml" ]; then
    echo "Error: librechat.yaml not found!"
    exit 1
fi
echo "Found librechat.yaml, proceeding with build..."

# Create network
docker network create librechat-net

# Start MongoDB
docker run -d \
  --name mongodb \
  --network librechat-net \
  -v ./data-node:/data/db \
  mongo

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to be ready..."
sleep 10

# Start Meilisearch
docker run -d \
  --name meilisearch \
  --network librechat-net \
  -v ./meili_data:/meili_data \
  getmeili/meilisearch:v1.7.3

# Start VectorDB
docker run -d \
  --name vectordb \
  --network librechat-net \
  -v pgdata2:/var/lib/postgresql/data \
  -e POSTGRES_DB=mydatabase \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  ankane/pgvector:latest

# Start RAG API
docker run -d \
  --name rag_api \
  --network librechat-net \
  -e DB_HOST=vectordb \
  -e RAG_PORT=8000 \
  -e POSTGRES_DB=mydatabase \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  --env-file .env \
  ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest

# Build LibreChat
docker build -f Dockerfile.multi \
  --target api-build \
  --build-arg NODE_ENV=production \
  -t librechat .

# Convert Windows path to Docker format
DOCKER_PATH=$(pwd -W | sed 's/\\/\//g' | sed 's/://')

# Start LibreChat
docker run -d \
  --name librechat \
  --network librechat-net \
  -p 3080:3080 \
  --env-file .env \
  -v ./images:/app/client/public/images \
  -v ./logs:/app/api/logs \
  -v "/$DOCKER_PATH/librechat.yaml:/app/librechat.yaml" \
  -e HOST=0.0.0.0 \
  -e MONGO_URI=mongodb://mongodb:27017/LibreChat \
  -e MEILI_HOST=http://meilisearch:7700 \
  -e RAG_PORT=8000 \
  -e RAG_API_URL=http://rag_api:8000 \
  librechat

# Verify config file is mounted
echo "Verifying config file mount..."
docker exec librechat ls -l /app/librechat.yaml

echo "Containers started. Check logs with: docker logs librechat"