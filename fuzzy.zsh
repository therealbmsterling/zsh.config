#!/bin/zsh

# Only show load message in debug mode
[[ -n "$ZSH_DEBUG" ]] && echo "zsh.config/fuzzy loaded"

# ===================================================================
# FZF + FD + BAT CONFIGURATION
# ===================================================================

# ===================================================================
# BASIC TOOL SETUP
# ===================================================================

# Load fzf shell integration if available
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

# ===================================================================
# FZF CONFIGURATION
# ===================================================================

# Use fd as the default source for fzf (respects .gitignore)
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# Enhanced fzf options with better UI and preview
export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border
  --info=inline
  --prompt='🔍 '
  --pointer='▶'
  --marker='✓'
  --color=fg:#908caa,bg:#232136,hl:#ea9a97
  --color=fg+:#e0def4,bg+:#393552,hl+:#ea9a97
  --color=border:#44415a,header:#3e8fb0,gutter:#232136
  --color=spinner:#f6c177,info:#9ccfd8,separator:#44415a
  --color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa
"

# File preview with bat
if command -v bat >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS="
    --preview 'bat --style=numbers --color=always --line-range :500 {}'
    --preview-window=right:50%:wrap
  "
fi

# Directory preview with tree or ls
export FZF_ALT_C_OPTS="
  --preview 'tree -C {} | head -100'
  --preview-window=right:50%:wrap
"

# ===================================================================
# BAT CONFIGURATION
# ===================================================================

# Configure bat for optimal display
export BAT_THEME="Coldark-Dark"
export BAT_STYLE="numbers,changes,header,grid"
export BAT_PAGER="less -FR"

# ===================================================================
# FRONTEND-SPECIFIC FZF FUNCTIONS
# ===================================================================

