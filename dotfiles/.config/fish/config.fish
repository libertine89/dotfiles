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
        echo "Usage: gpush [repo1 repo2 ...] \"commit message\""
        return 1
    end

    # Last argument is the commit message
    set msg $argv[(count $argv)]

    # If only one argument, commit in current directory
    if test (count $argv) -eq 1
        echo "Pushing in current directory"
        git add .
        git commit -m "$msg"
        git push
        return
    end

    # Loop through repos (all args except last)
    set repos $argv[1..(count $argv)-1]

    for repo in $repos
        set repo_path "/home/$USER/Git/$repo"
        if test -d $repo_path
            echo "Pushing in repo: $repo"
            cd $repo_path
            git add .
            git commit -m "$msg"
            git push
            cd - >/dev/null
        else
            echo "Repo not found: $repo_path"
        end
    end
end


