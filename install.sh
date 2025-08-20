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

# Log directory and file
LOG_DIR="./tmp"
LOG_FILE="${LOG_DIR}/ktp_install.log"

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
    echo "${CYAN}    $REPO_NAME${NC}"
    echo "${YELLOW} Base Environment Setup${NC}"
    echo "--------------------------------"
}

log_error() {
    echo "${RED}[✗]${NC} $1" >&2
    echo "[ERROR] $(date): $1" >> "$LOG_FILE"
}

log_success() {
    echo "${LIME}[✓]${NC} $1"
    echo "[SUCCESS] $(date): $1" >> "$LOG_FILE"
}

log_info() {
    echo "${YELLOW}[INFO] ${CYAN}$1${NC}"
    echo "[INFO] $(date): $1" >> "$LOG_FILE"
}

log_debug() {
    echo "[DEBUG] $(date): $1" >> "$LOG_FILE"
}

# Ensure log directory exists and is writable
setup_logging() {
    # Create log directory if it doesn't exist
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || {
            echo "${RED}Failed to create log directory: $LOG_DIR${NC}" >&2
            exit 1
        }
    fi
    
    # Check if log directory is writable
    if [ ! -w "$LOG_DIR" ]; then
        echo "${RED}Log directory is not writable: $LOG_DIR${NC}" >&2
        exit 1
    fi
    
    # Initialize log file
    echo "=== KTP Installation Log - $(date) ===" > "$LOG_FILE"
    echo "Installation started at: $(date)" >> "$LOG_FILE"
    echo "Log directory: $LOG_DIR" >> "$LOG_FILE"
    echo "Log file: $LOG_FILE" >> "$LOG_FILE"
}

install_client() {
    log_info "Checking KTP installation..."

    # 1. Проверка существования команды ktp
    if [ -f "$PREFIX/bin/ktp" ]; then
        log_info "KTP client is already installed at: $PREFIX/bin/ktp"
        return 0
    fi

    # 2. Проверка существования папки termux-tool-pack
    local ktp_dir="$HOME/termux-tool-pack"
    if [ -d "$ktp_dir" ]; then
        log_info "Found existing KTP directory at: $ktp_dir"
    fi

    if [ ! -d "$ktp_dir" ]; then
        log_info "Cloning KTP repository..."
        if git clone --depth 1 https://github.com/kaleert/termux-tool-pack.git "$ktp_dir" 2>> "$LOG_FILE"; then
            log_success "Repository cloned successfully"
        else
            log_error "Failed to clone repository"
            return 1
        fi
    fi

    # 4. Установка клиента
    log_info "Installing KTP client..."
    if cp -f "$ktp_dir/ktp" "$PREFIX/bin/" 2>> "$LOG_FILE"; then
        chmod +x "$PREFIX/bin/ktp" 2>> "$LOG_FILE"
        log_success "KTP client installed successfully!"
        echo -e "Run with: ${LIME}ktp --help${NC}"
        return 0
    else
        log_error "Failed to install KTP client"
        return 1
    fi
}

setup_x11() {
    log_info "Starting X server..."
    # Проверяем, не запущен ли уже X server
    if ! pgrep -x "termux-x11" > /dev/null; then
        termux-x11 :0 >> "$LOG_FILE" 2>&1 &
        sleep 3
    fi
    export DISPLAY=:0

    log_info "Setting up X11 permissions..."
    xhost +localhost >> "$LOG_FILE" 2>&1 || log_error "Failed to set X11 permissions"
}

