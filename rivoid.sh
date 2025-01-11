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
## RIVER WITH TERMINAL ##
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
mkdir -p "$HOME/.config/river"
RIVER_INIT="$HOME/.config/river/init"
if [ ! -f "$RIVER_INIT" ]; then
    echo "Creating river init file at $RIVER_INIT"
    cat > "$RIVER_INIT" <<EOF
#!/bin/sh

term="foot"
browser1="qutebrowser"
browser2="brave-browser"
browser3="zen"
menu="fuzzel"

# River Key Binds
riverctl map normal Super+Shift E exit
riverctl map normal Super Q close

riverctl map normal Super X spawn \$term
riverctl map normal Super F spawn \$menu
riverctl map normal Super B spawn \$browser1
riverctl map normal Super+Shift B spawn \$browser2

# Toggle statusbar
riverctl map normal Super+Shift R spawn "killall yambar || ~/.config/yambar/scripts/yambar-start.sh"



# Set background and border color
riverctl background-color 0x002b36
riverctl border-color-focused 0x33ccff
riverctl border-color-unfocused 0x595959

# Set the default layout generator to be rivertile and start it.
# River will send the process group of the init executable SIGTERM on exit.
riverctl default-layout rivertile
rivertile -view-padding 5 -outer-padding 5 -main-ratio 0.5 &

EOF
    chmod +x "$RIVER_INIT" || { echo "Failed to set executable permission on river init file."; exit 1; }
    echo "River init file created succesfully"
else
    echo "River init file already exists at $RIVER_INIT. Skipping creation."
fi

####################################################################################################################
####################################################################################################################
## ADD YAMBAR AND FUZZEL##
####################################################################################################################
echo "Installing fuzzel and yambar packages..."
sudo xbps-install -Sy fuzzel yambar wlr-randr || { echo "Package installation failed."; exit 1; }

##############################################################
# Setup ~/.config/fuzzel/fuzzel.ini
mkdir -p "$HOME/.config/fuzzel"
FUZZEL="$HOME/.config/fuzzel/fuzzel.ini"
if [ ! -f "$FUZZEL" ]; then
    echo "Creating fuzzel.ini at $FUZZEL"
    cat > "$FUZZEL" <<EOF
# output=<not set>
font=GoMono Nerd Font:size=10
dpi-aware=no
# prompt=> 
icon-theme=hicolor
icons-enabled=yes

fuzzy=yes

# lines=15
width=35
horizontal-pad=10
vertical-pad=10
inner-pad=10

# image-size-ratio=0.5

# line-height=<use font metrics>
# letter-spacing=0
line-height=18
[colors]
background=000000CC
text=efefefef
match=fabd2fff
selection-match=fabd2fff
selection=666666ff
selection-text=efefefef
border=33eeffee

[border]
width=2
radius=3

[dmenu]
# mode=text  # text|index
# exit-immediately-if-empty=no

EOF
    echo "Fuzzel.init created succesfully"
else
    echo "Fuzzel.init already exists at $FUZZEL. Skipping creation."
fi

##############################################################

# Setup ~/.config/yambar/config.yml
mkdir -p "$HOME/.config/yambar/"
YAMBAR_CONF="$HOME/.config/yambar/config.yml"
if [ ! -f "$YAMBAR_CONF" ]; then
    echo "Creating yambar-start script at $YAMBAR_CONF"
    cat > "$YAMBAR_CONF" <<EOF
nerdfont: &nerdfont Symbols Nerd Font Mono:pixelsize=12 
gomono: &gomono GoMono Nerd Font Mono:pixelsize=12
bg_default: &bg_default {stack: [{background: {color: 00000000}}, {underline: {size: 3, color: 98971aff}}]}

