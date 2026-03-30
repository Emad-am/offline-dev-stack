#!/bin/bash
# go-dark.sh — Emergency offline preparation
# Run when internet shutdown is imminent!

set -e

echo ""
echo "🚨 ==========================================="
echo "   EMERGENCY OFFLINE PREPARATION"
echo "   ==========================================="
echo ""

VAULT="$HOME/offline-vault"
mkdir -p "$VAULT"/{docker-images,git-mirrors,python-packages}

# ─── 1. AI Models ───
echo "🤖 [1/6] Updating AI models..."
ollama pull llama3.1:8b 2>/dev/null || echo "  ⚠️ llama3.1:8b skipped"
ollama pull qwen2.5-coder:7b 2>/dev/null || echo "  ⚠️ qwen2.5-coder:7b skipped"
ollama pull qwen2.5-coder:1.5b 2>/dev/null || echo "  ⚠️ qwen2.5-coder:1.5b skipped"
ollama pull mistral:7b 2>/dev/null || echo "  ⚠️ mistral:7b skipped"
echo "  ✅ AI models done"

# ─── 2. Docker Images ───
echo ""
echo "🐳 [2/6] Saving Docker images..."
IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>")
for IMAGE in $IMAGES; do
  FILENAME=$(echo "$IMAGE" | tr '/:' '_')
  docker pull "$IMAGE" 2>/dev/null || true
  docker save -o "$VAULT/docker-images/$FILENAME.tar" "$IMAGE" 2>/dev/null || true
done
echo "  ✅ Docker images done"

# ─── 3. NPM Caches ───
echo ""
echo "📦 [3/6] Refreshing NPM caches..."
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"
if [ -d "$PROJECTS_DIR" ]; then
  for DIR in "$PROJECTS_DIR"/*/; do
    if [ -f "$DIR/package.json" ]; then
      echo "  📦 $(basename $DIR)"
      (cd "$DIR" && npm install --silent 2>/dev/null || true)
    fi
  done
fi
echo "  ✅ NPM caches done"

# ─── 4. Git Mirrors ───
echo ""
echo "🔄 [4/6] Fetching latest git changes..."
for MIRROR in "$VAULT"/git-mirrors/*.git; do
  if [ -d "$MIRROR" ]; then
    echo "  🔄 $(basename $MIRROR)"
    (cd "$MIRROR" && git fetch --all --prune 2>/dev/null || true)
  fi
done
echo "  ✅ Git mirrors done"

# ─── 5. Composer Caches ───
echo ""
echo "🎵 [5/6] Refreshing Composer caches..."
if [ -d "$PROJECTS_DIR" ]; then
  for DIR in "$PROJECTS_DIR"/*/; do
    if [ -f "$DIR/composer.json" ]; then
      echo "  🎵 $(basename $DIR)"
      (cd "$DIR" && composer update --no-interaction --quiet 2>/dev/null || true)
    fi
  done
fi
echo "  ✅ Composer caches done"

# ─── 6. System Updates ───
echo ""
echo "🔧 [6/6] System updates..."
sudo apt update -qq && sudo apt upgrade -y -qq 2>/dev/null || echo "  ⚠️ apt update skipped"
echo "  ✅ System updates done"

# ─── Summary ───
echo ""
echo "==========================================="
echo "✅ OFFLINE PREPARATION COMPLETE"
echo "==========================================="
echo ""
echo "Your services:"
echo "  🤖 AI Chat:      http://localhost:3000"
echo "  📝 Code Agent:   Continue.dev in VS Code"
echo "  📦 NPM Registry: http://localhost:4873"
echo "  🔧 Git Server:   http://localhost:3300"
echo "  🐳 Docker Reg:   http://localhost:5000"
echo "  📊 Database:     localhost:5432 (postgres)"
echo "  📧 Mail Test:    http://localhost:8025"
echo ""
echo "Start all services:"
echo "  docker compose -f docker-compose.offline-stack.yml up -d"
echo ""
echo "You are ready to go dark. Good luck. 🛡️"
