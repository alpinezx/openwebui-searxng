#!/bin/bash
# =============================================================
# setup2.sh — Launch Open WebUI and SearXNG
# Run this after restarting WSL following setup1.sh.
# =============================================================

set -e  # Stop immediately if any command fails

echo ""
echo "============================================="
echo " Open WebUI + SearXNG Setup — Part 2 of 2"
echo "============================================="
echo ""

# --- Verify Docker is working ---
echo "[1/5] Verifying Docker..."
docker run hello-world > /dev/null 2>&1 && echo "      Docker is working." || {
  echo ""
  echo "ERROR: Docker isn't working yet."
  echo "Make sure you ran wsl --shutdown and reopened Ubuntu before running this script."
  exit 1
}

# --- Launch Open WebUI ---
echo "[2/5] Starting Open WebUI container..."
docker run -d \
  --network=host \
  -v ~/open-webui-data:/app/backend/data \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "      Container started. Waiting for Open WebUI to be ready..."
sleep 8

# --- Verify Open WebUI is responding ---
echo "      Verifying Open WebUI..."
curl -sf "http://localhost:8080" > /dev/null && echo "      Open WebUI is working." || {
  echo ""
  echo "ERROR: Open WebUI didn't respond. Check logs with: docker logs open-webui --tail 20"
  exit 1
}

# --- Create SearXNG config ---
echo "[3/5] Creating SearXNG config..."
sudo mkdir -p ~/searxng-config
sudo chown -R $USER:$USER ~/searxng-config

sudo tee ~/searxng-config/settings.yml > /dev/null << 'EOF'
use_default_settings: true

server:
  secret_key: "changethis123456789"
  limiter: false
  image_proxy: true
  port: 8081
  bind_address: "0.0.0.0"

search:
  safe_search: 0
  autocomplete: ""
  default_lang: ""
  max_results: 15
  formats:
    - html
    - json

engines:
  - name: google
    engine: google
    disabled: false
  - name: bing
    engine: bing
    disabled: false
  - name: duckduckgo
    engine: duckduckgo
    disabled: false
  - name: brave
    engine: brave
    disabled: false
  - name: startpage
    engine: startpage
    disabled: false
  - name: wikipedia
    engine: wikipedia
    disabled: false
  - name: reddit
    engine: reddit
    disabled: false

ui:
  static_use_hash: true
EOF

echo "      Config written."

# --- Launch SearXNG ---
echo "[4/5] Starting SearXNG container..."
docker run -d \
  --name searxng \
  --network=host \
  --restart always \
  -e SEARXNG_PORT=8081 \
  -v ~/searxng-config:/etc/searxng \
  searxng/searxng

echo "      Container started. Waiting for SearXNG to be ready..."
sleep 5

# --- Verify SearXNG is responding ---
echo "[5/5] Verifying SearXNG..."
curl -sf "http://localhost:8081/search?q=test&format=json" > /dev/null && echo "      SearXNG is working." || {
  echo ""
  echo "ERROR: SearXNG didn't respond. Check logs with: docker logs searxng --tail 20"
  exit 1
}

echo ""
echo "============================================="
echo " Setup complete!"
echo ""
echo " Open WebUI:  http://localhost:8080"
echo " SearXNG:     http://localhost:8081"
echo ""
echo " *** ACTION REQUIRED ***"
echo " Open http://localhost:8080 in your browser"
echo " and create your admin account."
echo " The first account created is permanent admin."
echo ""
echo " Then connect SearXNG in Open WebUI:"
echo " Admin Panel → Settings → Web Search"
echo " See the README for full instructions."
echo "============================================="
echo ""
