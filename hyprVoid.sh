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
sudo xbps-install -Syu

# Install needed packages
sudo xbps-install -Sy base-devel git wget xtools neovim mesa-dri stow wl-clipboard
sudo xbps-install -Sy dunst dbus elogind seatd cups cronie polkit
sudo xbps-install -Sy fastfetch alacritty foot Thunar Waybar wofi rofi nerd-fonts
sudo xbps-install -Sy zig go rust fzf zoxide starship

# Install void Repo
git clone https://github.com/Catskinner6/void.git

# Backup .bashrc if it exists
if [ -f ~/.bashrc ]; then
    mv ~/.bashrc ~/.bashrc.bak
fi

# Stow/symlink config files
cd ~/void/configs/
for dir in nvim bash alacritty foot hypr waybar; do
    stow $dir
done

# Prepare for building Hyprland
mkdir -p ~/.local/pkgs
cd ~/.local/pkgs/
[ ! -d void-packages ] && git clone https://github.com/void-linux/void-packages.git
[ ! -d hyprland-void ] && git clone https://github.com/Makrennel/hyprland-void.git

# Bootstrap Void packages
cd void-packages/
./xbps-src binary-bootstrap

# Build and install Hyprland
cd ../hyprland-void/
cat common/shlibs >> ~/.local/pkgs/void-packages/common/shlibs
cp -r srcpkgs/* ~/.local/pkgs/void-packages/srcpkgs/
cd ../void-packages/
./xbps-src pkg hyprland
./xbps-src pkg xdg-desktop-portal-hyprland
./xbps-src pkg hyprland-protocols

sudo xbps-install -R hostdir/binpkgs hyprland
sudo xbps-install -R hostdir/binpkgs xdg-desktop-portal-hyprland
sudo xbps-install -R hostdir/binpkgs hyprland-protocols

# Enable necessary services
for service in seatd dbus elogind cronyd cupsd polkitd; do
    sudo ln -sf /etc/sv/$service /var/service/
done

# Add user to seatd group
sudo usermod -aG _seatd $USERNAME

# Setup cron job for fstrim
FSTRIM_PATH="/etc/cron.weekly/fstrim"

if [ ! -f "$FSTRIM_PATH" ]; then
    echo "Creating fstrim script at $FSTRIM_PATH"
    sudo tee "$FSTRIM_PATH" > /dev/null <<EOF
#!/bin/bash

# Weekly trim of stuff
fstrim -A
EOF
    sudo chmod +x "$FSTRIM_PATH"
else
    echo "fstrim script already exists at $FSTRIM_PATH. Skipping creation."
fi

echo "Script completed successfully!"

