#!/bin/bash
# cache-npm-packages.sh — Pre-cache popular npm packages through Verdaccio
# Ensure Verdaccio is running and npm registry is set to http://localhost:4873

set -e

PACKAGES=(
  "express" "fastify" "koa" "hapi"
  "react" "react-dom" "next" "@next/env"
  "vue" "nuxt"
  "svelte" "@sveltejs/kit"
  "typescript" "ts-node" "tsx"
  "eslint" "prettier"
  "jest" "vitest" "mocha" "chai"
  "webpack" "vite" "esbuild" "rollup"
  "axios" "node-fetch" "got"
  "prisma" "@prisma/client"
  "mongoose" "sequelize" "knex"
  "tailwindcss" "postcss" "autoprefixer"
  "dotenv" "zod" "joi" "lodash"
  "jsonwebtoken" "bcrypt" "bcryptjs"
  "socket.io" "ws"
  "bull" "bullmq"
  "nodemailer"
  "sharp" "multer"
  "winston" "pino"
  "helmet" "cors" "compression"
  "@types/node" "@types/react" "@types/express"
)

echo "📦 NPM Package Cacher"
echo "====================="
echo "Registry: $(npm config get registry)"
echo ""

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
npm init -y --silent

CACHED=0
FAILED=0

for PKG in "${PACKAGES[@]}"; do
  echo -n "  📦 $PKG ... "
  if npm install "$PKG" --save --silent 2>/dev/null; then
    echo "✅"
    ((CACHED++))
  else
    echo "⚠️ failed"
    ((FAILED++))
  fi
done

echo ""
echo "✅ Cached: $CACHED | ⚠️ Failed: $FAILED"
rm -rf "$TEMP_DIR"