install_base() {
    show_header

    log_info "Updating packages..."
    pkg update -y >> "$LOG_FILE" 2>&1 || log_error "Failed to update packages"

    log_info "Installing base dependencies..."
    pkg install -y git python3 x11-repo proot-distro socat >> "$LOG_FILE" 2>&1
    pkg install termux-x11 xdotool xorg-xhost -y >> "$LOG_FILE" 2>&1 || log_error "Failed to install packages"

    setup_x11

    log_info "Installing Ubuntu..."
    # Check if Ubuntu is installed (оригинальная проверка)
    if ! proot-distro install ubuntu 2>&1 | grep -q "already installed"; then
        if [ $? -eq 0 ]; then
            log_success "Ubuntu installed successfully"
        else
            log_error "Failed to install Ubuntu"
            return 1
        fi
    else
        log_info "Ubuntu is already installed"
    fi

    # Базовая настройка Ubuntu
    log_info "Configuring Ubuntu environment..."
    proot-distro login ubuntu -- bash -c "
        # Colors
        NC='\033[0m'
        CYAN='\033[0;36m'
        MAGENTA='\033[0;35m'
        GREEN='\033[0;32m'
        RED='\033[0;31m'
    
        # Message functions
        info_msg() {
            echo -e \"\${NC}[\${CYAN}Ubuntu\${NC}] \${MAGENTA}\$1\${NC}\"
        }
        
        success_msg() {
            echo -e \"\${NC}[\${CYAN}Ubuntu\${NC}] \${GREEN}\$1\${NC}\"
        }
        
        error_msg() {
            echo -e \"\${NC}[\${CYAN}Ubuntu\${NC}] \${RED}\$1\${NC}\"
        }
    
        # Main installation process
        export DEBIAN_FRONTEND=noninteractive
        
        # Fix locale issues
        export LC_ALL=C
        
        # Update packages
        info_msg \"Updating package lists...\"
        apt-get update -y -qq >/dev/null 2>&1 || true
    
        # Package list (убрал проблемные пакеты)
        packages=(
            wget
            xdotool
            x11-apps
            libgtk-3-0
            libxss1
            dbus
            dbus-x11
            libasound2t64
        )
    
        # Installation
        info_msg \"Installing required packages...\"
        for pkg in \"\${packages[@]}\"; do
            info_msg \"Installing \${pkg}...\"
            if apt-get install -y -qq --allow-downgrades --allow-remove-essential \"\${pkg}\" >/dev/null 2>&1; then
                success_msg \"\${pkg} installed successfully\"
            else
                error_msg \"Failed to install \${pkg} - skipping\"
            fi
        done
    
        # Пробуем установить libasound2 отдельно с разными вариантами
        info_msg \"Trying to install libasound2...\"
        if apt-get install -y -qq libasound2 >/dev/null 2>&1; then
            success_msg \"libasound2 installed successfully\"
        elif apt-get install -y -qq libasound2t64 >/dev/null 2>&1; then
            success_msg \"libasound2t64 installed successfully\"
        else
            error_msg \"Failed to install libasound2 - audio may not work\"
        fi
    
        # Verification (проверяем только основные пакеты)
        info_msg \"Verifying installed packages...\"
        for pkg in \"\${packages[@]}\"; do
            if dpkg -l | grep -q \"^ii  \${pkg}\"; then
                success_msg \"\${pkg} verified and installed correctly\"
            else
                error_msg \"\${pkg} is not installed properly\"
                # Не выходим с ошибкой, продолжаем
            fi
        done
    
        success_msg \"Ubuntu environment configured successfully!\"
        info_msg \"Note: Some packages may have installation issues in Termux environment\"
    " 2>> "$LOG_FILE" || {
        log_error "Failed to configure Ubuntu environment"
        return 1
    }

    install_client || {
        log_error "KTP installation failed"
        return 1
    }

    log_success "Base installation completed!"
    echo "\nNow you can install apps with:"
    echo "  ${LIME}ktp install vscode${NC}"
    echo "  ${LIME}ktp install brave${NC}"
    echo "  ${LIME}ktp install lxqt${NC}"
    echo "\n${YELLOW}Note: Audio support may be limited in Termux environment${NC}"
}

# Main execution
setup_logging

log_info "Starting KTP installation process..."

if install_base; then
    log_success "Installation completed successfully!"
    echo -e "\n${YELLOW}Log file: $LOG_FILE${NC}"
else
    log_error "Installation failed. Check log file: $LOG_FILE"
    exit 1
fi