#!/bin/zsh

# Only show load message in debug mode
[[ -n "$ZSH_DEBUG" ]] && echo "zsh.config/performance loaded"

# ===================================================================
# ZSH PERFORMANCE OPTIMIZATIONS
# ===================================================================

# ===================================================================
# HISTORY SETTINGS
# ===================================================================
# Optimize history for better performance and functionality

# History file settings
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000                    # Memory history size
SAVEHIST=50000                    # File history size

# History options for performance and functionality
setopt APPEND_HISTORY             # Append to history file
setopt SHARE_HISTORY             # Share history between sessions
setopt HIST_IGNORE_DUPS          # Don't record duplicates
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicates
setopt HIST_IGNORE_SPACE         # Don't record commands starting with space
setopt HIST_REDUCE_BLANKS        # Remove extra blanks
setopt HIST_VERIFY               # Show command before executing from history
setopt EXTENDED_HISTORY          # Save timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first when trimming

# ===================================================================
# COMPLETION SYSTEM OPTIMIZATION
# ===================================================================

# Completion caching for better performance
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"

# Create cache directory if it doesn't exist
[[ ! -d "$HOME/.zsh/cache" ]] && mkdir -p "$HOME/.zsh/cache"

# Faster completion matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Group completions by type
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'

# Completion colors
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Don't complete backup files as executables
zstyle ':completion:*:complete:-command-::commands' ignored-patterns '*\~'

# Completion performance improvements
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' squeeze-slashes true

# ===================================================================
# LAZY LOADING FOR PERFORMANCE
# ===================================================================

# Lazy load NVM (significant startup time improvement)
lazy_load_nvm() {
  # Validate NVM_DIR
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"

  if [[ ! -d "$nvm_dir" ]]; then
    echo "❌ Error: NVM directory not found: $nvm_dir" >&2
    echo "💡 Install NVM: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash" >&2
    return 1
  fi

  # Safely unset wrapper functions
  for func in nvm node npm npx; do
    if typeset -f "$func" >/dev/null; then
      unset -f "$func" 2>/dev/null || true
    fi
  done

  export NVM_DIR="$nvm_dir"

  # Load NVM with error handling
  local nvm_script="$NVM_DIR/nvm.sh"
  local nvm_completion="$NVM_DIR/bash_completion"

  if [[ -s "$nvm_script" ]]; then
    if ! source "$nvm_script"; then
      echo "❌ Error: Failed to load NVM script: $nvm_script" >&2
      return 1
    fi
  else
    echo "❌ Error: NVM script not found: $nvm_script" >&2
    return 1
  fi

  # Load completion (optional, don't fail if missing)
  if [[ -s "$nvm_completion" ]]; then
    source "$nvm_completion" 2>/dev/null || echo "⚠️  Warning: Failed to load NVM completion" >&2
  fi

  return 0
}

# Create wrapper functions for nvm-related commands with enhanced error handling
nvm() {
  if ! lazy_load_nvm; then
    echo "❌ Error: Failed to load NVM" >&2
    return 1
  fi

  # After loading, check for .nvmrc in current directory
  load_nvmrc_optimized

  # Ensure nvm command is available after loading
  if ! command -v nvm >/dev/null 2>&1; then
    echo "❌ Error: NVM command not available after loading" >&2
    return 1
  fi

  nvm "$@"
}

node() {
  if ! lazy_load_nvm; then
    echo "❌ Error: Failed to load NVM for node" >&2
    return 1
  fi

  if ! command -v node >/dev/null 2>&1; then
    echo "❌ Error: Node.js not available. Install with: nvm install node" >&2
    return 1
  fi

  node "$@"
}

npm() {
  if ! lazy_load_nvm; then
    echo "❌ Error: Failed to load NVM for npm" >&2
    return 1
  fi

  if ! command -v npm >/dev/null 2>&1; then
    echo "❌ Error: npm not available. Install Node.js first: nvm install node" >&2
    return 1
  fi

  npm "$@"
}

npx() {
  if ! lazy_load_nvm; then
    echo "❌ Error: Failed to load NVM for npx" >&2
    return 1
  fi

  if ! command -v npx >/dev/null 2>&1; then
    echo "❌ Error: npx not available. Install Node.js first: nvm install node" >&2
    return 1
  fi

  npx "$@"
}

