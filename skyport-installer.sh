#!/bin/bash

# ========================================
# Skyport Installer - Production Ready
# ========================================
# Installs Docker, Node.js, Git, Skyport, and optionally PM2.
# Skips existing dependencies and automatically handles config.
# Provides colored output, error handling, and tips.
# ========================================

set -euo pipefail  # exit on error, unset variables, pipe errors

# -------------------------------
# Colors for output
# -------------------------------
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# -------------------------------
# Messaging functions
# -------------------------------
step()   { echo -e "${CYAN}[*] $1${RESET}"; }
success(){ echo -e "${GREEN}[✓] $1${RESET}"; }
warn()   { echo -e "${YELLOW}[!] $1${RESET}"; }
error()  { echo -e "${RED}[X] $1${RESET}"; }

# -------------------------------
# Error trap
# -------------------------------
trap 'error "An unexpected error occurred at line $LINENO."; exit 1' ERR

echo -e "${GREEN}=== Skyport Installer ===${RESET}"
echo

# -------------------------------
# Command existence check
# -------------------------------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# -------------------------------
# Docker installation
# -------------------------------
if command_exists docker; then
    success "Docker is already installed. Skipping..."
else
    step "Installing Docker..."
    curl -fsSL https://get.docker.com/ | CHANNEL=stable bash
    success "Docker installed."
    warn "Tip: To run Docker as a non-root user, consider rootless mode:"
    echo -e "      ${YELLOW}dockerd-rootless-setuptool.sh install${RESET}"
fi
echo

# -------------------------------
# Node.js installation
# -------------------------------
if command_exists node; then
    success "Node.js is already installed. Skipping..."
else
    step "Setting up NodeSource repository (Node.js 22)..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
        | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
    success "NodeSource repository added."

    step "Installing Node.js..."
    sudo apt update -qq
    sudo apt install -y nodejs
    success "Node.js installed."
fi
echo

# -------------------------------
# Git installation
# -------------------------------
if command_exists git; then
    success "Git is already installed. Skipping..."
else
    step "Installing Git..."
    sudo apt update -qq
    sudo apt install -y git
    success "Git installed."
fi
echo

# -------------------------------
# Skyport download
# -------------------------------
step "Downloading Skyport..."
cd /etc || { error "Cannot access /etc directory."; exit 1; }

if [[ -d "skyport" ]]; then
    warn "Skyport folder already exists. Skipping clone."
else
    sudo git clone https://github.com/skyport-team/panel || { error "Failed to clone repository."; exit 1; }
    sudo mv panel skyport
    success "Skyport downloaded."
fi
echo

# -------------------------------
# Skyport dependencies
# -------------------------------
step "Installing Skyport dependencies..."
cd skyport || { error "Skyport directory not found."; exit 1; }
npm install
success "Dependencies installed."
echo

# -------------------------------
# Configuration
# -------------------------------
step "Setting up configuration..."
if [[ -f "example_config.json" ]]; then
    sudo mv example_config.json config.json
    success "Configuration file created from example_config.json."
else
    # Auto-create minimal config if missing
    echo '{"serverPort":3000,"dbUrl":"mongodb://localhost/skyport"}' | sudo tee config.json >/dev/null
    warn "example_config.json not found. Created minimal config.json, please edit as needed."
fi
echo

# -------------------------------
# Seed database & create user
# -------------------------------
step "Seeding database and creating admin user..."
npm run seed || warn "Database seeding encountered issues, check logs."
npm run createUser || warn "User creation encountered issues, check logs."
success "Database setup complete."
echo

# -------------------------------
# User chooses run mode
# -------------------------------
echo -e "${CYAN}Select how to run Skyport:${RESET}"
echo -e "  1) Start directly (foreground)"
echo -e "  2) Start with PM2 (background, auto-restart)"
read -rp "$(echo -e ${YELLOW}'Enter choice [1 or 2]: '${RESET})" run_choice
echo

if [[ "$run_choice" == "1" ]]; then
    step "Starting Skyport directly..."
    node . || { error "Skyport failed to start."; exit 1; }
else
    # PM2 setup
    if command_exists pm2; then
        success "PM2 is already installed. Skipping..."
    else
        step "Installing PM2 globally..."
        npm install -g pm2
        success "PM2 installed."
    fi

    step "Starting Skyport with PM2..."
    pm2 start index.js --name "skyport"
    success "Skyport is now running under PM2."
    echo

    step "Enabling PM2 startup on boot..."
    pm2 startup -u "$USER" --hp "$HOME"
    pm2 save
    success "PM2 startup enabled."
    echo

    echo -e "${CYAN}Quick PM2 Commands:${RESET}"
    echo -e "  pm2 status          ${YELLOW}# Check status${RESET}"
    echo -e "  pm2 logs skyport    ${YELLOW}# View logs${RESET}"
    echo -e "  pm2 restart skyport ${YELLOW}# Restart application${RESET}"
    echo -e "  pm2 stop skyport    ${YELLOW}# Stop application${RESET}"
    echo
fi

success "Installation complete. Skyport is ready to use!"