# Fuzzy find and edit files
fe() {
  local files
  IFS=$'\n' files=($(fzf --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && ${EDITOR:-code} "${files[@]}"
}

# Fuzzy find and cd to directory
fcd() {
  local query="$1"
  local base_dir="${2:-.}"  # Default to current directory
  local dir

  # If a specific directory is provided as argument and it exists, cd directly
  if [[ -n "$query" ]] && [[ -d "$query" ]]; then
    cd "$query"
    return $?
  fi

  # Build fd command with optional query filter
  local fd_cmd="fd --type d"

  # Add search pattern if query provided
  if [[ -n "$query" ]]; then
    fd_cmd="$fd_cmd '$query'"
  fi

  # Add base directory
  fd_cmd="$fd_cmd . '$base_dir'"

  # Execute fd command and pipe to fzf with enhanced options
  local fzf_opts="--height 60% --layout=reverse --border"

  # If query provided, use it as initial query in fzf
  if [[ -n "$query" ]]; then
    fzf_opts="$fzf_opts --query='$query'"
  fi

  # Add preview for directories
  fzf_opts="$fzf_opts --preview='tree -C -L 2 {} 2>/dev/null || ls -la {}'"
  fzf_opts="$fzf_opts --preview-window=right:50%:wrap"

  # Execute the search
  dir=$(eval "$fd_cmd" | fzf $fzf_opts)

  # Change directory if selection was made
  if [[ -n "$dir" ]]; then
    cd "$dir"
  else
    echo "📁 No directory selected"
    return 1
  fi
}

# Fuzzy find in project files (respecting .gitignore)
fif() {
  if [ ! "$#" -gt 0 ]; then
    echo "Need a string to search for!"
    return 1
  fi

  local file
  file=$(rg --files-with-matches --no-messages "$1" | fzf --preview "rg --ignore-case --pretty --context 10 '$1' {}" --preview-window=right:50%:wrap) && ${EDITOR:-code} "$file"
}

# Fuzzy search git files
fgf() {
  local files
  files=$(git ls-files | fzf --multi --preview 'bat --style=numbers --color=always {}' --preview-window=right:50%:wrap)
  [[ -n "$files" ]] && ${EDITOR:-code} $(echo "$files")
}

# Fuzzy search modified git files
fgm() {
  local files
  files=$(git diff --name-only | fzf --multi --preview 'git diff --color=always {}' --preview-window=right:50%:wrap)
  [[ -n "$files" ]] && ${EDITOR:-code} $(echo "$files")
}

# Fuzzy switch git branches
fgb() {
  local branches branch
  branches=$(git branch -a | grep -v HEAD) &&
  branch=$(echo "$branches" | fzf +s +m -e) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# Fuzzy search npm scripts
fnpm() {
  if [[ ! -f "package.json" ]]; then
    echo "❌ No package.json found in current directory"
    return 1
  fi

  local script
  script=$(jq -r '.scripts | keys[]' package.json | fzf --prompt="npm script> " --preview="jq -r '.scripts.{}' package.json")

  if [[ -n "$script" ]]; then
    echo "🏃 Running npm script: $script"
    npm run "$script"
  fi
}

# Fuzzy search and kill processes
fkill() {
  local pid
  if [ "$UID" != "0" ]; then
    pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
  else
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  fi

  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -${1:-9}
  fi
}

# Fuzzy search command history
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}

# Enhanced history menu with better UI and options
fhistory() {
  local cmd
  cmd=$(history | fzf \
    --height 50% \
    --layout=reverse \
    --border \
    --tac \
    --prompt="Command History> " \
    --header="Enter: Execute | Ctrl-Y: Copy | Ctrl-E: Edit | Esc: Cancel" \
    --bind="ctrl-y:execute(echo {} | sed 's/^[ ]*[0-9]*[ ]*//' | pbcopy)+abort" \
    --bind="ctrl-e:execute(echo {} | sed 's/^[ ]*[0-9]*[ ]*//' > /tmp/cmd.tmp && \${EDITOR:-code} /tmp/cmd.tmp && cat /tmp/cmd.tmp)+abort" \
    --preview="echo {} | sed 's/^[ ]*[0-9]*[ ]*//' | fold -s -w \$((COLUMNS-20))" \
    --preview-window=up:3:wrap \
    | sed 's/^[ ]*[0-9]*[ ]*//')

  if [[ -n "$cmd" ]]; then
    print -z "$cmd"  # Put command in history buffer for editing
  fi
}

# Interactive history browser with categories
fhistory_browse() {
  local category="${1:-all}"
  local filter=""

  case "$category" in
    "git")
      filter="git"
      ;;
    "npm"|"node")
      filter="npm\|node\|yarn\|pnpm"
      ;;
    "cd"|"nav")
      filter="cd\|ls\|pwd"
      ;;
    "files")
      filter="cp\|mv\|rm\|mkdir\|touch"
      ;;
    "docker")
      filter="docker\|kubectl"
      ;;
    *)
      filter=".*"
      ;;
  esac

  local cmd
  cmd=$(history | grep -E "$filter" | fzf \
    --height 60% \
    --layout=reverse \
    --border \
    --prompt="$category commands> " \
    --header="Ctrl-A: All | Ctrl-G: Git | Ctrl-N: Node | Ctrl-D: Docker | Ctrl-F: Files" \
    --bind="ctrl-a:reload(history)" \
    --bind="ctrl-g:reload(history | grep -E 'git')" \
    --bind="ctrl-n:reload(history | grep -E 'npm\|node\|yarn\|pnpm')" \
    --bind="ctrl-d:reload(history | grep -E 'docker\|kubectl')" \
    --bind="ctrl-f:reload(history | grep -E 'cp\|mv\|rm\|mkdir\|touch')" \
    --preview="echo {} | sed 's/^[ ]*[0-9]*[ ]*//' | fold -s -w \$((COLUMNS-20))" \
    --preview-window=up:3:wrap \
    | sed 's/^[ ]*[0-9]*[ ]*//')

  if [[ -n "$cmd" ]]; then
    print -z "$cmd"
  fi
}

# Recent commands (last 50) with execution frequency
frecent_history() {
  local cmd
  cmd=$(fc -l -50 | awk '{$1=""; print substr($0,2)}' | sort | uniq -c | sort -nr | \
    fzf --with-nth=2.. \
        --height 40% \
        --layout=reverse \
        --border \
        --prompt="Frequent Commands> " \
        --header="Commands sorted by frequency" \
        --preview="echo {2..} | fold -s -w \$((COLUMNS-20))" \
        --preview-window=up:3:wrap \
    | awk '{$1=""; print substr($0,2)}')

  if [[ -n "$cmd" ]]; then
    print -z "$cmd"
  fi
}

# Fuzzy search environment variables
fenv() {
  local variable
  variable=$(env | fzf | cut -d= -f1)
  [[ -n "$variable" ]] && echo "\$$variable = ${(P)variable}"
}

# ===================================================================
# TLDR INTEGRATION WITH FZF
# ===================================================================

# Fuzzy search tldr pages
ftldr() {
  local page
  page=$(tldr --list | fzf --preview="tldr {}" --preview-window=right:70%:wrap)
  [[ -n "$page" ]] && tldr "$page"
}

# Fuzzy search and explain a command from history
fhelp_history() {
  local cmd
  cmd=$(history | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | awk '{print $1}')
  [[ -n "$cmd" ]] && tldr "$cmd"
}

# ===================================================================
# PROJECT-SPECIFIC FUZZY FUNCTIONS
# ===================================================================

