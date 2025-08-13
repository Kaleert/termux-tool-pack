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
        UBUNTU_RED='\033[1;31m'
        UBUNTU_GREEN='\033[1;32m'
        UBUNTU_YELLOW='\033[1;33m'
        UBUNTU_CYAN='\033[1;36m'
        UBUNTU_NC='\033[0m'
        
        ubuntu_msg() {
            echo -e \"\${UBUNTU_CYAN}[Ubuntu] \${UBUNTU_YELLOW}\$1\${UBUNTU_NC}\"
        }
        
        ubuntu_warning() {
            echo -e \"\${UBUNTU_CYAN}[Ubuntu] \${UBUNTU_YELLOW}WARNING: \$1\${UBUNTU_NC}\" >&2
        }
        
        ubuntu_error() {
            echo -e \"\${UBUNTU_CYAN}[Ubuntu] \${UBUNTU_RED}ERROR: \$1\${UBUNTU_NC}\" >&2
            exit 1
        }
        
        # 1. Принудительное обновление пакетов (игнорируя ошибки репозиториев)
        ubuntu_msg \"Updating package lists (forcing through errors)...\"
        apt-get update -qq -y \
            --allow-unauthenticated \
            --allow-insecure-repositories \
            --fix-missing 2>/dev/null || {
            ubuntu_warning \"Some repository updates failed - continuing anyway\"
        }
        
        # 2. Установка критически важных пакетов
        CORE_PACKAGES=(wget curl xdotool x11-apps libgtk-3-0 libxss1 libasound2 dbus dbus-x11)
        
        ubuntu_msg \"Installing core packages...\"
        for pkg in \"\${CORE_PACKAGES[@]}\"; do
            if ! apt-get install -y --allow-unauthenticated \
                --allow-downgrades \
                --allow-remove-essential \
                --no-install-recommends \
                \"\$pkg\" 2>/dev/null; then
                
                ubuntu_warning \"Failed to install \$pkg normally - trying degraded mode\"
                # Попытка установки без зависимостей
                apt-get install -y --allow-unauthenticated \
                    --ignore-missing \
                    --fix-broken \
                    \"\$pkg\" 2>/dev/null || true
            fi
        done
        
        # 3. Проверка установленных пакетов
        FAILED_PACKAGES=()
        for pkg in wget xdotool dbus; do
            if ! dpkg -l | grep -q \"^ii  \$pkg \"; then
                FAILED_PACKAGES+=(\"\$pkg\")
            fi
        done
        
        # 4. Попытка исправить зависимости
        if [ \${#FAILED_PACKAGES[@]} -gt 0 ]; then
            ubuntu_msg \"Attempting to repair missing packages...\"
            apt-get -f install -y 2>/dev/null || true
            
            # Повторная проверка
            FAILED_PACKAGES=()
            for pkg in wget xdotool dbus; do
                if ! dpkg -l | grep -q \"^ii  \$pkg \"; then
                    FAILED_PACKAGES+=(\"\$pkg\")
                fi
            done
        fi
        
        # 5. Финальный статус
        if [ \${#FAILED_PACKAGES[@]} -gt 0 ]; then
            ubuntu_warning \"These packages failed to install: \${FAILED_PACKAGES[*]}\"
            ubuntu_warning \"Some functionality may be limited\"
        else
            ubuntu_msg \"\${UBUNTU_GREEN}Core packages installed successfully\${UBUNTU_NC}\"
        fi
        
        # 6. Базовая конфигурация
        ubuntu_msg \"Configuring environment...\"
        mkdir -p /run/dbus
        dbus-uuidgen > /var/lib/dbus/machine-id 2>/dev/null || true
        
        ubuntu_msg \"\${UBUNTU_GREEN}Ubuntu environment ready\${UBUNTU_NC}\"
        exit 0
    " || {
    error_msg "Ubuntu configuration encountered issues"
    echo "${YELLOW}Last error output:${NC}"
    echo "$(tail -n 20 /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/root/.bash_history 2>&1)"
    echo "\n${YELLOW}Warning: Some packages may not be installed properly, but base environment should work.${NC}"
    echo "You can try to fix issues manually later with:"
    echo "  ${LIME}proot-distro login ubuntu${NC}"
    echo "  ${LIME}apt-get install -f${NC}"
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