
# GETTEXT_KEYWORD="gt_gp"

LANG_CONFIG_FILE=/etc/live/config/language.conf
DISABLED_RC_DIR=/etc/live/disabled-rc.d

PROTECT_DIR=/etc/live/protect
PERSIST_PROTECT_FILE=$PROTECT_DIR/persist
REMASTER_PROTECT_FILE=$PROTECT_DIR/remaster

INIT_LOG_FILE=/var/log/antiX/antiX-boot.log

export TEXTDOMAIN=$(basename $0)
export TEXTDOMAINDIR=/usr/share/locale

gt() {
    gettext "$1"
}

pfgt() {
    local fmt="$1" && shift
    printf "$(gettext "$fmt")" "$@"
}


gt_gp() {
    gettext -d antiX-bash-libs "$1"
}

#COLOR_LOW=true

[ "$CMDLINE" ] || CMDLINE="$(cat /proc/cmdline)"
for PARAM in $CMDLINE; do
    case "$PARAM" in
        noco|nocolor) COLOR_OFF=true;;
       loco|lowcolor) COLOR_LOW=true;;
      hico|highcolor) unset COLOR_LOW;;
               nolog) unset INIT_LOG_FILE;;
             antiX=*) ANTIX_PARAM=$( echo $PARAM | sed "s/antiX=//" | tr "[a-z]" "[A-Z]");;
    esac
done

if [ "$ANTIX_PARAM" ]; then
    expr match $ANTIX_PARAM ".*L" > /dev/null && CMDLINE="$CMDLINE lean"
    expr match $ANTIX_PARAM ".*X" > /dev/null && CMDLINE="$CMDLINE Xtralean"
    expr match $ANTIX_PARAM ".*M" > /dev/null && CMDLINE="$CMDLINE mean"
    expr match $ANTIX_PARAM ".*D" > /dev/null && CMDLINE="$CMDLINE nodbus"
fi

if ! [ "$COLOR_OFF" ]; then
    NO_COLOR="[0m"
    RED="[1;31m"
    GREEN="[1;32m"
    YELLOW="[1;33m"
    BLUE="[1;34m"
    MAGENTA="[1;35m"
    CYAN="[1;36m"
    WHITE="[1;37m"
    AMBER="[0;33m"
    [ "$INIT_LOG_FILE" ] && INIT_LOG_FILE_COLOR=$INIT_LOG_FILE.color
fi

if [ "$COLOR_LOW" ]; then
    ANTIX_COLOR="$WHITE"
    LIVE_COLOR="$AMBER"
    PARAM_COLOR="$WHITE"
    SCRIPT_COLOR="$GREEN"
    SCRIPT_PARAM_COLOR="$WHITE"
    ERROR_PARAM_COLOR="$RED"
else
    ANTIX_COLOR="$GREEN"
    LIVE_COLOR="$CYAN"
    PARAM_COLOR="$YELLOW"
    SCRIPT_COLOR="$GREEN"
    SCRIPT_PARAM_COLOR="$CYAN"
    ERROR_PARAM_COLOR="$RED"
fi

pquote() {
   echo "$PARAM_COLOR$@$LIVE_COLOR"
}

paren() {
    echo "($SCRIPT_COLOR$@$LIVE_COLOR)"
}

start_init_logging() {
    is_boot_param nolog         && return
    [ "$STARTED_INIT_LOGGING" ] && return
    [ "$INIT_LOG_FILE" ]        || return

    mkdir -p $(dirname $INIT_LOG_FILE)

    if [ "$INIT_LOG_FILE_COLOR" ]; then
        # tee stderr to log file.  Don't remove the space.
        exec 2> >(tee -a $INIT_LOG_FILE | tee -a $INIT_LOG_FILE_COLOR)
    else
        exec 2> >(tee -a $INIT_LOG_FILE)
    fi

    STARTED_INIT_LOGGING="true"
}

