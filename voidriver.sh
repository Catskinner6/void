#!/bin/sh
set -e  # Exit on any error

# Start a `sudo` session
echo "Enter your sudo password to start the script:"
sudo -v

# Keep the `sudo` session alive
(while true; do sudo -n true; sleep 60; done) &
SUDO_PID=$!

trap 'kill $SUDO_PID' EXIT  # Ensure the session keeper stops on script exit

# Define the username
USERNAME=$(whoami)
echo "Script running for user: $USERNAME"

# Update the system and repositories
echo "Updating system..."
sudo xbps-install -Syu || { echo "Failed to update system."; exit 1; }


# Install base packages
echo "Installing base packages..."
# System Basics
sudo xbps-install -Sy git wget base-devel xtools mesa-dri stow nerd-fonts bash-completion || { echo "Package installation failed."; exit 1; }
# Wayland Specific
sudo xbps-install -Sy linux-firmware-intel mesa-dri wl-clipboard grim slurp imv yazi || { echo "Package installation failed."; exit 1; }
# River / DE
sudo xbps-install -Sy river gdm fuzzel yambar wlr-randr kanshi swaylock swayidle qutebrowser || { echo "Package installation failed."; exit 1; }
# Services
sudo xbps-install -Sy dbus avahi cups cronie elogind dunst || { echo "Package installation failed."; exit 1; }
# Terminal
sudo xbps-install -Sy alacritty foot fastfetch neovim zig go rust fzf zoxide starship btop himalaya zathura || { echo "Package installation failed."; exit 1; }
# Audio and extras
pipeWire alsa-pipewire libjack-pipewire wireplumber libpulseaudio 


# Install void repo
if [ ! -d ~/void ]; then
    git clone https://github.com/Catskinner6/void.git || { echo "Failed to clone void repository."; exit 1; }
else
    echo "Void repository already exists. Skipping clone."
fi

# Backup .bashrc if it exists
if [ -f ~/.bashrc ]; then
    echo "Backing up .bashrc..."
    mv ~/.bashrc ~/.bashrc.bak
fi

# Stow/symlink config files
echo "Stowing configuration files..."
cd ~/void/config/ || { echo "Config directory not found."; exit 1; }
for dir in nvim bash alacritty foot; do
    stow -t ~ $dir || { echo "Failed to stow $dir."; exit 1; }
done
cd ~
#. ~/.bashrc
echo "Config files stowed successfully"
#echo "and .bashrc sourced"

# Prepare for building Hyprland
echo "Preparing for src build..."
mkdir -p ~/.local/pkgs
cd ~/.local/pkgs/
[ ! -d void-packages ] && git clone https://github.com/void-linux/void-packages.git || echo "void-packages already cloned."

# Bootstrap Void packages
echo "Bootstrapping void-packages..."
cd void-packages/ || { echo "void-packages directory not found."; exit 1; }
./xbps-src binary-bootstrap || { echo "Bootstrap failed."; exit 1; }

# Enable necessary services
echo "Enabling services..."
for service in dbus crond cupsd avahi-daemon gdm elogind; do
    if [ -d /etc/sv/$service ]; then
        sudo ln -sf /etc/sv/$service /var/service/ || { echo "Failed to enable $service."; exit 1; }
    else
        echo "Service $service not found. Skipping."
    fi
done

# Setup cron job for fstrim
FSTRIM_PATH="/etc/cron.weekly/fstrim"
if [ ! -f "$FSTRIM_PATH" ]; then
    echo "Creating fstrim script at $FSTRIM_PATH"
    sudo tee "$FSTRIM_PATH" > /dev/null <<EOF
#!/bin/bash

# Weekly trim of stuff
fstrim -A
EOF
    sudo chmod +x "$FSTRIM_PATH" || { echo "Failed to set executable permission on fstrim script."; exit 1; }
else
    echo "fstrim script already exists at $FSTRIM_PATH. Skipping creation."
fi

# Install FiraCode and MesloLG fonts
echo "Installing FiraCode and MesloLG Fonts"
sudo mkdir -p /usr/share/fonts
curl -L -o "FiraCode.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip"
curl -L -o "MesloLG.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Meslo.zip"
sudo unzip -o "FiraCode.zip" -d /usr/share/fonts
sudo unzip -o "MesloLG.zip" -d /usr/share/fonts
sudo fc-cache -fv /usr/share/fonts
echo "Fonts installed successfully."

echo "Script completed successfully!"
echo "\nPlease reboot this machine. and start the gdm service."
