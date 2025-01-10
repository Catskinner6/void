#!/bin/bash
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

sudo xbps-install -Sy unzip || { echo "Failed to update system."; exit 1; }

# Download the file
cd ~
sudo mkdir -p /usr/share/fonts  # Use -p to avoid errors if the directory already exists
mkdir -p downloads  # Same here
cd ~/downloads

# Download the ZIP file
ZIP_FILE="FiraCode.zip"
curl -L -o "$ZIP_FILE" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip"

# Unzip the file into ~/.fonts
unzip -o "$ZIP_FILE" -d ~/.fonts

# Move the ZIP file into ~/.fonts (if you want to keep the ZIP file)
sudo mv "$ZIP_FILE" /usr/share/fonts


echo "Script completed successfully!"
echo "\nPlease reboot this machine."
