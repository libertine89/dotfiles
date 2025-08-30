#!/usr/bin/env fish

# -----------------------------------------------------
# Prompt Theme
# -----------------------------------------------------

oh-my-posh init fish --config $HOME/.config/ohmyposh/EDM115-newline.omp.json | source

# -----------------------------------------------------
# Init
# -----------------------------------------------------

fastfetch

# Start ssh if its setup for Git
if test -f ~/.ssh/id_ed25519
    ssh-add ~/.ssh/id_ed25519 >/dev/null 2>/dev/null
end

# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

# -----------------------------------------------------
# General
# -----------------------------------------------------
alias root="cd /"
alias home="cd $HOME"
alias .="cd .."
alias ..="cd .."
alias ...="cd ../.."
alias ..2="cd ../.."
alias ..3="cd ../../.."
alias ..4="cd ../../../.."
alias ..5="cd ../../../../.."
alias ls="ls -lah --color=auto"    # -long all humanread
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"
alias rmdir="rm -ri"
alias ln="ln -i"
alias df="df -H"
alias mkdir="mkdir -pv"
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias fgrep="fgrep --color=auto"
alias c='clear'
alias nf="fastfetch"
alias pf="fastfetch"
alias ff="fastfetch"
alias shutdown="systemctl poweroff"
alias v="$EDITOR"
alias vim="$EDITOR"
alias wifi="nmtui"
alias cnt='echo " " (find . -maxdepth 1 -mindepth 1 \( -type f -o -type d \) | wc -l)'

# -----------------------------------------------------
# Package Managers
# -----------------------------------------------------
## Apt
function aptin; sudo apt install $argv; end
function aptup; sudo apt update; and sudo apt upgrade; end
function aptd; sudo apt update; end
function aptg; sudo apt upgrade; end
function aptrm; sudo apt remove $argv; end

function pacman; command sudo pacman -S $argv; end
function pacup; sudo pacman -Syu; end               # Update & Upgrade
function pacd; sudo pacman -Sy; end                 # Update Pacman
function pacg; sudo pacman -Su; end                 # Upgrade Packages
function pacrm; sudo pacman -Rns $argv; end

function yay; command yay -S $argv; end
function yayup; yay -Syu; end                       # Update & Upgrade
function yayd; yay -Sy; end                         # Update AUR & Pacman
function yayg; yay -Su; end                         # Upgrade Packages
function yayrm; yay -Rns $argv; end


# -----------------------------------------------------
# Git
# -----------------------------------------------------
alias gs="git status"
alias gr="git remote -v"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gst="git stash"
alias gsp="git stash; git pull"
alias gfo="git fetch origin"
alias gcheck="git checkout"
alias gcredential="git config credential.helper store"

function push
    set base "$HOME/Git"
    set argc (count $argv)
    set msg (string sub -s -1 -- $argv)   # last argument is commit message

    if test $argc -eq 1
        # current repo mode
        git add .
        git commit -m "$msg"
        git push
    else
        # all but last argument are repo names
        set repos $argv[1..-2]

        for repo in $repos
            if test -d "$base/$repo/.git"
                echo "Pushing in $repo..."
                pushd "$base/$repo" >/dev/null

                git add .
                git commit -m "$msg"
                git push

                popd >/dev/null
            else
                echo "⚠️ Skipping $repo (not found or not a git repo)"
            end
        end
    end
end

function pull
    set base "/home/$USER/Git"
    set repos
    set git_args

    # Split args into repo names and git pull flags
    for arg in $argv
        if string match -r "^-" $arg
            set git_args $git_args $arg
        else
            set repos $repos $arg
        end
    end

    if test (count $repos) -eq 0
        # current repo mode
        git pull $git_args
        or begin
            echo "⚠️ Pull failed in current repo. Resolve conflicts and press Enter to continue..."
            read
        end
    else
        for repo in $repos
            if test -d "$base/$repo/.git"
                echo "Pulling in $repo..."
                pushd "$base/$repo" > /dev/null
                git pull $git_args
                or begin
                    echo "⚠️ Pull failed in $repo. Resolve conflicts and press Enter to continue..."
                    read
                end
                popd > /dev/null
            else
                echo "⚠️ Skipping $repo (not found or not a git repo)"
            end
        end
    end
end

# -----------------------------------------------------
# ML4W Apps + Scripts
# -----------------------------------------------------
alias ml4w='flatpak run com.ml4w.welcome'
alias ml4w-settings='flatpak run com.ml4w.settings'
alias ml4w-calendar='flatpak run com.ml4w.calendar'
alias ml4w-hyprland='flatpak run com.ml4w.hyprlandsettings'
alias ml4w-sidebar='flatpak run com.ml4w.sidebar'
alias ml4w-options='ml4w-hyprland-setup -m options'
alias ml4w-diagnosis='~/.config/hypr/scripts/diagnosis.sh'
alias ml4w-hyprland-diagnosis='~/.config/hypr/scripts/diagnosis.sh'
alias ml4w-qtile-diagnosis='~/.config/ml4w/qtile/scripts/diagnosis.sh'
alias ml4w-update='~/.config/ml4w/scripts/installupdates.sh'
alias cleanup='~/.config/ml4w/scripts/cleanup.sh'
alias ts='~/.config/ml4w/scripts/arch/snapshot.sh'

# -----------------------------------------------------
# Window Managers
# -----------------------------------------------------

alias Qtile='startx'
# Hyprland with Hyprland

# -----------------------------------------------------
# Scripts
# -----------------------------------------------------
alias ascii='~/.config/ml4w/scripts/figlet.sh'

# -----------------------------------------------------
# System
# -----------------------------------------------------
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'

# -----------------------------------------------------
# Qtile
# -----------------------------------------------------
alias res1='xrandr --output DisplayPort-0 --mode 2560x1440 --rate 120'
alias res2='xrandr --output DisplayPort-0 --mode 1920x1080 --rate 120'
alias setkb='setxkbmap de;echo "Keyboard set back to de."'



