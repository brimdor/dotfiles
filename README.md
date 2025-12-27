# Dotfile configuration

This repository contains my dotfiles. I use [chezmoi](https://www.chezmoi.io/what-does-chezmoi-do) to manage them. It's by no means perfect, but it works for me. There are still some loose ends, but I'm working on fine-tuning it.

Feel free to use it as a reference or copy it entirely. If you have any questions or suggestions, feel free to open an issue or a pull request.

## Installation

1. [Install chezmoi](https://www.chezmoi.io/install/):

```bash
GITHUB_USERNAME=llajas
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```

Some quality of life improvements are included, such as oh-my-zsh, tmux, and vim plugins.