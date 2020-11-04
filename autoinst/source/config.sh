#!/usr/bin/env bash

#/
#|--- home/
#     |--- steve/
#          |--- userconf.sh
#          |--- .config/
#               |--- autostart/
#                    |--- userconf.desktop




USER_TO_TARGET=$1


# The script below does 3 things.
#
# 1. Using Here Document syntax, creates a script named '/home/USER_TO_TARGET/userconf.sh' 
#    which configures some global and named-user settings when run. Makes the script 
#    executable and changes ownership from 'root' to USER_TO_TARGET.
#
# 2. Creates the directories '/home/USER_TO_TARGET/.config' and '/home/USER_TO_TARGET/.config/autostart'
#    and changes the ownership of both from 'root' to USER_TO_TARGET.
#
# 3. Using Here Document syntax, creates a Unity Launcher named 'userconf.desktop' in the 
#    '/home/USER_TO_TARGET/.config/autostart' directory which ensures it runs when 
#    the user logs in. On execution, the 'userconf.desktop' launcher opens a Terminal window
#    and runs the '/home/USER_TO_TARGET/userconf.sh' script. Makes the launcher 
#    executable and changes ownership from 'root' to USER_TO_TARGET.
#
# All tasks are performed as 'root'



cp /root/userconf.sh /home/$USER_TO_TARGET/userconf.sh

# Change ownership of '/home/$USER_TO_TARGET/userconf.sh' from 'root' to '$USER_TO_TARGET' and make it executable.
chown $USER_TO_TARGET /home/$USER_TO_TARGET/userconf.sh
chmod +x /home/$USER_TO_TARGET/userconf.sh


# Create the directories '/home/$USER_TO_TARGET/.config' and '/home/$USER_TO_TARGET/.config/autostart' and change ownership from 'root' to '$USER_TO_TARGET'
[ ! -d  /home/$USER_TO_TARGET/.config ] && mkdir /home/$USER_TO_TARGET/.config
chown $USER_TO_TARGET /home/$USER_TO_TARGET/.config

[ ! -d  /home/$USER_TO_TARGET/.config/autostart ] && mkdir /home/$USER_TO_TARGET/.config/autostart
chown $USER_TO_TARGET /home/$USER_TO_TARGET/.config/autostart


# Create a Unity Launcher named 'userconf.desktop' in the '/home/$USER_TO_TARGET/.config/autostart' directory so it executes when the USER_TO_TARGET logs in.
tee /home/$USER_TO_TARGET/.config/autostart/userconf.desktop <<EOF

#!/usr/bin/env xdg-open
[Desktop Entry]
Type=Application
Version=1.1
Name=User Configuration Script
Name[en_GB]=User Configuration Script
Exec=gnome-terminal -e "bash -c '~/userconf.sh;$SHELL'"
Terminal=false

EOF


# Change ownership of '/home/$USER_TO_TARGET/.config/autostart/userconf.desktop' from 'root' to '$USER_TO_TARGET' and make it executable.
chown $USER_TO_TARGET /home/$USER_TO_TARGET/.config/autostart/userconf.desktop
chmod +x /home/$USER_TO_TARGET/.config/autostart/userconf.desktop








