# no fuckups plz
alias rm='rm -I'
alias cp='cp -i'
alias mv='mv -i'

# make all the things nice!
alias ls='ls --color'
alias ll='ls -lh --color'
alias la='ll -a --color'
alias less='less --raw-control-chars'

# let out my inner child!
alias boop='touch'

# I did an oopsie
alias fuck='sudo $(history -p \!\!)'

# some bash stuff
alias reload-bashrc='. ~/.bashrc'
alias dirs='dirs -v'

# gdb
alias gdb='gdb -quiet'
alias arm-none-eabi-gdb='arm-none-eabi-gdb -quiet'

alias xdo='xdg-open'

alias ip='ip -c'

# Adding an extra space behind command
# Makes it possible to expand command and use aliasses
alias watch='watch --color '

# docker
alias docker-rm-containers='docker rm $(docker ps -a -q)' # Delete all containers
alias docker-rm-images='docker rmi $(docker images -q)'   # Delete all images
alias docker-rm-all='docker_rm_containers ; docker_rm_images'

# package updates
alias dnfu='sudo dnf upgrade --refresh'

# vpn
alias connect-vpn='. $HOME/scripts/vpn/connect-vpn.sh'

# Set screen commands
alias home-dual='xrandr --output DP-1 --primary --mode 3440x1440 --pos 0x0 --output HDMI-0 --mode 1920x1080 --pos 3440x180'
alias home-single='xrandr --output HDMI-0 --primary --mode 1920x1080 --output DP-1 --mode 1920x1080 --same-as HDMI-0'

# include aliases with specific system aliases
if [ -f ~/.bash_aliases_system ]; then
        . ~/.bash_aliases_system
fi