# Fuzzy find React/Vue components
fcomp() {
  local component_dirs=("src/components" "components" "src/app" "app" "pages" "src/pages")
  local search_dirs=""

  for dir in "${component_dirs[@]}"; do
    [[ -d "$dir" ]] && search_dirs="$search_dirs $dir"
  done

  if [[ -z "$search_dirs" ]]; then
    echo "❌ No component directories found"
    return 1
  fi

  local file
  file=$(fd --type f -e jsx -e tsx -e vue -e svelte . $search_dirs | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:50%:wrap)
  [[ -n "$file" ]] && ${EDITOR:-code} "$file"
}

# Fuzzy find test files
ftest() {
  local test_patterns=("**/*.test.*" "**/*.spec.*" "**/__tests__/**/*")
  local files=""

  for pattern in "${test_patterns[@]}"; do
    files="$files\n$(fd --type f $pattern)"
  done

  local file
  file=$(echo "$files" | grep -v "^$" | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:50%:wrap)
  [[ -n "$file" ]] && ${EDITOR:-code} "$file"
}

# Fuzzy find configuration files
fconfig() {
  local config_patterns=("*config*" ".*rc" "*.config.*" "*.json" "*.yaml" "*.yml" "*.toml")
  local files=""

  for pattern in "${config_patterns[@]}"; do
    files="$files\n$(fd --type f --max-depth 2 $pattern)"
  done

  local file
  file=$(echo "$files" | grep -v "^$" | sort -u | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:50%:wrap)
  [[ -n "$file" ]] && ${EDITOR:-code} "$file"
}

# Fuzzy find and open documentation
fdocs() {
  local doc_patterns=("README*" "CHANGELOG*" "docs/**/*" "*.md" "*.mdx")
  local files=""

  for pattern in "${doc_patterns[@]}"; do
    files="$files\n$(fd --type f $pattern)"
  done

  local file
  file=$(echo "$files" | grep -v "^$" | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:50%:wrap)
  [[ -n "$file" ]] && ${EDITOR:-code} "$file"
}

# ===================================================================
# ENHANCED FILE OPERATIONS
# ===================================================================

# Better cat with syntax highlighting (optional - only override if you want it)
# Uncomment if you want bat to replace cat globally
# cat() {
#   if command -v bat >/dev/null 2>&1; then
#     bat "$@"
#   else
#     command cat "$@"
#   fi
# }

# ===================================================================
# GIT INTEGRATION WITH FZF
# ===================================================================

# Interactive git add
fga() {
  local files
  files=$(git status --porcelain | fzf --multi --preview 'git diff --color=always {2..}' --preview-window=right:50%:wrap | awk '{print $2}')
  [[ -n "$files" ]] && git add $(echo "$files")
}

# Interactive git restore
fgr() {
  local files
  files=$(git status --porcelain | fzf --multi --preview 'git diff --color=always {2..}' --preview-window=right:50%:wrap | awk '{print $2}')
  [[ -n "$files" ]] && git restore $(echo "$files")
}