bar:
  font: *gomono
  height: 20
  location: top
  right-spacing: 8
  right-margin: 10
  border:
    top-margin: 5 
    left-margin: 10
    right-margin: 10
    color: D8DEE900 
  background: 000000AA
  foreground: ffffffff

  left:
    - river:
        anchors:
          - base: &river_base
              left-margin: 10
              right-margin: 10 
              default: {string: {text: , font: *gomono}}
              conditions:
                id == 1: {string: {text: 1, font: *gomono}}  
                id == 2: {string: {text: 2, font: *gomono}}  
                id == 3: {string: {text: 3, font: *gomono}}  
                id == 4: {string: {text: 4, font: *gomono}}  
                id == 5: {string: {text: 5, font: *gomono}}  
                id == 6: {string: {text: 6, font: *gomono}}  
                id == 7: {string: {text: 7, font: *gomono}}  
                id == 8: {string: {text: 8, font: *gomono}}  
                id == 9: {string: {text: 9, font: *gomono}}
                # id == 21: {string: {text: "Scratchpad", font: *gomono}}

        content:
          map:
            on-click: 
              left: sh -c "riverctl set-focused-tags $((1 << ({id} - 1)))"
              right: sh -c "riverctl toggle-focused-tags $((1 << ({id} -1)))"
              middle: sh -c "riverctl toggle-view-tags $((1 << ({id} -1)))"
            conditions:
              state == urgent:
                map:
                  <<: *river_base
                  deco: {background: {color: D08770ff}}
              state == focused:
                map:
                  <<: *river_base
                  deco: *bg_default
              state == visible && ~occupied:
                map:
                  <<: *river_base
              state == visible && occupied:
                map:
                  <<: *river_base
                  deco: *bg_default
              state == unfocused:
                map:
                  <<: *river_base
              state == invisible && ~occupied: {empty: {}}
              state == invisible && occupied:
                map:
                  <<: *river_base
                  deco: {underline: {size: 3, color: 00000000}}

  center:
    - script:
        path: ~/.config/yambar/scripts/dater.sh
        args: []
        content:
            string: 
                margin: 0
                text: "{date}"
                on-click: sh -c "~/.config/yambar/scripts/calendar.sh show"
    - clock:
        content:
          - string:
                margin: 0
                text: "{time}"

  right: 
    - script:
        path: ~/.config/yambar/scripts/void-updates.sh
        args: []
        content: 
            string: 
                margin: 0
                text: "{updates}"
                font: *nerdfont
                foreground: 98971aff
                on-click: sh -c "~/.config/yambar/scripts/void-updates.sh update"
   # - script:
   #     path: ~/.config/yambar/scripts/idleinhibit.sh
   #     args: []
   #     content: 
   #         string: 
   #             margin: 0
   #             text: "{idleinhibit}"
   #             font: *nerdfont
   #             on-click: sh -c "~/.config/yambar/scripts/idleinhibit.sh toggle"
    - pipewire:
        anchors:
          volume: &volume
            conditions:
              muted:
                string:
                  text: "0%"
                  on-click:
                    middle: sh -c "amixer set Master 1+ toggle"
              ~muted:
                string:
                  text: "{cubic_volume}%"
                  on-click:
                    left: sh -c "amixer sset Master 2%-"
                    middle: sh -c "amixer set Master 1+ toggle"
                    right: sh -c "amixer sset Master 2%+"
        content:
          list:
            items:
              - map:
                  conditions:
                    type == "sink":
                      map:
                        conditions:
                          icon == "audio-headset-bluetooth":
                            string: {text: "󰋋", font: *nerdfont}
                          muted: {string: {text: "󰝟", font: *nerdfont}}
                        default:
                          - ramp:
                              tag: cubic_volume
                              items:
                                - string: {text: "󰕿", font: *nerdfont}
                                - string: {text: "󰖀", font: *nerdfont}
                                - string: {text: "󰕾", font: *nerdfont}
                    type == "source":
                      - string: {text: "", font: *nerdfont, left-margin: 5}
              - map:
                  <<: *volume
    - backlight:
        name: amdgpu_bl0
        content: [ string: {text: , font: *nerdfont}, string: {text: "{percent}%", on-click: { left: sh -c "light -U 5", right: sh -c "light -A 5"}}]
    - network:
        name: enp5s0
        content:
          map:
            conditions:
              state == down: {string: {text: 󰲜, font: *nerdfont, foreground: ffffffff}}
              ~carrier: {empty: {}}
              carrier:
                map:
                  default: {string: {text: 󰈀, font: *nerdfont, foreground: ffffffff}}
                  conditions:
                    state == up && ipv4 != "": {string: {text: 󰈀, font: *nerdfont}}
    - network:
        name: wlp3s0
        poll-interval: 1000
        content:
          map:
            default: {string: {text: , font: *nerdfont, foreground: ffffff66}}
            conditions:
              state == down: {string: {text: , font: *nerdfont, foreground: ffffffff}}
              state == up:
                map:
                  default:
                    - string: {text: , font: *nerdfont}
                    - string: {text: "{ssid} {dl-speed:mb}/{ul-speed:mb} Mb/s"}

                  conditions:
                    ipv4 == "":
                      - string: {text: , font: *nerdfont, foreground: ffffff66}
                      - string: {text: "{ssid} {dl-speed:mb}/{ul-speed:mb} Mb/s", foreground: ffffff66}
    - battery:
        name: BAT0
        poll-interval: 10000
        anchors:
          discharging: &discharging
            list:
              items:
                - ramp:
                    tag: capacity
                    items:
                      - string: {text: , foreground: ff0000ff, font: *nerdfont}
                      - string: {text: , foreground: ffa600ff, font: *nerdfont}
                      - string: {text: , font: *nerdfont}
                      - string: {text: , font: *nerdfont}
                      - string: {text: , font: *nerdfont}
                      - string: {text: , font: *nerdfont}
                      - string: {text: , font: *nerdfont}
                      - string: {text: , font: *nerdfont}
                      - string: {text: , font: *nerdfont}
                      - string: {text: , foreground: ffffffff, font: *nerdfont}
                - string: {text: "{capacity}% {estimate}"}
        content:
          map:
            conditions:
              state == unknown:
                <<: *discharging
              state == discharging:
                <<: *discharging
              state == charging:
                - string: {text: , foreground: ffffffff, font: *nerdfont}
                - string: {text: "{capacity}% {estimate}"}
              state == full:
                - string: {text: , foreground: ffffffff, font: *nerdfont}
                - string: {text: "{capacity}% full"}
              state == "not charging":
                - ramp:
                    tag: capacity
                    items:
                      - string: {text:  , foreground: ff0000ff, font: *nerdfont}
                      - string: {text:  , foreground: ffa600ff, font: *nerdfont}
                      - string: {text:  , foreground: ffffffff, font: *nerdfont}
                      - string: {text:  , foreground: ffffffff, font: *nerdfont}
                      - string: {text:  , foreground: ffffffff, font: *nerdfont}
                      - string: {text:  , foreground: ffffffff, font: *nerdfont}
                      - string: {text:  , foreground: ffffffff, font: *nerdfont}
                      - string: {text:  , foreground: ffffffff, font: *nerdfont}
                      - string: {text:  , foreground: ffffffff, font: *nerdfont}
                      - string: {text:  , foreground: ffffffff, font: *nerdfont}
                - string: {text: "{capacity}%"}


