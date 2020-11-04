#!/usr/bin/env bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#        THIS SCRIPT IS RUN AS PART OF AN UNATTENDED INSTALL
#          OF UBUNTU DESKTOP GUEST OS IN VMWARE FUSION AND 
#            CAN BE USED TO FINE-TUNE THE CONFIGURATION
#                      TO SUIT YOUR NEEDS.
#           
#      IT RUNS WHEN THE USER CREATED DURING THE UNATTENDED INSTALL 
#          FIRST LOGS-IN AND IS EXECUTED BY THE UNITY LAUNCHER 
#        'USERCONF.DESKTOP'. TO ENSURE THE SCRIPT IS ONLY RUN ON 
#            INITIIAL LOGIN IT RENAMES 'USERCONF.DESKTOP' TO 
#           'USERCONF.DESKTOP.RUN' WHEN IT FINISHES EXECUTION.
#
#        IF YOU DON'T WANT TO FINE-TUNE THE CONFIGURATION, 
#                  DELETE EVERYTHING BETWEEN 
#          'BEGIN CUSTOMISATION' AND 'END CUSTOMISATION'.            
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
# > > > > > > > > > > > > > > > > > > > > > > > > > >   B E G I N   C U S T O M I S A T I O N   > > > > > > > > > > > > > > > > > > > > > > > > > 
# 

# Note: LOGIN SCREEN SCALE (200%), LOGIN SCREEN SIZE (1152x864) and DISPLAY SCALE (200%) below are dependant on 
# Virtual Machine > Settings > Display > 'Use full resolution for Retina display' in VMware Fusion being checked 
# (gui.fitGuestUsingNativeDisplayResolution = "TRUE" in .vmx file) 



