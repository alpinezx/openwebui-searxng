#!/bin/bash
# =============================================================
# uninstall.sh — Remove Open WebUI and/or SearXNG
# Cleans up only what was installed by the setup scripts.
# =============================================================

echo ""
echo "============================================="
echo " Open WebUI + SearXNG — Uninstaller"
echo "============================================="
echo ""
echo " What would you like to remove?"
echo ""
echo "   1) SearXNG only"
echo "   2) Open WebUI only"
echo "   3) Both SearXNG and Open WebUI"
echo "   4) Everything (containers, images, Docker, Ubuntu cleanup)"
echo "   5) Exit"
echo ""
read -p " Enter choice [1-5]: " choice
echo ""

# =============================================================
# Helper functions
# =============================================================

remove_searxng() {
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

# =============================================================
# Menu options
# =============================================================

case $choice in

  1)
    echo "This will remove SearXNG and clean up Ubuntu."
    read -p "Are you sure? (y/n): " confirm
    echo ""
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      remove_searxng
      ubuntu_cleanup
      echo "============================================="
      echo " SearXNG has been removed."
      echo "============================================="
    else
      echo "Cancelled. Nothing was removed."
    fi
    ;;

  2)
    echo "This will remove Open WebUI and clean up Ubuntu."
    read -p "Are you sure? (y/n): " confirm
    echo ""
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      remove_openwebui
      ubuntu_cleanup
      echo "============================================="
      echo " Open WebUI has been removed."
      echo "============================================="
    else
      echo "Cancelled. Nothing was removed."
    fi
    ;;

  3)
    echo "This will remove both Open WebUI and SearXNG and clean up Ubuntu."
    read -p "Are you sure? (y/n): " confirm
    echo ""
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      remove_searxng
      remove_openwebui
      ubuntu_cleanup
      echo "============================================="
      echo " Open WebUI and SearXNG have been removed."
      echo "============================================="
    else
      echo "Cancelled. Nothing was removed."
    fi
    ;;

  4)
    echo "WARNING: This will remove Open WebUI, SearXNG, and Docker entirely."
    read -p "Are you sure? (y/n): " confirm
    echo ""
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      remove_searxng
      remove_openwebui
      remove_docker
      ubuntu_cleanup
      print_wsl_instructions
    else
      echo "Cancelled. Nothing was removed."
    fi
    ;;

  5)
    echo "Exiting. Nothing was removed."
    echo ""
    ;;

  *)
    echo "Invalid choice. Please run the script again and enter 1-5."
    echo ""
    ;;

esac
