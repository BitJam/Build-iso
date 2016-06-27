#!/bin/bash

THEME_DIR=$(dirname $(readlink -f $0))
source $THEME_DIR/../theme-functions.sh
start_theme "$@"

copy_dir wallpaper/             	/usr/share/wallpaper --create 

copy_file bootchartd.conf 		/etc/
copy_file rc.local 			/etc/
copy_file sysctl.conf           	/etc/
copy_file grub                  	/etc/default/
copy_file 10_linux 			/etc/grub.d/
copy_file 80-net-name-slot.rules 	/etc/udev/rules.d/
copy_file live-to-installed 		/usr/sbin
copy_file rc.local.install      	/usr/share/antiX/ --create
copy_file issue				/usr/share/antiX/

exit