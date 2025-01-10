#!/bin/sh
set -e  # Exit on any error

# Start a `sudo` session
echo "Enter your sudo password to start the script:"
sudo -v

# Keep the `sudo` session alive
(while true; do sudo -n true; sleep 60; done) &
SUDO_PID=$!
trap 'kill $SUDO_PID; exit' EXIT  # Ensure cleanup on script exit

# Define the username
USERNAME=$(whoami)
echo "Script running for user: $USERNAME"

# Update the system and repositories
echo "Updating system..."
sudo xbps-install -Syu || { echo "Failed to update system."; exit 1; }

# Install needed packages
echo "Installing required packages..."
sudo xbps-install -Sy base-devel git wget xtools neovim mesa-dri stow wl-clipboard xorg-server-xwayland dunst dbus seatd elogind libseat xcb-util-wm cups chrony polkit sddm fastfetch alacritty foot Thunar Waybar wofi rofi nerd-fonts unzip zig go rust fzf zoxide starship btop || { echo "Package installation failed."; exit 1; }

# Clone Void repo
if [ ! -d ~/void ]; then
    git clone https://github.com/Catskinner6/void.git || { echo "Failed to clone void repository."; exit 1; }
else
    echo "Void repository already exists. Skipping clone."
fi

# Backup .bashrc
[ -f ~/.bashrc ] && mv ~/.bashrc ~/.bashrc.bak

# Stow configuration files
echo "Stowing configuration files..."
cd ~/void/config/ || { echo "Config directory not found."; exit 1; }
for dir in nvim bash alacritty foot hypr waybar; do
    stow -t ~ $dir || { echo "Failed to stow $dir."; exit 1; }
done
echo "Configuration files stowed successfully."

# Install FiraCode and MesloLG fonts
echo "Installing FiraCode and MesloLG Fonts"
sudo mkdir -p /usr/share/fonts
curl -L -o "FiraCode.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip"
curl -L -o "MesloLG.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Meslo.zip"
sudo unzip -o "FiraCode.zip" -d /usr/share/fonts
sudo unzip -o "MesloLG.zip" -d /usr/share/fonts
sudo fc-cache -fv /usr/share/fonts
echo "Fonts installed successfully."

# Prepare for building Hyprland
echo "Preparing for Hyprland build..."
mkdir -p ~/.local/pkgs
cd ~/.local/pkgs/
[ ! -d void-packages ] && git clone https://github.com/void-linux/void-packages.git || echo "void-packages already cloned."
[ ! -d hyprland-void ] && git clone https://github.com/Makrennel/hyprland-void.git || echo "hyprland-void already cloned."

# Bootstrap and build Hyprland
cd void-packages/ && ./xbps-src binary-bootstrap || { echo "Bootstrap failed."; exit 1; }
cd ../hyprland-void/ && cp -r srcpkgs/* ../void-packages/srcpkgs/
cd ../void-packages/ && ./xbps-src pkg hyprland || { echo "Hyprland build failed."; exit 1; }

# Install Hyprland
sudo xbps-install -yR hostdir/binpkgs hyprland || { echo "Hyprland installation failed."; exit 1; }

# Enable services
for service in seatd dbus chronyd cupsd polkitd elogind sddm; do
    [ -d /etc/sv/$service ] && sudo ln -sf /etc/sv/$service /var/service || echo "Service $service not found. Skipping."
done

# Add user to seatd group
getent group _seatd > /dev/null && sudo usermod -aG _seatd $USERNAME || echo "Group _seatd does not exist. Skipping."

# Create cron job for fstrim
FSTRIM_PATH="/etc/cron.weekly/fstrim"
if [ ! -f "$FSTRIM_PATH" ]; then
    echo "Creating fstrim script at $FSTRIM_PATH"
    sudo tee "$FSTRIM_PATH" > /dev/null <<EOF
#!/bin/bash
fstrim -A
EOF
    sudo chmod +x "$FSTRIM_PATH" || { echo "Failed to set executable permission on fstrim script."; exit 1; }
else
    echo "fstrim script already exists. Skipping creation."
fi

echo -e "Script completed successfully!\nPlease reboot this machine."
