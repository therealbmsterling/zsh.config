#!/bin/zsh

# Only show load message in debug mode
[[ -n "$ZSH_DEBUG" ]] && echo "zsh.config/theme loaded"

# ===================================================================
# THEME CONFIGURATION: Oh My Posh
# ===================================================================

# Function to initialize Oh My Posh theme with robust error handling
init_oh_my_posh() {
  # Skip if oh-my-posh is not available
  if ! command -v oh-my-posh >/dev/null 2>&1; then
    [[ -n "$ZSH_DEBUG" ]] && echo "⚠️  Oh My Posh not found. Install with: brew install oh-my-posh" >&2
    return 1
  fi

  # Skip Apple Terminal (limited capabilities)
  if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
    [[ -n "$ZSH_DEBUG" ]] && echo "📱 Apple Terminal detected - skipping Oh My Posh (limited support)"
    return 0
  fi

  # Validate terminal capabilities
  if [[ -z "$TERM" ]] || [[ "$TERM" == "dumb" ]]; then
    [[ -n "$ZSH_DEBUG" ]] && echo "⚠️  Terminal doesn't support Oh My Posh features" >&2
    return 1
  fi

  # Custom theme path - you can change this to any theme you prefer
  # Options:
  # 1. Keep custom file: "$HOME/honukai.omp.json"
  # 2. Use built-in theme directly: "$(find_theme_path "tokyo")"
  # 3. Use different custom file: "$HOME/my-theme.omp.json"
  local custom_theme="$(find_theme_path "kushal")"
  local selected_theme=""
  local theme_name=""

  # Determine which theme to use
  if [[ -f "$custom_theme" ]] && [[ -r "$custom_theme" ]]; then
    selected_theme="$custom_theme"
    theme_name="honukai (custom)"
  else
    # Try to find a fallback theme
    local fallback_theme_path
    if fallback_theme_path="$(find_theme_path "jandedobbeleer")"; then
      selected_theme="$fallback_theme_path"
      theme_name="jandedobbeleer (fallback)"
    else
      [[ -n "$ZSH_DEBUG" ]] && echo "❌ Error: No Oh My Posh themes found" >&2
      [[ -n "$ZSH_DEBUG" ]] && echo "💡 Searched:" >&2
      [[ -n "$ZSH_DEBUG" ]] && echo "   - Custom: $custom_theme" >&2
      [[ -n "$ZSH_DEBUG" ]] && echo "   - Fallback: jandedobbeleer theme in standard locations" >&2
      [[ -n "$ZSH_DEBUG" ]] && echo "" >&2
      [[ -n "$ZSH_DEBUG" ]] && echo "🔧 Try installing themes with: brew reinstall oh-my-posh" >&2
      return 1
    fi
  fi

  # Validate JSON syntax of theme file
  if command -v jq >/dev/null 2>&1; then
    if ! jq empty "$selected_theme" >/dev/null 2>&1; then
      [[ -n "$ZSH_DEBUG" ]] && echo "❌ Error: Invalid JSON in theme file: $selected_theme" >&2
      return 1
    fi
  fi

  # Initialize Oh My Posh with error handling
  local init_cmd
  if ! init_cmd="$(oh-my-posh init zsh --config "$selected_theme" 2>&1)"; then
    [[ -n "$ZSH_DEBUG" ]] && echo "❌ Error: Failed to initialize Oh My Posh with theme: $selected_theme" >&2
    [[ -n "$ZSH_DEBUG" ]] && echo "💡 Error details: $init_cmd" >&2
    return 1
  fi

  # Evaluate the initialization command
  if ! eval "$init_cmd" 2>/dev/null; then
    [[ -n "$ZSH_DEBUG" ]] && echo "❌ Error: Failed to load Oh My Posh configuration" >&2
    return 1
  fi

  # Only show success message in normal mode or debug
  echo "🎨 Oh My Posh loaded with theme: $theme_name"
  return 0
}

# Utility function to find theme path
find_theme_path() {
  local theme_name="$1"

  if [[ -z "$theme_name" ]]; then
    return 1
  fi

  # Try multiple locations
  local theme_paths=(
    "/opt/homebrew/opt/oh-my-posh/themes/${theme_name}.omp.json"      # Homebrew Apple Silicon
    "/usr/local/opt/oh-my-posh/themes/${theme_name}.omp.json"         # Homebrew Intel
    "$(brew --prefix 2>/dev/null)/opt/oh-my-posh/themes/${theme_name}.omp.json"  # Dynamic brew prefix
    "/opt/homebrew/share/oh-my-posh/themes/${theme_name}.omp.json"    # Alternative location
    "/usr/local/share/oh-my-posh/themes/${theme_name}.omp.json"       # Alternative location
    "$HOME/.oh-my-posh/themes/${theme_name}.omp.json"                 # User installation
  )

  for theme_path in "${theme_paths[@]}"; do
    if [[ -f "$theme_path" ]] && [[ -r "$theme_path" ]]; then
      echo "$theme_path"
      return 0
    fi
  done

  return 1
}

