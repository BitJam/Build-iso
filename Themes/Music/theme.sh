#!/bin/bash

THEME_DIR=$(dirname $(readlink -f $0))
source $THEME_DIR/../theme-functions.sh
start_theme "$@"

ICEWM=/etc/skel/.icewm

edit   $ICEWM/preferences  's/^(\s*TimeFormat=).*/\1" %a %x %l:%M:%S %p "/'
append $ICEWM/startup      'aplay /usr/share/sounds/music-distro/desktop.wav'

append /etc/skel/.local/share/applications/defaults.list \
    'audio/midi=timidity.desktop;'

edit /etc/timidity/timidity.cfg \
    's=^(source /etc/timidity/freepats.cfg)=# \1=' \
    's=^#\s*(source /etc/timidity/fluidr3_gs.cfg)=\1='

comment   /etc/timidity/timidity.cfg 'source /etc/timidity/freepats.cfg'
uncomment /etc/timidity/timidity.cfg 'source /etc/timidity/fluidr3_gs.cfg'

exit

copy_file desktop.wav           /usr/share/sounds/music-distro      --create
copy_file sample.ntd            /etc/skel/nted                      --create
copy_file wallpaper-list.conf   /usr/share/antix-settings/wallpaper

copy_dir desktop/               /usr/share/applications/
copy_dir wallpaper/             /usr/share/wallpaper/
