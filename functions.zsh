#!/bin/zsh

# Only show load message in debug mode
[[ -n "$ZSH_DEBUG" ]] && echo "zsh.config/functions loaded"

unalias cd 2>/dev/null

# Enhanced cd function with robust error handling
cd() {
  # Input validation
  if [[ $# -gt 1 ]]; then
    echo "❌ Error: cd accepts only one argument" >&2
    echo "💡 Usage: cd [directory]" >&2
    return 1
  fi

  # Handle special cases
  local target_dir="${1:-.}"  # Default to current directory if no argument

  # Expand tilde and resolve path
  target_dir="${target_dir/#\~/$HOME}"

  # Check if target exists and is accessible
  if [[ ! -e "$target_dir" ]]; then
    echo "❌ Error: Directory '$target_dir' does not exist" >&2
    return 1
  fi

  if [[ ! -d "$target_dir" ]]; then
    echo "❌ Error: '$target_dir' is not a directory" >&2
    return 1
  fi

  if [[ ! -r "$target_dir" ]]; then
    echo "❌ Error: Permission denied to access '$target_dir'" >&2
    return 1
  fi

  # Attempt to change directory
  if ! builtin cd "$target_dir"; then
    echo "❌ Error: Failed to change to directory '$target_dir'" >&2
    return 1
  fi

  # Only show listing for interactive shells and if directory isn't too large
  if [[ $- == *i* ]] && [[ -t 1 ]]; then
    # Safe file counting with timeout and error handling
    local file_count=0
    local count_timeout=2  # 2 second timeout

    # Use timeout if available, otherwise fallback
    if command -v timeout >/dev/null 2>&1; then
      file_count=$(timeout "$count_timeout" find . -maxdepth 1 -type f 2>/dev/null | wc -l 2>/dev/null || echo 0)
    else
      # Fallback without timeout
      file_count=$(find . -maxdepth 1 -type f 2>/dev/null | wc -l 2>/dev/null || echo 0)
    fi

    # Handle counting errors
    if [[ ! "$file_count" =~ ^[0-9]+$ ]]; then
      file_count=0
    fi

    # Skip listing for very large directories (>100 files) to maintain performance
    if (( file_count <= 100 )); then
      if command -v eza >/dev/null 2>&1; then
        if ! eza --group-directories-first -la --icons=auto 2>/dev/null; then
          echo "⚠️  eza failed, falling back to ls" >&2
          ls -la --color=auto 2>/dev/null || ls -la 2>/dev/null || echo "❌ Unable to list directory contents" >&2
        fi
      else
        if ! ls -la --color=auto 2>/dev/null && ! ls -la 2>/dev/null; then
          echo "❌ Unable to list directory contents" >&2
        fi
      fi
    else
      echo "📁 Directory contains $file_count files (listing skipped for performance)"
      echo "💡 Use 'ls' or 'eza' to list files manually"
    fi
  fi
}

# Enhanced error handling utility functions
safe_source() {
  local file="$1"
  local description="${2:-file}"

  if [[ -z "$file" ]]; then
    echo "❌ Error: safe_source requires a file path" >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    echo "⚠️  Warning: $description not found: $file" >&2
    return 1
  fi

  if [[ ! -r "$file" ]]; then
    echo "❌ Error: Cannot read $description: $file (permission denied)" >&2
    return 1
  fi

  if ! source "$file"; then
    echo "❌ Error: Failed to source $description: $file" >&2
    return 1
  fi

  return 0
}

# Safe command execution with error handling
safe_exec() {
  local cmd="$1"
  local description="${2:-command}"
  local timeout="${3:-10}"

  if [[ -z "$cmd" ]]; then
    echo "❌ Error: safe_exec requires a command" >&2
    return 1
  fi

  if ! command -v "${cmd%% *}" >/dev/null 2>&1; then
    echo "❌ Error: Command not found: ${cmd%% *}" >&2
    return 1
  fi

  if command -v timeout >/dev/null 2>&1; then
    if ! timeout "$timeout" eval "$cmd"; then
      echo "❌ Error: $description failed or timed out after ${timeout}s" >&2
      return 1
    fi
  else
    if ! eval "$cmd"; then
      echo "❌ Error: $description failed" >&2
      return 1
    fi
  fi

  return 0
}

# Safe directory creation
safe_mkdir() {
  local dir="$1"
  local mode="${2:-755}"

  if [[ -z "$dir" ]]; then
    echo "❌ Error: safe_mkdir requires a directory path" >&2
    return 1
  fi

  if [[ -e "$dir" ]] && [[ ! -d "$dir" ]]; then
    echo "❌ Error: '$dir' exists but is not a directory" >&2
    return 1
  fi

  if [[ ! -d "$dir" ]]; then
    if ! mkdir -p "$dir" 2>/dev/null; then
      echo "❌ Error: Failed to create directory: $dir" >&2
      return 1
    fi

    if ! chmod "$mode" "$dir" 2>/dev/null; then
      echo "⚠️  Warning: Failed to set permissions on: $dir" >&2
    fi
  fi

  return 0
}

# ===================================================================
# ERROR HANDLING AND DEBUGGING UTILITIES
# ===================================================================

# Error logging functionality
ZSH_ERROR_LOG="/tmp/zsh_errors_$$.log"

# Log errors with timestamp
log_error() {
  local error_msg="$1"
  local function_name="${2:-unknown}"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] ERROR in $function_name: $error_msg" >> "$ZSH_ERROR_LOG"
}

# Show recent errors
show_recent_errors() {
  if [[ -f "$ZSH_ERROR_LOG" ]]; then
    echo "🔍 Recent zsh errors:"
    tail -20 "$ZSH_ERROR_LOG" | while IFS= read -r line; do
      echo "  $line"
    done
  else
    echo "✅ No recent errors logged"
  fi
}

# Enable debug mode
enable_debug_mode() {
  export ZSH_DEBUG=1
  export ZSH_SECURITY_CHECK=1
  set -x  # Enable command tracing
  echo "🐛 Debug mode enabled"
  echo "💡 Use 'disable_debug_mode' to turn off"
}

# Disable debug mode
disable_debug_mode() {
  unset ZSH_DEBUG
  unset ZSH_SECURITY_CHECK
  set +x  # Disable command tracing
  echo "✅ Debug mode disabled"
}

# Cleanup function for error logs
cleanup_error_logs() {
  [[ -f "$ZSH_ERROR_LOG" ]] && rm -f "$ZSH_ERROR_LOG" 2>/dev/null
}

# Register cleanup on exit
trap cleanup_error_logs EXIT

# Enhanced error reporting for functions
report_error() {
  local exit_code="$1"
  local function_name="$2"
  local error_context="$3"

  if [[ "$exit_code" != "0" ]]; then
    local error_msg="Function '$function_name' failed with exit code $exit_code"
    [[ -n "$error_context" ]] && error_msg="$error_msg - $error_context"

    echo "❌ $error_msg" >&2
    log_error "$error_msg" "$function_name"

    if [[ -n "$ZSH_DEBUG" ]]; then
      echo "🐛 Debug info:" >&2
      echo "   PWD: $PWD" >&2
      echo "   User: $USER" >&2
      echo "   Shell: $SHELL" >&2
      echo "   ZSH version: $ZSH_VERSION" >&2
    fi
  fi

  return "$exit_code"
}

# ===================================================================
# FRONTEND DEVELOPMENT FUNCTIONS
# ===================================================================

# Quick project setup
create_frontend_project() {
  local project_name="$1"
  local framework="${2:-react}"

  if [[ -z "$project_name" ]]; then
    echo "❌ Error: Project name is required" >&2
    echo "💡 Usage: create_frontend_project <name> [framework]" >&2
    echo "💡 Frameworks: react, vue, angular, svelte, next, nuxt, vite" >&2
    return 1
  fi

  echo "🚀 Creating $framework project: $project_name"

  case "$framework" in
    "react")
      npx create-react-app "$project_name" --template typescript
      ;;
    "next")
      npx create-next-app@latest "$project_name" --typescript --tailwind --eslint
      ;;
    "vue")
      npm create vue@latest "$project_name"
      ;;
    "nuxt")
      npx nuxi@latest init "$project_name"
      ;;
    "angular")
      npx @angular/cli@latest new "$project_name"
      ;;
    "svelte")
      npm create svelte@latest "$project_name"
      ;;
    "vite")
      npm create vite@latest "$project_name" -- --template react-ts
      ;;
    *)
      echo "❌ Unsupported framework: $framework" >&2
      return 1
      ;;
  esac

  if [[ -d "$project_name" ]]; then
    cd "$project_name"
    echo "✅ Project created successfully!"
    echo "📁 Current directory: $(pwd)"
  fi
}

