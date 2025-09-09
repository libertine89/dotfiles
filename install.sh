#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------
# Variables
# --------------------------------------------------------------

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
USER_NAME="$(whoami)"
HOME_DIR="/home/$USER_NAME"
GIT_DIR="$HOME_DIR/Git"
DOTFILES_REPO="https://github.com/libertine89/dotfiles"
ALIS_REPO="https://github.com/libertine89/Balis"
HYPRSCROLLER_REPO="https://github.com/cpiber/hyprscroller.git"
SETUP_SCRIPT="$GIT_DIR/dotfiles/setup/setup-arch.sh"
SDDM_THEME="sugar-candy"
SDDM_THEMES_DIR="$GIT_DIR/dotfiles/sddm-themes"
SDDM_WALLPAPER="default.jpg"
THEME_DEPENDENCIES="qt5-graphicaleffects qt5-quickcontrols2 qt5-svg"
CUSTOM_MIRROR1="https://mirror.bytemark.co.uk/archlinux/\$repo/os/\$arch"
CUSTOM_MIRROR2="https://mirror.roe.ac.uk/archlinux/\$repo/os/\$arch"
SNAPPER_ROOT_HOURLY=12
SNAPPER_ROOT_DAILY=7
SNAPPER_HOME_DAILY=7
HYPRSCROLLER="true" # Install hyprsroller?

# --------------------------------------------------------------
# Colours
# --------------------------------------------------------------

GREEN='\033[1;32m'
WHITE_BOLD='\033[1;97m'
BLUE='\033[1;34m'
NONE='\033[0m'

# --------------------------------------------------------------
# Helpers & Functions
# --------------------------------------------------------------

_writeHeader() {
    distro=$1
    clear
    echo -e "${GREEN}"
cat <<"EOF"
   ____    __
  / __/__ / /___ _____
 _\ \/ -_) __/ // / _ \
/___/\__/\__/\_,_/ .__/
                /_/

EOF

    if [[ "$(tty)" != /dev/tty* ]]; then
        echo "⚠️ This script must be run from a TTY (not inside a graphical session)."
        echo "Please switch to a TTY (e.g., Ctrl+Alt+F2) and re-run the script."
        exit 1
    fi

    echo "ML4W Dotfiles for Hyprland for $distro"
    echo -e "${NONE}"
    echo "This setup script will install all required packages and dependencies for the dotfiles."
    echo
    if gum confirm "DO YOU WANT TO START THE SETUP NOW?: "; then
        echo ":: Installation started."
        echo
    else
        echo ":: Installation canceled"
        exit
    fi
}

_checkCommandExists() {
    cmd="$1"
    if ! command -v "$cmd" >/dev/null; then
        echo 1
        return
    fi
    echo 0
    return
}

