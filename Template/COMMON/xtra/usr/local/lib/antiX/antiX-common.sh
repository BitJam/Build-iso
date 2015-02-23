
VERSION="0.23"
VDATE="Thu Dec 13 12:02:05 MDT 2012"

# GETTEXT_KEYWORD="gt_ac"
# GETTEXT_KEYWORD="pfgt_ac"
# GETTEXT_KEYWORD="help_error"

RESTORE_LIVE_DIRS="usr/share/antiX-install"
EXCLUDES_DIR=/usr/local/share/excludes
INITRD_CONF=/live/config/initrd.out

antiX_lib=/usr/local/lib/antiX

[ "$Static_antiX_libs" ] || source $antiX_lib/antiX-gui-cli.sh

export TEXTDOMAIN=$(basename $0)
export TEXTDOMAINDIR=/usr/share/locale

# This is needed for restarting
CMDLINE_ARGS=("$@")

       GUI_TERM="x-terminal-emulator"
      TERM_OPTS="--geometry=+50+50 -e"
 TERM_TITLE_OPT="--title"
      GUI_FILER="rox"
     FILER_OPTS="--new -d"

        ARCHIVE="archive"

STD_OPTIONS="
    b,bright||COLOR_BRIGHT
    c,cli|~|GUI
    debug||DEBUG
    dump||DUMP
    dump-all||DUMP_ALL
    g,gui||GUI
    h,help||HELP
    m,mute||COLOR_MUTE
    nolog||NO_LOG
    n,noco,nocolor||COLOR_OFF
    q,quiet||QUIET
    v,verbose||VERBOSE
    no-yad||NO_YAD
"

SIZE_CHOICE="
    128_Meg:128
    256_Meg:256
    320_Meg:320
    512_Meg:512
    768_Meg:768
    1.0_Gig:1024
    1.5_Gig:1536
    2.0_Gig:2048
    2.5_Gig:2560
    3.0_Gig:3072
    4.0_Gig:4096
    6.0_Gig:6144
    8.0_Gig:8192
"

#------------------------------------------------------------------------------
# All of these variables can be over-ridden after sourcing this file (I think).
#------------------------------------------------------------------------------

MOUNT_ERRORS_FATAL="true"

# Note: the -l option seems to nullify the -d option (at least on my Gentoo box)
#UMOUNT_OPTS="-d"
#UMOUNT="umount $UMOUNT_OPTS"
UMOUNT="my_umount"

# Get the name of the program without the path
[ "$ME" ] || ME="$(basename $0)"

TEMP_DIR="/live/tmp/$ME"

CONF_DIR=/live/config


DU_CMD="du --apparent-size"

gt() {
    gettext "$1"
}

pfgt() {
    local fmt="$1" && shift
    printf "$(gettext "$fmt")" "$@"
}


[ "$Static_antiX_Libs" -o "$LOADED_STYLE" ] || \
    source $antiX_lib/antiX-style-default.sh

gt_ac() {
    gettext -d antiX-bash-libs "$@"
}

pfgt_ac() {
    local fmt="$1" && shift
    printf "$(gettext -d antiX-bash-libs "$fmt")" "$@"
}

check_for_yad() {
    [ "$SET_NO_YAD" ] && unset YAD
    [ "$YAD" ]        && return
    [ "$SET_GUI" ]    || return
    if tty | grep -q ^/dev/tty; then
        echo "$ME: $(gt_ac "Switching to CLI mode.")"
        vmsg "$(echo "Switching to CLI mode.")"
        unset SET_GUI
        return
    fi
    which x-terminal-emulator &> /dev/null || exit
    vmsg "$(echo "No yad found.  Trying to open a x-terminal-emulator ...")"
    for arg in ${CMDLINE_ARGS[@]}; do
        args="$args $arg"
    done
    vmsg "x-terminal-emulator --execute bash -c \"$0 $args --cli; bash\""
    clean_up
    x-terminal-emulator --execute bash -c "$0 $args --cli; bash" &>/dev/null &
    exit
}

#===== Usage and Args =========================================================

usage() {
    [ "$USAGE" ] || USAGE="
$(gt "Usage"): [p]$ME[/] [$(gt "options")] $USAGE_ARGS
    $BLURB

[b]$(gt_ac "Standard options"):[/]
    -c|--cli         $(gt_ac "Force command line interface")
    -b|--bright      $(gt_ac "Force console colors to bright")
    -g|--gui         $(gt_ac "Force GUI interface (usually never needed)")
    -h|--help        $(gt_ac "Show this simple help")
    -m|--mute        $(gt_ac "Force console colors to muted/dimmer")
    -n|--nocolor     $(gt_ac "Turn off console colors")
       --nolog       $(gt_ac "Turn off logging")
    -q|--quiet       $(gt_ac "Suppress extra questions and printing")
       --no-yad      $(gt_ac "Pretend yad does not exist")
    -v|--verbose     $(gt_ac "Print more")
$EXTRA_USAGE
[b]$(gt_ac "Debug options"):[/]
    --debug          $(gt_ac "Debug Pango markup sent to yad")
    --dump           $(gt_ac "Show all lower-case globals when done")
    --dump-all       $(gt_ac "Show all globals when done")
"
    make_help "$USAGE"
    exit
}

add_options() {
    STD_OPTIONS="$1 $STD_OPTIONS"
}

