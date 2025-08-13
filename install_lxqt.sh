#!/data/data/com.termux/files/usr/bin/bash

# Colors
RED='\033[1;31m'
LIME='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
NC='\033[0m'

show_header() {
    clear
    echo "${GREEN}"
    echo "██╗  ██╗██╗  ██╗ ██████╗ ████████╗"
    echo "██║  ██║╚██╗██╔╝██╔═══██╗╚══██╔══╝"
    echo "███████║ ╚███╔╝ ██║   ██║   ██║   "
    echo "██╔══██║ ██╔██╗ ██║   ██║   ██║   "
    echo "██║  ██║██╔╝ ██╗╚██████╔╝   ██║   "
    echo "╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝    ╚═╝   "
    echo "${NC}"
    echo "${YELLOW}LXQt Desktop Installation${NC}"
    echo "----------------------------"
}

error_msg() { echo "${RED}[✗]${NC} $1" >&2; exit 1; }
success_msg() { echo "${LIME}[✓]${NC} $1"; }
info_msg() { echo "${YELLOW}[INFO] ${CYAN}$1${NC}"; }

install_lxqt() {
    show_header
    
    info_msg "Installing LXQt Desktop in Ubuntu environment..."
    proot-distro login ubuntu -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq -y >/dev/null 2>&1
        apt-get install -qq -y --allow-downgrades --allow-remove-essential lxqt-core xorg lightdm qterminal >/dev/null || exit 1
        
        echo '[SeatDefaults]
        autologin-user=ubuntu' > /etc/lightdm/lightdm.conf.d/50-autologin.conf
    " || error_msg "Failed to install LXQt Desktop"

    success_msg "LXQt Desktop successfully installed!"
    echo -e "\nStart with: ${LIME}proot-distro login ubuntu -- startlxqt${NC}"
}

install_lxqt