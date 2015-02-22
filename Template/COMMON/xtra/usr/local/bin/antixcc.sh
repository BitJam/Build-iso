#!/bin/bash
# File Name: controlcenter.sh
# Purpose: all-in-one control centre for antiX
# Authors: OU812 and minor modifications by anticapitalista
# Latest Change: 20 August 2008
# Latest Change: 11 January 2009 and renamed antixcc.sh
# Latest Change: 15 August 2009 some apps and labels altered.
# Latest Change: 09 March 2012 by anticapitalista. Added Live section.
# Latest Change: 22 March 2012 by anticapitalista. Added jwm config options and edited admin options.
# Latest Change: 18 April 2012 by anticapitalista. mountbox-antix opens as user not root.
# Latest Change: 06 October 2012 by anticapitalista. Function for ICONS. New icon theme.
# Latest Change: 26 October 2012 by anticapitalista. Includes gksudo and ktsuss.
# Latest Change: 12 May 2013 by anticapitalista. Let user set default apps.
# Acknowledgements: Original script by KDulcimer of TinyMe. http://tinyme.mypclinuxos.com
#################################################################################################################################################

TEXTDOMAINDIR=/usr/share/locale
TEXTDOMAIN=antixcc.sh
# Options
ICONS=/usr/share/icons/antiX
ED1=geany
TERM=urxvt

Desktop=$"Desktop" System=$"System" Network=$"Network" Session=$"Session"
Live=$"Live" Disks=$"Disks" Hardware=$"Hardware" 

# Edit syslinux.cfg if the device it is own is mounted read-write
grep -q " /live/boot-dev .*\<rw\>" /proc/mounts \
    && edit_bootloader=$(cat <<Edit_Bootloader
		<hbox>
		  <button>
		  <input file>"$ICONS/preferences-desktop.png"</input>
		  <action>gksudo $ED1 /live/boot-dev/boot/syslinux/syslinux.cfg &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Edit Bootloader menu"`"</label>
		  </text>
		</hbox>
Edit_Bootloader
)

