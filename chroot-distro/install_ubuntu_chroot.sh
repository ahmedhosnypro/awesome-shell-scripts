#!/bin/bash

# Setup Oh My Zsh, Powerlevel10k, and plugins for Ubuntu Chroot on Android
# Designed to be run inside the Ubuntu Chroot:
# ubuntu
# cd /root/awesome-shell-scripts/chroot-distro && chmod +x install_ubuntu_chroot.sh && ./install_ubuntu_chroot.sh

echo "🚀 Starting Ubuntu Chroot Zsh setup..."

# --- Step 1: Install Prerequisites ---
echo "⚙️  Installing prerequisites (zsh, git, curl, fontconfig)..."
apt update
apt install -y zsh git curl fontconfig

# --- Step 2: Install Oh My Zsh ---
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "✔️  Oh My Zsh is already installed. Skipping installation."
else
  echo "💻 Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- Step 3: Install Powerlevel10k Theme ---
echo "🎨 Installing Powerlevel10k theme..."
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
if [ -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
  echo "  ✔️  Powerlevel10k already installed."
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k
fi

# --- Step 4: Install Plugins ---
echo "🔌 Installing plugins..."

install_plugin() {
    local name=$1
    local url=$2
    if [ -d "${ZSH_CUSTOM}/plugins/$name" ]; then
        echo "  ✔️  Plugin '$name' already installed."
    else
        echo "  📦 Installing '$name'..."
        git clone --depth=1 "$url" "${ZSH_CUSTOM}/plugins/$name"
    fi
}

install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
install_plugin "fast-syntax-highlighting" "https://github.com/zdharma-continuum/fast-syntax-highlighting.git"
install_plugin "zsh-autocomplete" "https://github.com/marlonrichert/zsh-autocomplete.git"

# --- Step 5: Configure .zshrc ---
echo "📝 Configuring .zshrc..."

cat <<'EOF' > ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)
source $ZSH/oh-my-zsh.sh

# Android specific SSL fix
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

# --- Step 6: Apply Pre-defined Powerlevel10k Configuration ---
if [ -f "./.p10k.zsh" ]; then
    echo "⚙️  Applying pre-defined .p10k.zsh..."
    cp "./.p10k.zsh" ~/.p10k.zsh
else
    echo "⚠️  .p10k.zsh not found in $(pwd), you may need to run 'p10k configure'."
fi

# --- Step 7: Set Zsh as Default ---
echo "🐚 Changing shell to zsh..."
chsh -s $(which zsh) root

echo "✅ Ubuntu Chroot Zsh setup complete!"
echo "Type 'exec zsh' or restart the chroot to enjoy your new shell."
