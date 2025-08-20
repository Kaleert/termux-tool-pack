#!/data/data/com.termux/files/usr/bin/bash

# Colors
RED='\033[1;31m'
LIME='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m'

# Log directory and file
LOG_DIR="./tmp"
LOG_FILE="${LOG_DIR}/vscode_install.log"

show_header() {
    clear
    echo "${MAGENTA}"
    echo "VSCODE"
    echo "${NC}"
    echo "${CYAN}Visual Studio Code Installation${NC}"
    echo "${YELLOW}Kaleert's Tool Pack${NC}"
    echo "-------------------------------------"
}

log_error() {
    echo "${RED}[✗]${NC} $1" >&2
    echo "[ERROR] $(date): $1" >> "$LOG_FILE"
    exit 1
}

log_success() {
    echo "${LIME}[✓]${NC} $1"
    echo "[SUCCESS] $(date): $1" >> "$LOG_FILE"
}

log_info() {
    echo "${YELLOW}[INFO] ${CYAN}$1${NC}"
    echo "[INFO] $(date): $1" >> "$LOG_FILE"
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
    echo "=== VS Code Installation Log - $(date) ===" > "$LOG_FILE"
    echo "Installation started at: $(date)" >> "$LOG_FILE"
}

install_vscode() {
    show_header
    
    log_info "Installing VS Code in Ubuntu environment..."
    
    proot-distro login ubuntu -- bash -c "
        # Colors for Ubuntu messages
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
            exit 1
        }
    
        # Main installation process
        export DEBIAN_FRONTEND=noninteractive
        export LC_ALL=C
        
        # Update package lists
        info_msg \"Updating package lists...\"
        apt update -y >/dev/null 2>&1 || error_msg \"Failed to update packages\"
        
        # Install dependencies
        info_msg \"Installing dependencies...\"
        apt install -y wget gpg apt-transport-https curl >/dev/null 2>&1 || error_msg \"Failed to install dependencies\"
        
        # Download and install Microsoft GPG key (альтернативный способ)
        info_msg \"Downloading Microsoft GPG key...\"
        curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg >/dev/null 2>&1
        
        # Create repository file
        info_msg \"Creating repository configuration...\"
        echo \"deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main\" | tee /etc/apt/sources.list.d/vscode.list >/dev/null
        
        # Update package lists
        info_msg \"Updating package lists with new repository...\"
        apt update -y >/dev/null 2>&1 || error_msg \"Failed to update package lists\"
        
        # Install VS Code (пробуем разные варианты)
        info_msg \"Installing VS Code...\"
        
        # Пробуем установить code или code-insiders
        if apt install -y code >/dev/null 2>&1; then
            success_msg \"VS Code installed successfully!\"
        elif apt install -y code-insiders >/dev/null 2>&1; then
            success_msg \"VS Code Insiders installed successfully!\"
        else
            # Если официальный репозиторий не работает, пробуем скачать .deb пакет
            info_msg \"Trying alternative installation method...\"
            wget -O /tmp/vscode.deb \"https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64\" >/dev/null 2>&1
            if [ -f /tmp/vscode.deb ]; then
                dpkg -i /tmp/vscode.deb >/dev/null 2>&1
                apt install -f -y >/dev/null 2>&1
                rm /tmp/vscode.deb
                success_msg \"VS Code installed from .deb package!\"
            else
                error_msg \"All installation methods failed\"
            fi
        fi
    " 2>> "$LOG_FILE" || log_error "Failed to install VS Code in Ubuntu environment"

    log_success "VS Code successfully installed!"
    echo -e "\nStart with: ${LIME}proot-distro login ubuntu -- code --no-sandbox${NC}"
    echo -e "Or use: ${LIME}ktp run vscode${NC} (if KTP client is installed)"
}

# Main execution
setup_logging
log_info "Starting VS Code installation process..."

install_vscode

log_success "VS Code installation completed!"
echo -e "\n${YELLOW}Log file: $LOG_FILE${NC}"