read_options() {
    local options="$STD_OPTIONS"
    local param aliases par_type var_name value found par_name dash2

    while [ $# -gt 0 ]; do
        unset found
        for param in $options; do
            aliases=$( echo $param | cut -d"|" -f1)
            par_type=$(echo $param | cut -d"|" -f2)
            var_name=$(echo $param | cut -d"|" -f3)
            for par_name in $(echo $aliases | tr "," " "); do
                dash2=-
                [ ${#par_name} -gt 2 ] && dash2=--
                case "$1" in
                    -$par_name|$dash2$par_name)
                        if [ "$par_type" = "o" -o "$par_type" = "n" ]; then
                            [ "$#" -ge 2 ] \
                                || help_error "option %s requires an argument" "[p]$1[/]"
                            check_numeric $par_name $par_type "$2"
                            eval OPT_$var_name=\"$2\"
                            shift
                        fi
                        ;;
                    -$par_name=*|$dash2$par_name=*)
                        [ "$par_type" = "o" -o "$par_type" = "n" ] \
                            || help_error "option %s does not take an argument" "[p]$par_name[/]"

                        value="$(echo "$1" | sed "s/^--\?$par_name=//")"
                        check_numeric $par_name $par_type "$value"
                        eval OPT_$var_name=\"$value\"
                        ;;
                    *)
                        continue
                        ;;
                esac
                found=true
                if [ "$par_type" = "~" ]; then
                    eval "unset SET_$var_name"
                else
                    eval SET_$var_name=true
                fi
                shift
                break
            done
            [ "$found" ] && break
        done
        if ! [ "$found" ]; then

            # Error out on unknown arg
            expr match "$1" "-" > /dev/null && help_error "unknown argument %s" "[p]$1[/]"
            # Otherwise, we're done
            break
        fi

        # Deal with colors early so they apply when showing help
        case "$par_name" in
            b|bright|m|mute|n|noco|nocolor)
                set_color $par_name
                ;;
        esac

    done

    [ "$SET_HELP" ] && usage
    check_for_yad

    REMAINING_ARGS=("$@")
}

extra_args() {
    local limit="$1"
    local required="$2"
    local cnt=${#REMAINING_ARGS}
    [ "$cnt" -gt "$limit" ]    && help_error "Too many extra arguments: %s" "[p]${REMAINING_ARGS[@]}[/]"
    [ "$required" ]            || return
    [ "$cnt" -lt "$required" ] && help_error "Too few arguments.  Needed at least %s" "[n]$required[/]"
}

check_numeric(){
    [ "$2" = "n" ] || return 0

    echo "$3" | grep -q "^[0-9]*$" && return 0
    help_error "$(pfgt_ac "Expected a numeric value after %s parameter" "[p]$1[/]")"
}

help_error() {
    local fmt="$1" && shift
    local text="$(printf "`gettext -d bash-libs "$fmt"`" "$@")"
    markup_text "$ME:[e] Error:[/] $text. Use [p]-h[/] for help." >&2
    exit 2
}

control_c() {
    dialog_box_cli "yes_no" "$(pfgt_ac "\nDo you really want to quit from %s?" $ME)" && exit 12
}

make_help() {
    local line
    for line in "$(markup_text "$@")"; do
        echo -e "$line" | sed "s/\(^\s*\)\(-[a-z-]\+\)/\1$PARAM_COLOR\2$NO_COLOR/" |
            sed "s/|\(-[a-z-]\+\)/|$PARAM_COLOR\1$NO_COLOR/"
    done
}

#------------------------------------------------------------------------------
# Function: read_conf [-q] [config_file]
#
# Merely sources the config_file.  will use /live/config/$ME.conf if the file
# is not specified.  Normally we give an error if the directory holding the
# the config_file is not found.  If it is found but the file does not exist
# then we return FALSE.
#
# If the -q option is given or $SET_QUIET is true then we exit silently on error.
#
# You MUST either use -q or handle the error when this returns FALSE.
#------------------------------------------------------------------------------
read_conf() {
    if test ! -e $INITRD_CONF; then
        vmsg "Using old initrd interface"
        old_read_conf "$@"
        return $?
    fi
    local conf_dir=$(dirname $INITRD_CONF)

    vmsg "Using new initrd interface"
    local quiet=$SET_QUIET
    [ "$1" = "-q" ] && quiet=true && shift
    local self=$(basename $ME .sh) flag_file=initrd.out
    case $self in
        live-remaster|remaster-live) : ${flag_file:=remasterable} ;;
                       persist-save) : ${flag_file:=save-persist} ;;
    esac

    local full_file=$conf_dir/$flag_file
    if ! [ "$quiet" ]; then
        [ -d "$conf_dir" ] || error_box                                                         \
            "$(pfgt_ac "This script can only be run in a %s environment." "[b]$SYS_TYPE[/b]")"  \
            "$(pfgt_ac "The %s directory does not exist" "[f]$conf_dir[/]")"                    \
            "$(pfgt_ac "indicating this is not a %s environment." "[b]$SYS_TYPE[/b]")"          \
            ""                                                                                  \
            "$(gt_ac "Exiting.")"

        [ -f "$full_file" ] || return 1
    fi

    [ -f "$full_file" ] || vexit "config file: %s not found." "[f]$full_file[/]"

    vpf "reading config file: %s" "[f]$INITRD_CONF[/]"
    source $INITRD_CONF
}