excludes_dir=/usr/local/share/excludes
test -d $excludes_dir && edit_excludes=$(cat <<Edit_Excludes
		<hbox>
		  <button>
		  <input file>"$ICONS/preferences-desktop.png"</input>
		  <action>gksudo $ED1 $excludes_dir/*.list &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Edit Exclude files"`"</label>
		  </text>
		</hbox>
Edit_Excludes
)

live_tab=$(cat <<Live_Tab
  <vbox>
    <frame>
	<hbox>
	  <vbox>
		<hbox>
          <button>
          <input file>"$ICONS/palimpsest.png"</input>
		  <action>persist-config &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Configure live persistence"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/preferences-desktop.png"</input>
		  <action>gksudo persist-makefs &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Set up live persistence"`"</label>
		  </text>
		</hbox>
        $edit_excludes
	  </vbox>
	  <vbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/palimpsest.png"</input>
		  <action>gksudo persist-save &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Save root persistence"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/preferences-desktop.png"</input>
		  <action>gksudo remaster-live &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Remaster"`"</label>
		  </text>
		</hbox>
        $edit_bootloader
	  </vbox>
	</hbox>
    </frame>
  </vbox>
Live_Tab
)

# If we are on a live system then ...
if grep -q " /live/aufs aufs" /proc/mounts; then
    tab_labels="$Desktop|$System|$Network|$Session|$Live|$Disks|$Hardware"

else
    tab_labels="$Desktop|$System|$Network|$Session|$Disks|$Hardware"
    live_tab=
fi

export ControlCenter=$(cat <<End_of_Text
<window title="antiX Control Center" icon="gnome-control-center" window-position="1">
<vbox>
  
  <notebook tab-pos="0" labels="$tab_labels">
  
  <vbox>
  <frame>
	<hbox>
	  <vbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/preferences-desktop-wallpaper.png"</input>
		  <action>wallpaper.py &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Choose Wallpaper"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/desktop-effects.png"</input>
		  <action>$ED1 ~/.fluxbox/overlay ~/.fluxbox/keys ~/.fluxbox/init ~/.fluxbox/startup ~/.fluxbox/apps ~/.fluxbox/menu &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Edit Fluxbox Settings"`"</label>
		  </text>
		</hbox>
                <hbox>
		  <button>
		  <input file>"$ICONS/utilities-system-monitor.png"</input>
		  <action>$ED1 ~/.conkyrc  &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Edit System Monitor"`"</label>
		  </text>
		</hbox>
       </vbox>
	  <vbox>   
		<hbox>
		  <button>
		  <input file>"$ICONS/preferences-desktop-theme.png"</input>
		  <action>lxappearance &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Change Gtk2 and Icon Themes"`"</label>
		  </text>
		</hbox> 
		<hbox>
		  <button>
		  <input file>"$ICONS/desktop-effects.png"</input>
		  <action>$ED1 ~/.icewm/winoptions ~/.icewm/preferences ~/.icewm/keys ~/.icewm/startup ~/.icewm/toolbar ~/.icewm/menu &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Edit IceWM Settings"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/desktop-effects.png"</input>
		  <action>$ED1 ~/.jwm/preferences ~/.jwm/keys ~/.jwm/tray ~/.jwm/startup ~/.jwmrc ~/.jwm/menu &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Edit jwm Settings"`"</label>
		  </text>
		</hbox>
	  </vbox>
	</hbox>
    </frame>
  </vbox>
  <vbox>
	<frame>
	<hbox>
	  <vbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/synaptic.png"</input>
		  <action>gksudo synaptic &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Manage Packages"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/applications-system.png"</input>
		  <action>gksudo antix-system.sh &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Configure System"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/gnome-settings-default-applications.png"</input>
		  <action>$TERM -e su -c sysv-rc-conf &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Choose Startup Services"`"</label>
		  </text>
		</hbox>
        </vbox>
	  <vbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/config-users.png"</input>
		  <action>gksudo user-management &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Manage Users"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/preferences-desktop.png"</input>
		  <action>ktsuss $ED1 /etc/fstab /etc/default/keyboard /boot/grub/menu.lst /etc/slim.conf /etc/apt/sources.list.d/various.list /etc/apt/sources.list.d/antix.list /etc/apt/sources.list.d/debian.list &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Edit Config Files"`"</label>
		  </text>
		</hbox>
                <hbox>
		  <button>
		  <input file>"$ICONS/time-admin.png"</input>
		  <action>$TERM -e su -c "dpkg-reconfigure tzdata" &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Set Date and Time"`"</label>
		  </text>
		</hbox>
	  </vbox>
	</hbox>
	</frame>
  </vbox>

  <vbox>
	<frame>
	<hbox>
	  <vbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/network-wired.png"</input>
		  <action>$TERM -e sudo ceni &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Network Interfaces (ceni)"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/network-wired.png"</input>
		  <action>umts-panel &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Configure GPRS/UMTS Connection"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/network-wireless.png"</input>
		  <action>gksudo wicd-gtk &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Connect Wirelessly (wicd)"`"</label>
		  </text>
		</hbox>
        </vbox>
	  <vbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/network-wireless.png"</input>
		  <action>ktsuss rutilt &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Wireless (rutilt)"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/network-wired.png"</input>
		  <action>gnome-ppp &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Configure Dial-Up Connection"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/preferences-system-firewall.png"</input>
		  <action>gksudo gufw &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Manage Firewall"`"</label>
		  </text>
		</hbox>
	  </vbox>
	</hbox>
	</frame>
  </vbox>

  <vbox>
    <frame>
	<hbox>
	  <vbox>
                <hbox>
		  <button>
		  <input file>"$ICONS/keyboard.png"</input>
		  <action>antixcckeyboard.sh &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Change Keyboard Layout"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/preferences-desktop-wallpaper.png"</input>
		  <action>ktsuss antixccslim.sh</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Change Slim Background"`"</label>
		  </text>
 		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/video-display.png"</input>
		  <action>ktsuss arandr &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Set Screen Resolution"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/computer.png"</input>
		  <action>gksudo geany /etc/desktop-session/desktop-session.conf /etc/desktop-session/startup /etc/desktop-session/file_compare /etc/desktop-session/desktop-defaults.conf &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Global desktop-session configuration"`"</label>
		  </text>
		</hbox>
          </vbox>
	  <vbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/gnome-session.png"</input>
		  <action>gksudo -k update-default-desktop &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Edit Login Options"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/gdm-setup.png"</input>
		  <action>ktsuss slim-login &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Set auto-login"`"</label>
		  </text>
		</hbox>
                <hbox>
		  <button>
		  <input file>"$ICONS/video-display.png"</input>
		  <action>set-screen-blank &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Set Screen Blanking"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/computer.png"</input>
		  <action>geany ~/.desktop-session/desktop-session.conf ~/.desktop-session/startup ~/.desktop-session/file_compare ~/.desktop-session/desktop-defaults.conf &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"User desktop-session configuration"`"</label>
		  </text>
		</hbox>
	  </vbox>
	</hbox>
    </frame>
  </vbox>
  $live_tab
  <vbox>
     <frame>
	<hbox>
	  <vbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/gparted.png"</input>
		  <action>gksudo gparted &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Partition a Drive"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/drive-removable-media.png"</input>
		  <action>mountbox &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Mount Connected Devices"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/file-roller.png"</input>
		  <action>ktsuss luckybackup &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Backup Your System"`"</label>
		  </text>
		</hbox>
       </vbox>
	  <vbox>  
                <hbox>
		  <button>
		  <input file>"$ICONS/drive-removable-media-usb.png"</input>
		  <action>gksudo antix2usb.py &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"antiX2usb"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/drive-harddisk-system.png"</input>
		  <action>$TERM -e su -c partimage &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Image a Partition"`"</label>
		  </text>
		</hbox>
		<hbox>
		  <button>
		  <input file>"$ICONS/preferences-desktop-remote-desktop.png"</input>
		  <action>grsync &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Synchronize Directories"`"</label>
		  </text>
		</hbox>
            </vbox>
	</hbox>
	</frame>
  </vbox>

  <vbox>
    <frame>
	<hbox>
	  <vbox>
                <hbox>
                  <button>
                  <input file>"$ICONS/computer.png"</input>
                  <action>hardinfo &</action>
                  </button>
                  <text use-markup="true" width-chars="25">
                  <label>"`gettext $"System Information"`"</label>
                  </text>
                 </hbox>		
		<hbox>
		  <button>
		  <input file>"$ICONS/printer.png"</input>
		  <action>system-config-printer &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Setup a Printer"`"</label>
		  </text>
		</hbox>
                <hbox>
                  <button>
                  <input file>"$ICONS/computer.png"</input>
                  <action>inxi-gui &</action>
                  </button>
                  <text use-markup="true" width-chars="25">
                  <label>"`gettext $"PC Information"`"</label>
                  </text>
                </hbox>
          </vbox>
	  <vbox>
                <hbox>
		  <button>
		  <input file>"$ICONS/input-mouse.png"</input>
		  <action>antixccmouse.sh &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Configure Mouse"`"</label>
		  </text>
		</hbox>
                 <hbox>
		  <button>
		  <input file>"$ICONS/preferences-desktop-sound.png"</input>
		  <action>$TERM -e speaker-test --channels 2 --test wav --nloops 3 &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Test Sound"`"</label>
		  </text>
		</hbox>
                 <hbox>
		  <button>
		  <input file>"$ICONS/preferences-desktop-sound.png"</input>
		  <action>$TERM -e alsamixer &</action>
		  </button>
		  <text use-markup="true" width-chars="25">
		  <label>"`gettext $"Adjust Mixer"`"</label>
		  </text>
		</hbox>
	  </vbox>
	</hbox>
	</frame>
  </vbox>
  </notebook>
</vbox>
</window>
End_of_Text
)

gtkdialog --program=ControlCenter
unset ControlCenter
