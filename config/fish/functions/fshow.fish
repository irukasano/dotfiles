#alias glNoGraph='git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an" "$@"' 
#set -l _gitLogLineToHash "echo {} | grep -o '[a-f0-9]\{7\}' | head -1" 
#set -l _viewGitLogLine "$_gitLogLineToHash | xargs -I % sh -c 'git show --color=always % | diff-so-fancy'"

function fshow
    set -l _gitLogLineToHash "echo {} | grep -o '[a-f0-9]\{7\}' | head -1" 
    set -l _viewGitLogLine "$_gitLogLineToHash | xargs -I % sh -c 'git show --color=always %'"

    set -l args $argv
    if test -z "$args"
        set args "."
    end

    git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an" "$args" | \
        fzf --no-sort --reverse --tiebreak=index --no-multi \
            --ansi --preview="$_viewGitLogLine" \
            --header "enter to view" \
            --bind "enter:execute:$_viewGitLogLine | less -R" 
            #--header "enter to view, alt-y to copy hash" \
            #--bind "enter:execute:$_viewGitLogLine | less -R" \
            #--bind "alt-y:execute:$_gitLogLineToHash | xclip"

end