old_read_conf() {
    local quiet=$SET_QUIET
    [ "$1" = "-q" ] && quiet=true && shift

    local conf_file="$1"
    [ "$conf_file" ] || conf_file="$CONF_DIR/$(basename $ME .sh).conf"

    if ! [ "$quiet" ]; then
        local dir=$(dirname $conf_file)
        [ -d "$dir" ] || error_box                                                              \
            "$(pfgt_ac "This script can only be run in a %s environment." "[b]$SYS_TYPE[/b]")"  \
            "$(pfgt_ac "The %s directory does not exist" "[f]$dir[/]")"                         \
            "$(pfgt_ac "indicating this is not a %s environment." "[b]$SYS_TYPE[/b]")"          \
            ""                                                                                  \
            "$(gt_ac "Exiting.")"

        [ -f "$conf_file" ] || return 1
    fi

    [ -f "$conf_file" ] || vexit "config file: %s not found." "[f]$conf_file[/]"

    vpf "reading config file: %s" "[f]$conf_file[/]"
    source $conf_file
}
read_conf_error() {
    local file="$1"
    local script="$2"
    [ "$script" ] || script=$CONF_DIR/$(basename $ME .sh).conf
    error_box \
    "$(pfgt "This script can only be run in a %s environment" "$SYS_TYPE")"            \
    "$(pfgt "where the device holding the %s file can be written to." "[f]$file[/]")"  \
    ""                                                                                 \
    "$(pfgt "The file %s was not found" "[f]$script[/]")"                              \
    "$(pfgt "This indicates that %s can't be run on this system." "$ME")"              \
    ""
}

need_root() {
    [ $UID -eq 0 ] && return
    if [ "$SET_GUI" ] && which gksu &>/dev/null; then
        vmsg "Relaunching as root ..."
        clean_up
        exec gksu -- "$0" "${CMDLINE_ARGS[@]}"
    fi
    error_box "$(gt_ac "Please run this script as root.")"
}

random_hex_32() {
    dd if=/dev/urandom bs=1 count=40 2>/dev/null | md5sum | cut -d" " -f1
}

version_id() {
    echo "==== $(random_hex_32)"
}

delay() {
    local i cnt=$1
    [ "$cnt" -lt 1 ] && return
    printf "delaying %s seconds" $cnt
    for i in $(seq $cnt -1 1); do
        echo -n "."
        sleep 1
    done
    echo
}

I_need_var() {
    local string missing name var where="$1"
    shift

    for name in "$@"; do
        eval "string=\"\$$name\""
        [ "$string" ] && continue
        if [ "$missing" ]; then
            missing="$missing $name"
        else
            missing=$name
        fi
    done

    [ "$missing" ] || return 0

    local msg
    if expr match ".* " "$missing" &>/dev/null; then
        msg="$(pfgt_ac "Variables %s are empty" "[p]$missing[/]")"
    else
        msg="$(pfgt_ac "Variable %s is empty" "[p]$missing[/]")"
    fi
    error_box                                  \
        "$(pfgt_ac "In %s:" "[b]$where[/]")"   \
        "$msg"                                 \
        ""                                     \
        "$(gt_ac "This is a fatal error")"
}

restore_live() {
    local dir dirs="$1"
    [ "$dirs" ] || dirs="$RESTORE_LIVE_DIRS"

    I_need_var "live-common.sh:restore_live()" AUFS_MP SQFS_MP

    for dir in $dirs; do
        local from="$SQFS_MP/$dir"
        [ -e "$from" ] || continue

        vpf "Restoring live from %s" "[f]$from[/]"

        rm -rf $AUFS_MP/$dir
        cp -a $from $AUFS_MP/$dir

        lifo_string TO_DELETE_RF $AUFS_MP/$dir
    done
}

_excludes() {
    local file list_file=$1 dir=$2
    [ -n "${list_file##/*}" ] && list_file=$EXCLUDES_DIR/$list_file
    shift 2

    # append trailing slash to non-empty $dir
    [ -n "${dir%%*/}" ] && dir="$dir/"

    for file in $(grep -v "^\s*#" $list_file | sed -r -e 's=^\s*/=='  -e 's/\s+#.*//') "$@"; do
        echo "$dir$file"
    done
}

rootfs_excludes() {
    _excludes persist-save-exclude.list "$@"
}

remaster_excludes() {
    _excludes live-remaster-exclude.list "$@"
}

#===== Locking ================================================================

create_lock() {

    local lock_prog=lockfile-create
    if ! which $lock_prog &>/dev/null; then
        noisy_yes_no_box -c                                                                         \
            "[title]$TITLE[/]: [w]$(gt_ac Warning)[/]"                                              \
            ""                                                                                      \
            "$(pfgt_ac "The program %s wasn't found so locking won't happen." "[f]$lock_prog[/]")"  \
            ""                                                                                      \
            "$(gt_ac "Do you want to continue anyway?")" || exit
        return
    fi

    local lock_file=$CONF_DIR/locked
    $lock_prog --retry 0 --lock-name $lock_file &>/dev/null || error_box                         \
        "$(pfgt_ac "Another copy of %s is running." "[b]remaster-live[/] or  [b]persist-save[/]")" \
        "$(gt_ac "If you are certain this is not so then delete the file:")"                     \
        "[f]$lock_file[/] $(gt_ac "and try again.")"

    lockfile-touch --lock-name $lock_file &
    LOCK_PID=$!
    LOCK_FILE=$lock_file
    return 0
}

remove_lock() {
    [ "$LOCK_PID" ] && kill $LOCK_PID
    unset LOCK_PID
    [ "$LOCK_FILE" ] || return
    vpf "  Removing lockfile %s" "[f]$LOCK_FILE[/]"
    lockfile-remove --lock-name $LOCK_FILE
    unset LOCK_FILE
}


