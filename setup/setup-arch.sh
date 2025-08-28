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
ALIS_REPO="https://github.com/libertine89/alis"
SETUP_SCRIPT="$GIT_DIR/dotfiles/setup/setup-arch.sh"
SDDM_THEME="sugar-candy"
SDDM_THEMES_DIR="$GIT_DIR/dotfiles/sddm-themes"
THEME_DEPENDENCIES="qt5-graphicaleffects qt5-quickcontrols2 qt5-svg"
CUSTOM_MIRROR1="https://mirror.bytemark.co.uk/archlinux/\$repo/os/\$arch"
CUSTOM_MIRROR2="https://mirror.roe.ac.uk/archlinux/\$repo/os/\$arch"

# --------------------------------------------------------------
# Colours
# --------------------------------------------------------------

GREEN='\033[0;32m'
WHITE_BOLD='\033[1;97m'
NONE='\033[0m'

# --------------------------------------------------------------
# Helper & Functions
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
    step_name="$1"
    shift

    # Calculate dynamic line length
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
        echo ":: gum is already installed"
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
        echo "Cloning dotfiles repo..."
        git clone "$DOTFILES_REPO" "$GIT_DIR/dotfiles"
    else
        echo "Dotfiles repo already exists, pulling latest changes..."
        git -C "$GIT_DIR/dotfiles" pull
    fi

    # Clone alis repo if not already present
    if [ ! -d "$GIT_DIR/alis/.git" ]; then
        echo "Cloning alis repo..."
        git clone "$ALIS_REPO" "$GIT_DIR/alis"
    else
        echo "Alis repo already exists, pulling latest changes..."
        git -C "$GIT_DIR/alis" pull
    fi
}

_install_dotfiles(){
    # Backup existing dotfiles if they exist
    if [ -f "$HOME_DIR/.bashrc" ]; then
        mv "$HOME_DIR/.bashrc" "$HOME_DIR/.bashrc.backup"
        echo "Backed up existing .bashrc to .bashrc.backup"
    fi

    if [ -f "$HOME_DIR/.config/hypr/hyprland.conf" ]; then
        mv "$HOME_DIR/.config/hypr/hyprland.conf" "$HOME_DIR/.config/hypr/hyprland.conf.backup"
        echo "Backed up existing hyprland.conf to hyprland.conf.backup"
    fi

    # Install oh-my-zsh & plug-ins
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting

    # Use GNU Stow to symlink dotfiles into home directory
    #echo "Stowing dotfiles into $HOME_DIR..."
    #cd "$GIT_DIR/dotfiles" || exit 1
    #stow --target="$HOME_DIR" dotfiles

    # Copy all dotfiles and .config folder contents into $HOME_DIR
    echo "Copying dotfiles into $HOME_DIR..."
    cp -r "$GIT_DIR/dotfiles/dotfiles/." "$HOME_DIR/"
    echo "Dotfiles copied successfully."
}

_install_sddm_theme() {
    echo "Installing SDDM theme: $SDDM_THEME"

    # Setting up sudoers for hyprpaper later
    #SUDOERS_FILE="/etc/sudoers.d/sddm-wallpaper"
    #if [ ! -f "$SUDOERS_FILE" ]; then
    #    echo "Setting up sudoers rule for wallpaper updates..."
    #    echo "$USER_NAME ALL=(ALL) NOPASSWD: /bin/cp -f * /usr/share/sddm/themes/*/default.jpg, /usr/bin/touch /usr/share/sddm/themes/*/default.jpg" | sudo tee "$SUDOERS_FILE" > /dev/null
    #    sudo chmod 440 "$SUDOERS_FILE"
    #fi

    sudo mkdir -p /usr/share/sddm/themes

    # Ensure SDDM theme dependencies are installed
    for pkg in $THEME_DEPENDENCIES; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            echo "Installing missing package: $pkg"
            sudo pacman -S --noconfirm --needed "$pkg"
        fi
    done

    # Copy wallpapers into the selected theme folder
    echo "Copying wallpapers from $GIT_DIR/dotfiles/.config/ml4w/wallpapers into $SDDM_THEMES_DIR/$SDDM_THEME..."
    sudo cp -r "$GIT_DIR/dotfiles/dotfiles/.config/ml4w/wallpapers/"* "$SDDM_THEMES_DIR/$SDDM_THEME/"

    # Update theme.conf to set Background="default.jpg"
    THEME_CONF="$SDDM_THEMES_DIR/$SDDM_THEME/theme.conf"
    if [ -f "$THEME_CONF" ]; then
        echo "Updating background in $THEME_CONF..."
        sudo sed -i 's/^Background=.*/Background="default.jpg"/' "$THEME_CONF"
    else
        echo "Warning: $THEME_CONF not found!"
    fi

    # Copy all themes into /usr/share/sddm/themes
    echo "Copying all themes from $SDDM_THEMES_DIR into /usr/share/sddm/themes..."
    sudo cp -r "$SDDM_THEMES_DIR/"* /usr/share/sddm/themes/

    sudo mkdir -p /etc/sddm.conf.d

cat <<-EOT | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
[Theme]
Current=$SDDM_THEME
EOT
    echo "SDDM theme $SDDM_THEME installed and configured."
}

_finishMessage() {

    cd $HOME_DIR
    rm -rf setup-arch.sh

    echo -e "\n${GREEN}Dependencies & Dotfiles installation complete!${NONE}\n"

    for (( i = 15; i >= 1; i-- )); do
        read -r -s -n 1 -t 1 -p $'\r'"Rebooting in $i seconds... Press Esc to abort or R to reboot now. " KEY
        if [ $? -eq 0 ]; then
            case "$KEY" in
                $'\e') echo -e "\nReboot aborted. Please reboot manually."; return ;;
                [rR])  echo -e "\nRebooting now..."; reboot; return ;;
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
    _execute_step "Cloning Git Repos" _clone_gits
    source $GIT_DIR/dotfiles/setup/pkgs.sh
    _execute_step "Updating System" _update_system
    _execute_step "Adding Custom Mirrors" _add_mirrors
    _execute_step "Installing Yay" _install_yay
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
    _finishMessage
}

main