_execute_step() {
    # CGet step name & alculate dynamic line length for header
    step_name="$1"
    shift
    step_length=${#step_name}
    total_length=$((step_length + 4))  # 8 accounts for brackets and spaces
    line=$(printf '=%.0s' $(seq 1 $total_length))

    echo -e "${GREEN}>>>${WHITE_BOLD}${line}${GREEN}<<<${NONE}"
    echo -e "${GREEN}>>>${WHITE_BOLD}  $step_name  ${GREEN}<<<${NONE}"
    echo -e "${GREEN}>>>${WHITE_BOLD}${line}${GREEN}<<<${NONE}"

    # Execute the command
    "$@"
}

_isInstalled() {
    package="$1"
    check="$(sudo pacman -Qs --color always "${package}" | grep "local" | grep "${package} ")"
    if [ -n "${check}" ]; then
        echo 0
        return #true
    fi
    echo 1
    return #false
}

_installYay() {
    if [[ ! $(_isInstalled "base-devel") == 0 ]]; then
        sudo pacman --noconfirm -S "base-devel"
    fi
    if [[ ! $(_isInstalled "git") == 0 ]]; then
        sudo pacman --noconfirm -S "git"
    fi
    if [ -d $HOME/Downloads/yay-bin ]; then
        rm -rf $HOME/Downloads/yay-bin
    fi
    SCRIPT=$(realpath "$0")
    temp_path=$(dirname "$SCRIPT")
    git clone https://aur.archlinux.org/yay-bin.git $HOME/Downloads/yay-bin
    cd $HOME/Downloads/yay-bin
    makepkg --noconfirm -si
    cd $temp_path
    echo ":: yay has been installed successfully."
}


_check_hypr() {
    if pacman -Qi hyprland &> /dev/null; then

        if hyprctl version | grep -q "Plugin API: enabled"; then
            echo "✅ Hyprland Git is installed"
        else
            echo "⚠️ Hyprland installed but not Git version."
            echo "Stopping any running Hyprland sessions..."
            pkill -TERM -u "$USER_NAME" Hyprland || true
            echo "Installing Hyprland"
            sudo pacman -Rns hyprland
            _install_hypr
        fi
    else
        echo "❌ Hyprland not installed, installing hyprland-git"
        _install_hypr
    fi
}
_install_hypr(){
    for pkg in "${hyprgit[@]}"; do
        if [[ $(_isInstalled "${pkg}") == 0 ]]; then
            echo ":: ${pkg} is already installed."
        else
        yay -S --noconfirm --needed "${pkg}"
        fi
    done
    yay -S --noconfirm hyprland-git
    echo "Hyprland Git Installed"
    
    echo "Getting Hyprscroller"
    if [ "${HYPRSCROLLER}" == "true" ]; then
        cd $GIT_DIR/hyprscroller 
        make all
        make install
        echo "Hyprscroller Installed"
    fi 
}

_installPackages() {
    for pkg; do
        if [[ $(_isInstalled "${pkg}") == 0 ]]; then
            echo ":: ${pkg} is already installed."
            continue
        fi
        yay --noconfirm -S "${pkg}"
    done
}

_install_gum(){
    if [[ $(_checkCommandExists "gum") == 0 ]]; then
        # echo ":: gum is already installed" 
        echo "" # dont show so it boots straight into installer
    else
        echo ":: The installer requires gum. gum will be installed now"
        sudo pacman --noconfirm -S gum
    fi
}

_install_yay(){
    if [[ $(_checkCommandExists "yay") == 0 ]]; then
        echo ":: yay is already installed"
    else
        echo ":: The installer requires yay. yay will be installed now"
        _installYay
    fi
}

_install_omp(){
    if [ ! -d $HOME/.local/bin ]; then
        mkdir -p $HOME/.local/bin
    fi
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
}

_add_mirrors(){
    echo "Adding custom mirrors.."
    echo "$CUSTOM_MIRROR1"
    echo "$CUSTOM_MIRROR2"
    # Add working UK mirrors to pacman mirrorlist
    sudo tee -a /etc/pacman.d/mirrorlist >/dev/null <<EOT

## Custom UK mirrors
Server = $CUSTOM_MIRROR1
Server = $CUSTOM_MIRROR2
EOT
    echo "Complete"
}

_update_system(){
    sudo pacman -Syyu --noconfirm
}


_clone_gits(){
    mkdir -p "$GIT_DIR"

    # Clone dotfiles repo if not already present
    if [ ! -d "$GIT_DIR/dotfiles/.git" ]; then
        echo -e "${BLUE}   --->${WHITE_BOLD}  Cloning dotfiles repo...${NONE}"
        git clone "$DOTFILES_REPO" "$GIT_DIR/dotfiles"
    else
        echo "Dotfiles repo already exists, pulling latest changes..."
        git -C "$GIT_DIR/dotfiles" pull
    fi

    # Clone alis repo if not already present
    if [ ! -d "$GIT_DIR/alis/.git" ]; then
        echo -e "${BLUE}   --->${WHITE_BOLD}  Cloning alis repo...${NONE}"
        git clone "$ALIS_REPO" "$GIT_DIR/alis"
    else
        echo "Alis repo already exists, pulling latest changes..."
        git -C "$GIT_DIR/alis" pull
    fi

    # Clone Hyprsrcoller if not already present 
    if [ ! -d "$GIT_DIR/hyprscroller/.git" ] && [ "${HYPRSCROLLER}" == "true" ]; then
        echo -e "${BLUE}   --->${WHITE_BOLD}  Cloning Hyprscroller repo...${NONE}"
        git clone "$HYPRSCROLLER_REPO" "$GIT_DIR/hyprscroller"
    elif [ -d "$GIT_DIR/hyprscroller/.git" ]; then
        echo "Hyprscroller repo already exists, pulling latest changes..."
        git -C "$GIT_DIR/hyprscroller" pull
    else
        echo "Skipping Hyprscroller..."
    fi
}

_install_dotfiles(){
    # Install oh-my-zsh & plug-ins
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting

    # Backup existing dotfiles if they exist
    BACKUPS=(
        ".bashrc"
        ".zshrc"
        ".config/hypr/hyprland.conf"
        ".local/share/user-place.xbel"
    )
    
    for file in "${BACKUPS[@]}"; do
        if [ -f "$HOME_DIR/${file}" ]; then
            mv "$HOME_DIR/${file}" "$HOME_DIR/${file}.backup"
            echo -e "${BLUE}   --->${WHITE_BOLD}  Backed up existing ${file} to ${file}.backup.${NONE}"
        fi
    done

    # Use GNU Stow to symlink dotfiles into home directory
    echo -e "${BLUE}   --->${WHITE_BOLD}  Stowing dotfiles into $HOME_DIR...${NONE}"
    cd "$GIT_DIR/dotfiles" || exit 1
    stow --target="$HOME_DIR" dotfiles
}

_install_sddm_theme() {
    echo -e "${BLUE}   --->${WHITE_BOLD}  Installing SDDM theme: $SDDM_THEME...${NONE}"

    sudo mkdir -p /usr/share/sddm/themes

    # Ensure SDDM theme dependencies are installed
    for pkg in $THEME_DEPENDENCIES; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            echo "Installing missing package: $pkg"
            sudo pacman -S --noconfirm --needed "$pkg"
        fi
    done

    # Copy wallpapers into the selected theme folder
    echo -e "${BLUE}   --->${WHITE_BOLD}  Copying wallpapers from $GIT_DIR/dotfiles/.config/ml4w/wallpapers into $SDDM_THEMES_DIR/$SDDM_THEME...${NONE}"
    sudo cp -r "$GIT_DIR/dotfiles/sddm-themes/wallpapers/$SDDM_WALLPAPER"* "$SDDM_THEMES_DIR/$SDDM_THEME/"

    # Update theme.conf to set Background="default.jpg"
    THEME_CONF="$SDDM_THEMES_DIR/$SDDM_THEME/theme.conf"
    if [ -f "$THEME_CONF" ]; then
        echo "Updating background in $THEME_CONF..."
        sudo sed -i "s|^Background=.*|Background=\"$SDDM_WALLPAPER\"|" "$THEME_CONF"
    else
        echo "Warning: $THEME_CONF not found!"
    fi

    # Copy all themes into /usr/share/sddm/themes
    echo -e "${BLUE}   --->${WHITE_BOLD}  Copying all themes from $SDDM_THEMES_DIR into /usr/share/sddm/themes...${NONE}"
    sudo cp -r "$SDDM_THEMES_DIR/"* /usr/share/sddm/themes/

    sudo mkdir -p /etc/sddm.conf.d

cat <<-EOT | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
[Theme]
Current=$SDDM_THEME
EOT

    sudo systemctl set-default graphical.target
    sudo systemctl enable sddm.service
    echo -e "${BLUE}   --->${WHITE_BOLD}  SDDM theme $SDDM_THEME installed and configured.${NONE}"
}

function _snapper_cfg() {
    local ROOT_SUBVOLUME="/snapshots/root"
    local HOME_SUBVOLUME="/snapshots/home"
    local CONFIG_DIR="/etc/snapper/configs"

    if [ -d "/snapshots" ]; then
        if [ ! -d "$ROOT_SUBVOLUME" ]; then
            sudo btrfs subvolume create $ROOT_SUBVOLUME
            sudo chown root:root $ROOT_SUBVOLUME
            sudo chmod 755 $ROOT_SUBVOLUME
        fi

        if [ ! -d "$HOME_SUBVOLUME" ]; then
            sudo btrfs subvolume create $HOME_SUBVOLUME
            sudo chown "$USER_NAME":"$USER_NAME" $HOME_SUBVOLUME
            sudo chmod 755 $HOME_SUBVOLUME
        fi
    fi

    if [ ! -f "$CONFIG_DIR/root" ]; then
        sudo snapper -c root create-config "$ROOT_SUBVOLUME"
        
        sudo sed -i "s/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY=\"$SNAPPER_ROOT_HOURLY\"/" /etc/snapper/configs/root
        sudo sed -i "s/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY=\"$SNAPPER_ROOT_DAILY\"/" /etc/snapper/configs/root
        sudo sed -i 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="yes"/' /etc/snapper/configs/root
        sudo sed -i 's/^TIMELINE_CLEANUP=.*/TIMELINE_CLEANUP="yes"/' /etc/snapper/configs/root
    fi

    if [ ! -f "$CONFIG_DIR/home" ]; then
        sudo snapper -c home create-config "$HOME_SUBVOLUME"

        # Adjust root & home config using variables
        sudo sed -i "s/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY=\"$SNAPPER_HOME_DAILY\"/" /etc/snapper/configs/home

        # Set config to create and cleanup snaps
        sudo sed -i 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="yes"/' /etc/snapper/configs/home
        sudo sed -i 's/^TIMELINE_CLEANUP=.*/TIMELINE_CLEANUP="yes"/' /etc/snapper/configs/home
    fi

    # Enable systemd timers for snaps
    sudo systemctl enable --now snapper-timeline.timer
    sudo systemctl enable --now snapper-cleanup.timer
}

function _snapshot() {
    echo -e "${BLUE}   --->${WHITE_BOLD}  Creating $1...${NONE}"
    sudo snapper -c root create -d "$1"
        echo "root snapshot created."
    sudo snapper -c home create -d "$1"
        echo "home snapshot created."
}

_finishMessage() {
    cd "$HOME_DIR" || exit 1
    rm -rf install.sh

    echo -e "\n${GREEN}Dependencies & Dotfiles installation complete!${NONE}\n"

    echo -e "${GREEN}"
cat <<"EOF"
   _____      _     __          __
  / __(_)__  (_)__ / /  ___ ___/ /
 / _// / _ \/ (_-</ _ \/ -_) _  / 
/_/ /_/_//_/_/___/_//_/\__/\_,_/ 

EOF
    echo -e "${NONE}"

    for (( i = 15; i >= 1; i-- )); do 
        echo -ne "\rRebooting in $i seconds... Press Esc to abort or R to reboot now. "
        if read -r -s -n 1 -t 1 KEY; then
            case "$KEY" in
                $'\e') 
                    echo -e "\nReboot aborted. Please reboot manually."; 
                    return ;;
                [rR])  
                    echo -e "\nRebooting now..."; 
                    reboot; 
                    return ;;
            esac
        fi
    done

    echo -e "\nRebooting...\n"
    reboot
}

