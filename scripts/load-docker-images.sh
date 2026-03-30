#!/bin/bash
# load-docker-images.sh — Load all saved Docker image tarballs
# Run this on the air-gapped machine

set -e

SAVE_DIR="${1:-$HOME/offline-vault/docker-images}"

if [ ! -d "$SAVE_DIR" ]; then
  echo "❌ Directory not found: $SAVE_DIR"
  echo "Usage: $0 [path-to-saved-images]"
  exit 1
fi

echo "📥 Docker Image Loader — loading from $SAVE_DIR"
echo "================================================"

for TAR in "$SAVE_DIR"/*.tar; do
  [ -f "$TAR" ] || continue
  echo "📥 Loading: $(basename $TAR)"
  docker load -i "$TAR"
done

echo ""
echo "✅ All images loaded"
echo ""
docker images
