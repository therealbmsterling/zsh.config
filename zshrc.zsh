#!/bin/zsh

# Only show load message in debug mode
[[ -n "$ZSH_DEBUG" ]] && echo "zsh.config/zshrc loaded"

source "$ZSH_CONFIG/aliases.zsh"
source "$ZSH_CONFIG/functions.zsh"
source "$ZSH_CONFIG/fuzzy.zsh"
source "$ZSH_CONFIG/theme.zsh"
# Note: plugins.zsh is sourced in .zshrc before Oh My Zsh initialization

# Google Cloud SDK - now lazy loaded via performance.zsh for faster startup

# nvm - use .nvmrc automatically (optimized version)
autoload -U add-zsh-hook
add-zsh-hook chpwd load_nvmrc_optimized

# Note: nvmrc loading will happen automatically when changing directories
# or when using any nvm/node commands (lazy loading)


export PATH=/opt/homebrew/opt/gnu-getopt/bin:node_modules/.bin:$HOME/.local/bin:$PATH

# Secure environment variables are loaded via security.zsh
# HIVE_TOKEN and other secrets should be in ~/.env (run 'setup-secure-tokens' to migrate)