#===== RAM Space ==============================================================

ram_free() {
    free -m | grep ^Mem | awk '{print $4}'
}

ram_total() {
    free -m | grep ^Mem | awk '{print $2}'
}

#===== Disk Space =============================================================
# Three routines for getting space (in megs) of mounted file systems.
# The input can be the mountpoint or the device

all_space() {
     df -Pm "$1" | awk '{size=$2}END{print size}'
}

used_space() {
     df -Pm "$1" | awk '{size=$3}END{print size}'
}

free_space() {
     df -Pm "$1" | awk '{size=$4}END{print size}'
}

fs_type() {
    df -PmT "$1" | awk '{type=$2}END{print type}'
}

fs_percent() {
    df -Pm "$1" | awk '{percent=$5}END{print percent}'

}
du_size() {
    $DU_CMD -scm "$@" 2>/dev/null | tail -n 1 | cut -f1
}


#===== Mounting ===============================================================

# NOTE: sometimes loopback devices don't show up in /proc/mounts.   In this case
# we use losetup to find the loopback device associated with the filefs and then
# use that loopback device to find the mountpoint. *sigh*
get_mountpoint() {
    local dev="$1"
    #vmsg "get_mountpoint($dev)"
    local mp=$(grep "^$dev " /proc/mounts | cut -d" " -f2)
    #vmsg "get_mountpoint: mp=$mp"
    if [ "$mp" ]; then
        echo $mp
        return
    fi

    #echo "$dev" | grep -q ^/dev && return
    local basename=$(basename $dev)
    local loop=$(losetup -a | grep "($dev)" | cut -d: -f1)
    [ -z "$loop" -a $basename = rootfs ] && loop=$(losetup -a | grep "/$basename)" | cut -d: -f1 | head -n1)
    [ "$loop" ] || return
    grep "^$loop " /proc/mounts | cut -d" " -f2 
}

get_device() {
    grep "^[^ ]* $1 " /proc/mounts | cut -d" " -f1
}

mp_has_param() {
    local param=$(cut -d" " -f2,4 /proc/mounts | grep "^$1 " | cut -d" " -f2)
    case ",$param," in
        *,$2,*) return 0;;
    esac
    return 1
}

is_readonly_mp() {
    mp_has_param $1 ro
    return $?
}

is_readwrite_mp() {
    mp_has_param $1 rw
    return $?
}

is_readonly_device() {
    case "$1" in
        /dev/sr[0-9]*)
            return 0
            ;;
    esac
    return 1
}

#------------------------------------------------------------------------------
# function make_readwrite MOUNT_POINT [no-error-box]
#
# Tries to make device at MOUNT_POINT read-write.  Normally we error out on
# failure but if a 2nd parameter is passed we just return false instead.
#------------------------------------------------------------------------------
make_readwrite() {
    local mp=$1
    is_readwrite_mp $mp && return 0
    mount -o remount,rw $mp
    if ! is_readwrite_mp $mp; then
        [ "$2" ] && return 2
        error_box "$(pfgt_ac "Could not make %s read-write" "[f]$mp[/]")"
    fi

    # Record for later making read-only
    lifo_string TO_READ_ONLY $mp
    return 0
}

mount_error() {
    if [ "$MOUNT_ERRORS_FATAL" ]; then
        error_box "$@"
    else
        warn_box "$@"
    fi
}

fatal_mount_errors() {
    MOUNT_ERRORS_FATAL="true"
}

nonfatal_mount_errors() {
    unset MOUNT_ERRORS_FATAL
}

