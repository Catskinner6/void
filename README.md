# Void Install Script

This repo makes loading a pre-configured desktop or wm simple. Currently it is set to Hyprland.
Run the following two commands to install on a fresh Void Linux tty:

```bash
sudo xbps-install -Sy curl openssl

# For Hyprland:
curl -s https://raw.githubusercontent.com/Catskinner6/void/main/hyprVoid.sh | sh
# For Gnome Desktop:
curl -s https://raw.githubusercontent.com/Catskinner6/void/main/gnovoid.sh | sh
```

Enjoy.
