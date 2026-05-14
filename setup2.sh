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
echo "[1/6] Verifying Docker..."
docker run hello-world > /dev/null 2>&1 && echo "      Docker is working." || {
  echo ""
  echo "ERROR: Docker isn't working yet."
  echo "Make sure you ran wsl --shutdown and reopened Ubuntu before running this script."
  exit 1
}

# --- Launch Open WebUI ---
echo "[2/6] Starting Open WebUI container..."

if docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
  echo "      Found existing open-webui container — removing it..."
  docker rm -f open-webui > /dev/null
fi

docker run -d \
  --network=host \
  -v ~/open-webui-data:/app/backend/data \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  --name open-webui \
  --restart always \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  ghcr.io/open-webui/open-webui:main

echo "      Container started. Waiting for Open WebUI to be ready..."
echo "      (First launch downloads models — this may take a minute or two...)"

spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
elapsed=0
until curl -sf "http://localhost:8080" > /dev/null 2>&1; do
  i=$((elapsed % 10))
  char="${spinner:$i:1}"
  printf "\r      %s Waiting for Open WebUI... %ds" "$char" "$elapsed"
  sleep 1
  elapsed=$((elapsed + 1))
  if [ $elapsed -ge 180 ]; then
    echo ""
    echo ""
    echo "ERROR: Open WebUI didn't respond after 3 minutes."
    echo "Check logs with: docker logs open-webui --tail 20"
    exit 1
  fi
done
printf "\r      ✓ Open WebUI is working. (%ds)          \n" "$elapsed"

# --- SearXNG configuration choices ---
echo "[3/6] SearXNG configuration..."
echo ""

# Engine selection
echo "  Search engines:"
echo "    1) Preset    — 7 curated engines (Google, Bing, DuckDuckGo, Brave,"
echo "                   Startpage, Wikipedia, Reddit)"
echo "    2) Defaults  — SearXNG's 93 built-in defaults (web, news, images,"
echo "                   science, files and more)"
echo ""
while true; do
  read -p "  Enter choice [1-2]: " engine_choice
  case "$engine_choice" in
    1) ENGINE_MODE="preset";   echo "      Preset engines selected.";   break ;;
    2) ENGINE_MODE="defaults"; echo "      SearXNG defaults selected."; break ;;
    *) echo "  Invalid choice. Please enter 1 or 2." ;;
  esac
done
echo ""

# Safe search
echo "  Safe search:"
echo "    1) Off      — no filtering"
echo "    2) Moderate — filter explicit images"
echo "    3) Strict   — filter explicit content"
echo ""
while true; do
  read -p "  Enter choice [1-3]: " safe_choice
  case "$safe_choice" in
    1) SAFE_SEARCH=0; echo "      Safe search off.";      break ;;
    2) SAFE_SEARCH=1; echo "      Moderate safe search."; break ;;
    3) SAFE_SEARCH=2; echo "      Strict safe search.";   break ;;
    *) echo "  Invalid choice. Please enter 1, 2 or 3." ;;
  esac
done
echo ""

# Max results
echo "  Max results per search:"
echo "    1) 10  — faster, lighter"
echo "    2) 20  — balanced (recommended)"
echo "    3) 30  — more results, slightly slower"
echo ""
while true; do
  read -p "  Enter choice [1-3]: " results_choice
  case "$results_choice" in
    1) MAX_RESULTS=10; echo "      Max results: 10."; break ;;
    2) MAX_RESULTS=20; echo "      Max results: 20."; break ;;
    3) MAX_RESULTS=30; echo "      Max results: 30."; break ;;
    *) echo "  Invalid choice. Please enter 1, 2 or 3." ;;
  esac
done
echo ""

# Image proxy
echo "  Image proxy (routes images through SearXNG for privacy):"
echo "    1) On   — recommended for privacy"
echo "    2) Off  — images load directly from source"
echo ""
while true; do
  read -p "  Enter choice [1-2]: " proxy_choice
  case "$proxy_choice" in
    1) IMAGE_PROXY=true;  echo "      Image proxy on.";  break ;;
    2) IMAGE_PROXY=false; echo "      Image proxy off."; break ;;
    *) echo "  Invalid choice. Please enter 1 or 2." ;;
  esac
done
echo ""

# --- Create SearXNG config ---
echo "[4/6] Creating SearXNG config..."
mkdir -p ~/searxng-config
sudo chown -R $USER:$USER ~/searxng-config

SECRET_KEY=$(openssl rand -hex 20)

# Build engine block based on selection
if [ "$ENGINE_MODE" = "preset" ]; then
  ENGINE_BLOCK="engines:
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
    disabled: false"
else
  ENGINE_BLOCK=""
fi

tee ~/searxng-config/settings.yml > /dev/null << EOF
use_default_settings: true

server:
  secret_key: "$SECRET_KEY"
  limiter: false
  image_proxy: $IMAGE_PROXY
  port: 8081
  bind_address: "0.0.0.0"

search:
  safe_search: $SAFE_SEARCH
  autocomplete: ""
  default_lang: ""
  max_results: $MAX_RESULTS
  formats:
    - html
    - json

$ENGINE_BLOCK
ui:
  static_use_hash: true
EOF

echo "      Config written."

# --- Launch SearXNG ---
echo "[5/6] Starting SearXNG container..."

if docker ps -a --format '{{.Names}}' | grep -q '^searxng$'; then
  echo "      Found existing searxng container — removing it..."
  docker rm -f searxng > /dev/null
fi

# Pull SearXNG image with up to 3 retries to handle TLS hiccups
MAX_RETRIES=3
attempt=1
until docker pull searxng/searxng; do
  if [ $attempt -ge $MAX_RETRIES ]; then
    echo ""
    echo "ERROR: Failed to pull SearXNG image after $MAX_RETRIES attempts."
    echo "Check your network connection and try again."
    exit 1
  fi
  echo "      Pull failed (attempt $attempt/$MAX_RETRIES) — retrying..."
  attempt=$((attempt + 1))
  sleep 3
done

docker run -d \
  --name searxng \
  --network=host \
  --restart always \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  -e SEARXNG_PORT=8081 \
  -v ~/searxng-config:/etc/searxng \
  searxng/searxng

echo "      Container started. Waiting for SearXNG to be ready..."
sleep 5

# --- Verify SearXNG is responding ---
echo "[6/6] Verifying SearXNG..."
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