# ===================================================================
# DIRECTORY NAVIGATION OPTIMIZATION
# ===================================================================

# Auto-change directory
setopt AUTO_CD

# Directory stack options
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Correct typos in directory names
setopt CORRECT

# ===================================================================
# GLOBBING AND EXPANSION
# ===================================================================

# Better globbing
setopt EXTENDED_GLOB
setopt GLOB_DOTS

# Don't beep on error
setopt NO_BEEP

# ===================================================================
# PROMPT OPTIMIZATION
# ===================================================================

# Disable VCS info for faster prompt (if not using git plugin)
# zstyle ':vcs_info:*' enable NONE

# ===================================================================
# ADVANCED PERFORMANCE OPTIMIZATIONS
# ===================================================================

# Startup time tracking
ZSH_STARTUP_START_TIME=$(date +%s.%N)

# PATH optimization - avoid duplicates
typeset -U path PATH

# Reduce fork() calls by using built-ins
setopt NO_BG_NICE          # Don't run background jobs at lower priority
setopt NO_HUP              # Don't send HUP signal to jobs on shell exit
setopt NO_LIST_BEEP        # No beep on ambiguous completion
setopt LOCAL_OPTIONS       # Allow functions to have local options
setopt LOCAL_TRAPS         # Allow functions to have local traps

# Memory optimization
setopt NO_MAIL_WARNING     # Don't check for mail
setopt NO_CHECK_JOBS       # Don't warn about running jobs on exit

# ===================================================================
# LAZY LOADING FOR HEAVY TOOLS
# ===================================================================

# Lazy load Google Cloud SDK (significant startup improvement)
lazy_load_gcloud() {
  local gcloud_dir="$HOME/google-cloud-sdk"
  local gcloud_path="$gcloud_dir/path.zsh.inc"
  local gcloud_completion="$gcloud_dir/completion.zsh.inc"

  # Validate Google Cloud SDK installation
  if [[ ! -d "$gcloud_dir" ]]; then
    echo "❌ Error: Google Cloud SDK not found in: $gcloud_dir" >&2
    echo "💡 Install: https://cloud.google.com/sdk/docs/install" >&2
    return 1
  fi

  # Safely unset wrapper functions
  for func in gcloud gsutil bq kubectl docker-credential-gcloud; do
    if typeset -f "$func" >/dev/null; then
      unset -f "$func" 2>/dev/null || true
    fi
  done

  # Load Google Cloud SDK path
  if [[ -f "$gcloud_path" ]]; then
    if ! source "$gcloud_path"; then
      echo "❌ Error: Failed to load Google Cloud SDK path: $gcloud_path" >&2
      return 1
    fi
  else
    echo "❌ Error: Google Cloud SDK path script not found: $gcloud_path" >&2
    return 1
  fi

  # Load completion (optional)
  if [[ -f "$gcloud_completion" ]]; then
    source "$gcloud_completion" 2>/dev/null || echo "⚠️  Warning: Failed to load Google Cloud SDK completion" >&2
  fi

  return 0
}

# Create wrapper functions for gcloud commands with enhanced error handling
gcloud() {
  if ! lazy_load_gcloud; then
    echo "❌ Error: Failed to load Google Cloud SDK for gcloud" >&2
    return 1
  fi

  if ! command -v gcloud >/dev/null 2>&1; then
    echo "❌ Error: gcloud command not available after loading SDK" >&2
    return 1
  fi

  gcloud "$@"
}

gsutil() {
  if ! lazy_load_gcloud; then
    echo "❌ Error: Failed to load Google Cloud SDK for gsutil" >&2
    return 1
  fi

  if ! command -v gsutil >/dev/null 2>&1; then
    echo "❌ Error: gsutil not available. Ensure Google Cloud SDK is properly installed" >&2
    return 1
  fi

  gsutil "$@"
}

bq() {
  if ! lazy_load_gcloud; then
    echo "❌ Error: Failed to load Google Cloud SDK for bq" >&2
    return 1
  fi

  if ! command -v bq >/dev/null 2>&1; then
    echo "❌ Error: bq not available. Ensure Google Cloud SDK is properly installed" >&2
    return 1
  fi

  bq "$@"
}

