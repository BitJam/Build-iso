# File: /live/custom/antiX/1.sh 
# antiX Specific /init code to that runs right before
# breakpoint 1

live_param_filter() {
    local param
    for param; do
        case $param in
        # Our Live params
        aX=*|amnt|amnt=*|antiX=*|automount|automount=*|confont=*|conkeys=*);;
        desktop=*|dpi=*|drvr=*|dummy|fstab=*|hostname=*|kbd=*|kbopt=*|kbvar=*);;
        lang=*|lean|mean|mirror=*|mount=*|noRox|nodbus|noloadkeys|noprompt);;
        nosplash|password|password=*|prompt|pw|pw=*|tz=*|ubp=*|ushow=*);;
        uverb=*|xdrvr=*|xorgconf|xres=*|Xtralean);;
        
        *) printf "$param " ;;
        esac
    done
}

# Filter out antiX Live specific bootcodes from UNKNOWN_BOOTCODES
UNKNOWN_BOOTCODES=$(live_param_filter $UNKNOWN_BOOTCODES)
