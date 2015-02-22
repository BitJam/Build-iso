# File: /live/custom/antiX/0.sh
# antiX Specific /init code

LIST_MODULES=true
CHECK_BOOTCODES=true

DO_DEB=true
DO_FSCK=true
DO_XTRA=true
DO_GFX=true

FANCY_PROMPT="prompt-fancy"
AUTO_LOGIN_PROG="autologin"
AUTO_LOGIN_TERMS="2-4"

live_param_filter() {
    local param val disable
    for param; do
        val=${param#*=}

        case $param in
        disable_srv=*|disable_service=*) disable=$val ;;
        ax=*|antiX=*)                    disable=$val ;;
        lean)                           CMD_LEAN=true ;;
        mean)                           CMD_MEAN=true ;;
        Xtralean)                  CMD_XTRA_LEAN=true ;;
        nodbus)                      CMD_NO_DBUS=true ;;

        # Our Live params
        hwclock=utc|hwclock=local) ;;
        amnt|amnt=*|automount|automount=*|confont=*|conkeys=*);;
        desktop=*|dpi=*|drvr=*|fstab=*|hostname=*|kbd=*|kbopt=*|kbvar=*);;
        lang=*|mirror=*|mount=*|noloadkeys|noprompt);;
        nosplash|password|password=*|prompt|pw|pw=*|tz=*|ubp=*|ushow=*);;
        uverb=*|xdrvr=*|xorgconf|xres=*);;

        *) printf "$param " ;;
        esac
    done

    if [ "$disable" ]; then
        # If the ## expression matches then the resulting string length is zero
        [ "${disable##*[lL]*}" ] ||      touch /live/config/lean
        [ "${disable##*[mM]*}" ] ||      touch /live/config/mean
        [ "${disable##*[xX]*}" ] ||      touch /live/config/xtra-lean
        [ "${disable##*[dD]*}" ] ||      touch /live/config/no-dbus
    fi

}