kubectl() {
  if ! lazy_load_gcloud; then
    echo "❌ Error: Failed to load Google Cloud SDK for kubectl" >&2
    return 1
  fi

  if ! command -v kubectl >/dev/null 2>&1; then
    echo "❌ Error: kubectl not available. Install with: gcloud components install kubectl" >&2
    return 1
  fi

  kubectl "$@"
}

# ===================================================================
# OPTIMIZED NVMRC AUTO-LOADING
# ===================================================================

# Optimized version with caching and error handling
load_nvmrc_optimized() {
  # Skip if nvm is not loaded yet (lazy loading)
  if ! command -v nvm >/dev/null 2>&1; then
    return 0
  fi

  # Skip if nvm_find_nvmrc function is not available (nvm not fully loaded)
  if ! command -v nvm_find_nvmrc >/dev/null 2>&1; then
    return 0
  fi

  local nvmrc_path="$(nvm_find_nvmrc 2>/dev/null)"
  local current_version="$(nvm current 2>/dev/null)"

  # Use cache to avoid repeated version checks
  local last_dir_file="/tmp/.nvmrc_last_dir_$$"

  # Check if we're in the same directory as last time
  if [[ -f "$last_dir_file" ]] && [[ "$(cat "$last_dir_file")" == "$PWD" ]]; then
    return 0
  fi

  echo "$PWD" > "$last_dir_file"

  if [[ -n "$nvmrc_path" ]]; then
    local nvmrc_version="$(cat "$nvmrc_path" 2>/dev/null)"
    if [[ -n "$nvmrc_version" ]]; then
      local resolved_version="$(nvm version "$nvmrc_version" 2>/dev/null)"

      if [[ "$resolved_version" == "N/A" ]]; then
        echo "📦 Installing Node.js version: $nvmrc_version"
        nvm install "$nvmrc_version" >/dev/null 2>&1
        nvm use "$nvmrc_version" >/dev/null 2>&1
      elif [[ "$resolved_version" != "$current_version" ]]; then
        echo "🔄 Switching to Node.js version: $resolved_version"
        nvm use "$nvmrc_version" >/dev/null 2>&1
      fi
    fi
  elif [[ -n "$current_version" ]] && [[ "$current_version" != "$(nvm version default 2>/dev/null)" ]]; then
    echo "🔙 Reverting to default Node.js version"
    nvm use default >/dev/null 2>&1
  fi
}

# ===================================================================
# DISK I/O OPTIMIZATION
# ===================================================================

# Reduce filesystem calls
DIRSTACKSIZE=10           # Limit directory stack size
setopt HIST_FCNTL_LOCK    # Use fcntl for history file locking (faster)

# Cache expensive operations
typeset -A _zsh_cache
_zsh_cache_timeout=300    # 5 minutes

# Cached which command
cached_which() {
  local cmd="$1"
  local cache_key="which_$cmd"
  local current_time=$(date +%s)

  if [[ -n "${_zsh_cache[$cache_key]}" ]]; then
    local cache_entry="${_zsh_cache[$cache_key]}"
    local cache_time="${cache_entry%% *}"
    local cache_value="${cache_entry#* }"

    if (( current_time - cache_time < _zsh_cache_timeout )); then
      echo "$cache_value"
      return 0
    fi
  fi

  local result="$(command which "$cmd" 2>/dev/null)"
  _zsh_cache[$cache_key]="$current_time $result"
  echo "$result"
}

# ===================================================================
# PROCESS AND MEMORY MONITORING
# ===================================================================

# Monitor zsh memory usage
zsh_memory_usage() {
  local pid=$$
  if command -v ps >/dev/null 2>&1; then
    ps -o pid,rss,vsz,pcpu,comm -p "$pid" | awk 'NR==2 {printf "PID: %s, RSS: %s KB, VSZ: %s KB, CPU: %s%%\n", $1, $2, $3, $4}'
  fi
}

