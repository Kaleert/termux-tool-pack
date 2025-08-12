#!/data/data/com.termux/files/usr/bin/bash

# Colors
RED='\033[1;31m'
LIME='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m'

# Repo info
REPO_NAME="Kaleert's Tool Pack"
REPO_URL="https://github.com/kaleert/termux-tool-pack"

show_header() {
    clear
    echo -e "${MAGENTA}"
    echo -e " ██╗  ██╗████████╗██████╗ "
    echo -e " ██║ ██╔╝╚══██╔══╝██╔══██╗"
    echo -e " █████╔╝    ██║   ██████╔╝"
    echo -e " ██╔═██╗    ██║   ██╔═══╝ "
    echo -e " ██║  ██╗   ██║   ██║     "
    echo -e " ╚═╝  ╚═╝   ╚═╝   ╚═╝     "
    echo -e "${NC}"
    echo -e "${CYAN}$REPO_NAME${NC}"
    echo -e "${YELLOW} Base Environment Setup${NC}"
    echo -e "--------------------------------"
}

error_msg() {
    echo -e "${RED}[✗]${NC} $1" >&2
    exit 1
}

success_msg() {
    echo -e "${LIME}[✓]${NC} $1"
}

info_msg() {
    echo -e "${YELLOW}[INFO] ${CYAN}$1${NC}"
}

setup_x11() {
    info_msg "Starting X server..."
    termux-x11 :0 >/dev/null 2>&1 &
    export DISPLAY=:0
    sleep 5

    info_msg "Setting up X11 permissions..."
    xhost +localhost >/dev/null 2>&1 || error_msg "Failed to set X11 permissions"
}

install_base() {
    show_header
    
    info_msg "Updating packages..."
    pkg update -y >/dev/null 2>&1 || error_msg "Failed to update packages"

    info_msg "Installing base dependencies..."
    pkg install -y git python3 x11-repo proot-distro socat \
        termux-x11 xdotool xorg-xhost >/dev/null 2>&1 || error_msg "Failed to install packages"

    setup_x11

    info_msg "Setting up Ubuntu proot..."
    if ! proot-distro list | grep -q "ubuntu"; then
        yes | proot-distro install ubuntu >/dev/null 2>&1 || error_msg "Failed to install Ubuntu"
    fi

    # Базовая настройка Ubuntu
    info_msg "Configuring Ubuntu environment..."
    proot-distro login ubuntu -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt update -y >/dev/null
        apt install -y wget curl xdotool x11-apps libgtk-3-0 libxss1 libasound2 dbus dbus-x11 >/dev/null
    " || error_msg "Failed to configure Ubuntu"

    success_msg "Base installation completed!"
    echo -e "\nNow you can install apps with:"
    echo -e "  ${LIME}ktp install vscode${NC}"
    echo -e "  ${LIME}ktp install brave${NC}"
    echo -e "  ${LIME}ktp install lxqt${NC}"
}

install_base