log_msg() {
    echo -e "$@"
    [ "$INIT_LOG_FILE" ] || return
    echo -e "$@" | sed -r "s:\x1B\[[0-9;]*[mK]::g" >> $INIT_LOG_FILE
    [ "$INIT_LOG_FILE_COLOR" ] && echo -e "$@"     >> $INIT_LOG_FILE_COLOR
}

echo_live() {
    local fmt="$(gettext "$1")" && shift
    local msg="$(printf "$fmt" "$@")"
    log_msg "$(date):   $LIVE_COLOR$msg$NO_COLOR"
}

error() {
    log_msg "${ERROR_COLOR}`gt_gp Error`:$NO_COLOR$@$NO_COLOR"
}

echo_script() {
    local msg="$(gettext "$1")"
    local script=$(basename $2)

    [ "$INIT_LOG_FILE" ] && echo \
        "--------------------------------------------------------------------" >> $INIT_LOG_FILE
    [ "$INIT_LOG_FILE_COLOR" ] && echo \
        "--------------------------------------------------------------------" >> $INIT_LOG_FILE_COLOR

    log_msg "$(date): $SCRIPT_COLOR$script$NO_COLOR: $SCRIPT_PARAM_COLOR$msg$NO_COLOR"
}

is_boot_param() {
   local param
   for param in $CMDLINE; do
        case "$param" in
            $1|$1=*)
                return 0
                ;;
        esac
    done
    return 1
}

get_boot_param() {
    local param
    for param in $CMDLINE; do
        case "$param" in
            $1=*)
                echo "$param" | sed "s/^$1=//"
                return 0
                ;;
        esac
    done
    return 1
}

should_run_shutdown() {
    local flag="$1" prog="$2"

    # Return true if boot param is missing
    is_boot_param "$flag"  || return 0

    # Return true if program is running
    ps -U root -o cmd | grep "^$prog" && return 0

    # If flag is set and program is not running return false
    return 1
}

get_linuxrc_param() {
    local name="$1" file="$2"
    [ "$file" ] || file="/live/config/linuxrc.out"
    grep "^\s*$name=" $file | sed 's/^[a-zA-Z_]\+="\(.*\)"/\1/';
}

set_linuxrc_variable() {
    local name="$1" file="$2" var="$3"
    [ "$var" ] || var="$name"
    local param="$(get_linuxrc_param $name)"
    eval "$var=\"$param\""
}

persist_enabled() {
    local quiet
    [ "$1" = "-q" ] && quiet=true && shift
    local type="$1" persistence="$(get_linuxrc_param PERSISTENCE)"
    case ",$persistence," in
        *,$type,*)
            [ "$quiet" ] || echo "yes"
            return 0
            ;;
    esac
    return 1
}

was_installed() {
    local quiet
    [ "$1" = "-q" ] && quiet=true && shift
    case "$(readlink -f /dev/root)" in
        /dev/hd*|/dev/sd*)
            [ "$quiet" ] || echo "yes"
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

#------------------------------------------------------------------------------
# Function: first_write unique-flag
#
# Decide if a config file should be updated or protected/preserved.  If The
# unique flag (usually the absolute path of the config file) is not in either
# of the protect files then we return true, signaling that the file should be
# initialized.
#
# The idea is that some config files should only be intialized once if
# persistence is enabled.  If a boot parameter is specifically given then we
# will update the file anyway.
#
# DOES NOT COMMUTE!  Should be after all ANDs and before all ORs.
#------------------------------------------------------------------------------

first_write() {
    local flag="$1" && shift

    if ! grep -q "^$flag$" $PERSIST_PROTECT_FILE &> /dev/null; then
        echo "$flag" >> $PERSIST_PROTECT_FILE

        grep -q "^$flag$" $REMASTER_PROTECT_FILE &> /dev/null || return 0
    fi

    return 1
}

if [ -r "$LANG_CONFIG_FILE" ]; then
    . $LANG_CONFIG_FILE
    export LANG
fi

unset PARAM ANTIX_PARAM COLOR_OFF COLOR_LOW