# Show loaded functions and their sizes
zsh_function_sizes() {
  echo "📊 Loaded functions and their sizes:"
  functions | awk '/^[a-zA-Z_]/ {print $1}' | while read func; do
    local size=$(functions "$func" | wc -c)
    echo "  $func: ${size} bytes"
  done | sort -k2 -nr | head -20
}

# ===================================================================
# STARTUP TIME PROFILING
# ===================================================================

# Function to profile zsh startup time
zsh_profile() {
  echo "Profiling zsh startup time..."

  # Create temporary profile file
  local profile_file="/tmp/zsh_profile_$$"

  # Profile the startup
  time zsh -i -c exit 2>&1 | tee "$profile_file"

  echo ""
  echo "Full profile saved to: $profile_file"
  echo "To see detailed timing, run: zsh -xvs 2>&1 | ts -i | head -20"
}

# Function to benchmark specific commands
benchmark() {
  local cmd="$1"
  local iterations="${2:-10}"

  if [[ -z "$cmd" ]]; then
    echo "Usage: benchmark <command> [iterations]"
    return 1
  fi

  echo "Benchmarking: $cmd (${iterations} iterations)"

  local total=0
  for i in {1..$iterations}; do
    local start=$(date +%s.%N)
    eval "$cmd" >/dev/null 2>&1
    local end=$(date +%s.%N)
    local duration=$(echo "$end - $start" | bc -l)
    total=$(echo "$total + $duration" | bc -l)
    echo "Run $i: ${duration}s"
  done

  local average=$(echo "scale=4; $total / $iterations" | bc -l)
  echo "Average: ${average}s"
}

# ===================================================================
# PERFORMANCE MONITORING
# ===================================================================

# Show startup time if it takes too long
if [[ -n "$ZSH_STARTUP_TIME" ]]; then
  echo "⏱️  Zsh startup time: ${ZSH_STARTUP_TIME}ms"
  if (( ZSH_STARTUP_TIME > 1000 )); then
    echo "⚠️  Slow startup detected! Consider running 'zsh_profile' to investigate."
  fi
fi

# ===================================================================
# PERFORMANCE DIAGNOSTICS
# ===================================================================

# Comprehensive performance report
zsh_performance_report() {
  echo "🚀 Zsh Performance Report"
  echo "========================="
  echo ""

  # Startup time
  if [[ -n "$ZSH_STARTUP_START_TIME" ]]; then
    local current_time=$(date +%s.%N)
    local startup_time=$(echo "($current_time - $ZSH_STARTUP_START_TIME) * 1000" | bc -l)
    printf "⏱️  Current session startup time: %.2f ms\n" "$startup_time"
  fi

  # Memory usage
  echo "💾 Memory Usage:"
  zsh_memory_usage
  echo ""

  # Plugin status
  echo "🔌 Active Plugins:"
  if [[ -n "$plugins" ]]; then
    printf "  Oh My Zsh plugins: %s\n" "${(j:, :)plugins}"
  fi
  echo ""

  # Function count and sizes
  local func_count=$(functions | grep -c '^[a-zA-Z_]')
  echo "📝 Functions loaded: $func_count"
  echo ""

  # PATH analysis
  echo "🛤️  PATH entries: $(echo $PATH | tr ':' '\n' | wc -l)"
  echo ""

  # Cache status
  echo "🗄️  Cache status:"
  [[ -d "$HOME/.zsh/cache" ]] && echo "  Completion cache: ✅ $(ls -1 "$HOME/.zsh/cache" 2>/dev/null | wc -l) files"
  echo ""

  # Recommendations
  echo "💡 Performance Tips:"
  if (( startup_time > 500 )); then
    echo "  • Consider profiling with 'zsh-profile' to identify slow components"
  fi
  if (( func_count > 100 )); then
    echo "  • High function count detected - consider lazy loading more components"
  fi
  echo "  • Run 'zsh-benchmark' on commands you use frequently"
  echo "  • Use 'plugins' to check plugin status"
}

# Quick performance check
zsh_quick_check() {
  echo "🔍 Quick Performance Check:"

  # Test common operations
  local test_commands=(
    "ls >/dev/null"
    "pwd >/dev/null"
    "echo test >/dev/null"
    "which zsh >/dev/null"
  )

  for cmd in "${test_commands[@]}"; do
    local start=$(date +%s.%N)
    eval "$cmd"
    local end=$(date +%s.%N)
    local duration=$(echo "($end - $start) * 1000" | bc -l)
    printf "  %-20s: %.2f ms\n" "${cmd%% *}" "$duration"
  done
}