# Smart package.json script runner
run_script() {
  if [[ ! -f "package.json" ]]; then
    echo "❌ No package.json found in current directory" >&2
    return 1
  fi

  if [[ -z "$1" ]]; then
    echo "📦 Available scripts:"
    jq -r '.scripts | keys[]' package.json 2>/dev/null || echo "❌ Could not read scripts"
    return 0
  fi

  local script="$1"
  shift

  # Auto-detect package manager
  local pm=""
  if [[ -f "pnpm-lock.yaml" ]]; then
    pm="pnpm"
  elif [[ -f "yarn.lock" ]]; then
    pm="yarn"
  else
    pm="npm"
  fi

  echo "🏃 Running '$script' with $pm..."
  $pm run "$script" "$@"
}

# Project switcher for multiple repositories
switch_project() {
  local projects_dir="$HOME/Developer"

  if [[ ! -d "$projects_dir" ]]; then
    echo "❌ Projects directory not found: $projects_dir" >&2
    echo "💡 Update projects_dir in the function or create the directory" >&2
    return 1
  fi

  if [[ -z "$1" ]]; then
    echo "📁 Available projects:"
    find "$projects_dir" -maxdepth 2 -name "package.json" -exec dirname {} \; | \
      sed "s|$projects_dir/||g" | sort
    return 0
  fi

  local project_path="$projects_dir/$1"

  if [[ -d "$project_path" ]]; then
    cd "$project_path"
    echo "🔄 Switched to project: $1"

    # Auto-load .nvmrc if present
    if [[ -f ".nvmrc" ]] && command -v nvm >/dev/null 2>&1; then
      echo "📦 Loading Node version from .nvmrc..."
      nvm use
    fi

    # Show project info
    if [[ -f "package.json" ]]; then
      local project_info=$(jq -r '.name + " v" + .version + " - " + (.description // "No description")' package.json 2>/dev/null)
      echo "ℹ️  $project_info"
    fi
  else
    echo "❌ Project not found: $1" >&2
    switch_project  # Show available projects
  fi
}