EOF
    echo "Yambar config file created succesfully"
else
    echo "Yambar config file already exists at $YAMBAR_CONF. Skipping creation."
fi

# Setup ~/.config/yambar/scripts/yambar-start.sh
mkdir -p "$HOME/.config/yambar/scripts"
YAMBAR_START="$HOME/.config/yambar/scripts/yambar-start.sh"
if [ ! -f "$YAMBAR_START" ]; then
    echo "Creating yambar-start script at $YAMBAR_START"
    cat > "$YAMBAR_START" <<EOF
#!/bin/bash

killall yambar

monitors=$(wlr-randr | grep "^[^ ]" | awk '{ print$1 }')
total=$(wlr-randr | grep "^[^ ]" | awk '{ print$1 }' | wc -l)

for monitor in ${monitors}; do
	riverctl focus-output ${monitor}
	yambar &
	sleep 0.2
done
if [ "$total" -gt "1" ]; then
	riverctl focus-output HDMI-A-1
fi
exit 0

EOF
    chmod +x "$YAMBAR_START" || { echo "Failed to set executable permission on yambar-start script."; exit 1; }
    echo "Yambar-start script created succesfully"
else
    echo "Yambar-start script already exists at $YAMBAR_START. Skipping creation."
fi

##############################################################
# Setup ~/.config/yambar/scripts
DATER="$HOME/.config/yambar/scripts/dater.sh"
if [ ! -f "$DATER" ]; then
    echo "Creating dater.sh at $DATER"
    cat > "$DATER" <<EOF
