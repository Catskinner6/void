# VOID LINUX

## Install

### VM

When using virt manager:

- Customize before install
- Overview > EFI > X86 Secure boot

### Installer

- keyboard: us
- mirror:   california
- network:  eth0
- locale:   english(United States) [type 'f']
- partitions:
    - 1G, EFI-System (boot, will hold old kernels)
    - 4-12G, Swap (64GB+ RAM only uses a little as a buffer- no hibernation)
    - ~100G, Linux File System or Linux Root (Root, All programs go here)
    - 100G+, Linux File System or Linux Home (Home, for all documents, user files, etc)
- filesystem and mountpoints
    - 1GB:      vfat, /boot/efi
    - 4-12G:    swap
    - 100G:     btrfs, /
    - 100G+:    btrfs, /home

- reboot

### Update and restart

```bash
sudo xbps-install -Syu
sudo xbps-install -Syu
```

NOTE: Execute twice to ensure xbps is updated

restart pc 

```bash 
restart
```

or restart services

```bash 
sudo xbps-install -Syu xtools
xcheckrestart
```

## Setup

from the home directory create directories and edit bashrc file for aliases

```bash
mkdir .local/
mkdir .local/pkgs/

vi .bashrc

# XBPS
alias xin='sudo xbps-install -S'

# Terminal Programs
alias fetch='fastfetch'
alias nv='neovim'
alias vim='neovim'
```

Install:
```bash
xin git curl wget neovim fastfetch

xin thunar foot rofi-wayland dunst 
```

Next add void-packages and hyprland
```bash
git clone https://github.com/void-linux/void-packages.git
git clone https://github.com/Makrennel/hyprland-void.git

cd void-packages/
./xbps-src binary-bootstrap

cd ..
cd hyprland-void/
cat common/shlibs >> ~/.local/pkgs/void-packages/common/shlibs
cp -r srcpkgs/* ~/.local/pkgs/void-packages/srcpkgs/

cd ..
cd void-packages/
./xbps-src pkg hyprland
./xbps-src pkg xdg-desktop-portal-hyprland
./xbps-src pkg hyprland-protocols
sudo xbps-install -R hostdir/binpkgs hyprland
sudo xbps-install -R hostdir/binpkgs xdg-desktop-portal-hyprland
sudo xbps-install -R hostdir/binpkgs hyprland-protocols

xin dbus elogind seatd polkit mesa-dri

services seatd...
...
sudo usermod -aG _seatd $USERNAME

xin nerd-fonts
```

### SERVICES

List available services

```bash
ls /etc/sv/acpid/
```

Install services:

- dbus
- cronie
- cups
- avahi
- ipp-usb

```bash 
sudo xbps-install -Syu
```

Link and setup services

```bash 
sudo ln -s /etc/sv/dbus/ /var/service/
sudo ln -s /etc/sv/elogind/ /var/service/
sudo ln -s /etc/sv/cronyd/ /var/service/
sudo ln -s /etc/sv/cupsd/ /var/service/
```
fstrim:

```bash 
sudo nvim /etc/cron.weekly/fstrim
```

write bash script and save
```bash 
!/bin/bash 
fstrim -A
```

make executable
```bash 
sudo chmod u+x /etc/cron.weekly/fstrim
```

### Environment


### Key Programs to install

- xtools
- alacritty/foot
- neovim
- git
- wget
- zig
- go
- rust
- base-devel
- xmirror
- brave-browser (needs binary or different repo or flatpak?)
- fzf
- zoxide
- starship
- 



```bash
sudo xbps-install -Syu alacritty neovim 
```

### DESKTOP

- Hyprland
    - dunst
    - thunar
    - foot
    - rofi-wayland
    
at: /etc/xbps.d/hyprland-void.conf

```bash 
repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc
sudo xbps-install -S hyprland

```


    