# Quick git workflow functions
feature() {
  local branch_name="$1"

  if [[ -z "$branch_name" ]]; then
    echo "❌ Error: Feature branch name is required" >&2
    echo "💡 Usage: feature <branch-name>" >&2
    return 1
  fi

  git checkout -b "feature/$branch_name"
}

hotfix() {
  local branch_name="$1"

  if [[ -z "$branch_name" ]]; then
    echo "❌ Error: Hotfix branch name is required" >&2
    echo "💡 Usage: hotfix <branch-name>" >&2
    return 1
  fi

  git checkout -b "hotfix/$branch_name"
}

# Clean up node_modules and reinstall
clean_install() {
  echo "🧹 Cleaning up node_modules and lock files..."

  rm -rf node_modules
  rm -f package-lock.json yarn.lock pnpm-lock.yaml

  # Auto-detect and use appropriate package manager
  if command -v pnpm >/dev/null 2>&1 && [[ -f "pnpm-workspace.yaml" || -f "pnpm-lock.yaml" ]]; then
    echo "📦 Installing with pnpm..."
    pnpm install
  elif command -v yarn >/dev/null 2>&1 && [[ -f "yarn.lock" ]]; then
    echo "📦 Installing with yarn..."
    yarn install
  else
    echo "📦 Installing with npm..."
    npm install
  fi
}

# Port finder and killer
port_kill() {
  local port="$1"

  if [[ -z "$port" ]]; then
    echo "❌ Error: Port number is required" >&2
    echo "💡 Usage: port_kill <port>" >&2
    return 1
  fi

  local pid=$(lsof -ti:$port)

  if [[ -n "$pid" ]]; then
    echo "🔍 Found process $pid on port $port"
    kill -9 $pid
    echo "✅ Killed process on port $port"
  else
    echo "ℹ️  No process found on port $port"
  fi
}

# Show what's running on common development ports
port_status() {
  local common_ports=(3000 3001 4200 5000 5173 8000 8080 9000)

  echo "🔍 Checking common development ports:"
  for port in "${common_ports[@]}"; do
    local pid=$(lsof -ti:$port 2>/dev/null)
    if [[ -n "$pid" ]]; then
      local cmd=$(ps -p $pid -o comm= 2>/dev/null)
      echo "  Port $port: ✅ $cmd (PID: $pid)"
    else
      echo "  Port $port: ⚪ Free"
    fi
  done
}

