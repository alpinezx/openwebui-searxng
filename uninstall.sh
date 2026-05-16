#!/bin/bash
# =============================================================
# uninstall.sh — Remove Open WebUI and/or SearXNG
# Must be run as root: sudo bash uninstall.sh
# Detects what's installed and builds the menu dynamically.
# Cleans up only what was installed by the setup script.
# =============================================================

# --- Ensure running as root ---
if [ "$EUID" -ne 0 ]; then
  echo ""
  echo "ERROR: This script must be run as root."
  echo "       Please run: sudo bash uninstall.sh"
  echo ""
  exit 1
fi

# =============================================================
# Helper functions
# =============================================================

remove_searxng() {
  echo ""
  echo "--- Removing SearXNG ---"

  if docker ps -a --format '{{.Names}}' | grep -q '^searxng$'; then
    echo "  Stopping and removing searxng container..."
    docker stop searxng > /dev/null 2>&1
    docker rm searxng > /dev/null 2>&1
    echo "  [x] Container removed."
  else
    echo "  [ ] No searxng container found — skipping."
  fi

  if docker images --format '{{.Repository}}' | grep -q '^searxng/searxng$'; then
    echo "  Removing searxng image..."
    docker rmi searxng/searxng > /dev/null 2>&1
    echo "  [x] Image removed."
  else
    echo "  [ ] No searxng image found — skipping."
  fi

  if [ -d /root/searxng-config ]; then
    echo "  Removing /root/searxng-config..."
    rm -rf /root/searxng-config
    echo "  [x] Config directory removed."
  else
    echo "  [ ] No searxng-config directory found — skipping."
  fi

  echo ""
}

remove_openwebui() {
  echo ""
  echo "--- Removing Open WebUI ---"

  if docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
    echo "  Stopping and removing open-webui container..."
    docker stop open-webui > /dev/null 2>&1
    docker rm open-webui > /dev/null 2>&1
    echo "  [x] Container removed."
  else
    echo "  [ ] No open-webui container found — skipping."
  fi

  if docker images --format '{{.Repository}}' | grep -q '^ghcr.io/open-webui/open-webui$'; then
    echo "  Removing open-webui image..."
    docker rmi ghcr.io/open-webui/open-webui:main > /dev/null 2>&1
    echo "  [x] Image removed."
  else
    echo "  [ ] No open-webui image found — skipping."
  fi

  if [ -d /root/open-webui-data ]; then
    echo "  Removing /root/open-webui-data..."
    rm -rf /root/open-webui-data
    echo "  [x] Data directory removed."
  else
    echo "  [ ] No open-webui-data directory found — skipping."
  fi

  echo ""
}

remove_docker() {
  echo ""
  echo "--- Removing Docker ---"

  if docker images --format '{{.Repository}}' | grep -q '^hello-world$'; then
    echo "  Removing hello-world image..."
    docker rmi hello-world > /dev/null 2>&1
    echo "  [x] hello-world image removed."
  fi

  echo "  Uninstalling Docker packages..."
  apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
  rm -rf /var/lib/docker
  rm -rf /var/lib/containerd
  rm -f /etc/apt/sources.list.d/docker.list
  rm -f /etc/apt/keyrings/docker.asc
  echo "  [x] Docker removed."
  echo ""
}

ubuntu_cleanup() {
  echo "--- Running Ubuntu cleanup ---"
  apt-get autoremove -y
  apt-get clean
  echo "  [x] Cleanup complete."
  echo ""
}

print_wsl_instructions() {
  echo "============================================="
  echo " To completely remove Ubuntu, run these"
  echo " commands in Windows CMD or PowerShell:"
  echo ""
  echo "   wsl --shutdown"
  echo "   wsl --unregister Ubuntu"
  echo ""
  echo " Verify it's gone (should return File Not Found):"
  echo '   dir "C:\Users\%USERNAME%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu*"'
  echo "============================================="
  echo ""
}

