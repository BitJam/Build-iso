#!/bin/bash

THEME_DIR=$(dirname $(readlink -f $0))
source $THEME_DIR/../theme-functions.sh
start_theme "$@"

#copy_file menu-applications 		/usr/share/desktop-menu/.jwm/
copy_file arandr.desktop 		/usr/share/applications/
#copy_file bleachbit-root.desktop 	/usr/share/applications/
copy_file ceni.desktop 			/usr/share/applications/
copy_file gnome-ppp.desktop 		/usr/share/applications/
copy_file gparted.desktop 		/usr/share/applications/
copy_file grsync.desktop 		/usr/share/applications/
#copy_file grub-customizer.desktop 	/usr/share/applications/
copy_file hardinfo.desktop 		/usr/share/applications/
copy_file luckybackup.desktop 		/usr/share/applications/
copy_file luckybackup-gnome-su.desktop 	/usr/share/applications/
copy_file ndisgtk.desktop 		/usr/share/applications/
#copy_file njam.desktop 		/usr/share/applications/
copy_file pybootchartgui.desktop 	/usr/share/applications/
copy_file rxvt-unicode.desktop 		/usr/share/applications/
copy_file synaptic.desktop 		/usr/share/applications/antix/
copy_file system-config-printer.desktop /usr/share/applications/
copy_file umts-panel.desktop 		/usr/share/applications/
copy_file vim.tiny.desktop 		/usr/share/applications/
copy_file wpa_gui.desktop 		/usr/share/applications/
copy_file xfburn.desktop 		/usr/share/applications/
copy_file xmahjongg.desktop 		/usr/share/applications/
copy_file calculator.desktop 		/usr/share/applications/antix/
copy_file calcurse.desktop 		/usr/share/applications/antix/
copy_file nano.desktop 			/usr/share/applications/
#copy_file display-im6.desktop		/usr/share/applications/ 
#copy_file display-im6.q16.desktop	/usr/share/applications/
copy_file mahjongg.png 			/usr/share/icons/

copy_file lxde-audio-video.directory 	/usr/share/desktop-directories/
copy_file back.jpg 			/usr/share/wallpaper/

#copy_file iceweasel.js 		/etc/iceweasel/pref/
#copy_file prefs.js 			/etc/iceweasel/profile/ 
#copy_file bookmarks.html 		/etc/iceweasel/profile/

copy_file grub 				/etc/default/
copy_file 10_linux 			/etc/grub.d/
copy_file rc.local 			/etc/
copy_file bootchartd.conf 		/etc/
#copy_file 80-net-name-slot.rules 	/etc/udev/rules.d/
#copy_file libuser.conf 		/etc/
copy_file modules 			/etc/
copy_file 98vboxadd-xclient     	/etc/X11/Xsession.d/
#copy_file 20-thinkpad.conf      	/usr/share/X11/xorg.conf.d/
copy_file sysctl.conf           	/etc/
copy_file hosts                 	/etc/
copy_file hosts.ORIGINAL        	/etc/
copy_file hosts.saved           	/etc/
copy_file mouse.conf 			/etc/skel/.desktop-session/ 
copy_file issue				/usr/share/antiX/
copy_file asound.conf.PREAMP 		/etc/

copy_file .bashrc 			/etc/skel/
copy_file user-dirs.defaults 		/etc/xdg 
copy_file lxde-applications.menu 	/etc/xdg/menus 
copy_file equivalents.html       	/usr/share/antiX/
#copy_file background.jpg 		/usr/share/slim/themes/antiX/
copy_file ixquick-https.xml 		/usr/share/firefox-esr/distribution/searchplugins/common/
copy_file startpage-https.xml 		/usr/share/firefox-esr/distribution/searchplugins/common/
copy_file distribution.ini 		/usr/share/firefox-esr/distribution/
#copy_dir searchplugins/ 		/etc/iceweasel/searchplugins/common/
copy_dir dillo/                  	/etc/skel/.dillo/     --create
copy_dir streamtuner2/                  /etc/skel/.config/streamtuner2/     --create
copy_dir icons/                  	/usr/share/antiX/icons/     --create 

exit