# Interactive git commit browser
fgl() {
  git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

# ===================================================================
# NODE/NPM INTEGRATION
# ===================================================================

# Fuzzy search and navigate to node_modules
fnm() {
  if [[ ! -d "node_modules" ]]; then
    echo "❌ No node_modules directory found"
    return 1
  fi

  local module
  module=$(fd --type d --max-depth 2 . node_modules | fzf --preview 'ls -la {}' --preview-window=right:50%:wrap)
  [[ -n "$module" ]] && cd "$module"
}

# Fuzzy search package.json dependencies
fdeps() {
  if [[ ! -f "package.json" ]]; then
    echo "❌ No package.json found in current directory"
    return 1
  fi

  local dep
  dep=$(jq -r '.dependencies // {}, .devDependencies // {} | keys[]' package.json | sort | fzf --preview "jq -r '.dependencies.{}, .devDependencies.{}' package.json 2>/dev/null | head -1")

  if [[ -n "$dep" ]]; then
    echo "📦 Package: $dep"
    jq -r --arg dep "$dep" '.dependencies[$dep] // .devDependencies[$dep]' package.json
    echo ""
    echo "🔗 NPM page: https://www.npmjs.com/package/$dep"
  fi
}

# ===================================================================
# PERFORMANCE OPTIMIZATION
# ===================================================================

# Cache fzf results for better performance
FZF_CACHE_DIR="$HOME/.cache/fzf"
[[ ! -d "$FZF_CACHE_DIR" ]] && mkdir -p "$FZF_CACHE_DIR"

# Preload common searches in background
preload_fzf_cache() {
  if [[ -d ".git" ]] && command -v fd >/dev/null 2>&1; then
    # Cache git files
    git ls-files > "$FZF_CACHE_DIR/git_files_$(pwd | sed 's/\//_/g')" 2>/dev/null &
    # Cache all files
    fd --type f > "$FZF_CACHE_DIR/all_files_$(pwd | sed 's/\//_/g')" 2>/dev/null &
  fi
}

# Auto-preload cache when entering directories with git
if command -v fd >/dev/null 2>&1; then
  autoload -U add-zsh-hook
  add-zsh-hook chpwd preload_fzf_cache
fi

# ===================================================================
# KEY BINDINGS (Enhanced)
# ===================================================================

# Additional key bindings for custom functions
bindkey '^G^F' fgf      # Ctrl+G, Ctrl+F - fuzzy git files
bindkey '^G^B' fgb      # Ctrl+G, Ctrl+B - fuzzy git branches
bindkey '^G^M' fgm      # Ctrl+G, Ctrl+M - fuzzy modified files
bindkey '^N^P' fnpm     # Ctrl+N, Ctrl+P - fuzzy npm scripts

# History selection key bindings
bindkey '^H^H' fhistory          # Ctrl+H, Ctrl+H - enhanced history menu
bindkey '^H^B' fhistory_browse   # Ctrl+H, Ctrl+B - browse history by category
bindkey '^H^F' frecent_history   # Ctrl+H, Ctrl+F - frequent commands

# ===================================================================
# VALIDATION AND SETUP
# ===================================================================

# Validate tools are available
validate_fuzzy_tools() {
  echo "🔍 Fuzzy Tools Status:"

  local tools=("fzf" "fd" "bat")
  local all_good=true

  for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      echo "  ✅ $tool"
    else
      echo "  ❌ $tool (install with: brew install $tool)"
      all_good=false
    fi
  done

  if [[ "$all_good" == "true" ]]; then
    echo "🎉 All fuzzy tools are ready!"
  else
    echo "⚠️  Some tools are missing. Install them for full functionality."
  fi
}

# Show available fuzzy functions
fuzzy_help() {
  echo "🔍 Available Fuzzy Functions:"
  echo ""
  echo "📁 File & Directory Navigation:"
  echo "  fe     - fuzzy edit files"
  echo "  fcd    - fuzzy cd to directory (fcd [query] [base_dir])"
  echo "  fif    - fuzzy find in files (with ripgrep)"
  echo ""
  echo "🌿 Git Integration:"
  echo "  fgf    - fuzzy git files"
  echo "  fgm    - fuzzy git modified files"
  echo "  fgb    - fuzzy git branches"
  echo "  fga    - fuzzy git add"
  echo "  fgr    - fuzzy git restore"
  echo "  fgl    - fuzzy git log browser"
  echo ""
  echo "📦 Frontend Development:"
  echo "  fnpm   - fuzzy npm scripts"
  echo "  fcomp  - fuzzy find components"
  echo "  ftest  - fuzzy find test files"
  echo "  fconfig - fuzzy find config files"
  echo "  fdocs  - fuzzy find documentation"
  echo "  fnm    - fuzzy navigate node_modules"
  echo "  fdeps  - fuzzy search dependencies"
  echo ""
  echo "⚙️  System:"
  echo "  fkill  - fuzzy kill processes"
  echo "  fh     - fuzzy command history"
  echo "  fenv   - fuzzy environment variables"
  echo ""
  echo "📚 Help & Documentation:"
  echo "  ftldr  - fuzzy search tldr pages"
  echo "  fhelp_history - fuzzy help for commands from history"
  echo ""

  echo "📜 Enhanced History Selection:"
  echo "  hist (fhistory)     - enhanced history menu with copy/edit options"
  echo "  histbrowse          - browse history by category (git/npm/docker/files)"
  echo "  histfreq            - show most frequently used commands"
  echo "  histgit             - git command history only"
  echo "  histnpm             - npm/node command history only"
  echo "  histdocker          - docker command history only"
  echo ""

  echo "🔧 Key Bindings:"
  echo "  Ctrl+T - fuzzy file search"
  echo "  Ctrl+R - fuzzy history search"
  echo "  Alt+C  - fuzzy directory search"
  echo "  Ctrl+G,F - fuzzy git files"
  echo "  Ctrl+G,B - fuzzy git branches"
  echo "  Ctrl+G,M - fuzzy modified files"
  echo "  Ctrl+N,P - fuzzy npm scripts"
}

# Initialize fuzzy tools
init_fuzzy_tools() {
  # Validate installation
  if [[ -n "$ZSH_DEBUG" ]]; then
    validate_fuzzy_tools
  fi

  # Set up completions for bat
  if command -v bat >/dev/null 2>&1; then
    # Create bat cache directory
    [[ ! -d "$HOME/.cache/bat" ]] && mkdir -p "$HOME/.cache/bat"
  fi
}

# Run initialization
init_fuzzy_tools
