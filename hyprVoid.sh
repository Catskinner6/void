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

# Install needed packages
echo "Installing required packages..."
sudo xbps-install -Sy base-devel git wget xtools neovim mesa-dri stow wl-clipboard || { echo "Package installation failed."; exit 1; }
sudo xbps-install -Sy dunst dbus seatd libseat xcb-util-wm cups crony polkit || { echo "Package installation failed."; exit 1; }
sudo xbps-install -Sy fastfetch alacritty foot Thunar Waybar wofi rofi nerd-fonts || { echo "Package installation failed."; exit 1; }
sudo xbps-install -Sy zig go rust fzf zoxide starship btop || { echo "Package installation failed."; exit 1; }

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
for dir in nvim bash alacritty foot hypr waybar; do
    stow -t ~ $dir || { echo "Failed to stow $dir."; exit 1; }
done
cd ~
#. ~/.bashrc
echo "Config files stowed successfully"
#echo "and .bashrc sourced"

# Prepare for building Hyprland
echo "Preparing for Hyprland build..."
mkdir -p ~/.local/pkgs
cd ~/.local/pkgs/
[ ! -d void-packages ] && git clone https://github.com/void-linux/void-packages.git || echo "void-packages already cloned."
[ ! -d hyprland-void ] && git clone https://github.com/Makrennel/hyprland-void.git || echo "hyprland-void already cloned."

# Bootstrap Void packages
echo "Bootstrapping void-packages..."
cd void-packages/ || { echo "void-packages directory not found."; exit 1; }
./xbps-src binary-bootstrap || { echo "Bootstrap failed."; exit 1; }

# Build and install Hyprland
echo "Building Hyprland..."
cd ../hyprland-void/ || { echo "hyprland-void directory not found."; exit 1; }
cat common/shlibs >> ~/.local/pkgs/void-packages/common/shlibs
cp -r srcpkgs/* ~/.local/pkgs/void-packages/srcpkgs/
cd ../void-packages/
./xbps-src pkg hyprland || { echo "Hyprland build failed."; exit 1; }

sudo xbps-install -yR hostdir/binpkgs hyprland || { echo "Hyprland installation failed."; exit 1; }

# Enable necessary services
echo "Enabling services..."
for service in seatd dbus cronyd cupsd polkitd; do
    if [ -d /etc/sv/$service ]; then
        sudo ln -sf /etc/sv/$service /var/service/ || { echo "Failed to enable $service."; exit 1; }
    else
        echo "Service $service not found. Skipping."
    fi
done

# Add user to seatd group
sudo usermod -aG _seatd $USERNAME || { echo "Failed to add user to _seatd group."; exit 1; }

# Create XDG_RUNTIME_DIR for seatd
sudo mkdir -p /run/user/$(id -u)
sudo chown $(id -u):$(id -g) /run/user/$(id -u)
chmod 700 /run/user/$(id -u)

sudo sv start seatd

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

echo "Script completed successfully!"
echo "\nPlease reboot this machine."
