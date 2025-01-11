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

####################################################################################################################
####################################################################################################################

# Install base River Packages
echo "Installing base packages..."
sudo xbps-install -Sy river fuzzel yambar wlr-randr || { echo "Package installation failed."; exit 1; }
echo "Installing base terminal packages..."
sudo xbps-install -Sy foot neovim nerd-fonts || { echo "Package installation failed."; exit 1; }
echo "Installing base services..."
sudo xbps-install -Sy dbus elogind seatd || { echo "Package installation failed."; exit 1; }


# Enable necessary services
echo "Enabling services..."
for service in dbus seatd elogind; do
    if [ -d /etc/sv/$service ]; then
        sudo ln -sf /etc/sv/$service /var/service/ || { echo "Failed to enable $service."; exit 1; }
    else
        echo "Service $service not found. Skipping."
    fi
done

# Add user to seatd group
getent group _seatd > /dev/null && sudo usermod -aG _seatd $USERNAME || echo "Group _seatd does not exist. Skipping."


# Setup ~/.config/river/init
RIVER_INIT="~/.config/river/init"
if [ ! -f "$RIVER_INIT" ]; then
    echo "Creating river init file at $RIVER_INIT"
    sudo tee "$RIVER_INIT" > /dev/null <<EOF
#!/bin/bash

term="foot"
browser1="qutebrowser"
browser2="brave-browser"
browser3="zen"
menu="fuzzel"

# River Key Binds
riverctl map normal Super+Shift E exit
riverctl map normal Super Q close

riverctl map normal Super X spawn $term
riverctl map normal Super F spawn $menu
riverctl map normal Super B spawn $browser1
riverctl map normal Super+Shift B spawn $browser2


EOF
    sudo chmod +x "$RIVER_INIT" || { echo "Failed to set executable permission on river init file."; exit 1; }
else
    echo "River init file already exists at $RIVER_INIT. Skipping creation."
fi

####################################################################################################################
####################################################################################################################

# System Basics
#sudo xbps-install -Sy git wget base-devel xtools stow nerd-fonts bash-completion || { echo "Package installation failed."; exit 1; }
# Wayland Specific
#sudo xbps-install -Sy linux-firmware-intel mesa-dri wl-clipboard grim slurp wlopm|| { echo "Package installation failed."; exit 1; }
# River / DE
#sudo xbps-install -Sy river fuzzel yambar wlr-randr kanshi swaylock swayidle wlsunset swaybg|| { echo "Package installation failed."; exit 1; }
# Services
#sudo xbps-install -Sy dbus avahi cups cronie elogind dunst polkit-gnome|| { echo "Package installation failed."; exit 1; }
# Terminal
#sudo xbps-install -Sy alacritty foot fastfetch neovim zig go rust fzf zoxide starship btop himalaya zathura imv yazi mpv bat || { echo "Package installation failed."; exit 1; }
# Audio and extras
#sudo xbps-install -Sy pipewire alsa-pipewire libjack-pipewire wireplumber libpulseaudio qutebrowser || { echo "Package installation failed."; exit 1; }



# Install void repo
#if [ ! -d ~/void ]; then
#    git clone https://github.com/Catskinner6/void.git || { echo "Failed to clone void repository."; exit 1; }
#else
#    echo "Void repository already exists. Skipping clone."
#fi

# Backup .bashrc if it exists
#if [ -f ~/.bashrc ]; then
#    echo "Backing up .bashrc..."
#    mv ~/.bashrc ~/.bashrc.bak
#fi

# Stow/symlink config files
#echo "Stowing configuration files..."
#cd ~/void/config/ || { echo "Config directory not found."; exit 1; }
#for dir in river nvim bash alacritty foot yambar ; do
#    stow -t ~ $dir || { echo "Failed to stow $dir."; exit 1; }
#done
#cd ~
#. ~/.bashrc
#echo "Config files stowed successfully"
#echo "and .bashrc sourced"

# Prepare for building from src
#echo "Preparing for src build..."
#mkdir -p ~/.local/pkgs
#cd ~/.local/pkgs/
#[ ! -d void-packages ] && git clone https://github.com/void-linux/void-packages.git || echo "void-packages already cloned."

# Bootstrap Void packages
#echo "Bootstrapping void-packages..."
#cd void-packages/ || { echo "void-packages directory not found."; exit 1; }
#./xbps-src binary-bootstrap || { echo "Bootstrap failed."; exit 1; }



# Setup cron job for fstrim
#FSTRIM_PATH="/etc/cron.weekly/fstrim"
#if [ ! -f "$FSTRIM_PATH" ]; then
#    echo "Creating fstrim script at $FSTRIM_PATH"
#    sudo tee "$FSTRIM_PATH" > /dev/null <<EOF
##!/bin/bash

## Weekly trim of stuff
#fstrim -A
#EOF
#    sudo chmod +x "$FSTRIM_PATH" || { echo "Failed to set executable permission on fstrim script."; exit 1; }
#else
#    echo "fstrim script already exists at $FSTRIM_PATH. Skipping creation."
#fi

# Install FiraCode and MesloLG fonts
#echo "Installing FiraCode and MesloLG Fonts"
#sudo mkdir -p /usr/share/fonts
#curl -L -o "FiraCode.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip"
#curl -L -o "MesloLG.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Meslo.zip"
#sudo unzip -o "FiraCode.zip" -d /usr/share/fonts
#sudo unzip -o "MesloLG.zip" -d /usr/share/fonts
#sudo fc-cache -fv /usr/share/fonts
#echo "Fonts installed successfully."

echo "Script completed successfully!"
echo "\nPlease reboot this machine and launch <river> after login."
