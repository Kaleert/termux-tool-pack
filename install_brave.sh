#!/data/data/com.termux/files/usr/bin/bash

# Colors
RED='\033[1;31m'
LIME='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${RED}"
    echo -e "██████╗ ██████╗  █████╗ ██╗   ██╗███████╗"
    echo -e "██╔════╝██╔══██╗██╔══██╗██║   ██║██╔════╝"
    echo -e "██║     ██████╔╝███████║██║   ██║█████╗  "
    echo -e "██║     ██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  "
    echo -e "╚██████╗██║  ██║██║  ██║ ╚████╔╝ ███████╗"
    echo -e " ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}Brave Browser Installation${NC}"
    echo -e "--------------------------------"
}

error_msg() { echo -e "${RED}[✗]${NC} $1" >&2; exit 1; }
success_msg() { echo -e "${LIME}[✓]${NC} $1"; }
info_msg() { echo -e "${YELLOW}[INFO] ${CYAN}$1${NC}"; }

install_brave() {
    show_header
    
    info_msg "Installing Brave Browser in Ubuntu environment..."
    proot-distro login ubuntu -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt update -y >/dev/null
        apt install -y curl apt-transport-https gnupg >/dev/null
        
        curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
        echo \"deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main\" > /etc/apt/sources.list.d/brave-browser-release.list
        
        apt update -y >/dev/null
        apt install -y brave-browser >/dev/null || exit 1
    " || error_msg "Failed to install Brave Browser"

    success_msg "Brave Browser successfully installed!"
    echo -e "\nStart with: ${LIME}proot-distro login ubuntu -- brave-browser --no-sandbox${NC}"
}

install_brave