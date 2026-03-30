#!/bin/bash
# mirror-github-repos.sh — Clone/update bare mirrors of your GitHub repos
# Edit the REPOS array with your own repositories!

set -e

REPOS=(
  # Add your repos here:
  # "https://github.com/you/project-a.git"
  # "https://github.com/you/project-b.git"
)

MIRROR_DIR="${1:-$HOME/offline-vault/git-mirrors}"
mkdir -p "$MIRROR_DIR"

if [ ${#REPOS[@]} -eq 0 ]; then
  echo "⚠️  No repos configured!"
  echo "Edit this script and add your repos to the REPOS array."
  exit 1
fi

echo "🔄 Git Mirror Script — saving to $MIRROR_DIR"
echo "=============================================="

for REPO in "${REPOS[@]}"; do
  REPO_NAME=$(basename "$REPO" .git)
  echo ""
  
  if [ -d "$MIRROR_DIR/$REPO_NAME.git" ]; then
    echo "🔄 Updating mirror: $REPO_NAME"
    cd "$MIRROR_DIR/$REPO_NAME.git" && git fetch --all --prune
  else
    echo "📥 Cloning mirror: $REPO_NAME"
    git clone --mirror "$REPO" "$MIRROR_DIR/$REPO_NAME.git"
  fi
done

echo ""
echo "✅ All repos mirrored to $MIRROR_DIR"
ls -la "$MIRROR_DIR"
