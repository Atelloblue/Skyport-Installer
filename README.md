# Skyport Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0-brightgreen.svg)]()

A production-ready installer for **Skyport**, the management panel for servers, designed to automate setup on Linux systems.

---

## ⚡ Features

- Installs and configures **Docker**, **Node.js (v22)**, and **Git**.  
- Downloads the latest **Skyport panel** from GitHub.  
- Installs Skyport dependencies automatically using `npm`.  
- Creates a **config.json** automatically if missing.  
- Lets you choose to run Skyport **directly** or with **PM2** (background process with auto-restart).  
- PM2 is automatically configured for **startup on boot**.  
- Skips installation for dependencies that are already installed.  
- Colorized output for **better user feedback**.  
- Robust **error handling** and warnings.

---

## ⚙️ Requirements

- Linux system (Ubuntu/Debian recommended)  
- `sudo` privileges  
- Internet connection  

---

## 🚀 Quick Start

Run the installer directly from GitHub:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Atelloblue/Skyport-Installer/main/skyport-installer.sh)"
```


## 🛠️ PM2 Quick Commands

If you choose PM2 mode:

pm2 status          # Check Skyport status
pm2 logs skyport    # View logs
pm2 restart skyport # Restart application
pm2 stop skyport    # Stop application
