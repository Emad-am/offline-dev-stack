# 🛡️ The Complete Offline Developer Stack

## Survive an Internet Shutdown — Keep Building Without Connectivity

**Last Updated:** March 2026
**Purpose:** A comprehensive, battle-tested guide to preparing a full offline development environment — AI models, coding agents, package managers, container images, documentation, git hosting, and system packages — so you can keep shipping code when the internet goes dark.

---

## Table of Contents

1. [Philosophy & Preparation Strategy](#1-philosophy--preparation-strategy)
2. [Local AI Models (Ollama + LLM Runners)](#2-local-ai-models-ollama--llm-runners)
3. [AI Chat Interface (Open WebUI)](#3-ai-chat-interface-open-webui)
4. [AI Coding Agent (VS Code + Continue.dev)](#4-ai-coding-agent-vs-code--continuedev)
5. [Docker Images — Offline Registry](#5-docker-images--offline-registry)
6. [NPM Packages — Verdaccio Local Registry](#6-npm-packages--verdaccio-local-registry)
7. [PHP Composer — Satis Local Mirror](#7-php-composer--satis-local-mirror)
8. [Python pip — devpi / Bandersnatch Mirror](#8-python-pip--devpi--bandersnatch-mirror)
9. [System Packages — APT Offline Mirror](#9-system-packages--apt-offline-mirror)
10. [Git Hosting — Gitea Self-Hosted](#10-git-hosting--gitea-self-hosted)
11. [Offline Documentation — Zeal / DevDocs](#11-offline-documentation--zeal--devdocs)
12. [Master Preparation Checklist](#12-master-preparation-checklist)
13. [Master Docker Compose — All-in-One Stack](#13-master-docker-compose--all-in-one-stack)
14. [Hardware Recommendations](#14-hardware-recommendations)
15. [Emergency "Go Dark" Procedure](#15-emergency-go-dark-procedure)

---

## 1. Philosophy & Preparation Strategy

### The Core Idea

Everything you depend on from the internet must be **cached, mirrored, or self-hosted locally** before connectivity is lost. This means:

- **AI models** → Downloaded and stored locally
- **Package registries** → Proxied and cached on your machine
- **Container images** → Saved as tarballs or in a local registry
- **Documentation** → Downloaded via offline browsers
- **Git remote** → Self-hosted on your LAN
- **System packages** → Mirrored locally

### Storage Budget (Rough Estimates)

| Component              | Approximate Size        |
|------------------------|------------------------|
| AI Models (3-5 models) | 15–40 GB               |
| Docker images (20-30)  | 10–30 GB               |
| NPM cache (per project)| 500 MB–2 GB            |
| Composer cache          | 200 MB–1 GB            |
| PyPI (selective)        | 1–10 GB                |
| APT mirror (selective)  | 20–100 GB              |
| Documentation (Zeal)    | 2–5 GB                 |
| Gitea + repos           | 1–10 GB                |
| **TOTAL**              | **~50–200 GB**         |

> **Recommendation:** Dedicate a 500GB–1TB SSD (internal or external) as your "offline vault."

---

## 2. Local AI Models (Ollama + LLM Runners)

Ollama is the simplest way to run LLMs locally. Once models are downloaded, **zero internet is needed**.

### 2.1 Install Ollama

```bash
# Linux / macOS
curl -fsSL https://ollama.com/install.sh | sh

# Verify
ollama --version
```

**Windows:** Download installer from https://ollama.com/download

**For air-gapped install:** Download the installer and model files on a connected machine, transfer via USB. See: https://github.com/khmowais/offline_ollama_guide

### 2.2 Download Models (Do This While Online!)

```bash
# General-purpose chat (pick based on your RAM)
ollama pull llama3.1:8b           # 4.7 GB — good for 8GB RAM
ollama pull llama3.1:70b-q4_K_M   # ~40 GB — needs 48GB+ RAM
ollama pull mistral:7b             # 4.1 GB — fast and capable
ollama pull gemma2:9b              # 5.4 GB — Google's model

# Code-specialized models (CRITICAL for offline dev)
ollama pull qwen2.5-coder:7b      # 4.7 GB — best code model for size
ollama pull deepseek-coder-v2:16b  # 8.9 GB — excellent reasoning
ollama pull codellama:13b          # 7.4 GB — Meta's code model
ollama pull starcoder2:7b          # 4.0 GB — code completion focused

# Small/fast models for autocomplete
ollama pull qwen2.5-coder:1.5b    # 1.0 GB — very fast, good for autocomplete
ollama pull phi3:mini              # 2.3 GB — Microsoft's small model
```

### 2.3 Verify & Manage Models

```bash
# List all downloaded models
ollama list

# Show model details
ollama show qwen2.5-coder:7b

# Test a model
ollama run llama3.1:8b "Write a Python function to merge two sorted lists"

# See running models
ollama ps

# Free space by removing unneeded models
ollama rm <model-name>
```

### 2.4 Model Storage Location

| OS      | Path                                      |
|---------|-------------------------------------------|
| Linux   | `~/.ollama/models`                        |
| macOS   | `~/.ollama/models`                        |
| Windows | `C:\Users\<username>\.ollama\models`      |

> **Backup tip:** Copy the entire `models/` directory to your offline vault.

### 2.5 Create Custom Model Profiles

Create a `Modelfile` for your preferred settings:

```dockerfile
# File: ~/models/my-coder.Modelfile
FROM qwen2.5-coder:7b

PARAMETER temperature 0.3
PARAMETER num_ctx 8192
PARAMETER top_p 0.9

SYSTEM """You are an expert software engineer. You write clean, well-tested
code. You explain your reasoning briefly. When asked to write code, you
provide complete, working implementations."""
```

Build it:

```bash
ollama create my-coder -f ~/models/my-coder.Modelfile

# Test it
ollama run my-coder "Create a REST API endpoint in Express.js for user registration"
```

### 2.6 Start the API Server

```bash
# Ollama automatically serves on port 11434
ollama serve

# Test the API
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Hello, world!",
  "stream": false
}'
```

---

## 3. AI Chat Interface (Open WebUI)

Open WebUI gives you a **ChatGPT-like browser interface** for your local models.

### 3.1 Quick Start (Docker)

```bash
# Pull the image WHILE ONLINE
docker pull ghcr.io/open-webui/open-webui:main

# Run it
docker run -d \
  -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

Visit **http://localhost:3000** — create an admin account on first launch.

### 3.2 Docker Compose (Ollama + Open WebUI Together)

```yaml
# File: docker-compose.openwebui.yml
version: '3.8'
services:
  ollama:
    container_name: ollama
    image: ollama/ollama:latest
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "11434:11434"
    restart: always
    # Uncomment for GPU support:
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: all
    #           capabilities: [gpu]

  open-webui:
    container_name: open-webui
    image: ghcr.io/open-webui/open-webui:main
    volumes:
      - openwebui_data:/app/backend/data
    ports:
      - "3000:8080"
    environment:
      - OLLAMA_API_BASE_URL=http://ollama:11434/api
    depends_on:
      - ollama
    restart: always

volumes:
  ollama_data:
  openwebui_data:
```

```bash
docker compose -f docker-compose.openwebui.yml up -d
```

### 3.3 Key Features Available Offline

- ✅ Multi-model switching
- ✅ Chat history and conversations
- ✅ Document upload + RAG (ask questions about your PDFs)
- ✅ Prompt templates
- ✅ Multi-user support with roles
- ✅ Mobile-friendly PWA

---

## 4. AI Coding Agent (VS Code + Continue.dev)

This gives you a **GitHub Copilot-like experience** — completely offline.

### 4.1 Install the Stack

1. **Install VS Code** (download `.deb`/`.exe` while online)
2. **Install the Continue extension:** Search "Continue" in VS Code Extensions (publisher: `continue.dev`)
3. **Ensure Ollama is running** with code models pulled (Section 2)

### 4.2 Configure Continue for Local Models

Open VS Code → Command Palette → `Continue: Open Config File`

```json
{
  "models": [
    {
      "title": "Qwen2.5 Coder 7B",
      "provider": "ollama",
      "model": "qwen2.5-coder:7b",
      "apiBase": "http://localhost:11434"
    },
    {
      "title": "DeepSeek Coder V2",
      "provider": "ollama",
      "model": "deepseek-coder-v2:16b",
      "apiBase": "http://localhost:11434"
    },
    {
      "title": "Llama 3.1 (General)",
      "provider": "ollama",
      "model": "llama3.1:8b",
      "apiBase": "http://localhost:11434"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Qwen Autocomplete",
    "provider": "ollama",
    "model": "qwen2.5-coder:1.5b",
    "apiBase": "http://localhost:11434"
  },
  "allowAnonymousTelemetry": false
}
```

### 4.3 What You Get

| Feature              | How to Use                                    |
|----------------------|-----------------------------------------------|
| **Autocomplete**     | Just type — suggestions appear inline (Tab)   |
| **Chat**             | Open Continue sidebar, ask anything            |
| **Edit code**        | Select code → Ctrl+I → describe changes       |
| **Explain code**     | Select code → right-click → "Explain"          |
| **Generate tests**   | Select function → "Write tests for this"       |
| **Refactor**         | Select code → "Refactor to use async/await"    |

### 4.4 Other Offline Coding Tools

| Tool                | Type                  | Notes                                     |
|---------------------|-----------------------|-------------------------------------------|
| **Aider**           | CLI code agent        | `pip install aider-chat`, works with Ollama|
| **Open Interpreter** | CLI AI assistant      | Natural language → shell commands          |
| **Tabby**           | Self-hosted Copilot   | Alternative to Continue.dev               |
| **LM Studio**       | GUI model runner      | Alternative to Ollama, has built-in chat   |

---

## 5. Docker Images — Offline Registry

### 5.1 Strategy: Save Images While Online

```bash
#!/bin/bash
# File: scripts/save-docker-images.sh
# Run this WHILE you have internet!

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

SAVE_DIR="$HOME/offline-vault/docker-images"
mkdir -p "$SAVE_DIR"

for IMAGE in "${IMAGES[@]}"; do
  echo "📦 Pulling: $IMAGE"
  docker pull "$IMAGE"

  # Create a safe filename
  FILENAME=$(echo "$IMAGE" | tr '/:' '_')
  echo "💾 Saving: $IMAGE → $FILENAME.tar"
  docker save -o "$SAVE_DIR/$FILENAME.tar" "$IMAGE"
done

echo "✅ All images saved to $SAVE_DIR"
ls -lh "$SAVE_DIR"
```

### 5.2 Load Images Offline

```bash
#!/bin/bash
# File: scripts/load-docker-images.sh

SAVE_DIR="$HOME/offline-vault/docker-images"

for TAR in "$SAVE_DIR"/*.tar; do
  echo "📥 Loading: $TAR"
  docker load -i "$TAR"
done

echo "✅ All images loaded"
docker images
```

### 5.3 Run a Local Docker Registry (For Teams/Multiple Machines)

```bash
# Load the registry image first
docker load -i ~/offline-vault/docker-images/registry_2.tar

# Start local registry
docker run -d -p 5000:5000 \
  -v registry_data:/var/lib/registry \
  --name local-registry \
  --restart always \
  registry:2

# Tag and push images to local registry
docker tag nginx:alpine localhost:5000/nginx:alpine
docker push localhost:5000/nginx:alpine

# Other machines on your LAN can now pull from:
# docker pull your-ip:5000/nginx:alpine
```

### 5.4 Configure Docker for Insecure Local Registry

```json
// File: /etc/docker/daemon.json
{
  "insecure-registries": ["localhost:5000", "192.168.1.100:5000"]
}
```

```bash
sudo systemctl restart docker
```

---

## 6. NPM Packages — Verdaccio Local Registry

Verdaccio acts as a **caching proxy** — it downloads packages from npmjs.com and stores them locally. Once cached, everything works offline.

### 6.1 Install & Start Verdaccio

```bash
# Option A: Global install
npm install -g verdaccio
verdaccio

# Option B: Docker (recommended)
docker pull verdaccio/verdaccio:latest  # do this while online!

docker run -d \
  -p 4873:4873 \
  -v verdaccio_storage:/verdaccio/storage \
  -v verdaccio_conf:/verdaccio/conf \
  --name verdaccio \
  --restart always \
  verdaccio/verdaccio:latest
```

### 6.2 Point NPM to Verdaccio

```bash
# Global config
npm set registry http://localhost:4873

# Or per-project (.npmrc in project root)
echo "registry=http://localhost:4873" > .npmrc

# Verify
npm config get registry
# Should show: http://localhost:4873
```

### 6.3 Cache Your Project Dependencies (Do While Online!)

```bash
# For each project you want to work on offline:
cd /path/to/your/project

# This installs AND caches everything through Verdaccio
npm install

# For multiple projects, repeat:
cd /path/to/another-project && npm install
cd /path/to/third-project && npm install
```

### 6.4 Verify Offline Operation

```bash
# Disconnect from internet, then:
rm -rf node_modules
npm install   # Should work from Verdaccio cache!
```

### 6.5 Pre-Cache Common Packages (Smart Move)

```bash
#!/bin/bash
# File: scripts/cache-npm-packages.sh
# Pre-cache popular packages through Verdaccio

PACKAGES=(
  "express" "fastify" "koa"
  "react" "react-dom" "next"
  "vue" "nuxt"
  "typescript" "ts-node" "tsx"
  "eslint" "prettier"
  "jest" "vitest" "mocha"
  "webpack" "vite" "esbuild" "rollup"
  "axios" "node-fetch"
  "prisma" "@prisma/client"
  "mongoose" "sequelize"
  "tailwindcss" "postcss" "autoprefixer"
  "dotenv" "zod" "lodash"
  "jsonwebtoken" "bcrypt"
  "@types/node" "@types/react" "@types/express"
)

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
npm init -y

for PKG in "${PACKAGES[@]}"; do
  echo "📦 Caching: $PKG"
  npm install "$PKG" --save 2>/dev/null || echo "⚠️  Failed: $PKG"
done

echo "✅ Packages cached in Verdaccio"
rm -rf "$TEMP_DIR"
```

### 6.6 Verdaccio Configuration

```yaml
# File: /verdaccio/conf/config.yaml
storage: /verdaccio/storage/data
plugins: /verdaccio/plugins

web:
  title: "Offline NPM Registry"
  enable: true

auth:
  htpasswd:
    file: /verdaccio/storage/htpasswd
    max_users: -1  # unlimited

uplinks:
  npmjs:
    url: https://registry.npmjs.org/
    timeout: 30s
    cache: true

packages:
  '@*/*':
    access: $all
    publish: $authenticated
    proxy: npmjs

  '**':
    access: $all
    publish: $authenticated
    proxy: npmjs

middlewares:
  audit:
    enabled: true

listen:
  - 0.0.0.0:4873
```

---

## 7. PHP Composer — Satis Local Mirror

### 7.1 Install Satis

```bash
composer create-project composer/satis --stability=dev --keep-vcs
```

### 7.2 Configure satis.json

```json
{
  "name": "offline/composer-mirror",
  "homepage": "http://localhost:8080",
  "repositories": [
    { "type": "composer", "url": "https://repo.packagist.org" }
  ],
  "require": {
    "laravel/framework": "*",
    "laravel/sanctum": "*",
    "laravel/tinker": "*",
    "guzzlehttp/guzzle": "*",
    "monolog/monolog": "*",
    "phpunit/phpunit": "*",
    "fakerphp/faker": "*",
    "symfony/console": "*",
    "symfony/http-foundation": "*",
    "doctrine/dbal": "*",
    "league/flysystem": "*",
    "spatie/laravel-permission": "*",
    "spatie/laravel-medialibrary": "*",
    "livewire/livewire": "*",
    "filament/filament": "*",
    "inertiajs/inertia-laravel": "*"
  },
  "require-dependencies": true,
  "require-dev-dependencies": true,
  "archive": {
    "directory": "dist",
    "format": "zip",
    "skip-dev": false
  }
}
```

### 7.3 Build the Mirror

```bash
# This downloads everything — run while online!
php bin/satis build satis.json public/
```

### 7.4 Serve Locally

```bash
# Quick PHP server
cd public/
php -S localhost:8080

# Or use nginx/apache for production
```

### 7.5 Configure Composer to Use Local Mirror

```json
// File: composer.json (in your project)
{
  "repositories": [
    {
      "type": "composer",
      "url": "http://localhost:8080"
    }
  ],
  "config": {
    "secure-http": false
  }
}
```

Or globally:

```bash
composer config -g repo.packagist false
composer config -g repositories.offline composer http://localhost:8080
```

### 7.6 Cache Entire Projects Quickly

```bash
# The simplest approach: just run composer install for each project while online
# Composer caches packages globally in ~/.cache/composer/

# To see the cache:
composer config cache-dir

# To pre-warm the cache for a project:
cd /path/to/laravel-project
composer install
composer update

# The global cache works offline too!
# Set COMPOSER_CACHE_DIR for a portable cache location
export COMPOSER_CACHE_DIR="$HOME/offline-vault/composer-cache"
```

---

## 8. Python pip — devpi / Bandersnatch Mirror

### 8.1 Option A: devpi (Recommended — Caching Proxy)

```bash
# Install
pip install devpi-server devpi-web devpi-client

# Initialize
devpi-init

# Start server
devpi-server --host 0.0.0.0 --port 3141

# Configure pip to use it
pip config set global.index-url http://localhost:3141/root/pypi/+simple/
pip config set global.trusted-host localhost
```

### 8.2 Pre-Cache Python Packages

```bash
#!/bin/bash
# File: scripts/cache-python-packages.sh

PACKAGES=(
  "django" "flask" "fastapi" "uvicorn"
  "requests" "httpx" "aiohttp"
  "sqlalchemy" "alembic"
  "celery" "redis"
  "pillow" "numpy" "pandas"
  "pytest" "black" "ruff" "mypy"
  "python-dotenv" "pydantic"
  "boto3" "paramiko"
  "beautifulsoup4" "scrapy"
  "aider-chat"
  "langchain" "chromadb"
)

for PKG in "${PACKAGES[@]}"; do
  echo "📦 Caching: $PKG"
  pip install "$PKG" 2>/dev/null || echo "⚠️  Failed: $PKG"
done
```

### 8.3 Option B: Bandersnatch (Full/Selective Mirror)

```bash
pip install bandersnatch

# Generate config
bandersnatch mirror --config-check

# Edit /etc/bandersnatch.conf
```

```ini
; File: /etc/bandersnatch.conf
[mirror]
directory = /var/pypi-mirror
master = https://pypi.org
timeout = 30
workers = 3

; To mirror EVERYTHING (warning: 500GB+):
; [plugins]
; enabled = 

; For selective mirroring, add allowlist:
[allowlist]
packages =
    django
    flask
    fastapi
    requests
    numpy
    pandas
```

```bash
# Run the mirror (while online)
bandersnatch mirror

# Serve with nginx or Python
cd /var/pypi-mirror
python3 -m http.server 8081 --directory web/

# Configure pip
pip config set global.index-url http://localhost:8081/simple/
```

### 8.4 Simplest Approach: pip download

```bash
# Download packages to a directory for offline install
mkdir -p ~/offline-vault/python-packages

pip download -d ~/offline-vault/python-packages \
  django flask fastapi requests numpy pandas

# Install offline from that directory
pip install --no-index --find-links ~/offline-vault/python-packages django
```

---

## 9. System Packages — APT Offline Mirror

### 9.1 Install apt-mirror

```bash
sudo apt update
sudo apt install apt-mirror apache2
```

### 9.2 Configure Mirror

```bash
# File: /etc/apt/mirror.list
set base_path    /var/spool/apt-mirror
set mirror_path  $base_path/mirror
set skel_path    $base_path/skel
set var_path     $base_path/var
set nthreads     20
set _tilde       0

# Ubuntu 24.04 LTS (noble) — adjust for your distro!
deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-security main restricted universe multiverse

clean http://archive.ubuntu.com/ubuntu
```

### 9.3 Run the Sync (While Online)

```bash
# This downloads A LOT — expect 50-150GB and several hours
sudo apt-mirror
```

### 9.4 Serve to Clients

```bash
# Symlink into Apache's web root
sudo ln -s /var/spool/apt-mirror/mirror/archive.ubuntu.com/ubuntu /var/www/html/ubuntu

# On client machines, edit /etc/apt/sources.list:
# deb http://your-mirror-ip/ubuntu noble main restricted universe multiverse
# deb http://your-mirror-ip/ubuntu noble-updates main restricted universe multiverse

sudo apt update  # Now pulls from your local mirror
```

### 9.5 Lighter Alternative: Download Specific .deb Files

```bash
# On a connected machine, download packages with dependencies:
mkdir -p ~/offline-vault/deb-packages

# Download a package and all its dependencies
apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests \
  --no-conflicts --no-breaks --no-replaces --no-enhances build-essential \
  | grep "^\w" | sort -u)

# Transfer the directory, then install on air-gapped machine:
sudo dpkg -i ~/offline-vault/deb-packages/*.deb
```

---

## 10. Git Hosting — Gitea Self-Hosted

Gitea is lightweight, fast, and gives you a full GitHub-like experience on your LAN.

### 10.1 Docker Setup (Recommended)

```yaml
# File: docker-compose.gitea.yml
version: "3"
services:
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__server__ROOT_URL=http://localhost:3300/
      - GITEA__server__HTTP_PORT=3300
      - GITEA__database__DB_TYPE=sqlite3
      - GITEA__service__DISABLE_REGISTRATION=false
      - GITEA__picture__DISABLE_GRAVATAR=true
      - GITEA__picture__ENABLE_FEDERATED_AVATAR=false
    volumes:
      - gitea_data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3300:3300"
      - "2222:22"
    restart: always

volumes:
  gitea_data:
```

```bash
docker compose -f docker-compose.gitea.yml up -d
# Visit http://localhost:3300 to complete setup
```

### 10.2 Binary Install (No Docker)

```bash
# Download binary while online
wget -O gitea https://dl.gitea.io/gitea/1.22/gitea-1.22.0-linux-amd64
chmod +x gitea
sudo mv gitea /usr/local/bin/

# Create user and directories
sudo adduser --system --shell /bin/bash --group --disabled-password --home /home/git git
sudo mkdir -p /var/lib/gitea/{data,log} /etc/gitea
sudo chown -R git:git /var/lib/gitea/
sudo chown root:git /etc/gitea
sudo chmod 770 /etc/gitea

# Run
sudo -u git /usr/local/bin/gitea web --config /etc/gitea/app.ini
# Visit http://localhost:3000
```

### 10.3 Mirror Your GitHub Repos (Before Going Offline!)

```bash
#!/bin/bash
# File: scripts/mirror-github-repos.sh

REPOS=(
  "https://github.com/you/project-a.git"
  "https://github.com/you/project-b.git"
  "https://github.com/you/project-c.git"
)

MIRROR_DIR="$HOME/offline-vault/git-mirrors"
mkdir -p "$MIRROR_DIR"

for REPO in "${REPOS[@]}"; do
  REPO_NAME=$(basename "$REPO" .git)
  echo "🔄 Mirroring: $REPO_NAME"
  if [ -d "$MIRROR_DIR/$REPO_NAME.git" ]; then
    cd "$MIRROR_DIR/$REPO_NAME.git" && git fetch --all
  else
    git clone --mirror "$REPO" "$MIRROR_DIR/$REPO_NAME.git"
  fi
done

echo "✅ All repos mirrored to $MIRROR_DIR"
```

### 10.4 Push Mirrors to Local Gitea

```bash
# After Gitea is running, create repos in the web UI, then:
cd /path/to/your/project
git remote add offline http://localhost:3300/you/project-a.git
git push offline --all
git push offline --tags
```

---

## 11. Offline Documentation — Zeal / DevDocs

### 11.1 Zeal (Linux/Windows — Desktop App)

```bash
# Install
sudo apt install zeal    # Ubuntu/Debian
# or: flatpak install flathub org.zealdocs.Zeal
# or: Download from https://zealdocs.org/download.html
```

Open Zeal → **Tools → Docsets** → Download these essential docsets while online:

**Recommended Docsets:**
- JavaScript, TypeScript, Node.js
- React, Vue.js, Angular
- HTML, CSS, Tailwind CSS
- PHP, Laravel
- Python 3, Django, Flask
- Docker, Bash, Nginx
- PostgreSQL, MySQL, Redis
- Git

### 11.2 DevDocs (Browser-Based, Works Offline)

1. Visit https://devdocs.io
2. Click **Preferences** → Select documentation sets
3. Enable **"Enable offline data"** in Settings
4. All selected docs are cached as a PWA

> **Pro tip:** Bookmark `devdocs.io` — it works from your browser cache even offline.

### 11.3 Manual Documentation Downloads

```bash
mkdir -p ~/offline-vault/docs

# Download specific doc sites with wget
wget --mirror --convert-links --page-requisites \
  --no-parent -P ~/offline-vault/docs \
  https://docs.docker.com/

# Download man pages for offline reference
sudo apt install manpages-dev manpages-posix-dev
```

---

## 12. Master Preparation Checklist

Run through this list **before the internet goes down**:

### AI Stack
- [ ] Ollama installed
- [ ] 2-3 general chat models downloaded (`llama3.1:8b`, `mistral:7b`)
- [ ] 2-3 code models downloaded (`qwen2.5-coder:7b`, `deepseek-coder-v2:16b`)
- [ ] 1 small autocomplete model (`qwen2.5-coder:1.5b`)
- [ ] Open WebUI Docker image pulled
- [ ] Continue.dev VS Code extension installed
- [ ] Continue config pointing to local Ollama

### Package Registries
- [ ] Verdaccio running + all project dependencies cached
- [ ] Satis built with archived packages (PHP projects)
- [ ] devpi running + key Python packages cached
- [ ] Yarn/pnpm configured to use Verdaccio (if applicable)

### Docker
- [ ] All project Docker images saved as tarballs
- [ ] Base images saved (node, php, python, nginx, alpine)
- [ ] Database images saved (postgres, mysql, redis, mongo)
- [ ] Tool images saved (registry, verdaccio, gitea, open-webui)

### Git & Code
- [ ] All repos cloned locally with `--mirror`
- [ ] Gitea running + repos pushed
- [ ] VS Code + extensions installed

### System & Docs
- [ ] APT mirror synced (or key .deb files downloaded)
- [ ] Zeal docsets downloaded
- [ ] DevDocs offline mode enabled
- [ ] Key reference PDFs / ebooks saved

---

## 13. Master Docker Compose — All-in-One Stack

```yaml
# File: docker-compose.offline-stack.yml
# Your complete offline development infrastructure

version: '3.8'

services:
  # === AI Layer ===
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "11434:11434"
    restart: always
    # GPU support:
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: all
    #           capabilities: [gpu]

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    volumes:
      - openwebui_data:/app/backend/data
    ports:
      - "3000:8080"
    environment:
      - OLLAMA_API_BASE_URL=http://ollama:11434/api
    depends_on:
      - ollama
    restart: always

  # === Package Registries ===
  verdaccio:
    image: verdaccio/verdaccio:latest
    container_name: verdaccio
    volumes:
      - verdaccio_storage:/verdaccio/storage
      - verdaccio_conf:/verdaccio/conf
    ports:
      - "4873:4873"
    restart: always

  # === Git Hosting ===
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__server__ROOT_URL=http://localhost:3300/
      - GITEA__server__HTTP_PORT=3300
      - GITEA__database__DB_TYPE=sqlite3
      - GITEA__picture__DISABLE_GRAVATAR=true
      - GITEA__picture__ENABLE_FEDERATED_AVATAR=false
    volumes:
      - gitea_data:/data
    ports:
      - "3300:3300"
      - "2222:22"
    restart: always

  # === Docker Registry ===
  registry:
    image: registry:2
    container_name: local-registry
    volumes:
      - registry_data:/var/lib/registry
    ports:
      - "5000:5000"
    restart: always

  # === Databases (as needed) ===
  postgres:
    image: postgres:16-alpine
    container_name: postgres
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: devdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: always

  redis:
    image: redis:7-alpine
    container_name: redis
    ports:
      - "6379:6379"
    restart: always

  mailhog:
    image: mailhog/mailhog:latest
    container_name: mailhog
    ports:
      - "1025:1025"  # SMTP
      - "8025:8025"  # Web UI
    restart: always

volumes:
  ollama_data:
  openwebui_data:
  verdaccio_storage:
  verdaccio_conf:
  gitea_data:
  registry_data:
  postgres_data:
```

```bash
# Start your entire offline infrastructure:
docker compose -f docker-compose.offline-stack.yml up -d

# Check everything is running:
docker compose -f docker-compose.offline-stack.yml ps
```

### Service URLs Summary

| Service          | URL                          | Purpose                      |
|------------------|------------------------------|------------------------------|
| Open WebUI       | http://localhost:3000         | AI Chat Interface            |
| Ollama API       | http://localhost:11434        | LLM API                     |
| Verdaccio        | http://localhost:4873         | NPM Registry                |
| Gitea            | http://localhost:3300         | Git Hosting                  |
| Docker Registry  | http://localhost:5000         | Container Registry           |
| PostgreSQL       | localhost:5432                | Database                     |
| Redis            | localhost:6379                | Cache                        |
| MailHog          | http://localhost:8025         | Email Testing                |

---

## 14. Hardware Recommendations

### Minimum (Solo developer, small models)
- **CPU:** 4-core modern processor
- **RAM:** 16 GB
- **Storage:** 256 GB SSD (main) + 500 GB (offline vault)
- **GPU:** Not required (CPU inference works, just slower)

### Recommended (Comfortable dev experience)
- **CPU:** 8-core (AMD Ryzen 7 / Intel i7)
- **RAM:** 32 GB
- **Storage:** 512 GB NVMe (main) + 1 TB SSD (offline vault)
- **GPU:** NVIDIA RTX 3060 12GB or better (huge speed boost for AI)

### Power User (Large models, team server)
- **CPU:** 16+ cores
- **RAM:** 64 GB+
- **Storage:** 2 TB NVMe
- **GPU:** NVIDIA RTX 4090 24GB or A100

---

## 15. Emergency "Go Dark" Procedure

When you learn an internet shutdown is coming, execute this rapid preparation:

```bash
#!/bin/bash
# File: scripts/go-dark.sh
# Emergency preparation script — run when internet shutdown is imminent!

set -e
echo "🚨 EMERGENCY OFFLINE PREPARATION STARTING..."
echo "============================================="

VAULT="$HOME/offline-vault"
mkdir -p "$VAULT"/{docker-images,git-mirrors,python-packages,deb-packages}

# 1. Pull latest AI models
echo "🤖 Step 1/6: Updating AI models..."
ollama pull llama3.1:8b
ollama pull qwen2.5-coder:7b
ollama pull qwen2.5-coder:1.5b

# 2. Update Docker images and save
echo "🐳 Step 2/6: Saving Docker images..."
IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>")
for IMAGE in $IMAGES; do
  FILENAME=$(echo "$IMAGE" | tr '/:' '_')
  docker pull "$IMAGE" 2>/dev/null || true
  docker save -o "$VAULT/docker-images/$FILENAME.tar" "$IMAGE"
done

# 3. Update all npm caches through Verdaccio
echo "📦 Step 3/6: Refreshing NPM caches..."
for DIR in ~/projects/*/; do
  if [ -f "$DIR/package.json" ]; then
    echo "  Caching: $DIR"
    (cd "$DIR" && npm install 2>/dev/null || true)
  fi
done

# 4. Update git mirrors
echo "🔄 Step 4/6: Fetching latest git changes..."
for MIRROR in "$VAULT"/git-mirrors/*.git; do
  if [ -d "$MIRROR" ]; then
    echo "  Fetching: $(basename $MIRROR)"
    (cd "$MIRROR" && git fetch --all 2>/dev/null || true)
  fi
done

# 5. Update Composer caches
echo "🎵 Step 5/6: Refreshing Composer caches..."
for DIR in ~/projects/*/; do
  if [ -f "$DIR/composer.json" ]; then
    echo "  Caching: $DIR"
    (cd "$DIR" && composer update --no-interaction 2>/dev/null || true)
  fi
done

# 6. System package updates
echo "🔧 Step 6/6: Final system updates..."
sudo apt update && sudo apt upgrade -y

echo ""
echo "============================================="
echo "✅ OFFLINE PREPARATION COMPLETE"
echo "============================================="
echo ""
echo "Your services:"
echo "  🤖 AI Chat:     http://localhost:3000"
echo "  📝 Code Agent:  Continue.dev in VS Code"
echo "  📦 NPM:         http://localhost:4873"
echo "  🔧 Git:         http://localhost:3300"
echo "  🐳 Registry:    http://localhost:5000"
echo ""
echo "You are ready to go dark. Good luck. 🛡️"
```

```bash
chmod +x scripts/go-dark.sh
./scripts/go-dark.sh
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│           OFFLINE DEV STACK - QUICK REF         │
├─────────────────────────────────────────────────┤
│                                                 │
│  AI CHAT         →  http://localhost:3000        │
│  AI API          →  http://localhost:11434       │
│  CODE AGENT      →  Continue.dev in VS Code     │
│  NPM REGISTRY    →  http://localhost:4873       │
│  GIT SERVER      →  http://localhost:3300        │
│  DOCKER REGISTRY →  http://localhost:5000        │
│  POSTGRES        →  localhost:5432               │
│  REDIS           →  localhost:6379               │
│  MAIL TESTING    →  http://localhost:8025        │
│                                                 │
│  npm set registry http://localhost:4873          │
│  pip config set global.index-url                │
│    http://localhost:3141/root/pypi/+simple/      │
│  ollama run qwen2.5-coder:7b                    │
│                                                 │
│  Start everything:                              │
│  docker compose -f docker-compose.offline-stack  │
│    .yml up -d                                   │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Sources & Further Reading

- **Ollama:** https://ollama.com | https://github.com/ollama/ollama
- **Open WebUI:** https://github.com/open-webui/open-webui
- **Continue.dev:** https://continue.dev | https://marketplace.visualstudio.com/items?itemName=Continue.continue
- **Verdaccio:** https://verdaccio.org
- **Satis (Composer):** https://github.com/composer/satis
- **devpi (Python):** https://devpi.net
- **Bandersnatch:** https://bandersnatch.readthedocs.io
- **Gitea:** https://gitea.com | https://docs.gitea.com
- **Zeal Docs:** https://zealdocs.org
- **DevDocs:** https://devdocs.io
- **Docker Air-Gap Guide:** https://docs.docker.com/engine/install/
- **Ollama Offline Guide:** https://github.com/khmowais/offline_ollama_guide
- **Aider (CLI agent):** https://aider.chat
- **LM Studio:** https://lmstudio.ai

---

*Prepared March 2026. Test your offline stack regularly — don't wait for the shutdown to discover something is missing.*