confirm() {
  read -p " Are you sure? (y/n): " answer
  echo ""
  [[ "$answer" =~ ^[Yy]$ ]]
}

# =============================================================
# Main loop — re-runs after each action to refresh the menu
# =============================================================

while true; do

  # --- Detect what's installed ---
  has_openwebui=false
  has_searxng=false
  has_docker=false

  if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    has_docker=true
  fi

  if $has_docker; then
    docker ps -a --format '{{.Names}}' | grep -q '^open-webui$' && has_openwebui=true || true
    docker ps -a --format '{{.Names}}' | grep -q '^searxng$' && has_searxng=true || true
  fi

  # --- Header ---
  echo ""
  echo "============================================="
  echo " Open WebUI + SearXNG — Uninstaller"
  echo "============================================="
  echo ""
  echo " System status:"
  echo ""
  $has_openwebui && echo "   [x] Open WebUI  — installed" || echo "   [ ] Open WebUI  — not found"
  $has_searxng   && echo "   [x] SearXNG     — installed" || echo "   [ ] SearXNG     — not found"
  $has_docker    && echo "   [x] Docker      — installed" || echo "   [ ] Docker      — not found"
  echo ""

  # --- Build dynamic menu ---
  options=()

  if $has_searxng && $has_openwebui; then
    options+=("Remove SearXNG only")
    options+=("Remove Open WebUI only")
    options+=("Remove both SearXNG and Open WebUI")
  elif $has_searxng; then
    options+=("Remove SearXNG")
  elif $has_openwebui; then
    options+=("Remove Open WebUI")
  fi

  if $has_docker; then
    options+=("Remove everything (containers, images, Docker, Ubuntu cleanup)")
  fi

  options+=("Exit")

  # --- Nothing meaningful to remove ---
  if [ ${#options[@]} -eq 1 ]; then
    echo " Nothing installed to remove. Exiting."
    echo ""
    exit 0
  fi

  # --- Print menu ---
  echo " What would you like to do?"
  echo ""
  for i in "${!options[@]}"; do
    echo "   $((i+1))) ${options[$i]}"
  done
  echo ""
  read -p " Enter choice [1-${#options[@]}]: " choice
  echo ""

  # --- Validate input ---
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#options[@]}" ]; then
    echo " Invalid choice. Please try again."
    continue
  fi

  selected="${options[$((choice-1))]}"

  # --- Handle selection ---
  case "$selected" in

    "Remove SearXNG only"|"Remove SearXNG")
      echo " This will remove SearXNG and run Ubuntu cleanup."
      if confirm; then
        remove_searxng
        ubuntu_cleanup
        echo "============================================="
        echo " SearXNG has been removed."
        echo "============================================="
      else
        echo " Cancelled. Nothing was removed."
      fi
      ;;

    "Remove Open WebUI only"|"Remove Open WebUI")
      echo " This will remove Open WebUI and run Ubuntu cleanup."
      if confirm; then
        remove_openwebui
        ubuntu_cleanup
        echo "============================================="
        echo " Open WebUI has been removed."
        echo "============================================="
      else
        echo " Cancelled. Nothing was removed."
      fi
      ;;

    "Remove both SearXNG and Open WebUI")
      echo " This will remove both SearXNG and Open WebUI and run Ubuntu cleanup."
      if confirm; then
        remove_searxng
        remove_openwebui
        ubuntu_cleanup
        echo "============================================="
        echo " SearXNG and Open WebUI have been removed."
        echo "============================================="
      else
        echo " Cancelled. Nothing was removed."
      fi
      ;;

    "Remove everything (containers, images, Docker, Ubuntu cleanup)")
      echo " WARNING: This will remove everything including Docker itself."
      if confirm; then
        remove_searxng
        remove_openwebui
        remove_docker
        ubuntu_cleanup
        print_wsl_instructions
        exit 0
      else
        echo " Cancelled. Nothing was removed."
      fi
      ;;

    "Exit")
      echo " Exiting. Nothing was removed."
      echo ""
      exit 0
      ;;

  esac

done