# Utility function to check if a theme exists and is valid
theme_exists() {
  local theme_name="$1"

  if [[ -z "$theme_name" ]]; then
    return 1
  fi

  if ! command -v oh-my-posh >/dev/null 2>&1; then
    return 1
  fi

  local theme_path
  if ! theme_path="$(find_theme_path "$theme_name")"; then
    return 1
  fi

  # Validate JSON if jq is available
  if command -v jq >/dev/null 2>&1; then
    if ! jq empty "$theme_path" >/dev/null 2>&1; then
      return 1
    fi
  fi

  return 0
}

# Theme management functions with enhanced error handling
theme_list() {
  if ! command -v oh-my-posh >/dev/null 2>&1; then
    echo "❌ Error: Oh My Posh not installed" >&2
    echo "💡 Install with: brew install oh-my-posh" >&2
    return 1
  fi

  echo "🎨 Available Oh My Posh themes:"
  echo ""

  # Try multiple methods to find themes directory
  local themes_dirs=(
    "/opt/homebrew/opt/oh-my-posh/themes"       # Homebrew Apple Silicon
    "/usr/local/opt/oh-my-posh/themes"          # Homebrew Intel
    "$(brew --prefix 2>/dev/null)/opt/oh-my-posh/themes"    # Dynamic brew prefix
    "/opt/homebrew/share/oh-my-posh/themes"     # Alternative location
    "/usr/local/share/oh-my-posh/themes"        # Alternative location
    "$HOME/.oh-my-posh/themes"                  # User installation
  )

  local found_themes=false

    for themes_dir in "${themes_dirs[@]}"; do
    if [[ -d "$themes_dir" ]] && [[ -n "$(ls -A "$themes_dir"/*.omp.json 2>/dev/null)" ]]; then
      echo "📁 Found themes in: $themes_dir"
      found_themes=true

      # List themes - use a very direct approach
      echo ""
      basename -s .omp.json "$themes_dir"/*.omp.json 2>/dev/null | sort | head -30 | pr -3 -t 2>/dev/null || basename -s .omp.json "$themes_dir"/*.omp.json 2>/dev/null | sort | head -20

      echo ""
      local total_themes=$(ls "$themes_dir"/*.omp.json 2>/dev/null | wc -l | tr -d ' ')
      echo "📊 Total themes available: $total_themes"
      if (( total_themes > 30 )); then
        echo "💡 Showing first 30 themes above. Use specific theme names with preview/switch commands."
      fi

      break
    fi
  done

  if [[ "$found_themes" == "false" ]]; then
    echo "❌ No Oh My Posh themes found in standard locations:" >&2
    for dir in "${themes_dirs[@]}"; do
      if [[ -n "$dir" ]]; then
        echo "   - $dir" >&2
      fi
    done
    echo "" >&2
    echo "🔍 Troubleshooting:" >&2
    echo "   1. Check Oh My Posh version: oh-my-posh --version" >&2
    echo "   2. Reinstall: brew reinstall oh-my-posh" >&2
    echo "   3. Use built-in command: oh-my-posh config migrate --help" >&2
    return 1
  fi

  echo ""
  echo "💡 Usage:"
  echo "   theme-preview <theme_name>  - Preview a theme"
  echo "   theme-switch <theme_name>   - Switch to a theme"
  echo ""
  echo "🎯 Popular themes to try:"
  echo "   jandedobbeleer, paradox, powerlevel10k_rainbow, tokyo, craver"
}

# Debug function to diagnose Oh My Posh installation
debug_oh_my_posh() {
  echo "🔍 Oh My Posh Installation Diagnostic"
  echo "====================================="
  echo ""

  # Check if Oh My Posh is installed
  if command -v oh-my-posh >/dev/null 2>&1; then
    echo "✅ Oh My Posh is installed"
    echo "   Path: $(which oh-my-posh)"
    echo "   Version: $(oh-my-posh --version 2>/dev/null || echo 'Unknown')"
  else
    echo "❌ Oh My Posh not found in PATH"
    echo "   Install with: brew install oh-my-posh"
    return 1
  fi

  echo ""
  echo "🔍 Checking theme directories:"

  local theme_paths=(
    "/opt/homebrew/opt/oh-my-posh/themes"
    "/usr/local/opt/oh-my-posh/themes"
    "$(brew --prefix 2>/dev/null)/opt/oh-my-posh/themes"
    "/opt/homebrew/share/oh-my-posh/themes"
    "/usr/local/share/oh-my-posh/themes"
    "$HOME/.oh-my-posh/themes"
  )

  for dir in "${theme_paths[@]}"; do
    if [[ -n "$dir" ]]; then
      if [[ -d "$dir" ]]; then
        local theme_count=$(ls -1 "$dir"/*.omp.json 2>/dev/null | wc -l | tr -d ' ')
        echo "  ✅ $dir ($theme_count themes)"
      else
        echo "  ❌ $dir (not found)"
      fi
    fi
  done

  echo ""
  echo "🔍 Brew information:"
  if command -v brew >/dev/null 2>&1; then
    echo "  Brew prefix: $(brew --prefix 2>/dev/null || echo 'Unknown')"
    echo "  Oh My Posh status: $(brew list oh-my-posh 2>/dev/null | head -1 || echo 'Not installed via brew')"
  else
    echo "  Brew not found"
  fi

  echo ""
  echo "💡 If themes are missing, try:"
  echo "   brew reinstall oh-my-posh"
}

theme_preview() {
  local theme_name="$1"

  # Input validation
  if [[ -z "$theme_name" ]]; then
    echo "❌ Error: Theme name is required" >&2
    echo "💡 Usage: theme_preview <theme_name>" >&2
    echo "💡 Available themes:" >&2
    theme_list
    return 1
  fi

  if ! command -v oh-my-posh >/dev/null 2>&1; then
    echo "❌ Error: Oh My Posh not installed" >&2
    echo "💡 Install with: brew install oh-my-posh" >&2
    return 1
  fi

  # Find the theme path
  local theme_path
  if ! theme_path="$(find_theme_path "$theme_name")"; then
    echo "❌ Error: Theme '$theme_name' not found" >&2
    echo "" >&2
    echo "💡 Available themes:" >&2
    theme_list
    return 1
  fi

        # Preview the theme
  echo "🎨 Preview of theme '$theme_name':"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Run the preview command directly - let it output to terminal
  if oh-my-posh print primary --config "$theme_path" --plain; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 Use 'theme-switch $theme_name' to apply this theme"
    return 0
  else
    local exit_code=$?
    echo "❌ Error: Failed to preview theme: $theme_name" >&2
    echo "💡 The theme file exists but Oh My Posh cannot render it" >&2
    echo "" >&2
    echo "🛠️  Troubleshooting steps:" >&2
    echo "   1. Test manually: oh-my-posh print primary --config '$theme_path' --plain" >&2
    echo "   2. Check Oh My Posh version: oh-my-posh --version" >&2
    echo "   3. Try a different theme: themes" >&2
    return $exit_code
  fi
}

theme_switch() {
  local theme_name="$1"

  # Input validation
  if [[ -z "$theme_name" ]]; then
    echo "❌ Error: Theme name is required" >&2
    echo "💡 Usage: theme_switch <theme_name>" >&2
    echo "💡 Available themes:" >&2
    theme_list
    return 1
  fi

  if ! command -v oh-my-posh >/dev/null 2>&1; then
    echo "❌ Error: Oh My Posh not installed" >&2
    echo "💡 Install with: brew install oh-my-posh" >&2
    return 1
  fi

  # Find the theme path
  local theme_path
  if ! theme_path="$(find_theme_path "$theme_name")"; then
    echo "❌ Error: Theme '$theme_name' not found" >&2
    echo "" >&2
    echo "💡 Available themes:" >&2
    theme_list
    return 1
  fi

  echo "🔧 Switching to theme: $theme_name"
  echo "📍 Theme path: $theme_path"

  # Method 1: Try direct eval (works in most cases)
  local init_output
  if init_output="$(oh-my-posh init zsh --config "$theme_path" 2>&1)"; then
    echo "🔧 Executing theme initialization..."

    # Execute the init output directly
    if eval "$init_output" 2>/dev/null; then
      echo "✅ Theme initialization successful"

      # Force a prompt refresh
      if typeset -f precmd >/dev/null; then
        precmd 2>/dev/null || true
      fi

      echo "🎨 Successfully switched to theme: $theme_name"
      echo "💡 The new theme should appear on your next command prompt."
      echo "💡 If the theme doesn't appear, try: exec zsh"
      return 0
    else
      echo "⚠️  Direct initialization failed, trying alternative method..."
    fi
  else
    echo "❌ Error: Failed to initialize theme: $theme_name" >&2
    echo "💡 Error details: $init_output" >&2
    return 1
  fi

  # Method 2: Fallback - manual cache file approach
  echo "🔧 Trying alternative initialization method..."

  # Extract cache file path more robustly
  local cache_file
  cache_file=$(echo "$init_output" | grep -o "\$'[^']*'" | sed "s/\$'//g" | sed "s/'//g" | head -1)

  if [[ -z "$cache_file" ]]; then
    # Try another pattern
    cache_file=$(echo "$init_output" | grep -o '/[^[:space:]]*\.zsh' | head -1)
  fi

  if [[ -n "$cache_file" ]] && [[ -f "$cache_file" ]]; then
    echo "📁 Found cache file: $cache_file"
    if source "$cache_file" 2>/dev/null; then
      echo "✅ Theme loaded from cache file"
      echo "🎨 Successfully switched to theme: $theme_name"
      return 0
    fi
  fi

  # Method 3: Last resort - restart suggestion
  echo "❌ Unable to switch theme in current session" >&2
  echo "💡 Try restarting your shell: exec zsh" >&2
  echo "💡 Or ensure the theme works: oh-my-posh print primary --config '$theme_path'" >&2
  return 1
}

# Initialize the theme
init_oh_my_posh
