#!/bin/bash
# save-docker-images.sh — Pull and save all needed Docker images as tarballs
# Run this WHILE you have internet!

set -e

IMAGES=(
  "node:20-alpine"
  "node:20"
  "php:8.3-fpm"
  "php:8.3-cli"
  "composer:latest"
  "nginx:alpine"
  "mysql:8.0"
  "mariadb:11"
  "postgres:16-alpine"
  "redis:7-alpine"
  "mongo:7"
  "python:3.12-slim"
  "golang:1.22-alpine"
  "ubuntu:24.04"
  "debian:bookworm-slim"
  "alpine:3.19"
  "registry:2"
  "verdaccio/verdaccio:latest"
  "ollama/ollama:latest"
  "ghcr.io/open-webui/open-webui:main"
  "gitea/gitea:latest"
  "mailhog/mailhog:latest"
  "minio/minio:latest"
  "traefik:v3.0"
  "dpage/pgadmin4:latest"
  "phpmyadmin:latest"
)

SAVE_DIR="${1:-$HOME/offline-vault/docker-images}"
mkdir -p "$SAVE_DIR"

echo "🐳 Docker Image Saver — saving to $SAVE_DIR"
echo "================================================"

for IMAGE in "${IMAGES[@]}"; do
  echo ""
  echo "📦 Pulling: $IMAGE"
  docker pull "$IMAGE" || { echo "⚠️  Failed to pull: $IMAGE"; continue; }

  FILENAME=$(echo "$IMAGE" | tr '/:' '_')
  echo "💾 Saving: $IMAGE → $FILENAME.tar"
  docker save -o "$SAVE_DIR/$FILENAME.tar" "$IMAGE"
done

echo ""
echo "✅ All images saved to $SAVE_DIR"
echo ""
ls -lh "$SAVE_DIR"
