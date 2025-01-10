# VoidRice .bashrc
# 2025 JAN 04
#
##########################################################
## DEFAULT:
# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='[\u@\h \W]\$'

##########################################################

# Tab complete ignore-case
if [[ $- == *i* ]]; then
    bind 'set completion-ignore-case on'
fi
 

### ALIASES ###

# File Navigation
alias ls='ls --color=auto'


# XBPS and xtools
alias xup='sudo xbps-install -Su'
alias xin='sudo xbps-install -S'
alias xrm='sudo xbps-remove -R' #removes package and dependencies
alias xro='sudo xbps-remove -o' #removes all orphaned packages
alias xqr='xbps-query -Rs'
alias xqf='xbps-query -f'
alias xlist="xbps-query -l | awk '{ print $2 }' | xargs -n1 xbps-uhelper getpkgname"

# Xtools
alias xloc='xlocate -S'

# Terminal Programs
alias fetch='fastfetch'

alias nv='nvim'
alias vi='nvim'
alias vim='nvim'

alias stow='stow -t ~'

# fzf
#source /usr/share/fzf/key-bindings.bash
#source /usr/share/fzf/completion.bash

# End of File add-ons
eval "$(zoxide init bash)"
eval "$(starship init bash)"
