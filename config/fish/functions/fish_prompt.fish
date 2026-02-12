function fish_prompt
    #set_color cyan
    #printf "%s@%s" (whoami) (hostname -I | gawk '{print $1}')
    #set_color yellow
    #printf ":%s" (prompt_pwd)
    #set_color normal
    #printf "%s " (__fish_git_prompt)
    #printf "\n\$ "

    #fishline -s $status USERHOST VFISH FULLPWD GIT WRITE JOBS STATUS CLOCK N ROOT
    starship prompt
end

