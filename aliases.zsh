#!/bin/zsh

# Only show load message in debug mode
[[ -n "$ZSH_DEBUG" ]] && echo "zsh.config/aliases loaded"

# reload zsh configuration
alias zshsource="exec zsh"

alias zshconfig="cursor ~/zsh.config"

# edit global ssh configuration
alias sshconfig="code ~/.ssh/config"

# edit global git configuration
alias gitconfig="code ~/.gitconfig"

# navigate to ssh directory
alias sshhome="cd ~/.ssh"

# edit .npmrc
alias nvmrc="code ~/.npmrc"

# OPEN
alias chrome="open -a /Applications/Google\ Chrome.app"
alias firefox="open -a /Applications/Firefox.app"
alias brave="open -a /Applications/Brave\ Browser.app"
alias edge="open -a /Applications/Microsoft Edge.app"

# MISC
alias ls2=" eza --group-directories-first -la --icons=always"

alias k="clear"


# THEME MANAGEMENT
alias themes="theme_list"
alias theme-preview="theme_preview"
alias theme-switch="theme_switch"
alias theme-debug="debug_oh_my_posh"

# PLUGIN MANAGEMENT
alias plugins="plugins_status"
alias plugins-update="plugins_update"
alias plugins-install="plugins_install"

# PERFORMANCE MONITORING
alias zsh-profile="zsh_profile"
alias zsh-benchmark="benchmark"
alias zsh-report="zsh_performance_report"
alias zsh-check="zsh_quick_check"
alias zsh-memory="zsh_memory_usage"
alias zsh-functions="zsh_function_sizes"

# SECURITY MANAGEMENT
alias setup-secure-tokens="setup_secure_tokens"
alias check-secrets="check_hardcoded_secrets"
alias security-check="validate_env_security"
alias generate-password="generate_password"

# CONFIGURATION VALIDATION
alias zsh-validate="validate_zsh_config"
alias zsh-debug="enable_debug_mode"
alias zsh-debug-off="disable_debug_mode"
alias zsh-errors="show_recent_errors"

# CLIPBOARD UTILITIES
alias copy="copy_output"
alias copy-cmd="copy_output"
alias clipboard="pbcopy"
alias copy-silent="copy_silent"
alias copy-pwd="copy_pwd"
alias copy-file="copy_file"
alias paste="pbpaste"

# ===================================================================
# PACKAGE MANAGEMENT (Consolidated)
# ===================================================================

# NPM aliases
alias ni="npm install"
alias nr="npm run"
alias ns="npm start"
alias nt="npm test"
alias nb="npm run build"
alias nd="npm run dev"
alias nl="npm run lint"
alias nf="npm run lint:fix"
alias nc="npm run clean"

# Yarn alternatives
alias yi="yarn install"
alias yr="yarn run"
alias ys="yarn start"
alias yt="yarn test"
alias yb="yarn build"
alias yd="yarn dev"
alias yl="yarn lint"
alias yf="yarn lint:fix"

# pnpm alternatives (recommended for monorepos)
alias pi="pnpm install"
alias pr="pnpm run"
alias ps="pnpm start"
alias pt="pnpm test"
alias pb="pnpm build"
alias pd="pnpm dev"
alias pl="pnpm run lint"
alias pf="pnpm run lint:fix"

# ===================================================================
# GIT WORKFLOW (Only aliases NOT provided by Oh My Zsh git plugin)
# ===================================================================

# Code review shortcuts (these are unique)
alias review="gh pr view --web"
alias prs="gh pr list"
alias prco="gh pr checkout"

# Git workflow shortcuts (these extend Oh My Zsh)
alias feat="feature"        # Custom function for feature branches
alias fix="hotfix"          # Custom function for hotfix branches

# ===================================================================
# DIRECTORY NAVIGATION
# ===================================================================

# Quick project navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# Directory shortcuts for common frontend project structures
alias src="cd src"
alias comp="cd src/components"
alias pages="cd src/pages"
alias utils="cd src/utils"
alias hooks="cd src/hooks"
alias styles="cd src/styles"
alias assets="cd src/assets"
alias tests="cd tests || cd __tests__ || cd test"
alias docs="cd docs"
alias config="cd config"

