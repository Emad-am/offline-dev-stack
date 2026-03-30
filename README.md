# offline-dev

A collection of scripts and documentation for building a fully self-sufficient offline development environment. Survive internet outages and air-gapped environments while continuing to ship code.

> For the complete guide, see [OFFLINE-DEV-STACK.md](OFFLINE-DEV-STACK.md).

---

## What's Included

| File | Description |
|------|-------------|
| `OFFLINE-DEV-STACK.md` | Comprehensive guide covering AI models, package registries, Docker, git hosting, and more |
| `scripts/go-dark.sh` | Emergency preparation script — run when internet shutdown is imminent |
| `scripts/save-docker-images.sh` | Pull and save Docker images as tarballs while online |
| `scripts/load-docker-images.sh` | Load saved Docker image tarballs on an air-gapped machine |
| `scripts/cache-npm-packages.sh` | Pre-cache popular npm packages through a local Verdaccio registry |
| `scripts/mirror-github-repos.sh` | Clone/update bare mirrors of your GitHub repositories |

---

## Quick Start

### 1. Prepare while online

Run all preparation steps at once:

```bash
chmod +x scripts/*.sh

# Save Docker images
./scripts/save-docker-images.sh

# Mirror your GitHub repos (edit the REPOS array first)
./scripts/mirror-github-repos.sh

# Cache npm packages (requires Verdaccio running on :4873)
./scripts/cache-npm-packages.sh
```

### 2. Emergency mode

When internet loss is imminent, run the all-in-one preparation script:

```bash
./scripts/go-dark.sh
```

This will:
- Update local Ollama AI models
- Save all Docker images to `~/offline-vault/docker-images/`
- Refresh npm caches across your projects
- Fetch latest changes for all git mirrors
- Refresh Composer caches

### 3. Restore on an air-gapped machine

```bash
# Load Docker images from saved tarballs
./scripts/load-docker-images.sh ~/offline-vault/docker-images/
```

---

## Storage Requirements

| Component | Approximate Size |
|-----------|-----------------|
| AI models (3–5 models) | 15–40 GB |
| Docker images (20–30) | 10–30 GB |
| NPM cache | 500 MB–2 GB |
| Git mirrors | 1–10 GB |
| **Total** | **~50–200 GB** |

A 500 GB–1 TB dedicated SSD is recommended as an offline vault.

---

## Prerequisites

- Docker
- [Ollama](https://ollama.com)
- Node.js + npm
- [Verdaccio](https://verdaccio.org) (for npm caching)
- Git

---

## Offline Vault Layout

```
~/offline-vault/
├── docker-images/     # .tar files from save-docker-images.sh
├── git-mirrors/       # bare .git mirrors from mirror-github-repos.sh
└── python-packages/   # pip package cache
```