# Bundle analyzer for webpack/vite projects
analyze_bundle() {
  if [[ -f "package.json" ]]; then
    local has_webpack=$(jq -r '.devDependencies | has("webpack-bundle-analyzer")' package.json 2>/dev/null)
    local has_vite=$(jq -r '.devDependencies | has("vite")' package.json 2>/dev/null)

    if [[ "$has_webpack" == "true" ]]; then
      echo "📊 Running webpack bundle analyzer..."
      npm run build && npx webpack-bundle-analyzer build/static/js/*.js
    elif [[ "$has_vite" == "true" ]]; then
      echo "📊 Running vite bundle analyzer..."
      npx vite-bundle-analyzer
    else
      echo "❌ No supported bundle analyzer found" >&2
      echo "💡 Install: npm install --save-dev webpack-bundle-analyzer" >&2
    fi
  else
    echo "❌ No package.json found" >&2
  fi
}

# Test coverage shortcut
coverage() {
  local test_command=""

  if [[ -f "package.json" ]]; then
    # Try to find coverage script
    local coverage_script=$(jq -r '.scripts | to_entries[] | select(.value | contains("coverage")) | .key' package.json 2>/dev/null | head -1)

    if [[ -n "$coverage_script" ]]; then
      run_script "$coverage_script"
    else
      # Try common patterns
      if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
        echo "📊 Running tests with coverage..."
        run_script test --coverage
      else
        echo "❌ No test script found in package.json" >&2
      fi
    fi
  else
    echo "❌ No package.json found" >&2
  fi
}

# ===================================================================
# TLDR UTILITY FUNCTIONS
# ===================================================================

# Smart help function that tries tldr first, falls back to man
smart_help() {
  local cmd="$1"

  if [[ -z "$cmd" ]]; then
    echo "❌ Error: Command name is required" >&2
    echo "💡 Usage: smart_help <command>" >&2
    return 1
  fi

  # Try tldr first
  if command -v tldr >/dev/null 2>&1 && tldr "$cmd" 2>/dev/null; then
    return 0
  fi

  # Fall back to man page
  if command -v man >/dev/null 2>&1; then
    echo "📄 No tldr page found, showing man page for: $cmd"
    man "$cmd"
  else
    echo "❌ No help available for: $cmd" >&2
    return 1
  fi
}

# Get command examples for frontend tools
frontend_help() {
  local tool="${1:-}"

  if [[ -z "$tool" ]]; then
    echo "📚 Frontend Tool Help:"
    echo ""
    echo "Available tools with tldr pages:"
    local frontend_tools=("npm" "yarn" "pnpm" "git" "docker" "kubectl" "aws" "terraform" "webpack" "vite" "eslint" "prettier" "jest" "cypress")

    for tool in "${frontend_tools[@]}"; do
      if tldr --list 2>/dev/null | grep -q "^$tool$"; then
        echo "  ✅ $tool"
      else
        echo "  ❌ $tool (no tldr page)"
      fi
    done

    echo ""
    echo "💡 Usage: frontend_help <tool_name>"
    echo "💡 Example: frontend_help npm"
    return 0
  fi

  smart_help "$tool"
}

# Show random programming tip
random_tip() {
  if command -v tldr >/dev/null 2>&1; then
    echo "💡 Random Command Tip:"
    tldr --random
  else
    echo "❌ tldr not available" >&2
  fi
}

tree() {
  if command -v tree >/dev/null 2>&1; then
    command tree -L 6 -a -I 'node_modules|.git|.DS_Store|.vscode|.next'
  else
    echo "❌ tree not available" >&2
  fi
}

# Enhanced tree function with customizable ignore patterns
# Remove any existing alias to prevent conflicts
unalias get-tree 2>/dev/null
unalias get_tree 2>/dev/null

get_tree() {
  if ! command -v tree >/dev/null 2>&1; then
    echo "❌ tree not available" >&2
    return 1
  fi

  # Default ignore patterns
  local default_ignore='node_modules|.git|.DS_Store|.vscode|.next'
  local additional_ignore=""
  local other_args=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -I|--ignore)
        if [[ -n "$2" ]] && [[ "$2" != -* ]]; then
          additional_ignore="$2"
          shift 2
        else
          echo "❌ Error: -I requires a pattern argument" >&2
          echo "💡 Usage: get_tree [-I 'pattern1|pattern2'] [other tree options]" >&2
          return 1
        fi
        ;;
      *)
        other_args+=("$1")
        shift
        ;;
    esac
  done

  # Combine ignore patterns
  local final_ignore="$default_ignore"
  if [[ -n "$additional_ignore" ]]; then
    # Clean up the additional patterns (remove quotes and ./ prefixes)
    additional_ignore="${additional_ignore#\'}"  # Remove leading quote
    additional_ignore="${additional_ignore%\'}"  # Remove trailing quote
    additional_ignore="${additional_ignore//.\//}"  # Remove ./ prefixes

    final_ignore="$default_ignore|$additional_ignore"
  fi

  # Run tree with combined patterns
  command tree -L 8 -a -I "$final_ignore" "${other_args[@]}"
}

# Create an alias for the hyphenated version if preferred
alias get-tree='get_tree'

# ===================================================================
# CLIPBOARD UTILITIES
# ===================================================================

# Copy command output to clipboard with preview
copy_output() {
  if [[ $# -eq 0 ]]; then
    echo "❌ Error: Command is required" >&2
    echo "💡 Usage: copy_output <command> [args...]" >&2
    echo "💡 Example: copy_output ls -la" >&2
    echo "💡 Example: copy_output git status" >&2
    echo "💡 Example: copy_output get-tree -I 'pattern1|pattern2'" >&2
    return 1
  fi

  # Check if pbcopy is available (macOS)
  if ! command -v pbcopy >/dev/null 2>&1; then
    echo "❌ Error: pbcopy not available (macOS clipboard utility required)" >&2
    return 1
  fi

  local full_command="$*"
  echo "🔄 Executing: $full_command"

  # Capture command output with error handling
  local output
  local exit_code

  # Use eval with proper quoting to handle aliases and preserve arguments
  # Build command with proper escaping for each argument
  local escaped_cmd=""
  for arg in "$@"; do
    # Escape the argument properly for eval
    local escaped_arg=$(printf '%q' "$arg")
    if [[ -z "$escaped_cmd" ]]; then
      escaped_cmd="$escaped_arg"
    else
      escaped_cmd="$escaped_cmd $escaped_arg"
    fi
  done

  # Execute command with alias expansion and proper argument preservation
  if output=$(eval "$escaped_cmd" 2>&1); then
    exit_code=0
  else
    exit_code=$?
  fi

  # Handle command execution errors
  if [[ $exit_code -ne 0 ]]; then
    echo "❌ Command failed with exit code: $exit_code" >&2
    echo "📋 Error output:" >&2
    echo "$output" >&2
    echo ""
    echo "❓ Copy error output to clipboard anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "❌ Operation cancelled" >&2
      return $exit_code
    fi
  fi

  # Check if output is empty
  if [[ -z "$output" ]]; then
    echo "⚠️  Warning: Command produced no output" >&2
    echo "❓ Copy empty result to clipboard? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "❌ Operation cancelled" >&2
      return 1
    fi
  fi

  # Copy to clipboard
  if echo "$output" | pbcopy; then
    echo "✅ Output copied to clipboard successfully!" >&2

    # Show preview with smart truncation
    local preview_lines=10
    local line_count=$(echo "$output" | wc -l | tr -d ' ')

    echo "" >&2
    echo "📋 Copied content preview:" >&2
    echo "$(printf '─%.0s' {1..50})" >&2

    if [[ $line_count -le $preview_lines ]]; then
      # Show all lines if not too many
      echo "$output" >&2
    else
      # Show first few lines with truncation notice
      echo "$output" | head -n $preview_lines >&2
      echo "..." >&2
      echo "📏 Total: $line_count lines (showing first $preview_lines)" >&2
    fi

    echo "$(printf '─%.0s' {1..50})" >&2

    # Show helpful statistics
    local char_count=$(echo "$output" | wc -c | tr -d ' ')
    local word_count=$(echo "$output" | wc -w | tr -d ' ')
    echo "📊 Stats: $line_count lines, $word_count words, $char_count characters" >&2

  else
    echo "❌ Failed to copy to clipboard" >&2
    return 1
  fi

  return $exit_code
}

# Copy output without preview (silent mode)
copy_silent() {
  if [[ $# -eq 0 ]]; then
    echo "❌ Error: Command is required" >&2
    echo "💡 Usage: copy_silent <command> [args...]" >&2
    return 1
  fi

  if ! command -v pbcopy >/dev/null 2>&1; then
    echo "❌ Error: pbcopy not available" >&2
    return 1
  fi

  local output

  # Build properly escaped command for eval
  local escaped_cmd=""
  for arg in "$@"; do
    local escaped_arg=$(printf '%q' "$arg")
    if [[ -z "$escaped_cmd" ]]; then
      escaped_cmd="$escaped_arg"
    else
      escaped_cmd="$escaped_cmd $escaped_arg"
    fi
  done

  if output=$(eval "$escaped_cmd" 2>&1); then
    echo "$output" | pbcopy && echo "✅ Copied to clipboard" >&2
  else
    local exit_code=$?
    echo "❌ Command failed" >&2
    return $exit_code
  fi
}

# Copy current working directory path
copy_pwd() {
  if ! command -v pbcopy >/dev/null 2>&1; then
    echo "❌ Error: pbcopy not available" >&2
    return 1
  fi

  local current_path=$(pwd)
  echo "$current_path" | pbcopy
  echo "✅ Current directory path copied to clipboard:" >&2
  echo "📁 $current_path" >&2
}

# Copy file contents to clipboard
copy_file() {
  if [[ $# -eq 0 ]]; then
    echo "❌ Error: File path is required" >&2
    echo "💡 Usage: copy_file <file_path>" >&2
    return 1
  fi

  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    echo "❌ Error: File not found: $file_path" >&2
    return 1
  fi

  if [[ ! -r "$file_path" ]]; then
    echo "❌ Error: Cannot read file: $file_path" >&2
    return 1
  fi

  if ! command -v pbcopy >/dev/null 2>&1; then
    echo "❌ Error: pbcopy not available" >&2
    return 1
  fi

  # Get file size for large file warning
  local file_size=$(wc -c < "$file_path" 2>/dev/null || echo 0)
  local size_mb=$((file_size / 1024 / 1024))

  if [[ $size_mb -gt 10 ]]; then
    echo "⚠️  Warning: File is ${size_mb}MB. This might be too large for clipboard." >&2
    echo "❓ Continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "❌ Operation cancelled" >&2
      return 1
    fi
  fi

  if cat "$file_path" | pbcopy; then
    local line_count=$(wc -l < "$file_path" 2>/dev/null || echo 0)
    echo "✅ File copied to clipboard: $file_path" >&2
    echo "📊 Stats: $line_count lines, $file_size bytes" >&2
  else
    echo "❌ Failed to copy file to clipboard" >&2
    return 1
  fi
}

# ===================================================================
# INTERACTIVE TREE EXPLORER
# ===================================================================

# Helper function to generate navigation list for current directory
generate_nav_list() {
  local nav_dir="$1"
  local start_dir="$2"
  local show_files="$3"

  # Add parent directory option (except at start directory)
  if [[ "$nav_dir" != "$start_dir" ]]; then
    echo "📁 .."
  fi

  # Much simpler approach - avoid pipes which might be causing issues
  local temp_items=()

  # Get all items first
  for item in "$nav_dir"/*; do
    # Check if glob didn't match anything
    [[ ! -e "$item" ]] && continue

    local basename_item=$(basename "$item")

    # Skip common excludes
    case "$basename_item" in
      .*|node_modules|dist|build|coverage|.git|.DS_Store) continue ;;
    esac

    if [[ -d "$item" ]]; then
      temp_items+=("📁 $basename_item")
    elif [[ "$show_files" == "true" ]] && [[ -f "$item" ]]; then
      # Add file type icon
      local file_icon="📄"
      case "${basename_item##*.}" in
        js|jsx|ts|tsx) file_icon="⚡" ;;
        json) file_icon="📋" ;;
        md|markdown) file_icon="📝" ;;
        css|scss|sass|less) file_icon="🎨" ;;
        html|htm) file_icon="🌐" ;;
        png|jpg|jpeg|gif|svg|webp) file_icon="🖼️" ;;
        py) file_icon="🐍" ;;
        sh|bash|zsh) file_icon="⚡" ;;
        *) file_icon="📄" ;;
      esac
      temp_items+=("$file_icon $basename_item")
    elif [[ -L "$item" ]]; then
      temp_items+=("🔗 $basename_item")
    fi
  done

  # Sort and output
  for item in "${temp_items[@]}"; do
    echo "$item"
  done | sort
}

# Helper function to preview items
preview_item() {
  local item="$1"
  local current_dir="$2"

  # Clean the item name (remove icons)
  local clean_item=$(echo "$item" | sed 's/^[📁📄⚡🔗🎨🌐🖼️🐍📝📋] *//')

  if [[ "$clean_item" == ".." ]]; then
    echo "📁 Parent Directory"
    echo "⬅️  Use left arrow or select and press right arrow to go up"
    return
  fi

  local full_path="$current_dir/$clean_item"

  echo "📁 Preview: $clean_item"
  echo "📍 Path: $full_path"
  echo ""

  if [[ -d "$full_path" ]]; then
    echo "📁 Directory Contents:"
    ls -la "$full_path" 2>/dev/null | head -15 || echo "❌ Cannot access directory"
  elif [[ -f "$full_path" ]]; then
    echo "📄 File Contents:"
    local file_size=$(wc -c < "$full_path" 2>/dev/null || echo 0)
    echo "📏 Size: $file_size bytes"
    echo ""
    head -20 "$full_path" 2>/dev/null || echo "❌ Cannot read file"
  elif [[ -L "$full_path" ]]; then
    echo "🔗 Symlink Target:"
    ls -la "$full_path" 2>/dev/null || echo "❌ Broken symlink"
  else
    echo "❓ Unknown item type"
  fi
}

