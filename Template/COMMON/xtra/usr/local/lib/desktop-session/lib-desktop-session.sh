
ME=${0##*/}

PATH=.:$PATH

. /usr/local/lib/desktop-session/lib-popup-window.sh
. /usr/local/lib/desktop-session/desktop-session-file-locations.sh

icon_managers=rox,space
rox_enabled=fluxbox,icewm,jwm,openbox
space_enabled=fluxbox,icewm,jwm,openbox
rox_manager='rox --pinboard=antiX-${code##rox-}'
space_manager='spacefm --desktop &'
non_autostart=fluxbox,icewm,jwm
fallback_desktop="rox-fluxbox"
fallback_wmx="/usr/bin/icewm-session /usr/bin/startfluxbox"
signal_files="$gpid_file $ppid_file $restart_file $desktop_file"
signal_files="$signal_files $icon_pid_file $cycle_file"
stale_time=10

kill_wait=3
debug=true
               
echo_im_desktops() {
    case $1 in
    rox)
        echo "$rox_enabled";
    ;;
    rox-cmd)
        echo "$rox_manager";
    ;;
    space)
        echo "$space_enabled";
    ;;
    space-cmd)
        echo "$space_manager";
    ;;
    *)
        echo "Unknown option:";
        echo "rox       -> list rox enabled desktops";
        echo "rox-cmd   -> list rox desktop command";
        echo "space     -> list space enabled desktops";
        echo "space-cmd -> list space desktop command";
    ;;
    esac
}

fatal() {
    echo "$ME: Fatal Error: $*"
    exit 2
}

warn()  { echo "$ME: Warning: $*"           ; }
say()   { echo "$ME: $*"                    ; }
log()   { echo "$ME: $*" >> $log_file       ; }
shout() { echo "$ME: $*" | tee -a $log_file ; }
psay()  { say "$(plural "$@")"              ; }

echo_variable() {
	echo "$ME: Setting environment variable: $*"
	export "$@"
}

echo_cmd() {
    echo "$ME: run: $*"
    "$@"
}

echo_eval_cmd() {
    echo "$ME: run: eval $*"
    eval "$@" &
}

echo_bg_cmd() {
    echo "$ME: run: $* &"
    "$@" &
}

read_file() {
    local file=$1
    local data=$(cat $file 2>/dev/null)
    #rm -f $file
    echo $data
    [ "$data" ]
    return $?
}

plural() {
    local n=$1 str=$2
    case $n in
        1) local s=  ies=y   are=is    have=has;;
        *) local s=s ies=ies are=are   have=have;;
    esac
    echo "$str" | sed -e "s/%s/$s/g" -e "s/%ies/$ies/g"  \
        -e "s/%are/$are/g" -e "s/%have/$have/" -e "s/%n/$n/g"
}

# AFAIK, this is not needed
save_icon_pid() {
    local pid=$!
    say "icon pid: $pid"
    echo $pid > $icon_pid_file
}

#------------------------------------------------------------------------------
# Function: find_my_procs <process-name>
#
# Return list of pids for process named <process-name> that are owned by us and
# are running on our DISPLAY.
#------------------------------------------------------------------------------
find_my_procs() {
    local my_pid=$$
    local pid pid_list=$(pgrep --euid $EUID "$@" | grep -v "^$my_pid$" ) || return 1

    #log "Find procs: $*"

    # Strip off optional screen
    local disp=$(echo ${DISPLAY%.[0-9]} | sed 's/\./\\./g')

    ret=1
    for pid in $pid_list; do
        cat -v /proc/$pid/environ 2>/dev/null \
            | egrep -q "@DISPLAY=$disp(\.[0-9])?\^" 2>/dev/null || continue
        echo $pid
        ret=0
    done
    return $ret
}

#------------------------------------------------------------------------------
# Beginnig of Kill functions
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Function: kill_my <command-name>
#
# Like killall or pkill but only kills processes ownd by this user and with
# the same DISPLAY variable.
#------------------------------------------------------------------------------
kill_my() { kill_list $(find_my_procs "$@") ;}


#------------------------------------------------------------------------------
# Function: prune_pids <list of pids>
#
# Filter out non-existent processes.
#------------------------------------------------------------------------------
prune_pids() {
    local pid  ret=1
    for pid; do
        [ -d /proc/$pid ] || continue
        ret=0
        echo $pid
    done
    return $ret
}

#------------------------------------------------------------------------------
# Function: recursive_children <list of pids>
#
# Find all decendants of the processes in <list of pids>.  Echo a list of
# the pids of all the children, children's children, etc.
#------------------------------------------------------------------------------
recursive_children() {
    local pids=$(echo "$*" | sed 's/ \+/,/g')
    [ "$pids" ] || return
    local children=$(pgrep --parent $pids 2>/dev/null)
    [ "$children" ] || return
    recursive_children $children
    echo $children
}

kill_family() {
    kill_list $(recursive_children $*) $*
}

kill_children() {
    kill_list $(recursive_children $*)
}

kill_list() {
    local list=$(echo "$*")

    if [ -z "$list" ]; then
        say "No processes to kill"
        return
    fi

    ps_debug $list
    safe_kill -TERM $list
    list=$(prune_pids $list)
    if [ -z "$list" ]; then
        say "All processes died instantly"
        return
    fi
    say "Waiting for termination of: $(echo $list)"
    for try in $(seq 1 $kill_retry); do
        sleep 0.1
        list=$(prune_pids $list)
        [ "$list" ] && continue
        local div10=$(div10 $try)
        say "All processes died within $div10 seconds"
        return
    done
    say "Killing stuborn processes: $list"
    safe_kill -KILL $list
}

#------------------------------------------------------------------------------
# Function: div10 <integer>
#
# Silly way to "divide" an integer by 10 via adding a decimal point.
#------------------------------------------------------------------------------
div10() { echo $1 | sed -r 's/(.)$/.\1/' ;}


safe_kill() {
    local pid sig=$1; command shift

    for pid; do
        [ -d /proc/$pid ] && kill $sig $pid
    done
}

ps_debug() {
    [ "$debug" ] || return
    [ "$*" ]     || return
    say "ps_debug($*)"
    ps j -p "$*" | sed "s/^/$ME: /"
}

#------------------------------------------------------------------------------
# End of Kill functions
#------------------------------------------------------------------------------
