function f
    set -l program $argv[1]
    set -l args $argv
    set -e args[1]

    set file (fzf --multi)
    set -q file
    or return 1

    $program $args $file
end

