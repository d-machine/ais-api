#!/bin/bash

# Stop all running containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all volumes
docker volume rm $(docker volume ls -q)

# Build the API service using the development environment variables
docker-compose --env-file .env.development build api

# Start the API service
docker-compose --env-file .env.development up -d
