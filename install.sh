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
    echo "${MAGENTA}"
    echo " ██╗  ██╗████████╗██████╗ "
    echo " ██║ ██╔╝╚══██╔══╝██╔══██╗"
    echo " █████╔╝    ██║   ██████╔╝"
    echo " ██╔═██╗    ██║   ██╔═══╝ "
    echo " ██║  ██╗   ██║   ██║     "
    echo " ╚═╝  ╚═╝   ╚═╝   ╚═╝     "
    echo "${NC}"
    echo "${CYAN}$REPO_NAME${NC}"
    echo "${YELLOW} Base Environment Setup${NC}"
    echo "--------------------------------"
}

error_msg() {
    echo "${RED}[✗]${NC} $1" >&2
    exit 1
}

success_msg() {
    echo "${LIME}[✓]${NC} $1"
}

info_msg() {
    echo "${YELLOW}[INFO] ${CYAN}$1${NC}"
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

    info_msg "Installing Ubuntu..."
    # Check if Ubuntu is installed
 if ! proot-distro install ubuntu 2>&1 | grep -q "already installed"; then
     if [ $? -eq 0 ]; then
         success_msg "Ubuntu installed successfully"
     else
         error_msg "Failed to install Ubuntu"
     fi
 else
     info_msg "Ubuntu is already installed"
 fi

    # Базовая настройка Ubuntu
    info_msg "Configuring Ubuntu environment..."
    proot-distro login ubuntu -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
            # Обновляем пакеты (с подавлением предупреждений)
            apt-get update -qq -y >/dev/null 2>&1
            
            # Устанавливаем зависимости (с явным указанием версий для избежания конфликтов)
            apt-get install -qq -y --allow-downgrades --allow-remove-essential \
                wget \
                xdotool \
                x11-apps \
                libgtk-3-0t64 \
                libxss1 \
                libasound2t64 \
                dbus \
                dbus-x11 >/dev/null 2>&1
            
            # Проверяем успешность установки
            for pkg in wget xdotool dbus; do
                if ! dpkg -l | grep -q \"^ii  \$pkg\"; then
                    exit 1
                fi
            done
        " || {
    error_msg "Failed to configure Ubuntu"
    exit 1
}

    success_msg "Base installation completed!"
    echo -e "\nNow you can install apps with:"
    echo -e "  ${LIME}ktp install vscode${NC}"
    echo -e "  ${LIME}ktp install brave${NC}"
    echo -e "  ${LIME}ktp install lxqt${NC}"
}

install_base