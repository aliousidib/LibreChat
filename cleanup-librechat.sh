#!/bin/bash

# Stop and remove containers
docker stop librechat mongodb meilisearch
docker rm librechat mongodb meilisearch

# Remove network
docker network rm librechat-net

# Remove volumes (optional, uncomment if you want to clear data)
# rm -rf data-node meili_data 