# ===================================================================
# PROJECT MANAGEMENT FUNCTION SHORTCUTS
# ===================================================================

# Project management
alias create="create_frontend_project"
alias switch="switch_project"
alias projects="switch_project"  # Show available projects

# Development shortcuts
alias run="run_script"
alias scripts="run_script"  # Show available scripts
alias clean="clean_install"
alias ports="port_status"
alias kill-port="port_kill"

# Analysis and debugging
alias bundle="analyze_bundle"
alias cover="coverage"

# ===================================================================
# FUZZY FINDER ALIASES (FZF + FD + BAT)
# ===================================================================

# File operations
alias ff="fe"              # fuzzy find and edit files
# alias fcd="fcd"          # REMOVED: conflicts with function
alias fdd="fcd Developer"  # quick access to Developer directory

# Git fuzzy operations (extend Oh My Zsh git functionality)
alias gff="fgf"            # fuzzy git files
alias gmf="fgm"            # fuzzy git modified files
alias gbf="fgb"            # fuzzy git branches
alias gaf="fga"            # fuzzy git add
alias grf="fgr"            # fuzzy git restore
alias glf="fgl"            # fuzzy git log

# Frontend development
alias npmf="fnpm"          # fuzzy npm scripts
alias compf="fcomp"        # fuzzy components
alias testf="ftest"        # fuzzy test files
alias configf="fconfig"    # fuzzy config files
alias docsf="fdocs"        # fuzzy docs
alias depsf="fdeps"        # fuzzy dependencies

# System operations
alias killf="fkill"        # fuzzy kill processes
alias histf="fh"           # fuzzy history
alias envf="fenv"          # fuzzy environment

# Help and status
alias fuzzy="fuzzy_help"   # show fuzzy functions help
alias fhelp="fuzzy_help"   # alternative help command

# INTERACTIVE TREE EXPLORER
alias itree="interactive_tree"
alias tree-pick="interactive_tree"
alias tree-select="interactive_tree"

# HISTORY SELECTION
alias hist="fhistory"              # Enhanced history menu
alias histbrowse="fhistory_browse" # Category-based history browser
alias histfreq="frecent_history"   # Frequency-based history
alias histgit="fhistory_browse git"    # Git command history
alias histnpm="fhistory_browse npm"    # NPM/Node command history
alias histdocker="fhistory_browse docker" # Docker command history

# ALIAS DISCOVERY
alias aliases="alias | grep"       # Search your aliases
alias find-alias="alias-finder"    # Find aliases for a command (Oh My Zsh plugin)
alias show-aliases="alias | sort"  # Show all aliases sorted

# ===================================================================
# TLDR ALIASES (Quick Command Reference)
# ===================================================================

# Basic tldr shortcuts
alias tl="tldr"            # Short alias for tldr
alias help="tldr"          # Use tldr as default help command
alias man="tldr"           # Override man with tldr for quick reference
alias oldman="command man" # Keep access to original man pages

# tldr management
alias tldr-update="tldr --update"
alias tldr-clear="tldr --clear-cache"
alias tldr-random="tldr --random"

# Platform-specific examples
alias tldr-linux="tldr --platform=linux"
alias tldr-osx="tldr --platform=osx"
alias tldr-windows="tldr --platform=windows"

# Fuzzy tldr integration
alias tlf="ftldr"          # fuzzy tldr pages
alias helpf="fhelp_history" # fuzzy help from history

# Smart help functions
alias shelp="smart_help"   # smart help (tldr + man fallback)
alias fe-help="frontend_help"  # frontend tool help
alias tip="random_tip"     # random command tip

# DEVELOPMENT
alias stopall="pm2 stop all; pm2 delete all; oy containers stop; oy containers nuke"
alias startall="pnpm oy containers stop; pnpm oy containers start; pnpm oy start enterprise"
alias serve-local="pnpm serve:local"
alias get-tree="tree"

alias python="python3"
alias py="python3"
alias pip="pip3"