# --------------------------------------------------------------
# Main Loop
# --------------------------------------------------------------
main(){
    sudo -v
    _execute_step "Installing Gum" _install_gum
    _writeHeader "Arch"
    _execute_step "Configuring Snapshot" _snapper_cfg
    _execute_step "Pre Dotfiles Snapshot" _snapshot "Pre Dotfiles Snapshot"
    _execute_step "Cloning Git Repos" _clone_gits
    source $GIT_DIR/dotfiles/setup/pkgs.sh
    _execute_step "Updating System" _update_system
    _execute_step "Adding Custom Mirrors" _add_mirrors
    _execute_step "Installing Yay" _install_yay
    _execute_step "Installing Hyprland-Git" _check_hypr
    _execute_step "Installing General Packages" _installPackages "${general[@]}"
    _execute_step "Installing Apps Packages" _installPackages "${apps[@]}"
    _execute_step "Installing Tools Packages" _installPackages "${tools[@]}"
    _execute_step "Installing Distro Packages" _installPackages "${distro[@]}"
    _execute_step "Installing Hyprland Packages" _installPackages "${hyprland[@]}"
    _execute_step "Installing Oh My Posh " _install_omp
    _execute_step "Installing Prebuilt Bins" source $GIT_DIR/dotfiles/setup/_prebuilt.sh
    _execute_step "Installing ML4W Apps" source $GIT_DIR/dotfiles/setup/_ml4w-apps.sh
    _execute_step "Installing Flatpaks" source $GIT_DIR/dotfiles/setup/_flatpaks.sh
    _execute_step "Installing Cursors" source $GIT_DIR/dotfiles/setup/_cursors.sh
    _execute_step "Installing Fonts" source $GIT_DIR/dotfiles/setup/_fonts.sh
    _execute_step "Installing Dotfiles" _install_dotfiles
    _execute_step "Installing SDDM Theme" _install_sddm_theme
    _execute_step "Post Dotfiles Snapshot" _snapshot "Post Dotfiles Snapshot"
    _finishMessage
}

main
