# OpenWebUI-SearXNG

> **Windows only.** This setup runs Open WebUI and SearXNG inside WSL2 (Windows Subsystem for Linux). It is not intended for native Linux or macOS.

> **Ubuntu only.** This script has only been tested on Ubuntu inside WSL2 and is built on Ubuntu/Debian-specific tooling (`apt-get`, Docker's Ubuntu repository). Other WSL distributions are not supported.

Automated setup script for a private local search engine (SearXNG) connected to Open WebUI via Docker on Windows WSL2.

SearXNG is a self-hosted, privacy-respecting meta search engine. It queries Google, Bing, DuckDuckGo and others simultaneously, strips out all ads and tracking, and returns clean results — served entirely from your own machine. Open WebUI provides a polished chat interface for your local AI models, with SearXNG powering live web search.

> **Cloud models only.** This setup is designed for use with cloud-based AI providers (OpenAI, Anthropic, etc.) via their APIs. Local models via Ollama are not included or configured by these scripts. You will need an API key from your chosen provider to use Open WebUI after setup.

> **Already have Open WebUI installed?** Do not run these scripts — they will replace your existing Open WebUI container and may overwrite your data. If you already have Ollama running locally, it will connect automatically once Open WebUI is set up, but your existing container and settings will be lost.

---

## Before You Start

- Make sure **WSL is installed** with Ubuntu. If not, open CMD as Admin and run:
  ```
  wsl --install -d Ubuntu
  ```
  Set a username and password when prompted, then run:
  ```
  sudo apt update && sudo apt upgrade -y
  ```
  Then type `exit`, run `wsl --shutdown` in CMD, and reopen Ubuntu from the Start menu.

---

## Installation

Open Ubuntu and run:

```bash
curl -fsSL https://raw.githubusercontent.com/alpinezx/openwebui-searxng/refs/heads/main/setup.sh -o setup.sh && sudo bash setup.sh
```

The script will install Docker, launch Open WebUI, walk you through a short SearXNG configuration menu, and verify everything is working — all in one go. No restart required.

### Create your admin account

When the script completes, open **http://localhost:8080** in your browser and create your admin account. The first account created is permanent admin — choose carefully.

---

## Connect SearXNG to Open WebUI

In Open WebUI: **Admin Panel → Settings → Web Search**

Set the following:

| Setting | Value |
|---------|-------|
| Web Search Engine | searxng |
| Searxng Query URL | http://localhost:8081/search?q=\<query\> |
| Bypass Web Loader | On |
| Bypass Embedding and Retrieval | On |

Hit Save.

---

## Using SearXNG in Your Browser

SearXNG isn't just for Open WebUI — it's a fully functional private search engine you can use in any browser, any time.

Just visit: **http://localhost:8081**

To set it as your default search engine in Chrome, Edge, or Firefox, go to browser settings and add it manually using:
```
http://localhost:8081/search?q=%s
```

---

## Daily Use

Open Ubuntu from the Start menu. Docker, Open WebUI, and SearXNG all start automatically.

| What | Where |
|------|-------|
| Open WebUI | http://localhost:8080 |
| SearXNG | http://localhost:8081 |

For a clean stop, open CMD and run:
```
wsl --shutdown
```

---

## Optional: WSL Manager

Tired of keeping a Ubuntu terminal window open on your taskbar? WSL Manager lets you run WSL silently in the background with no visible window — and optionally start it automatically every time Windows boots.

👉 [Download WSL Manager](https://github.com/alpinezx/wsl-manager)

---

## Quick Reference Commands

```bash
sudo docker ps                                              # Check running containers
sudo docker logs open-webui --tail 50                       # Check Open WebUI logs
sudo docker restart open-webui                              # Restart Open WebUI
sudo docker restart searxng                                 # Restart SearXNG
sudo docker stop open-webui searxng                         # Stop all containers
sudo nano /root/searxng-config/settings.yml                 # Edit SearXNG configuration
curl "http://localhost:8081/search?q=test&format=json"      # Test SearXNG
```

---

## Editing the SearXNG Configuration

The config file lives at `/root/searxng-config/settings.yml`. Because the setup runs as root, you'll need `sudo` to edit it:

```bash
sudo nano /root/searxng-config/settings.yml
```

After saving, restart SearXNG for the changes to take effect:

```bash
sudo docker restart searxng
```

A few things worth knowing:

- **`use_default_settings: true`** at the top of the file is important — it means you only need to include the settings you want to override. SearXNG fills in everything else from its own defaults. Don't remove this line.
- **The port setting in `settings.yml` is ignored.** The port is controlled by the `-e SEARXNG_PORT=8081` flag in the docker run command. Don't bother changing it in the file.
- The full list of configurable options is documented at [docs.searxng.org](https://docs.searxng.org/admin/settings/index.html).

---

## Uninstall

### Using the uninstall script (recommended)

The easiest way to remove any part of the setup. Run this in Ubuntu:

```bash
curl -fsSL https://raw.githubusercontent.com/alpinezx/openwebui-searxng/refs/heads/main/uninstall.sh -o uninstall.sh && sudo bash uninstall.sh
```

The script detects what is currently installed and builds a menu based on what it finds:

```
=============================================
 Open WebUI + SearXNG — Uninstaller
=============================================

 System status:

   [x] Open WebUI  — installed
   [x] SearXNG     — installed
   [x] Docker      — installed

 What would you like to do?

   1) Remove SearXNG only
   2) Remove Open WebUI only
   3) Remove both SearXNG and Open WebUI
   4) Remove everything (containers, images, Docker, Ubuntu cleanup)
   5) Exit
```

Options that no longer apply are removed automatically after each action. Each option asks for confirmation before doing anything and runs an Ubuntu cleanup afterwards. The full removal option prints WSL unregister instructions at the end since that step must be done from Windows CMD.

---

### Manual uninstall

If you prefer to remove things by hand, use the commands below.

#### SearXNG only

```bash
sudo docker stop searxng
sudo docker rm searxng
sudo docker rmi searxng/searxng
sudo rm -rf /root/searxng-config
```

#### Open WebUI only

```bash
sudo docker stop open-webui
sudo docker rm open-webui
sudo docker rmi ghcr.io/open-webui/open-webui:main
sudo rm -rf /root/open-webui-data
```

#### Docker

```bash
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm /etc/apt/sources.list.d/docker.list
sudo rm /etc/apt/keyrings/docker.asc
sudo apt-get autoremove -y
```

#### Ubuntu (from Windows CMD)

```cmd
wsl --shutdown
wsl --unregister Ubuntu
```

Verify it's gone (should return File Not Found):
```cmd
dir "C:\Users\%USERNAME%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu*"
```

---

## Troubleshooting

**Running on a non-Ubuntu WSL distribution (e.g. Debian, openSUSE, Arch):**
This script is built for Ubuntu and will fail on other distributions. It uses `apt-get` for package management and pulls Docker from Ubuntu's package repository. If you need to use a different distro, the script would need to be adapted manually. The simplest fix is to install Ubuntu alongside your existing distro — WSL supports multiple distributions at once.

**VPN:** Disable before running `wsl --install`. VPNs block WSL downloads.

**Script not run as root:**
The setup script must be run with `sudo bash setup.sh`. Running without `sudo` will exit immediately with an error message.

**settings.yml permission denied:**
This shouldn't happen with the current script, but if you created the config manually, fix ownership and try again:
```bash
chown -R root:root /root/searxng-config
```

**Docker GPG signature errors on apt-get update:**
GPG key didn't save correctly. Re-run `setup.sh` from the beginning.

**Docker image download fails with TLS error (`bad record MAC`):**
A network hiccup corrupted the download mid-way. Clean up and re-run:
```bash
sudo docker rm -f open-webui
sudo docker rm -f searxng
sudo bash setup.sh
```
Both image pulls retry automatically on subsequent runs.

**Re-running setup.sh fails with container name conflict:**
The script detects and removes existing containers automatically before launching. If you are on an older version, remove them manually first:
```bash
sudo docker rm -f open-webui
sudo docker rm -f searxng
```

**SearXNG defaulting to port 8080 (conflicts with Open WebUI):**
Must be passed as `-e SEARXNG_PORT=8081` in the docker run command. The port setting in `settings.yml` is ignored by the container.

**Open WebUI web search returning only snippets, not full content:**
Ensure Bypass Web Loader is on in Admin Panel → Settings → Web Search.

**Searxng Query URL not working in Open WebUI:**
URL must be `http://localhost:8081/search?q=<query>` — the `<query>` placeholder is required. Don't use just the base URL.

**Some 403 errors in SearXNG logs (e.g. Wikidata):**
Normal. Individual engines occasionally block. Ignore these.

**Web search feels slow:**
Try reducing the Search Result Count in Admin Panel → Settings → Web Search. The default is 10 — lower values return faster results, higher values give the model more to work with. Adjust to taste.
