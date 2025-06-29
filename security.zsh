#!/bin/zsh

# Only show load message in debug mode
[[ -n "$ZSH_DEBUG" ]] && echo "zsh.config/security loaded"

# ===================================================================
# SECURE ENVIRONMENT VARIABLE MANAGEMENT
# ===================================================================

# Function to load environment variables from secure files
load_secure_env() {
  local env_file="$1"

  if [[ -f "$env_file" ]]; then
    # Check file permissions (should be 600 or 700)
    local perms=$(stat -f "%OLp" "$env_file" 2>/dev/null || stat -c "%a" "$env_file" 2>/dev/null)

    if [[ "$perms" != "600" ]] && [[ "$perms" != "700" ]]; then
      echo "⚠️  Warning: $env_file has insecure permissions ($perms). Should be 600 or 700."
      echo "   Fix with: chmod 600 $env_file"
    fi

    # Source the file if it exists and has reasonable permissions
    if [[ "$perms" =~ ^[67][0-7][0-7]$ ]]; then
      set -a  # Export all variables
      source "$env_file"
      set +a  # Stop exporting
      echo "🔐 Loaded secure environment from: $env_file"
    else
      echo "❌ Refusing to load $env_file due to insecure permissions"
    fi
  fi
}

# ===================================================================
# ENVIRONMENT FILE LOCATIONS
# ===================================================================

# Load environment variables from secure locations
ENV_FILES=(
  "$HOME/.env"                    # General environment variables
  "$HOME/.env.local"              # Local overrides
  "$ZSH_CONFIG/.env"             # Zsh-specific environment
  "$HOME/.config/environment"     # XDG config location
)

for env_file in "${ENV_FILES[@]}"; do
  load_secure_env "$env_file"
done

# ===================================================================
# SECURE TOKEN MANAGEMENT
# ===================================================================

# Function to set up secure token storage
setup_secure_tokens() {
  local env_file="$HOME/.env"

  echo "🔐 Setting up secure token storage..."
  echo ""
  echo "This will create a secure .env file for storing sensitive tokens."
  echo "Current hardcoded tokens will be moved there."
  echo ""

  if [[ -f "$env_file" ]]; then
    echo "📁 Environment file already exists: $env_file"
    echo "Would you like to append to it? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "Aborted."
      return 1
    fi
  else
    echo "Creating new environment file: $env_file"
    touch "$env_file"
    chmod 600 "$env_file"
  fi

  # Add HIVE_TOKEN if it's currently hardcoded
  if ! grep -q "HIVE_TOKEN" "$env_file" 2>/dev/null; then
    echo "" >> "$env_file"
    echo "# Hive API Token" >> "$env_file"
    echo "export HIVE_TOKEN=7bddbb97a7ddfe8032eb1bdc012510f8" >> "$env_file"
    echo "✅ Added HIVE_TOKEN to $env_file"
  fi

  echo ""
  echo "🔧 Next steps:"
  echo "1. Edit $env_file to add/modify your tokens"
  echo "2. Remove hardcoded tokens from zshrc.zsh"
  echo "3. Restart your shell: exec zsh"
  echo ""
  echo "💡 Tip: Add $env_file to your .gitignore to keep tokens private"
}

# Function to check for hardcoded secrets
check_hardcoded_secrets() {
  echo "🔍 Checking for potential hardcoded secrets..."

  local config_files=(
    "$HOME/.zshrc"
    "$ZSH_CONFIG/zshrc.zsh"
    "$ZSH_CONFIG/aliases.zsh"
    "$ZSH_CONFIG/functions.zsh"
  )

  local patterns=(
    "TOKEN="
    "API_KEY="
    "SECRET="
    "PASSWORD="
    "PASS="
    "_KEY="
  )

  local found_secrets=false

  for file in "${config_files[@]}"; do
    if [[ -f "$file" ]]; then
      for pattern in "${patterns[@]}"; do
        if grep -q "$pattern" "$file" 2>/dev/null; then
          echo "⚠️  Potential secret found in $file:"
          grep --color=always "$pattern" "$file"
          found_secrets=true
        fi
      done
    fi
  done

  if [[ "$found_secrets" == "false" ]]; then
    echo "✅ No obvious hardcoded secrets found"
  else
    echo ""
    echo "💡 Consider moving these to a secure .env file"
    echo "   Run 'setup-secure-tokens' to set this up automatically"
  fi
}

# Function to validate environment security
validate_env_security() {
  echo "🛡️  Environment Security Check:"
  echo ""

  # Check for secure file permissions
  for env_file in "${ENV_FILES[@]}"; do
    if [[ -f "$env_file" ]]; then
      local perms=$(stat -f "%OLp" "$env_file" 2>/dev/null || stat -c "%a" "$env_file" 2>/dev/null)
      if [[ "$perms" == "600" ]] || [[ "$perms" == "700" ]]; then
        echo "✅ $env_file (permissions: $perms)"
      else
        echo "❌ $env_file (permissions: $perms) - Should be 600 or 700"
      fi
    fi
  done

  # Check for exported sensitive variables
  echo ""
  echo "🔍 Checking for exported sensitive variables:"
  env | grep -E "(TOKEN|KEY|SECRET|PASS)" | while read -r var; do
    echo "⚠️  $var"
  done

  echo ""
  echo "💡 Security recommendations:"
  echo "• Use .env files with 600 permissions for secrets"
  echo "• Never commit .env files to version control"
  echo "• Use tools like 1Password CLI for production secrets"
  echo "• Regularly rotate API tokens and keys"
}

# ===================================================================
# SECURITY UTILITIES
# ===================================================================

# Generate a secure random password
generate_password() {
  local length="${1:-32}"
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
  elif [[ -f /dev/urandom ]]; then
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
  else
    echo "Unable to generate secure password - no entropy source found"
    return 1
  fi
}

# Check if a command exists without executing it
safe_command_check() {
  command -v "$1" >/dev/null 2>&1
}

# ===================================================================
# INITIALIZATION
# ===================================================================

# Only run security checks if not in CI/automated environment
if [[ -z "$CI" ]] && [[ -z "$GITHUB_ACTIONS" ]] && [[ "$TERM" != "dumb" ]]; then
  # Run basic security validation
  if [[ -n "$ZSH_SECURITY_CHECK" ]]; then
    validate_env_security
  fi
fi