# Helper function to generate selective tree from selected items
generate_selective_tree() {
  local selected_file="$1"
  local base_dir="$2"
  local show_files="$3"

  if [[ ! -f "$selected_file" ]] || [[ ! -s "$selected_file" ]]; then
    echo "❌ No selected items found" >&2
    return 1
  fi

  # Start with root directory
  local current_dir_name=$(basename "$base_dir")
  local output="📁 $current_dir_name/"

  # Read selected items and generate simple tree
  while IFS= read -r item; do
    # Skip empty lines
    [[ -z "$item" ]] && continue

    # Clean item name (remove icons)
    local clean_item=$(echo "$item" | sed 's/^[📁📄⚡🔗🎨🌐🖼️🐍📝📋] *//')

    # Build full path
    local full_path="$base_dir/$clean_item"

    # Check if item exists
    if [[ ! -e "$full_path" ]]; then
      continue
    fi

    # Simple tree structure
    if [[ -d "$full_path" ]]; then
      output="$output\n├── 📁 $clean_item/"
    elif [[ -f "$full_path" ]] && [[ "$show_files" == "true" ]]; then
      # Add file type icon
      local file_icon="📄"
      case "${clean_item##*.}" in
        js|jsx|ts|tsx) file_icon="⚡" ;;
        json) file_icon="📋" ;;
        md|markdown) file_icon="📝" ;;
        css|scss|sass|less) file_icon="🎨" ;;
        html|htm) file_icon="🌐" ;;
        png|jpg|jpeg|gif|svg|webp) file_icon="🖼️" ;;
        py) file_icon="🐍" ;;
        sh|bash|zsh) file_icon="⚡" ;;
        *) file_icon="📄" ;;
      esac
      output="$output\n├── $file_icon $clean_item"
    elif [[ -L "$full_path" ]]; then
      local link_target=$(readlink "$full_path" 2>/dev/null || echo "broken")
      output="$output\n├── 🔗 $clean_item -> $link_target"
    fi
  done < "$selected_file"

  # Convert \n to actual newlines
  echo -e "$output"
}

