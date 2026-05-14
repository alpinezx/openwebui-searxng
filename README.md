# OpenWebUI-SearXNG

> **Windows only.** This setup runs Open WebUI and SearXNG inside WSL2 (Windows Subsystem for Linux). It is not intended for native Linux or macOS.

> **Ubuntu only.** These scripts have only been tested on Ubuntu inside WSL2 and are built on Ubuntu/Debian-specific tooling (`apt-get`, Docker's Ubuntu repository). Other WSL distributions are not supported.

Automated setup scripts for a private local search engine (SearXNG) connected to Open WebUI via Docker on Windows WSL2.

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

### Step 1 — Run the first script

Open Ubuntu and run:

```bash
curl -fsSL https://raw.githubusercontent.com/alpinezx/openwebui-searxng/refs/heads/main/setup1.sh | bash
```

This installs Docker and adds your user to the docker group.

### Step 2 — Restart WSL

When the script finishes it will tell you to restart. Do this:

1. Type `exit` to close Ubuntu
2. Open CMD and run: `wsl --shutdown`
3. Reopen Ubuntu from the Start menu

### Step 3 — Run the second script

```bash
curl -fsSL https://raw.githubusercontent.com/alpinezx/openwebui-searxng/refs/heads/main/setup2.sh -o setup2.sh && bash setup2.sh
```

This walks you through a short configuration menu, then launches Open WebUI and SearXNG and verifies both are working.

### Step 4 — Create your admin account

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
docker ps                                               # Check running containers
docker logs open-webui --tail 50                        # Check Open WebUI logs
docker restart open-webui                               # Restart Open WebUI
docker restart searxng                                  # Restart SearXNG
docker stop open-webui searxng                          # Stop all containers
curl "http://localhost:8081/search?q=test&format=json"  # Test SearXNG
```

---

## Uninstall

### Using the uninstall script (recommended)

The easiest way to remove any part of the setup. Run these two commands in Ubuntu:

```bash
curl -fsSL https://raw.githubusercontent.com/alpinezx/openwebui-searxng/refs/heads/main/uninstall.sh -o uninstall.sh && bash uninstall.sh
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

Options that no longer apply are removed automatically after each action — so if you remove SearXNG first and run it again, the menu updates to reflect what is still installed. Each option asks for confirmation before doing anything and runs an Ubuntu cleanup afterwards.

---

### Manual uninstall

If you prefer to remove things by hand, use the commands below.

#### SearXNG only

```bash
docker stop searxng
docker rm searxng
docker rmi searxng/searxng
rm -rf ~/searxng-config
```

#### Open WebUI only

```bash
docker stop open-webui
docker rm open-webui
docker rmi ghcr.io/open-webui/open-webui:main
rm -rf ~/open-webui-data
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
These scripts are built for Ubuntu and will fail on other distributions. They use `apt-get` for package management and pull Docker from Ubuntu's package repository. If you need to use a different distro, the scripts would need to be adapted manually. The simplest fix is to install Ubuntu alongside your existing distro — WSL supports multiple distributions at once.

**VPN:** Disable before running `wsl --install`. VPNs block WSL downloads.

**Docker "permission denied":**
Run `wsl --shutdown` fully — closing the terminal is not enough for group membership changes to take effect.

**settings.yml permission denied:**
This shouldn't happen with the current script, but if you're on an older version or created the config manually as root, fix ownership and try again:
```bash
sudo chown -R $USER:$USER ~/searxng-config
```

**Docker GPG signature errors on apt-get update:**
GPG key didn't save correctly. Re-run `setup1.sh` one step at a time manually.

**Docker image download fails with TLS error (`bad record MAC`):**
A network hiccup corrupted the download mid-way. This can happen on slower or less stable connections. If you see this error, clean up and re-run the script:
```bash
docker rm -f open-webui
docker rm -f searxng
curl -fsSL https://raw.githubusercontent.com/alpinezx/openwebui-searxng/refs/heads/main/setup2.sh | bash
```
`setup2.sh` now retries the SearXNG image pull automatically, but if Open WebUI's image was the one that failed you will need to remove its container first as shown above.

**Re-running setup2.sh fails with container name conflict:**
The script now detects and removes existing containers automatically before launching. If you are on an older version, remove them manually first:
```bash
docker rm -f open-webui
docker rm -f searxng
```

**SearXNG defaulting to port 8080 (conflicts with Open WebUI):**
Must be passed as `-e SEARXNG_PORT=8081` in the docker run command. The port setting in `settings.yml` is ignored by the container. Do NOT use sed to edit settings inside the container — corrupts YAML and causes a crash loop.

**Open WebUI web search returning only snippets, not full content:**
Ensure Bypass Web Loader is on in Admin Panel → Settings → Web Search.

**Searxng Query URL not working in Open WebUI:**
URL must be `http://localhost:8081/search?q=<query>` — the `<query>` placeholder is required. Don't use just the base URL.

**Some 403 errors in SearXNG logs (e.g. Wikidata):**
Normal. Individual engines occasionally block. Ignore these.

**Web search feels slow:**
Try reducing the Search Result Count in Admin Panel → Settings → Web Search. The default is 10 — lower values return faster results, higher values give the model more to work with. Adjust to taste.
