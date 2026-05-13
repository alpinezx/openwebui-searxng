#!/bin/bash
# =============================================================
# uninstall.sh — Remove Open WebUI and/or SearXNG
# Detects what's installed and builds the menu dynamically.
# Cleans up only what was installed by the setup scripts.
# =============================================================

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
    echo "  ✓ Container removed."
  else
    echo "  No searxng container found — skipping."
  fi

  if docker images --format '{{.Repository}}' | grep -q '^searxng/searxng$'; then
    echo "  Removing searxng image..."
    docker rmi searxng/searxng > /dev/null 2>&1
    echo "  ✓ Image removed."
  else
    echo "  No searxng image found — skipping."
  fi

  if [ -d ~/searxng-config ]; then
    echo "  Removing ~/searxng-config..."
    sudo rm -rf ~/searxng-config
    echo "  ✓ Config directory removed."
  else
    echo "  No searxng-config directory found — skipping."
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
    echo "  ✓ Container removed."
  else
    echo "  No open-webui container found — skipping."
  fi

  if docker images --format '{{.Repository}}' | grep -q '^ghcr.io/open-webui/open-webui$'; then
    echo "  Removing open-webui image..."
    docker rmi ghcr.io/open-webui/open-webui:main > /dev/null 2>&1
    echo "  ✓ Image removed."
  else
    echo "  No open-webui image found — skipping."
  fi

  if [ -d ~/open-webui-data ]; then
    echo "  Removing ~/open-webui-data..."
    sudo rm -rf ~/open-webui-data
    echo "  ✓ Data directory removed."
  else
    echo "  No open-webui-data directory found — skipping."
  fi

  echo ""
}

remove_docker() {
  echo ""
  echo "--- Removing Docker ---"

  if docker images --format '{{.Repository}}' | grep -q '^hello-world$'; then
    echo "  Removing hello-world image..."
    docker rmi hello-world > /dev/null 2>&1
    echo "  ✓ hello-world image removed."
  fi

  echo "  Uninstalling Docker packages..."
  sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
  sudo rm -rf /var/lib/docker
  sudo rm -rf /var/lib/containerd
  sudo rm -f /etc/apt/sources.list.d/docker.list
  sudo rm -f /etc/apt/keyrings/docker.asc
  echo "  ✓ Docker removed."
  echo ""
}

ubuntu_cleanup() {
  echo "--- Running Ubuntu cleanup ---"
  sudo apt-get autoremove -y
  sudo apt-get clean
  echo "  ✓ Cleanup complete."
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
  $has_openwebui && echo "   ✓ Open WebUI  — installed" || echo "   ✗ Open WebUI  — not found"
  $has_searxng   && echo "   ✓ SearXNG     — installed" || echo "   ✗ SearXNG     — not found"
  $has_docker    && echo "   ✓ Docker      — installed" || echo "   ✗ Docker      — not found"
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