# Interactive tree explorer with FZF-based selection
interactive_tree() {
  local depth=6
  local show_files=true
  local current_dir="$(pwd)"

  # Check dependencies
  if ! command -v fzf >/dev/null 2>&1; then
    echo "❌ Error: fzf is required for interactive tree" >&2
    echo "💡 Install with: brew install fzf" >&2
    return 1
  fi

  if ! command -v tree >/dev/null 2>&1; then
    echo "❌ Error: tree is required" >&2
    echo "💡 Install with: brew install tree" >&2
    return 1
  fi

  echo "🌲 Interactive Tree Explorer"
  echo "📁 Current directory: $current_dir"
  echo ""

  # Step 1: Choose what to show
  local content_type
  content_type=$(printf "📁 Folders only\n📄 Folders and files" | \
    fzf --prompt="Select content type: " \
        --height=10 \
        --header="Choose what to display in the tree" \
        --no-multi)

  if [[ -z "$content_type" ]]; then
    echo "❌ Operation cancelled" >&2
    return 1
  fi

  if [[ "$content_type" == "📁 Folders only" ]]; then
    show_files=false
    echo "✅ Selected: Folders only"
  else
    show_files=true
    echo "✅ Selected: Folders and files"
  fi

  # Step 2: Get depth
  echo ""
  echo "🔢 Enter tree depth (default: 6, max: 10):"
  read -r user_depth

  if [[ -n "$user_depth" ]] && [[ "$user_depth" =~ ^[0-9]+$ ]] && [[ "$user_depth" -le 10 ]]; then
    depth="$user_depth"
  fi

  echo "✅ Using depth: $depth"

      # Step 3: Interactive navigation and selection
  echo ""
  echo "🔄 Starting interactive navigation..."

  local temp_list="/tmp/itree_list_$$.txt"
  local selected_file="/tmp/itree_selected_$$.txt"
  local current_nav_dir="$current_dir"
  local selected_items=()

  # Create temp files
  if ! touch "$temp_list" 2>/dev/null; then
    temp_list="./itree_list_$$.txt"
    if ! touch "$temp_list" 2>/dev/null; then
      echo "❌ Failed to create temp file anywhere" >&2
      return 1
    fi
  fi

  # Initialize selected items file
  if [[ -f "$selected_file" ]]; then
    rm -f "$selected_file"
  fi

  if ! touch "$selected_file" 2>/dev/null; then
    selected_file="/tmp/itree_selected_alt_$$.txt"
    if ! touch "$selected_file" 2>/dev/null; then
      selected_file="./itree_selected_$$.txt"
      if ! touch "$selected_file" 2>/dev/null; then
        echo "❌ Failed to create file anywhere" >&2
        return 1
      fi
    fi
  fi

  # Interactive navigation loop
  while true; do
    # Generate current directory listing
    echo "🔄 Scanning: $current_nav_dir"

    # Check if directory exists and is accessible
    if [[ ! -d "$current_nav_dir" ]]; then
      echo "❌ Directory does not exist: $current_nav_dir"
      break
    fi

    if [[ ! -r "$current_nav_dir" ]]; then
      echo "❌ Cannot read directory: $current_nav_dir"
      break
    fi

    # Call generate_nav_list directly
    generate_nav_list "$current_nav_dir" "$current_dir" "$show_files" > "$temp_list"

    # Check if we have any items to show
    if [[ ! -s "$temp_list" ]]; then
      echo "⚠️  No items found in current directory"
      echo "📁 Contents of $current_nav_dir:"
      ls -la "$current_nav_dir" 2>/dev/null || echo "❌ Cannot access directory"
      echo ""
      echo "Press Enter to continue or Ctrl+C to exit..."
      read -r
      continue
    fi

    # Calculate relative path for display
    local relative_path=""
    if [[ "$current_nav_dir" != "$current_dir" ]]; then
      relative_path="/${current_nav_dir#$current_dir/}"
    else
      relative_path="/"
    fi

    echo "🎯 Navigate: $relative_path"
    echo "📍 Current selections: $(wc -l < "$selected_file" | tr -d ' ') items"
    echo "📋 Available items: $(wc -l < "$temp_list" | tr -d ' ')"

    # Show FZF with navigation
    local fzf_result
    local exit_code

    fzf_result=$(cat "$temp_list" | fzf --multi \
         --prompt="Navigate ($relative_path): " \
         --header="Space: select, Enter: confirm, q: quit" \
         --preview="echo 'Preview: {}'; echo 'Path: $current_nav_dir/{}'" \
         --preview-window="right:50%" \
         --height=80% \
         --bind="space:toggle+down" \
         --bind="tab:toggle" \
         --bind="q:abort" \
         --bind="ctrl-c:abort" 2>/dev/null)

    exit_code=$?

    # Handle FZF result
    if [[ $exit_code -eq 130 ]] || [[ $exit_code -eq 1 ]]; then
      # User cancelled (Ctrl+C or q)
      echo "❌ Navigation cancelled" >&2
      rm -f "$temp_list" "$selected_file"
      return 1
    elif [[ $exit_code -eq 0 ]]; then
      # Success - process selected items
      if [[ -n "$fzf_result" ]]; then
        # Add selected items to our collection
        while IFS= read -r item; do
          [[ -z "$item" ]] && continue
          local clean_item=$(echo "$item" | sed 's/^[📁📄⚡🔗🎨🌐🖼️🐍📝📋] *//')
          if [[ "$clean_item" != ".." ]]; then
            local rel_path=""
            if [[ "$current_nav_dir" != "$current_dir" ]]; then
              rel_path="${current_nav_dir#$current_dir/}/$clean_item"
            else
              rel_path="$clean_item"
            fi
            echo "$rel_path" >> "$selected_file"
          fi
        done <<< "$fzf_result"

        echo "✅ Added $(echo "$fzf_result" | wc -l | tr -d ' ') items to selection"
      fi

      # For now, just exit after one selection - we'll enhance this
      break
    else
      echo "❌ FZF error (exit code: $exit_code)" >&2
      rm -f "$temp_list" "$selected_file"
      return 1
    fi

      done

  # Remove duplicates from selected file
  if [[ -s "$selected_file" ]]; then
    sort -u "$selected_file" > "${selected_file}.tmp" && mv "${selected_file}.tmp" "$selected_file"
  fi

  # Check if anything was selected
  if [[ ! -s "$selected_file" ]]; then
    echo "⚠️  No items selected" >&2
    rm -f "$temp_list" "$selected_file"
    return 1
  fi

      # Step 5: Show selection summary
  echo ""
  echo "🎯 Selection Summary:"
  local selected_count=$(wc -l < "$selected_file")
  local dir_count=0
  local file_count=0

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    local full_path="$current_dir/$item"
    if [[ "$item" == "." ]]; then
      full_path="$current_dir"
    fi

    if [[ -d "$full_path" ]]; then
      ((dir_count++))
    else
      ((file_count++))
    fi
  done < "$selected_file"

  echo "  📁 Directories: $dir_count"
  echo "  📄 Files: $file_count"
  echo "  📊 Total: $selected_count items"

  # Step 6: Generate selective tree with only selected items
  echo ""
  echo "🌲 Generating selective tree..."

  # Build custom tree representation from selected items
  local output
  output=$(generate_selective_tree "$selected_file" "$current_dir" "$show_files")

  if [[ -n "$output" ]]; then
    echo ""
    echo "📋 Selective Tree Structure:"
    echo "$(printf '═%.0s' {1..60})"
    echo "$output"
    echo "$(printf '═%.0s' {1..60})"

    # Copy to clipboard with enhanced output
    local clipboard_content="# Selective Tree Structure\n# Generated by interactive_tree\n# Directory: $current_dir\n# Date: $(date)\n\n$output"
    echo -e "$clipboard_content" | pbcopy
    echo "✅ Selective tree copied to clipboard with metadata!"

    # Show statistics
    local line_count=$(echo "$output" | wc -l | tr -d ' ')
    local char_count=$(echo "$output" | wc -c | tr -d ' ')
    local word_count=$(echo "$output" | wc -w | tr -d ' ')
    echo "📊 Output Stats: $line_count lines, $word_count words, $char_count characters"

    # Optional: Ask if user wants to save to file
    echo ""
    echo "💾 Save tree to file? (y/N)"
    read -r -t 5 save_response
    if [[ "$save_response" =~ ^[Yy]$ ]]; then
      local filename="selective_tree_$(date +%Y%m%d_%H%M%S).txt"
      echo -e "$clipboard_content" > "$filename"
      echo "✅ Tree saved to: $filename"
    fi

  else
    echo "❌ Failed to generate selective tree" >&2
  fi

  # Cleanup
  rm -f "$temp_list" "$selected_file"
}

