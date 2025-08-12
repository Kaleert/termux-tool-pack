#!/data/data/com.termux/files/usr/bin/bash

# Colors
RED='\033[1;31m'
LIME='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${BLUE}"
    echo -e "██╗   ██╗███████╗ ██████╗ ██████╗ ██████╗ "
    echo -e "██║   ██║██╔════╝██╔════╝██╔══██╗██╔══██╗"
    echo -e "██║   ██║███████╗██║     ██████╔╝██║  ██║"
    echo -e "╚██╗ ██╔╝╚════██║██║     ██╔══██╗██║  ██║"
    echo -e " ╚████╔╝ ███████║╚██████╗██║  ██║██████╔╝"
    echo -e "  ╚═══╝  ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═════╝ "
    echo -e "${NC}"
    echo -e "${YELLOW}Visual Studio Code Installation${NC}"
    echo -e "-------------------------------------"
}

error_msg() { echo -e "${RED}[✗]${NC} $1" >&2; exit 1; }
success_msg() { echo -e "${LIME}[✓]${NC} $1"; }
info_msg() { echo -e "${YELLOW}[INFO] ${CYAN}$1${NC}"; }

install_vscode() {
    show_header
    
    info_msg "Installing VS Code in Ubuntu environment..."
    proot-distro login ubuntu -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        echo 'code stable/main boolean true' | debconf-set-selections
        
        # Устанавливаем зависимости
        apt update -y >/dev/null
        apt install -y wget gpg apt-transport-https >/dev/null
        
        # Добавляем репозиторий VS Code
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
        echo 'deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' > /etc/apt/sources.list.d/vscode.list
        rm -f packages.microsoft.gpg
        
        # Устанавливаем VS Code
        apt update -y >/dev/null
        apt install -y code >/dev/null || exit 1
    " || error_msg "Failed to install VS Code"

    success_msg "VS Code successfully installed!"
    echo -e "\nStart with: ${LIME}proot-distro login ubuntu -- code --no-sandbox${NC}"
}

install_vscode