set -x USING_TAILSCALE 1

function chrome --description 'Run Google Chrome on WSLg with JP keyboard layout'
    setxkbmap jp >/dev/null 2>&1; or true
    command google-chrome $argv
end