# Auto-cleanup temp files on exit
cleanup_performance_files() {
  rm -f /tmp/.nvmrc_last_dir_$$ 2>/dev/null
}

# Register cleanup function
trap cleanup_performance_files EXIT

# ===================================================================
# CONFIGURATION VALIDATION
# ===================================================================

# Validate zsh configuration for common issues
validate_zsh_config() {
  echo "🔧 Zsh Configuration Validation"
  echo "==============================="
  echo ""

  local issues_found=0

  # Check if NVM functions are working
  echo "🔍 Checking NVM setup..."
  if command -v nvm >/dev/null 2>&1; then
    echo "  ✅ NVM is available"
    if command -v nvm_find_nvmrc >/dev/null 2>&1; then
      echo "  ✅ NVM functions are loaded"
    else
      echo "  ⚠️  NVM functions not loaded (this is normal with lazy loading)"
    fi
  else
    echo "  ❌ NVM not found - run 'node --version' to trigger lazy loading"
    ((issues_found++))
  fi

  # Check Oh My Posh
  echo ""
  echo "🎨 Checking theme setup..."
  if command -v oh-my-posh >/dev/null 2>&1; then
    echo "  ✅ Oh My Posh is available"
    if [[ -f "$HOME/honukai.omp.json" ]]; then
      echo "  ✅ Custom theme file found"
    else
      echo "  ⚠️  Custom theme file not found, using fallback"
    fi
  else
    echo "  ❌ Oh My Posh not found - install with: brew install oh-my-posh"
    ((issues_found++))
  fi

  # Check plugins
  echo ""
  echo "🔌 Checking plugins..."
  local plugin_base="$ZSH/custom/plugins"
  local required_plugins=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-history-substring-search")

  for plugin in "${required_plugins[@]}"; do
    if [[ -d "$plugin_base/$plugin" ]]; then
      echo "  ✅ $plugin"
    else
      echo "  ❌ $plugin (missing - run 'plugins-install')"
      ((issues_found++))
    fi
  done

  # Check Google Cloud SDK
  echo ""
  echo "☁️  Checking Google Cloud SDK..."
  if [[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]]; then
    echo "  ✅ Google Cloud SDK found (lazy loaded)"
  else
    echo "  ⚠️  Google Cloud SDK not found"
  fi

  # Check performance optimizations
  echo ""
  echo "⚡ Checking performance optimizations..."
  if [[ -d "$HOME/.zsh/cache" ]]; then
    echo "  ✅ Completion cache directory exists"
  else
    echo "  ⚠️  Completion cache directory missing (will be created)"
  fi

  # Summary
  echo ""
  echo "📊 Summary:"
  if (( issues_found == 0 )); then
    echo "  🎉 No critical issues found!"
    echo "  💡 Run 'zsh-report' for detailed performance analysis"
  else
    echo "  ⚠️  Found $issues_found issue(s) that should be addressed"
    echo "  💡 Run the suggested commands to fix them"
  fi
}

# ===================================================================
# STARTUP TIME COMPLETION
# ===================================================================

# Calculate and store final startup time
if [[ -n "$ZSH_STARTUP_START_TIME" ]]; then
  ZSH_STARTUP_END_TIME=$(date +%s.%N)
  ZSH_STARTUP_DURATION=$(echo "($ZSH_STARTUP_END_TIME - $ZSH_STARTUP_START_TIME) * 1000" | bc -l 2>/dev/null || echo "0")

  # Only show if startup is slow or if DEBUG is enabled
  if [[ -n "$ZSH_DEBUG" ]] || (( ${ZSH_STARTUP_DURATION%.*} > 800 )); then
    printf "⚡ Zsh loaded in %.2f ms\n" "$ZSH_STARTUP_DURATION"
  fi

  # Store for future reference
  echo "$ZSH_STARTUP_DURATION" > "/tmp/.zsh_last_startup_time"
fi
