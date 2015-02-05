
antix_specific_code() {
    rm -f /etc/fstab.hotplug
    
    local protect=/etc/live/protect
    mkdir -p $protect
    touch $protect/persist $protect/remaster
    
    # Must exist for samba to work
    [ -d /var/lib/samba ] && echo -n > /var/lib/samba/unexpected.tdb
    
    [ ! -e /etc/localtime ] \
        && /bin/cp --remove-destination $SQFS_MP/etc/localtime /etc/localtime

    rm -f /etc/console/boottime.old.kmap.gz
    /bin/cp --remove-destination $SQFS_MP/etc/console/* /etc/console/ &>/dev/null
    
    local f
    for f in /var/run/utmp /var/run/wtmp /etc/ioctl.save /etc/pnm2ppa.conf; do
        mkdir -p $(dirname $f)
        echo -n > $f
    done
    
    for f in /var/log/apt/history.log /var/log/apt/term.log /var/log/dpkg.log; do
        mkdir -p $(dirname $f)
        [ -e $f ] || touch $f
    done

    mount_tmpfs $NEW_ROOT/media 1 /media
}

antix_specific_code
