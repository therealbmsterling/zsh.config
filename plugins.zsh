#!/bin/zsh

# Only show load message in debug mode
[[ -n "$ZSH_DEBUG" ]] && echo "zsh.config/plugins loaded"

# ===================================================================
# PLUGIN CONFIGURATION & OPTIMIZATION
# ===================================================================

# Oh My Zsh Performance Settings
# Skip verification of insecure directories
ZSH_DISABLE_COMPFIX=true

# Disable Oh My Zsh auto-update to control when updates happen
zstyle ':omz:update' mode disabled

# ===================================================================
# CORE PLUGINS (loaded via Oh My Zsh)
# ===================================================================
# Optimized plugin list - removed conflicting and redundant plugins

# Essential development plugins
ZSH_PLUGINS_CORE=(
  git              # Git aliases and functions
  gitignore        # .gitignore generation
  git-flow         # Git flow workflow support
  git-extras       # Additional git commands
  github           # GitHub CLI integration
  branch           # Enhanced branch management
  alias-finder     # Find aliases for commands (proactive)
)

# ===================================================================
# ENHANCED PLUGINS (manually managed for better control)
# ===================================================================

# Initialize enhanced plugins with error handling
init_enhanced_plugins() {
  local plugin_base="$ZSH/custom/plugins"

  # Define plugins with their load order (syntax highlighting MUST be last)
  local enhanced_plugins=(
    "zsh-autosuggestions/zsh-autosuggestions.zsh"
    # "you-should-use/you-should-use.plugin.zsh"
    "zsh-history-substring-search/zsh-history-substring-search.zsh"
    "zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"  # Must be last!
  )

  echo "🔌 Loading enhanced plugins..."

  for plugin in "${enhanced_plugins[@]}"; do
    local plugin_path="$plugin_base/$plugin"
    local plugin_name=$(basename "$(dirname "$plugin")")

    if [[ -f "$plugin_path" ]]; then
      source "$plugin_path"
      echo "  ✅ $plugin_name"
    else
      echo "  ❌ $plugin_name (not found: $plugin_path)"

      # Suggest installation
      case "$plugin_name" in
        "zsh-autosuggestions")
          echo "     Install: git clone https://github.com/zsh-users/zsh-autosuggestions \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
          ;;
        "you-should-use")
          echo "     Install: git clone https://github.com/MichaelAquilina/zsh-you-should-use.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use"
          ;;
        "zsh-syntax-highlighting")
          echo "     Install: git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
          ;;
        "zsh-history-substring-search")
          echo "     Install: git clone https://github.com/zsh-users/zsh-history-substring-search \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search"
          ;;
      esac
    fi
  done

  # Load additional frontend-specific completions
  init_frontend_completions
}

# ===================================================================
# FRONTEND-SPECIFIC COMPLETIONS
# ===================================================================

init_frontend_completions() {
  [[ -n "$ZSH_DEBUG" ]] && echo "🔧 Setting up frontend tool completions..."

  # GitHub CLI completion
  if command -v gh >/dev/null 2>&1; then
    eval "$(gh completion -s zsh)" 2>/dev/null && [[ -n "$ZSH_DEBUG" ]] && echo "  ✅ GitHub CLI"
  fi

  # Kubectl completion (for frontend deployments)
  if command -v kubectl >/dev/null 2>&1; then
    eval "$(kubectl completion zsh)" 2>/dev/null && [[ -n "$ZSH_DEBUG" ]] && echo "  ✅ Kubectl"
  fi

  # pnpm completion
  if command -v pnpm >/dev/null 2>&1; then
    eval "$(pnpm completion zsh)" 2>/dev/null && [[ -n "$ZSH_DEBUG" ]] && echo "  ✅ pnpm"
  fi
}

# ===================================================================
# PLUGIN CONFIGURATION
# ===================================================================

# Configure zsh-autosuggestions
configure_autosuggestions() {
  # Performance: Use faster strategy
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)

  # Performance: Reduce delay
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

  # Better UX: Use different color
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"

  # Performance: Disable for large buffers
  ZSH_AUTOSUGGEST_DISABLE_WHEN_CURSOR_NOT_AT_END=true
}

# Configure zsh-syntax-highlighting
configure_syntax_highlighting() {
  # Enable additional highlighting
  ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

  # Custom colors
  typeset -A ZSH_HIGHLIGHT_STYLES
  ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
  ZSH_HIGHLIGHT_STYLES[function]='fg=blue,bold'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=yellow,bold'
  ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=red,bold'
  ZSH_HIGHLIGHT_STYLES[redirection]='fg=magenta,bold'
}

