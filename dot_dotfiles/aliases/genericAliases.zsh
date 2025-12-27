# ~/.dotfiles/aliases/genericAliases.zsh

# Because I hate typing kubectl and kubectl is too long - oc is cooler anyhow
alias kc='kubectl'
# Turns jnv on its head and into a yaml parser
alias ynv='yq -o json | jnv'
# Set context in kubectl (namespace set)
alias ksn='kubectl config set-context --current --namespace'
# Because Terraform is too long, too...
alias tf='terraform'
# 'chezmoi' is a bit of a mouthful - It's also a bit of a pain to type
alias cz='chezmoi'

#tmux aliases
alias tm='tmux'
alias tm-attach='tmux attach -t'
alias tm-new='tmux new -d -s'
alias tm-switch='tmux switch -t'