#!/bin/sh

while true; do
number=$(date +'%d')

case $number in
    1*)extension=th;;
    *1)extension=st;;
    *2)extension=nd;;
    *3)extension=rd;;
    *)extension=th;;
esac

date=$(date +"%A $(printf ${number##0}$extension) %B %Y -")

echo "date|string|$date"
echo ""

hour=$(date +'%H')
minute=$(date +'%M')

second=$(expr $hour \* 3600 + $minute \* 60)

sleep "$second"
done

EOF
    chmod +x "$DATER" || { echo "Failed to set executable permission on dater.sh."; exit 1; }
    echo "dater.sh created succesfully"
else
    echo "dater.sh already exists at $DATER. Skipping creation."
fi

##############################################################
CAL="$HOME/.config/yambar/scripts/calendar.sh"
if [ ! -f "$CAL" ]; then
    echo "Creating calendar.sh at $CAL"
    cat > "$CAL" <<EOF
#!/bin/bash

# Calendar script

function ShowCalendar() {
	dunstify -i "calendar"  "     Calendar" "$(cal --color=always | sed "s/..7m/<b><span color=\"#fabd2f\">/;s/..27m/<\/span><\/b>/")" -r 124
}

function EditCalendar() {
  echo 
}

case "$1" in
        show)
            ShowCalendar
            ;;
         
        edit)
            EditCalendar
            ;;
         
        *)
            echo $"Usage: ${0##*/} {show|edit}"
            exit 1
 
esac


EOF
    chmod +x "$CAL" || { echo "Failed to set executable permission on calendar.sh."; exit 1; }
    echo "calendar.sh created succesfully"
else
    echo "calendar.sh already exists at $CAL. Skipping creation."
fi

VOID="$HOME/.config/yambar/scripts/void-updates.sh"
if [ ! -f "$VOID" ]; then
    echo "Creating void-updates.sh at $VOID"
    cat > "$VOID" <<EOF
#!/bin/bash

function update-yambar {
echo "updates|string|"
echo ""

while true; do

xbps-install -Mun 1> /tmp/void-updates
updates="$(cat /tmp/void-updates | awk '{ print $1 }')"
number="$(cat /tmp/void-updates | wc -l)"

if [ "$number" -gt 0 ]; then
    text=" $number"
else
    text=""
fi

echo "updates|string|$text"
echo ""
sleep 30m

done
}

function update {
	foot bash -c "sudo xbps-install -Suv"; sh -c "~/.config/yambar/scripts/yambar-start.sh"
}

case $1 in
	update)
		update
		;;
	*)
		update-yambar
		;;
esac
exit 0
v
EOF
    chmod +x "$VOID" || { echo "Failed to set executable permission on void-updates.sh."; exit 1; }
    echo "void-updates.sh created succesfully"
else
    echo "void-updates.sh already exists at $VOID. Skipping creation."
fi


####################################################################################################################
####################################################################################################################
echo "Script completed successfully!"

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
