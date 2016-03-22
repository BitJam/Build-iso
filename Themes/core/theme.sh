#!/bin/bash

THEME_DIR=$(dirname $(readlink -f $0))
source $THEME_DIR/../theme-functions.sh
start_theme "$@"

copy_dir wallpaper/             /usr/share/wallpaper --create 
copy_file grub                  /etc/default/
#copy_file bash.bashrc           /etc/
#copy_file live-to-installed     /usr/sbin/
copy_file rc.local.install      /usr/share/antiX/ --create


exit