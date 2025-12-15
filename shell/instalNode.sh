#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# 1. Download and run the nvm installation script
echo "🌎 Downloading nvm install script..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# 2. Add nvm configuration to all shell profiles
echo "📝 Configuring nvm for all shell profiles..."

NVM_CONFIG='
# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
'

# Function to add nvm config to a profile file if not already present
add_nvm_to_profile() {
    local profile_file="$1"
    
    if [ -f "$profile_file" ]; then
        if ! grep -q "NVM_DIR" "$profile_file"; then
            echo "  ✅ Adding nvm to $profile_file"
            echo "$NVM_CONFIG" >> "$profile_file"
        else
            echo "  ✔️  nvm already configured in $profile_file"
        fi
    else
        echo "  📝 Creating $profile_file with nvm configuration"
        echo "$NVM_CONFIG" > "$profile_file"
    fi
}

# Add to all common shell profiles
add_nvm_to_profile "$HOME/.bashrc"
add_nvm_to_profile "$HOME/.zshrc"
add_nvm_to_profile "$HOME/.profile"
add_nvm_to_profile "$HOME/.bash_profile"

# 3. Activate nvm for the current session
echo "🚀 Activating nvm..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# 3. Verify nvm installation
echo "🔍 Verifying nvm installation..."
command -v nvm

# 4. Install the latest LTS version of Node.js
echo "📦 Installing latest LTS version of Node.js..."
nvm install node

# 5. Set the LTS version as the default
nvm use node

# 6. Verify Node.js installation
echo "✅ Node.js version:"
node -v
echo "✅ npm version:"
npm -v

# 7. Node Path
echo "📁 Node.js is installed at:
nvm which node"


echo "🎉 All done! Node.js and nvm are installed."
echo "💡 nvm has been configured for bash, zsh, and other shells."
echo "💡 Restart your terminal or run 'source ~/.zshrc' (or ~/.bashrc) to use nvm."