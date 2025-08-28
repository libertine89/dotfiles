oh-my-posh init fish --config $HOME/.config/ohmyposh/EDM115-newline.omp.json | source
fastfetch
if status is-interactive
end

if test -f ~/.ssh/id_ed25519
    ssh-add ~/.ssh/id_ed25519 >/dev/null 2>/dev/null
end

# Git helper function
function gpush
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