# Alias for convenience
alias itree="interactive_tree"

# Simple test function to debug the hanging issue
test_itree() {
  echo "🔧 Test: Starting test_itree"

  local current_dir="$(pwd)"
  echo "🔧 Test: current_dir=$current_dir"

  local temp_list="/tmp/test_itree_$$.txt"
  echo "🔧 Test: temp_list=$temp_list"

  echo "🔧 Test: Creating temp file..."
  if ! > "$temp_list"; then
    echo "❌ Test: Failed to create temp file"
    return 1
  fi
  echo "🔧 Test: Temp file created"

  echo "🔧 Test: Testing basic ls..."
  ls -1 "$current_dir" | head -5
  echo "🔧 Test: Basic ls completed"

  echo "🔧 Test: Testing directory loop..."
  local count=0
  for item in "$current_dir"/*; do
    [[ ! -e "$item" ]] && continue
    echo "🔧 Test: Found item: $(basename "$item")"
    ((count++))
    [[ $count -ge 3 ]] && break
  done
  echo "🔧 Test: Directory loop completed"

  echo "🔧 Test: Testing FZF..."
  echo -e "📁 test1\n📄 test2\n📁 test3" > "$temp_list"

  if command -v fzf >/dev/null 2>&1; then
    echo "🔧 Test: FZF is available"
    # Test FZF with simple input
    local result
    result=$(echo -e "option1\noption2\noption3" | fzf --prompt="Test: " --height=10 --header="Test FZF" 2>/dev/null || echo "cancelled")
    echo "🔧 Test: FZF result: $result"
  else
    echo "❌ Test: FZF not available"
  fi

  echo "🔧 Test: Cleaning up..."
  rm -f "$temp_list"

  echo "✅ Test: test_itree completed successfully"
}
