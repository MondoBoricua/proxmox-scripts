# 🧰 Proxmox Scripts

<p>
  <img alt="Proxmox" src="https://img.shields.io/badge/Proxmox-VE_8.x_%2F_9.x-E57000?style=for-the-badge&logo=proxmox&logoColor=white">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge">
  <a href="https://www.patreon.com/MT3K"><img alt="Patreon" src="https://img.shields.io/badge/Patreon-Support_MT3K-FF424D?style=for-the-badge&logo=patreon"></a>
</p>

One-command LXC installers for your Proxmox homelab — run a single line on the Proxmox host and get a fully configured container. Battle-tested on my own homelab. / Instaladores LXC de un solo comando para tu homelab Proxmox.

> This repo consolidates my former `proxmox-duckdns`, `proxmox-samba` and `nginx-server` repos — old links redirect or keep working via compatibility stubs.

## 📦 Scripts

| Script | What you get | Install (run on the Proxmox host) |
|---|---|---|
| [🦆 **duckdns/**](duckdns/) | Dynamic-DNS LXC — keeps your home IP updated on DuckDNS via cron. Interactive bilingual installer. | `curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/duckdns/auto-install.sh \| bash` |
| [🗂️ **samba/**](samba/) | Samba file-sharing LXC for your LAN. Auto-detects Ubuntu/Debian templates, guided setup. | `curl -sSL https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/samba/auto-install.sh \| bash` |
| [🌐 **nginx/**](nginx/) | Nginx + PHP web-server LXC — PHP-FPM 8.1–8.3, Composer, php-manager, SSL manager, security headers. WordPress/Laravel ready. | `bash -c "$(wget -qO- https://raw.githubusercontent.com/MondoBoricua/proxmox-scripts/main/nginx/auto-install.sh)"` |

Each folder has its full README with requirements, manual install and management tools.

## 📋 Requirements

- **Proxmox VE 8.x / 9.x**
- An **LXC template** (Ubuntu 22.04/24.04 or Debian 12/13 — auto-detected)

## ❤️ Support / Apoya

Free and open source (MIT). If these scripts saved you time, [**become a patron**](https://www.patreon.com/MT3K) — patrons ($5+) get early access to new MT3K tools and a voice on what ships next. / Gratis y open source (MIT). Si estos scripts te ahorraron tiempo, [**hazte patron**](https://www.patreon.com/MT3K).
