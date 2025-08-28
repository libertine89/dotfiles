oh-my-posh init fish --config $HOME/.config/ohmyposh/EDM115-newline.omp.json | source
fastfetch
if status is-interactive
end

if test -f ~/.ssh/id_ed25519
    ssh-add ~/.ssh/id_ed25519 >/dev/null 2>/dev/null
end

# Git helper function
function gpush
    if test (count $argv) -eq 0
        echo "Usage: gpush commit message"
        return 1
    end
    git add .
    git commit -m "$argv"
    git push
end
