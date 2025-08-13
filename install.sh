#!/data/data/com.termux/files/usr/bin/bash

# Colors
RED='\033[1;31m'
LIME='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
ORANGE='\033[1;33m'
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
    echo "${CYAN}   $REPO_NAME${NC}"
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

ubuntu_msg() {
    echo "${WHITE}[${ORANGE}Ubuntu${WHITE}] ${YELLOW}$1${NC}\n"
}

install_client() {
    info_msg "Checking KTP installation..."
    
    # 1. Проверка существования команды ktp
    if [ -f "$PREFIX/bin/ktp" ]; then
        info_msg "KTP client is already installed at: $PREFIX/bin/ktp"
        return 0
    fi
    
    # 2. Проверка существования папки termux-tool-pack
    local ktp_dir="~/termux-tool-pack"
    if [ -d "$ktp_dir" ]; then
        info_msg "Found existing KTP directory at: $ktp_dir"
    fi
    
    if [ ! -d "$ktp_dir" ]; then
        info_msg "Cloning KTP repository..."
        if git clone --depth 1 https://github.com/kaleert/termux-tool-pack.git "$ktp_dir" 2>/dev/null; then
            success_msg "Repository cloned successfully"
        else
            error_msg "Failed to clone repository"
            return 1
        fi
    fi

    # 4. Установка клиента
    info_msg "Installing KTP client..."
    if cp -f "$ktp_dir/ktp" $PREFIX/bin/ 2>/dev/null; then
        chmod +x $PREFIX/bin/ktp
        success_msg "KTP client installed successfully!"
        echo -e "Run with: ${LIME}ktp --help${NC}"
        return 0
    else
        error_msg "Failed to install KTP client"
        return 1
    fi
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
        
        # Цвета для Ubuntu
        RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
        WHITE='\033[1;37m'; ORANGE='\033[1;33m'; NC='\033[0m'
        
        ubuntu_msg() {
            echo -e \"${WHITE}[${ORANGE}Ubuntu${WHITE}] ${YELLOW}\$1${NC}\"
        }
        
        ubuntu_error() {
            echo -e \"${WHITE}[${RED}ERROR${WHITE}] ${RED}\$1${NC}\" >&2
            echo -e \"${RED}Details:${NC}\" >&2
            echo -e \"\${RED}\$2${NC}\" >&2
        }
        
        # Захватываем вывод обновления пакетов
        update_output=\$(apt-get update -qq -y 2>&1)
        if [ \$? -ne 0 ]; then
            ubuntu_error \"Package update failed\" \"\$update_output\"
            exit 1
        else
            ubuntu_msg \"Package lists updated successfully\"
        fi
        
        # Массив пакетов для установки
        packages=(wget xdotool x11-apps libgtk-3-0t64 libxss1 libasound2t64 dbus dbus-x11)
        
        for pkg in \"\${packages[@]}\"; do
            ubuntu_msg \"Installing \$pkg...\"
            install_output=\$(apt-get install -y --allow-downgrades --allow-remove-essential \"\$pkg\" 2>&1)
            if [ \$? -ne 0 ]; then
                ubuntu_error \"Failed to install \$pkg\" \"\$install_output\"
                exit 1
            fi
        done
        
        # Проверка установки
        failed_pkgs=()
        for pkg in wget xdotool dbus; do
            if ! dpkg -l | grep -q \"^ii  \$pkg\"; then
                failed_pkgs+=(\"\$pkg\")
            fi
        done
        
        if [ \${#failed_pkgs[@]} -gt 0 ]; then
            ubuntu_error \"Critical packages missing\" \"Failed packages: \${failed_pkgs[*]}\"
            exit 1
        fi
        
        ubuntu_msg \"${GREEN}Ubuntu environment configured successfully${NC}\"
    " || {
    error_msg "Ubuntu configuration failed"
    echo -e "${RED}Last error output:${NC}"
    echo -e "$(tail -n 20 /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/root/.bash_history 2>&1)"
    exit 1
}

    install_client || {
    error_msg "KTP installation failed"
    exit 1
}
    
    success_msg "Base installation completed!"
    echo "\nNow you can install apps with:"
    echo "  ${LIME}ktp install vscode${NC}"
    echo "  ${LIME}ktp install brave${NC}"
    echo "  ${LIME}ktp install lxqt${NC}"
}

install_base