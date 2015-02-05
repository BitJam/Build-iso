# System-wide .bashrc file for interactive bash(1) shells.

# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, overwrite the one in /etc/profile)
#PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Commented out, don't overwrite xterm -T "title" -n "icontitle" by default.
# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
#    ;;
#*)
#    ;;
#esac

# enable bash completion in interactive shells
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

#apt-get
alias agu="apt-get update"
alias agd="apt-get dist-upgrade"
alias agc="apt-get clean"
alias ag="apt-get update;apt-get dist-upgrade"

#remaster antiX
alias dn="mount -o remount,dev /dev/sda3"
alias ch="chroot new-squashfs"
alias mp="mount -t proc /proc proc"
alias ms="mount -t sysfs /sys sys"
alias md="mount -t devpts /dev/pts devpts"
alias us="umount -l /sys"
alias up="umount -l /proc"
alias rmn="rm new-squashfs/root/.bash_history"
alias rml="rm new-squashfs/var/lib/apt/lists/*"
alias rmc="rm new-squashfs/var/cache/apt/*.bin"
alias rmd="rm new-squashfs/var/cache/debconf/*-old"
alias rme="rm new-squashfs/etc/group- && rm new-squashfs/etc/gshadow- && rm new-squashfs/etc/passwd- && rm new-squashfs/etc/shadow-"
alias rmi="rm new-squashfs/etc/init.d/*.dpkg-dist"
alias rmt="rm new-squashfs/tmp/*"
alias rmo="rm new-squashfs/var/lib/dpkg/*-old"
alias rmlf="rm new-squashfs/var/log/*.log && rm new-squashfs/var/log/apt/*.log"
alias af="touch new-squashfs/var/log/apt/history.log && touch new-squashfs/var/log/apt/term.log && touch new-squashfs/var/log/dpkg.log"
alias rma="rm new-iso/antiX/linuxfs"
alias mksq="id_version > new-squashfs/etc/live/version/linuxfs.ver && mksquashfs new-squashfs new-iso/antiX/linuxfs && md5sum new-iso/antiX/linuxfs > new-iso/antiX/linuxfs.md5"
alias mkxz="id_version > new-squashfs/etc/live/version/linuxfs.ver && mksquashfs new-squashfs new-iso/antiX/linuxfs -comp xz && md5sum new-iso/antiX/linuxfs > new-iso/antiX/linuxfs.md5"
alias mkgc64="genisoimage -l -V antiXlive -R -J -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.cat -o ../antiX-core-libre-amd64.iso . && isohybrid ../antiX-core-libre-amd64.iso"
alias mkgb64="genisoimage -l -V antiXlive -R -J -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.cat -o ../antiX-base-amd64.iso . && isohybrid ../antiX-base-amd64.iso"
alias mkgf64="genisoimage -l -V antiXlive -R -J -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.cat -o ../antiX-amd64.iso . && isohybrid ../antiX-amd64.iso"
alias mkgc4="genisoimage -l -V antiXlive -R -J -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.cat -o ../antiX-core-libre-486.iso . && isohybrid ../antiX-core-libre-486.iso"
alias mkgb4="genisoimage -l -V antiXlive -R -J -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.cat -o ../antiX-base-486.iso . && isohybrid ../antiX-base-486.iso"
alias mkgf4="genisoimage -l -V antiXlive -R -J -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.cat -o ../antiX-486.iso . && isohybrid ../antiX-486.iso"

alias mkt="genisoimage -l -V antiXlive -R -J -pad -no-emul-boot -boot-load-size 4 -boot-info-table -b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.cat -o ../antiX-test.iso ."
alias ins="dpkg -l>/etc/skel/Documents/installed.txt"