# Configure history substring search
configure_history_search() {
  # Key bindings (compatible with your current setup)
  bindkey '^[OA' history-substring-search-up    # Up arrow
  bindkey '^[OB' history-substring-search-down  # Down arrow
  bindkey '^P' history-substring-search-up      # Ctrl+P
  bindkey '^N' history-substring-search-down    # Ctrl+N

  # Colors
  HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=green,fg=white,bold'
  HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=white,bold'

  # Performance
  HISTORY_SUBSTRING_SEARCH_FUZZY=1
}

# Configure you-should-use plugin for alias reminders
configure_you_should_use() {
  # Show reminders for both aliases and global aliases
  export YSU_MODE=ALL

  # Customize the reminder message style
  export YSU_MESSAGE_POSITION="after"  # Show after command execution

  # Customize colors and formatting
  export YSU_MESSAGE_FORMAT="💡 Reminder: You can use the alias $(tput setaf 2)%alias$(tput sgr0) for $(tput setaf 1)%command$(tput sgr0)"

  # Don't show reminders for these commands (add commands you want to exclude)
  export YSU_IGNORED_ALIASES=("g" "vi" "l" "ll")

  # Don't remind about aliases that are longer than the original command
  export YSU_HARDCORE=0
}

# ===================================================================
# PLUGIN MANAGEMENT FUNCTIONS
# ===================================================================

# List loaded plugins
plugins_status() {
  echo "🔌 Plugin Status:"
  echo ""
  echo "Core Plugins (Oh My Zsh):"
  for plugin in "${ZSH_PLUGINS_CORE[@]}"; do
    if [[ -d "$ZSH/plugins/$plugin" ]]; then
      echo "  ✅ $plugin"
    else
      echo "  ❌ $plugin (not found)"
    fi
  done

  echo ""
  echo "Enhanced Plugins:"
  local plugin_base="$ZSH/custom/plugins"
  local plugins=("zsh-autosuggestions" "you-should-use" "zsh-history-substring-search" "zsh-syntax-highlighting")

  for plugin in "${plugins[@]}"; do
    if [[ -d "$plugin_base/$plugin" ]]; then
      echo "  ✅ $plugin"
    else
      echo "  ❌ $plugin (not installed)"
    fi
  done
}

# Update all plugins
plugins_update() {
  echo "🔄 Updating plugins..."

  # Update Oh My Zsh plugins
  if command -v omz >/dev/null 2>&1; then
    omz update
  fi

  # Update custom plugins
  local plugin_base="$ZSH/custom/plugins"
  for plugin_dir in "$plugin_base"/*; do
    if [[ -d "$plugin_dir/.git" ]]; then
      echo "Updating $(basename "$plugin_dir")..."
      (cd "$plugin_dir" && git pull)
    fi
  done
}

# Install missing plugins
plugins_install() {
  echo "📥 Installing missing plugins..."

  local plugin_base="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

  # Install zsh-autosuggestions
  if [[ ! -d "$plugin_base/zsh-autosuggestions" ]]; then
    echo "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_base/zsh-autosuggestions"
  fi

  # Install zsh-syntax-highlighting
  if [[ ! -d "$plugin_base/zsh-syntax-highlighting" ]]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_base/zsh-syntax-highlighting"
  fi

  # Install zsh-history-substring-search
  if [[ ! -d "$plugin_base/zsh-history-substring-search" ]]; then
    echo "Installing zsh-history-substring-search..."
    git clone https://github.com/zsh-users/zsh-history-substring-search "$plugin_base/zsh-history-substring-search"
  fi

  # Install you-should-use for alias reminders
  if [[ ! -d "$plugin_base/you-should-use" ]]; then
    echo "Installing you-should-use (alias reminder plugin)..."
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$plugin_base/you-should-use"
  fi

  echo "✅ Plugin installation complete!"
}

# ===================================================================
# INITIALIZATION
# ===================================================================

# Set up the optimized plugin configuration
setup_plugins() {
  # Configure plugins before loading
  configure_autosuggestions
  configure_syntax_highlighting
  configure_history_search
  # configure_you_should_use

  # Export final plugin list for Oh My Zsh
  export plugins=("${ZSH_PLUGINS_CORE[@]}")
}

# Initialize plugins configuration
setup_plugins
