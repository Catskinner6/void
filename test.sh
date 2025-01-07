
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
echo "Installing git and stow packages"
sudo xbps-install -Sy git stow || { echo "Package installation failed."; exit 1; }
echo " Git and Stow succesfully installed"

# Install my void repo
if [ ! -d ~/void ]; then
    git clone https://github.com/Catskinner6/void.git || { echo "Failed to clone void repository."; exit 1; }
else
    echo "Void repository already exists. Skipping clone."
fi

# Backup .bashrc if it exists
if [ -f ~/.bashrc ]; then
    echo "Deleting .bashrc..."
    rm -rf ~/.bashrc
fi

# Stow/symlink config files
echo "Stowing configuration files..."
cd ~/void/config/ || { echo "Config directory not found."; exit 1; }
#for dir in nvim bash alacritty foot hypr waybar; do
#    stow -t ~ $dir || { echo "Failed to stow $dir."; exit 1; }
#done
stow -t ~ bash
echo "Config files stowed successfully"

cd
echo "changed dir"
source ~/.bashrc
echo "and .bashrc sourced"


echo "Script completed successfully!"
echo "\nPlease reboot this machine."
