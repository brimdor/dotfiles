# Dotfile configuration

This repository contains my personal dotfiles, managed with [chezmoi](https://www.chezmoi.io/what-does-chezmoi-do). It automates the setup of my development environment across Linux and macOS, handling everything from shell configuration to CLI tools and editor plugins.

## Overview & Flow

There is a major split in how software is installed and managed in this repo:

- **Prebuilt binaries** are installed via the `.chezmoiexternal.yaml` file. This file defines all tools that can be downloaded as prebuilt binaries for your OS and architecture (e.g., fastfetch, cpufetch, gh, fzf, etc.). Most are extracted to `~/.local/bin` and made executable automatically. If a binary is not available for your platform, chezmoi will simply skip it—no errors will be thrown.
- **Packaged software** (anything not available as a prebuilt binary) is installed via an Ansible playbook. The list of such packages is defined in `.chezmoitemplates/packaged-software`, which is rendered into the playbook's variables. The playbook makes a best-effort attempt to install the correct package for your OS and package manager (e.g., apt, dnf, pacman, brew).

**chezmoi** is used to manage and apply all dotfiles, templates, and scripts. It ensures reproducibility and easy migration between machines.
**Templates** are used for files that require system-specific values (e.g., architecture, OS, usernames). These are rendered at apply-time.
**Quality of life tools** like oh-my-zsh, tmux, and neovim plugins are included and set up automatically.
**Ansible** is used for more complex provisioning, such as installing packages that are not available as a binary release as well as configuring system-wide settings. The playbook is triggered via a `run_onchange` script.

## 1Password Integration

This repo supports two approaches for loading secure items from 1Password, determined by chezmoi templating:

- If the `OP_CONNECT_HOST` environment variable is present, the repo uses 1Password Connect (service-account, non-interactive mode). Functions in `dot_dotfiles/functions/opAll.zsh.tmpl` are adapted to use the Connect API for seamless, unattended secrets access.
- If `OP_CONNECT_HOST` is not set, the repo falls back to classic interactive mode, prompting for sign-in as needed. The same functions mutate their behavior to use the interactive CLI.

This dual approach ensures secrets are loaded securely and conveniently, regardless of environment.

## Exceptions & Special Cases

- Some binaries are only available for certain architectures or OSes. The templates in `.chezmoiexternal.yaml` handle these cases, so unsupported binaries are skipped.
- Some files (like `onefetch`) are only installed on `amd64` systems, as upstream does not provide arm64 builds.
- The repo uses both direct file downloads and archive extraction, depending on how upstream distributes releases.
- Some scripts and templates use Go templating and chezmoi variables to adapt to your environment.

## Installation

1. [Install chezmoi](https://www.chezmoi.io/install/):

```bash
GITHUB_USERNAME=brimdor
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```

This will clone the repo, apply all dotfiles, download binaries, and run any provisioning scripts. You can re-apply at any time with `chezmoi apply`.

## Low RAM Hosts

Some hosts in my environment have very limited RAM (CloudKey-class devices, tiny ARM SBCs, lightweight VMs, etc).
When using chezmoi externals, certain large tools (e.g., argocd, opencode, helm, terraform, etc.) are downloaded during `chezmoi apply` / `chezmoi update`.

ChezMoi’s external downloader does not stream downloads — it performs a full `io.ReadAll(response.Body)`. This means:

- The entire file is loaded into RAM as a giant byte slice before it is written to disk.
- Large binaries (100–300MB+) can exceed available memory on small hosts.

When that happens, Go’s runtime triggers a hard failure: `fatal error: runtime: out of memory`. This is not a disk-space problem — it is pure RAM exhaustion caused by externally-managed binaries.

### 🧠 Why enabling swap fixes the issue

Linux uses swap as overflow space for RAM. Unlike a tmpfs or ramdisk (which consume RAM), swap extends virtual memory, allowing large allocations like ChezMoi’s `io.ReadAll` to succeed.

Adding a one-time, temporary 2GB swap file is enough to let ChezMoi complete even large external downloads.

#### Temporary swap creation (safe, fast, and non-persistent)

```bash
sudo fallocate -l 2G /home/swapfile
sudo chmod 600 /home/swapfile
sudo mkswap /home/swapfile
sudo swapon /home/swapfile
```

This:
- Allocates a 2GB file on the SSD
- Marks it as swap
- Activates it immediately
- Does not persist across reboots
- Does not modify `/etc/fstab`

After the chezmoi update completes:

```bash
sudo swapoff /home/swapfile
sudo rm /home/swapfile
```

That’s it. Clean and reversible.

### ⚙️ When to use this technique

You only need this workaround when:
- You are on a host with low memory (≤1–2GB RAM)
- ChezMoi crashes with `runtime: out of memory`
- You are installing large tools through `.chezmoiexternal.(yaml|toml)`

This temporary swap file allows ChezMoi to complete the install/update reliably.

### 🧩 Future improvements (optional)

If this becomes a recurring issue, possible long-term options include:
- Putting large binaries behind `run_onchange_*.tmpl` scripts, which stream downloads
- Restricting externals based on hostname/architecture
- Adding a permanent swap file for embedded devices
- Using smaller binaries (e.g., musl builds)

But for single-use “fix it right now” situations, the temporary swap file is ideal.

## Included Tools & Features

- Zsh configuration with oh-my-zsh, plugins, and powerlevel10k theme
- Tmux configuration and plugins
- Neovim configuration and plugins
- CLI tools: gh, fzf, jq, yq, argocd, helm, kubectl, terraform, fastfetch, cpufetch, and more
- Custom aliases, completions, and functions
- Ansible playbook for system provisioning

## Contributing

Feel free to use this as a reference or copy it entirely. If you have questions or suggestions, open an issue or pull request.