# Get the installed Ubuntu version e.g. 20, 18, 16 etc. 
VERSION=$(lsb_release -r | awk '{print $2}' | cut -d '.' -f 1)



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# AUTHENTICATION AS ROOT
# 

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `userconf.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# FORCE DISPLAY OF GRUB MENU AT BOOT
#
# SOURCE: https://askubuntu.com/a/1078723
#
# GRUB_TIMEOUT_STYLE=menu
# GRUB_HIDDEN_TIMEOUT=
# GRUB_TIMEOUT=5

sudo sed -i 's/GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu\nGRUB_HIDDEN_TIMEOUT=/g' /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT=0/GRUB_TIMEOUT=5/g' /etc/default/grub

sudo update-grub



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SET LOGIN SCREEN SCALE (200%)
#
# SOURCE: https://askubuntu.com/a/1126769

sudo tee /usr/share/glib-2.0/schemas/93_hidpi.gschema.override <<EOF
[org.gnome.desktop.interface]
scaling-factor=2
text-scaling-factor=0.9
EOF

sudo glib-compile-schemas /usr/share/glib-2.0/schemas



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SET LOGIN SCREEN SIZE (1152x864)
#
# SOURCE: https://askubuntu.com/a/1041697 and https://askubuntu.com/a/54068
#
# #GRUB_GFXMODE=640x480
# GRUB_GFXMODE=1152x864x32
# GRUB_GFXPAYLOAD_LINUX=keep
# #GRUB_CMDLINE_LINUX_DEFAULT="nomodeset"

sudo sed -i 's/#GRUB_GFXMODE=640x480/#GRUB_GFXMODE=640x480\nGRUB_GFXMODE=1152x864x32\nGRUB_GFXPAYLOAD_LINUX=keep\n#GRUB_CMDLINE_LINUX_DEFAULT="nomodeset"/g' /etc/default/grub

sudo update-grub



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SET DISPLAY SCALE (200%)
#
# SOURCE: https://ubuntuforums.org/showthread.php?t=2384128&p=13736478#post13736478

gsettings set org.gnome.desktop.interface scaling-factor 2



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SET VOLUME
#
# 

amixer cset iface=MIXER,name="Master Playback Volume" 25 >/dev/null



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# EDIT USER'S .BASHRC
#
#

tee -a ~/.bashrc <<EOF
# Set keyboard model and layout
#setxkbmap -model apple -layout gb

# Message to display for each new Terminal window
printf "Use control [ctrl] + \ for # character\n\n"
EOF

#gsettings set org.gnome.desktop.input-sources sources  "[('xkb', 'gb'), ('xkb', 'gb+mac')]"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# FILES APP CONFIGURATION
#
# 

# Show hidden files
gsettings set org.gtk.Settings.FileChooser show-hidden true

# Set default to 'List' view 
gsettings set org.gnome.nautilus.preferences default-folder-viewer "'list-view'"

# Limit 'List' view columns
gsettings set org.gnome.nautilus.list-view default-visible-columns "['name', 'size', 'date_modified']"

# Use Tree view
gsettings set org.gnome.nautilus.list-view use-tree-view true



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# MOUSE SCROLL
#
# 

gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SCREEN LOCK
#
# 

# Disable automatic screen lock
gsettings set org.gnome.desktop.screensaver lock-enabled false


# Enable automatic screen lock
#gsettings set org.gnome.desktop.screensaver lock-enabled true


# Lock screen after 30 minutes
#gsettings set org.gnome.desktop.screensaver lock-delay uint32 1800



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# KEYBOARD SHORTCUTS
#
# 

# Change keyboard shortcut to open Terminal
if [ $VERSION -ge 20 ]; then 
    gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Alt><Super>t']"             # option-command-t on macOS
    #gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Primary><Alt>t']"           # control-option-t on macOS. Conflicts with Magnet's 'Right Two Thirds' option
else
    gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "'<Alt><Super>t'"             # option-command-t on macOS
    #gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "'<Primary><Alt>t'"           # control-option-t on macOS. Conflicts with Magnet's 'Right Two Thirds' option
fi    



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DOCK CONFIGURATION
#
# The default Desktop environment is GNOME 3 whose dock (Dash) 
# has been replaced by a fork of the 'dash-to-dock' GNOME Shell 
# extension named 'ubuntu-dock'.

gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode FIXED
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings set org.gnome.shell.extensions.dash-to-dock unity-backlit-items true



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# COPY HOST SSH CONFIGURATION TO GUEST OS
#
# 

# Mount shared host folders
sudo mkdir /mnt/hgfs
sudo vmhgfs-fuse .host:/ /mnt/hgfs/ -o allow_other -o uid=1000

# Copy host's SSH configuration
[ ! -d /home/$USER/.ssh ] && mkdir /home/$USER/.ssh
cp -r /mnt/hgfs/.ssh/ids /home/$USER/.ssh/ids

tee /home/$USER/.ssh/config <<EOF
# http://www.kelvinwong.ca/2011/03/30/multiple-ssh-private-keys-identityfile/
IdentityFile ~/.ssh/ids/%h/%r/id_ed25519
EOF

#sudo vmware-toolbox-cmd script shutdown enable
#sudo vmware-toolbox-cmd script shutdown set /etc/vmware-tools/poweroff-custom.sh



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# FONTS
#
# 

# Download and install 'Source Code Pro'
pushd /tmp
wget https://github.com/adobe-fonts/source-code-pro/archive/2.030R-ro/1.050R-it.zip
unzip 1.050R-it.zip
FONTPATH="${XDG_DATA_HOME:-$HOME/.local/share}"/fonts
mkdir -p $FONTPATH
cp source-code-pro-*-it/OTF/*.otf $FONTPATH
fc-cache -f -v
popd



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# INSTALL APPLICATIONS
#
# 

# Chromium
if [ $VERSION -ge 20 ]; then
    # installs '/var/lib/snapd/desktop/applications/chromium_chromium.desktop'
    sudo snap install chromium
else
    # installs '/usr/share/applications/chromium-browser.desktop'
    sudo apt install -y chromium-browser
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# CONFIGURE FAVORITES
#
# 

if [ $VERSION -ge 20 ]; then
    CHROMIUM="'chromium_chromium.desktop'"
    SWUPDATE="'snap-store_ubuntu-software.desktop'"
else
    SWUPDATE="'org.gnome.Software.desktop'"
    CHROMIUM="'chromium-browser.desktop'"
fi

gsettings set org.gnome.shell favorite-apps "['org.gnome.Terminal.desktop', $CHROMIUM, 'thunderbird.desktop', 'org.gnome.Nautilus.desktop', 'libreoffice-writer.desktop', 'update-manager.desktop', $SWUPDATE, 'gnome-control-center.desktop', 'yelp.desktop']"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# TERMINAL CONFIGURATION
#
# 

# Get the default Terminal profile
PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

# Set the default Terminal profile name 
dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/visible-name "'My Default'"

# Set the default Terminal font 
dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/font "'Source Code Pro 12'"
dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/use-system-font false

# Set the default size for new Terminal windows
dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/default-size-columns "98"
dconf write /org/gnome/terminal/legacy/profiles:/:$PROFILE/default-size-rows "32"                       # 98 / 3.06 = 32.03

#
# < < < < < < < < < < < < < < < < < < < < < < < < < < <   E N D   C U S T O M I S A T I O N   < < < < < < < < < < < < < < < < < < < < < < < < < < 
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#                                                                                                                                               #
#                                 D O   N O T   C H A N G E   A N Y T H I N G   B E L O W   T H I S   L I N E !                                 #
# _____________________________________________________________________________________________________________________________________________ #

# Change the name of the launcher to 'userconf.desktop.run' so it won't be executed again at login
mv /home/$USER/.config/autostart/userconf.desktop /home/$USER/.config/autostart/userconf.desktop.run

clear

read -p "Press enter to power-off"
shutdown -h now