mount_if_needed() {
    # set $mp to last param and $dev to next-to-last param.  This way we can
    # mimic the order of params to the normal mount command.
    local mp idx dev
    mp="$(eval echo \$$#)"
    idx=$(( $# - 1))
    dev="$(eval echo \$$idx)"

    if ! [ -e "$dev" ]; then
        mount_error "$(pfgt "%s is not a device or a file" "[f]$dev[/]")"
        return
    fi

    if ! [ -d "$mp" ]; then
        vpf "Creating mountpoint directory: %s" "[f]$mp[/i]"
        if ! mkdir -p $mp; then
            mount_error "$(pfgt_ac "Could not create the %s mountpoint." "[f]$mp[/]")"
            return
        fi
    fi

    local exist_mp=$(get_mountpoint $dev)
    if [ "$exist_mp" ]; then
        #  If $dev was already mounted at $mp then there's nothing to do.
        [ "$exist_mp" = "$mp" ] && return
        vpf "Device %s was already mounted at %s.  Bind mounting at %s" "[f]$dev[/]" "[f]$exist_mp[/]" "[f]$mp[/]"
        if ! mount -o bind $exist_mp $mp; then
            mount_error "$(pfgt_ac "Could not bind mount %s to %s." "[f]$exist_mp[/f]" "[f]$mp[/]")"
            return
        fi
    else
        if ! mount "$@"; then
            mount_error "$(pfgt_ac "Could not mount %s at %s."  "[f]$dev[/]" "[f]$mp[/]")"
            return
        fi
        vpf "mounted %s at %s." "[f]$dev[/]" "[f]$mp[/]"
    fi

    # Record for later umounting
    lifo_string TO_UMOUNT $mp
}

my_umount() {
    umount "$1" &>/dev/null || umount -l "$1"
}

# mount_any() {
#     mount -t vfat -o umask=000,shortname=winnt,rw  "$1" "$2" &>/dev/null || \
#         mount -t iso9660                    -o ro  "$1" "$2" &>/dev/null || \
#             ntfs-3g -o umask=000,force,rw          "$1" "$2" &>/dev/null || \
#             mount -t ntfs -o umask=000,ro          "$1" "$2" &>/dev/null || \
#                 mount -t reiserfs            -o rw "$1" "$2" &>/dev/null || \
#                     mount -t ext4            -o rw "$1" "$2" &>/dev/null || \
#                         mount -t ext3        -o rw "$1" "$2" &>/dev/null || \
#                             mount -t ext2    -o rw "$1" "$2" &>/dev/null
#     return "$?"
# }
# 
# mount_file() {
#     mount -t reiserfs         -o loop,rw "$1" "$2"  2>/dev/null || \
#         mount -t ext4         -o loop,rw "$1" "$2"  2>/dev/null || \
#             mount -t ext3     -o loop,rw "$1" "$2"  2>/dev/null || \
#                 mount -t ext2 -o loop,rw "$1" "$2"  2>/dev/null
#     return "$?"
# }
# 
# 
# mount_any_if_needed() {
#     mount_X_if_needed "any" "$@"
# }
# 
# mount_file_if_needed() {
#     "file" "$@"
# }
# 
# mount_X_if_needed() {
#     local type="$1"
#     local dev="$2"
#     local mp="$3"
# 
#     if ! [ -d "$mp" ]; then
#         vpf "Creating mountpoint directory: %s" "[f]$mp[/i]"
#         mkdir -p $mp || error_box "$(pfgt_ac "Could not create the %s mountpoint." "[f]$mp[/]")"
#     fi
# 
#     local exist_mp=$(get_mountpoint $dev)
#     if [ "$exist_mp" ]; then
#         #  If $dev was already mounted at $mp then there's nothing to do.
#         [ "$exist_mp" = "$mp" ] && return
#         vpf "Device %s was already mounted at %s.  Bind mounting at %s" "[f]$dev[/]" "[f]$exist_mp[/]" "[f]$mp[/]"
#         mount -o bind $exist_mp $mp || error_box "$(pfgt_ac "Could not bind mount %s to %s." "[f]$exist_mp[/f]" "[f]$mp[/]")"
#     else
#         if [ "$type" = "any" ]; then
#             mount_any $dev $mp || error_box "$(pfgt_ac "Could not mount %s at %s."  "[f]$dev[/]" "[f]$mp[/]")"
# 
#         elif [ "$type" = "file" ]; then
#             mount_file $dev $mp || error_box "$(pfgt_ac "Could not mount file %s at %s."  "[f]$dev[/]" "[f]$mp[/]")"
# 
#         else
#             error_box "$(pfqt "Unknown type: %s sent to %s" "[n]$type[/]" "[f]mount_X_if_needed[/]")"
#         fi
# 
#         vpf "mounted %s at %s." "[f]$dev[/]" "[f]$mp[/]"
#     fi
#     # Record for later umounting
#     lifo_string TO_UMOUNT $mp
# }


mount_squashfs() {
    mount -o loop,ro -t squashfs "$1" "$2"
    local ret=$?
    [ "$ret" = "0" ] && lifo_string TO_UMOUNT $2
    return $ret
}

mount_squashfs_temp() {
    local file="$1"
    local dir=$(make_temp_dir)

    mount_squashfs $file $dir
    local ret=$?

    while true; do
        vpf "umounting %s" "[f]$file[/]"

        mountpoint -q $dir || break
        sleep 1
        my_umount $dir

        mountpoint -q $dir || break
        sleep 1
        my_umount $dir

        mountpoint -q $dir || break
        error_box "$(pfgt_ac "Could not umount %s" "[f]$dir[/]")"
        break
    done

    rmdir $dir
    return $ret
}

restore_readonly() {
    for mp in $TO_READ_ONLY; do
        mountpoint -q $mp || continue
        mount -o remount,ro  $mp
    done
    unset TO_READ_ONLY
}

restore_umount() {
    for mp in $TO_UMOUNT; do
        mountpoint -q  $mp || continue
        vmsg "  umounting [f]$mp[/]"
        my_umount $mp
    done
    unset TO_UMOUNT
}

delete_files() {
    local file
    for file in $TO_DELETE; do
        if [ -d "$file" ]; then
            vpf "deleting directory %s" "[f]$file[/]"
            rmdir $file
            continue
        fi
        if [ -e "$file" ]; then
            vpf "deleting file %s" "[f]$file[/]"
            rm -f $file
        fi
    done
    unset TO_DELETE
}

delete_files_rf() {
    local file
    for file in $TO_DELETE_RF "$@"; do
        [ -e "$file" ] || continue
        vpf "deleting -rf %s" "[f]$file[/]"
        rm -rf --one-file-system "$file"
    done
}

clean_up() {
    vmsg "$(echo "[w]Cleaning up ...[/]")"

    kill_bg_info_box -f

    restore_umount
    restore_readonly
    delete_files

    if [ -d "$TEMP_DIR" ]; then
        for f in $TEMP_DIR/*; do
            if  mountpoint &>/dev/null $f; then
                vmsg "Last ditch umount [f]$f[/]"
                my_umount $f
            fi
        done
    fi

    delete_files_rf $TEMP_DIR
    remove_lock

    [ "$SET_DUMP_ALL" ] && printenv | sed "s/^\([A-Za-z_]\+\)/$PARAM_COLOR\1$NO_COLOR/"
    [ "$SET_DUMP"     ] && printenv | grep "^[a-z][a-z_]*="    | sed "s/^\([a-z_]\+\)/$PARAM_COLOR\1$NO_COLOR/"
    return 0
}

#------------------------------------------------------------------------------
# function lifo_string NAME NEW
#
# We are given the NAME of a variable and a new item to add to a space
# delimited list in that variable.  Used for remembering what mountpoints
# to umount, what ones to restore_readonly, etc.
#------------------------------------------------------------------------------
lifo_string() {
    local new string var="$1" && shift
    eval "string=\"\$$var\""
    for new in "$@"; do    # Prevent dupes
        case " $string " in
            *\ $new\ *) continue ;;
        esac
        string="$new $string"
    done
    eval "$var=\"$new $string\""
    return 0
}

find_files() {
    local name ext dir="$1" names="$2" exts="$3"
    for name in $names; do
        for ext in $exts; do
            [ -e "$dir/$name.$ext" ] && echo "$name.$ext"
        done
    done
}

save_or_delete() {
    local full dir="$1" file="$2"
    full="$dir/$file"
    if ! [ -e "$full" ]; then
        warn "$(pfgt_ac "Strange.  File %s does not exit." "[f]$full[/]")"
        return 0
    fi

    local file_size=$(du_size $full)

    # Make sure we can mount the file
    local can_mount=true
    while true; do
        mount_squashfs_temp $full && break
        unset can_mount
        yes_no_box "[w]$(gt_ac "Warning")[/]"                          \
        ""                                                             \
        "$(pfgt_ac "the file %s cannot be mounted." "[f]$full[/]")"    \
        "$(fmt_size "`gt_ac "size"`" $file_size)"                      \
        ""                                                             \
        "$(gt_ac "Should it be deleted?")" || break

        vpf "deleting %s" "[f]$full[/]"
        rm -f $full
        return
    done

    local choice
    local delete_it="$(gt_ac "Delete it")"
    local save_it="$(gt_ac   "Save it")"
    local view_it="$(gt_ac   "View info")"
    local quit="$(gt_ac      "Quit")"

    case "$file" in
        *.bad|*.tmp)
            choice="$delete_it!$save_it"
            ;;
        *)
            choice="$save_it!$delete_it"
            ;;
    esac

    ext_fmt="[fixed][b]%s[/][/]: %s"
    [ "$can_mount" ] && choice="$choice!$view_it"
    choice="$choice!$quit"
    while true; do
        combo_box $file "$choice" -a                                                            \
            "$(center "[title]`gt_ac "Cleaning up"`[/]")"                                       \
            "$(center [f]$dir[/])"                                                              \
            ""                                                                                  \
            "`pfgt_ac "What should we do with %s ?" "[f]$file[/]"`"                             \
            "$(fmt_size "`gt_ac "size"`" $file_size)"                                           \
            ""                                                                                  \
            "$(pf "$ext_fmt" ".bad" "`gt_ac "Left over from a rollback.  Normally delete."`")"  \
            "$(pf "$ext_fmt" ".new" "`gt_ac "A remaster you made without rebooting."`")"        \
            "$(pf "$ext_fmt" ".old" "`gt_ac "Previous squashfs file.  Save or delete."`")"      \
            "$(pf "$ext_fmt" ".tmp" "`gt_ac "An incomplete remaster."`")"                       \
            ""                                                                                  \
            "`gt_ac "Select an action:"`"

        case "$UI_RESULT" in
            $save_it)
                archive_master $dir $file
                ;;
            $delete_it)
                vmsg "deleting [f]$full[/]"
                rm -f $full
                ;;
            $view_it)
                view_vid_info $full
                continue
                ;;
            $quit)
                vexit "At user request within save_or_delete()"
                ;;
            *)
                error_box_pf "Bad save_or_delete() choice: %s" "$UI_RESULT"
        esac
        break
    done
}

view_vid_info() {
    local info="$(get_vid_info $1 | sed  "s=^\(\w[[:alnum:]_ -]*\):=[p]\1:[/]=" )"
    local retval=$?
    okay_box -o --width=800 -o --height=300      \
        "[title]$(gt_ac "Version info for")[/]"  \
        "[f]$1[/]"                               \
        ""                                       \
        "$info"                                  \
        ""
}

get_vid_info() {
    file="$1" dir=$(make_temp_dir)
    mount_squashfs $file $dir || return 1

    local info line vid ret=2
    if [ -r "$dir/$VID_FILE" ]; then
        ret=0
        while read line; do
            if expr match "$line" "^====" &>/dev/null; then
                VID_FROM_FILE="$line"
                info=();
            else
                # append to end of info array
                info[${#info[*]}]="$line"
            fi
        done < $dir/$VID_FILE

        for line in "${info[@]}"; do
            echo "$line"
        done
    fi
    my_umount $dir || return 3
    rmdir $dir
    return $ret
}

archive_master() {
    local bdir="$1" file="$2"
    local adir="$bdir/$ARCHIVE"
    mkdir -p $adir

    local dir max=0
    for dir in $(ls $adir); do
        echo $dir | grep -q "^[0-9]\+$" || continue
        [ "$max" -lt "$dir" ] && max="$dir"
    done
    max=$(( $max + 1 ))
    local dest=$adir/$(printf "%04d" $max)
    vpf "creating archive directory %s" "[f]$dest[/]"
    mkdir -p $dest

    vpf "Archiving %s" "[f]$file[/]"

    mv $bdir/$file $dest

    local temp_dir=$(make_temp_dir)
    if mount_squashfs $dest/$file $temp_dir; then
        if [ -e "$temp_dir/$VID_FILE" ]; then
            vpf "Archiving VID file %s" "[f]$VID_FILE[/]"
            cp $temp_dir/$VID_FILE $dest
        else
            gt_ac "No VID file" >> $dest/error
        fi
        my_umount $temp_dir
        rmdir $temp_dir
    else
        pfgt_ac "Could not mount %s" "$file" >> $dest/error
    fi
}

make_temp_dir() {
    mkdir -p $TEMP_DIR
    local temp_dir
    if [ "$1" ]; then
        temp_dir=$(mktemp -d $TEMP_DIR/$1-XXXXXX)
    else
        temp_dir=$(mktemp -d $TEMP_DIR/XXXXXX)
    fi
    lifo_string TO_DELETE $temp_dir
    echo $temp_dir
}


push_array() {
    local name=$1 && shift
    local el
    for el in "$@"; do
        eval "$name[\${#$name[*]}]='$el'"
    done
}

min_of() {
    local min="$1"; shift
    for num in "$@"; do
        [ "$num" -lt "$min" ] && min=$num
    done
    echo $min
}

max_of() {
    local max="$1"; shift
    for num in "$@"; do
        [ "$num" -gt "$max" ] && max=$num
    done
    echo $max
}

select_size() {
    local min max use_max
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -min) min=$2 && shift 2;;
            -max) max=$2 && shift 2;;
            -Max) max=$2 && use_max="true" && shift 2;;
             *)  break;;
        esac
    done
    [ "$min" ] || min=0
    vmsg "select_size: min=[n]$min[/] max=[n]$max[/]"
    options="$SIZE_CHOICE"
    local choice size str size_str

    for size_str in $options; do
        str=$( echo $size_str | cut -d: -f1 | tr "_"  " ")
        size=$(echo $size_str | cut -d: -f2)

        [ "$min" -a "$size" -lt "$min" ] && continue

        local max_choice="$max Meg"
        if [ "$size" -ge "$max" ]; then
            [ "$use_max" ] && choice="$choice!$max_choice"
            break
        fi

        choice="$choice!$str"
    done

    [ "$choice" ] || return 1
    local custom_choice="$(gt "Custom size")"
    choice="$choice!$custom_choice"

    combo_box "size" "$choice" "$@"

    case "$UI_RESULT" in
        "$max_choice")
            UI_RESULT="$max"
            return 0
            ;;
        "$custom_choice")
            get_custom_size "$min" "$max"
            return
            ;;
    esac
    
    for size_str in $options; do
        str=$( echo $size_str | cut -d: -f1  | tr "_"  " ")
        size=$(echo $size_str | cut -d: -f2)
        [ "$str" = "$UI_RESULT" ] || continue
        UI_RESULT=$size
        return 0
    done

    error_box "$(pfgt_ac "Strange.  Could not find a string matching \"%s\"." "$UI_RESULT")"
}

get_custom_size() {
    local min="$1"
    local max="$2"
    local min_lab="$(gt "none")"
    local max_lab="$(gt "none")"
    [ "$min" ] && min_lab="[n]$min[/]"
    [ "$max" ] && max_lab="[n]$max[/]"

    local error="[e]$(gt "Error"):[/] "
    local error_msg=()
    while true; do
        get_text "$TITLE"  ""  -q                     \
            "${error_msg[@]}"                         \
            "$(gt "Please enter a custom size:")"     \
            "$(pfgt "Minimum size: %s" "$min_lab")"   \
            "$(pfgt "Maximum size: %s" "$max_lab")" ""

        local size="$UI_RESULT"

        if ! echo $UI_RESULT | grep -q '^[0-9]\+$'; then
            error_msg=("$error$(pfgt "%s is not a number" "[n]$size[/]")")
        elif [ "$min" -a "$size" -lt "$min" ]; then
            error_msg=("$error$(pfgt "%s is below the minium" "[n]$size[/]")")
        elif [ "$max" -a "$size" -gt "$max" ]; then
            error_msg=("$error$(pfgt "%s is above the maximum" "[n]$size[/]")")
        else
            return
        fi
    done
}


select_device() {

    local all mounted unmounted device title notitle text
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -m)  mounted=true   && shift;;
            -u)  unmounted=true && shift;;
            -a)  all=true       && shift;;
            --)  notitle=true   && shift;;
             *)  break;;
        esac
    done
    [ "$notitle" ] || title="$1" && shift

    [ "$title" -a    "$SET_GUI" ] && text="$(ctitle "$title")$text"
    [ "$title" -a -z "$SET_GUI" ] && text="$(concat_strings -t "[title]$title[/]")$text"

    text=("${text[@]}" "" "$(gt_ac "Select which devices to choose from"):   ")

    local all_dev="$(gt_ac "All")"
    local mounted_dev="$(gt_ac "Mounted")"
    local unmounted_dev="$(gt_ac "Unmounted")"

    while ! [ "$mounted" -o "$all" -o "$unmounted" ]; do
        combo_box "$(gt_ac "devices")" "$all_dev!$mounted_dev!$unmounted_dev" -a "${text[@]}"
        case "$UI_RESULT" in
                  $all_dev)  all=true ;;
              $mounted_dev)  mounted=true ;;
            $unmounted_dev)  unmounted=true ;;
        esac
    done

    local text line
    text="$(concat_strings "$@")"

    if [ "$SET_GUI" ]; then
        local ok_str="`gt_ac "OK"`"
        ok_str="$(echo "[b]$ok_str[/]" | sed "$PANGO_MARKUP")"
        text="$text\n\n$(pfgt_ac "Click on a device then hit %s" "$ok_str")"
    fi

    [ "$title" ] && text="$(center_strings "[title]$title[/]")\n$text"

    local rootdev=$(readlink -f /dev/root)

    local device_lab="$(gt_ac "Device")"
    local mount_lab="$(gt_ac "Mount")"
    local type_lab="$(gt_ac "Type")"
    local label_lab="$(gt_ac "Label")"
    local size_lab="$(gt_ac "Size")"
    local free_lab="$(gt_ac "Free")"

    local sep="|"
    unset UI_RESULT
    while ! [ "$UI_RESULT" ]; do
        if [ "$SET_GUI" ]; then
            local result=$(device_info "\n" "$mounted" "$unmounted" | while read line; do
                echo -e "$line"
            done | $YAD $YAD_STD_OPTS $YAD_DEVICE_OPTS  \
                --text "$text"                          \
                --list                                  \
                --column="$device_lab"                  \
                --column="$type_lab"                    \
                --column="$label_lab"                   \
                --column="$mount_lab"                   \
                --column="$size_lab"                    \
                --column="$free_lab"                    \
            )

            [ "$result" ] || confirm_quit

            UI_RESULT=$(echo "$result" | cut -d"|" -f1)

        else

            echo "$text"
            local format="[p]%-12s[/] %-8s [b]%-15s[/] [f]%-12s[/] [n]%8s[/] [n]%8s[/]\n"
            local lab_format="$(echo "$format" | sed 's/\[.\]//g')"

            echo "$PARAM_COLOR$UNDERLINE"
            printf "    $lab_format" "$device_lab" "$type_lab" "$label_lab" "$mount_lab" "$size_lab" "$free_lab"
            echo -n "$NO_COLOR"
            format="$(markup_text "$PROMPT_COLOR%2s[/]) $format")"
            local cnt=0
            local choice_array

            # This funny construct with the _device_info at the bottom of the loop allows
            # me to do assignments inside the "while read" loop that I can use outside.
            while read line; do
                cnt=$(( $cnt + 1 ))
                choice_array[$cnt]=$(echo "$line" | cut -d"|" -f1)

                IFS="|"
                printf "$format" $cnt $line
                unset IFS
            done <<End_While_Read
$(device_info "|" "$mounted" "$unmounted")
End_While_Read

            select_choice_cli -q "${choice_array[@]}"

        fi
    done

    return 0
}

#------------------------------------------------------------------------------
# Function: device_info $sep $mounted $umounted
#
# Echoes properties of /dev/sd and /dev/hd devices one device per line with the
# entrie seperated by $sep.  The default is to print info for all devices.
# If $mounted   is true but not $unmounted only   mounted devices are shown.
# If $unmounted is true but not $mounted   only unmounted devices are shown.
#------------------------------------------------------------------------------
device_info() {
    local sep="$1"  mounted="$2" unmounted="$3"

    local dev attribs LABEL UUID TYPE PTTYPE SEC_TYPE PARTUUID PARTLABEL
    blkid | while read dev attribs; do
        dev=${dev%:}
        case "$dev" in
            /dev/sd[a-z][0-9]*|/dev/hd[a-z][0-9]*)  ;;
                                                *)  continue;;
        esac

        TYPE= ; LABEL= ;

        eval "$attribs"

        [ "$TYPE" = "swap" ] && continue

        if [ "$dev" = "$rootdev" ]; then
            mount=$(grep "^/dev/root " /proc/mounts | head -n1 | cut -d" " -f2)
        else
            mount=$(grep "^$dev "      /proc/mounts | head -n1 | cut -d" " -f2)
        fi

        [    "$mount" -a -z "$mounted" -a    "$unmounted" ] && continue
        [ -z "$mount" -a    "$mounted" -a -z "$unmounted" ] && continue

        local size= free=
        [ "$mount" ] && size=$(df -Ph $mount | awk '{size=$2}END{print size}')
        [ "$mount" ] && free=$(df -Ph $mount | awk '{size=$4}END{print size}')

        echo -e "$dev${sep}$TYPE${sep}$LABEL${sep}$mount${sep}$size${sep}$free"
    done
}

explore_dir() {
    local dir="$1"
    shift;

    if [ "$SET_GUI" ]; then
        #bg_info_box -o --undecorated "$TITLE" "" "$@"
        bg_info_box "$TITLE" "" "$@"
        $GUI_FILER $FILER_OPTS $dir
        kill_bg_info_box
    else
        #markup_text "$@"
        local prompt
        for line in "$@"; do
            prompt="$prompt$(markup_text "$line")$NO_COLOR\n"
        done
        
        prompt="$prompt$RED$ME$GREEN>$NO_COLOR "
        echo "$(pfgt_ac "Use the \"exit\" command to return to %s" "$ME")"
        (
            cd $dir;
            PS1="$prompt" bash --norc -i
        )
    fi
}


# # FIXME: this routine is broken
# fix_it_yourself() {
#     local dir="$1"
#     shift;
# 
#     #noisy_yes_no_box "$@" "" "$(gt_ac "Do you want to try to fix this problem yourself?")" || exit
# 
#     if [ "$SET_GUI" ]; then
# 
#         $GUI_FILER $FILER_OPTS $dir
#     else
#         echo "$(pfgt_ac "Use the \"exit\" command to return to %s" "$ME")"
#         (cd $dir && export PS1="$ME> " bash)
#     fi
#     # Restart this program
#     exec $0 "${CMDLINE_ARGS[@]}"
#     vexit "should never get here"
# }


