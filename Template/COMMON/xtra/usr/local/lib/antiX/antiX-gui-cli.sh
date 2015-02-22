# GETTEXT_KEYWORD="gt_gui"
# GETTEXT_KEYWORD="pfgt_gui"

gt_gui() {
    gettext -d antiX-bash-libs "$1"
}

pfgt_gui() {
    local fmt="$1" && shift
    printf "$(gettext -d antiX-bash-libs "$fmt")" "$@"
}

#===== GUI/CLI stuff ==========================================================

BG_INFO_SLEEP=1

YAD=$(which yad 2>/dev/null)

#tty >> $HOME/tty.out

SET_GUI=true
tty | grep -q ^/dev/tty && unset SET_GUI

[ "$DISPLAY" ] || unset SET_GUI

fmt_size() {
    printf "$SIZE_FMT" "$(gettext "$1")" "$2"
}

start_logging() {
    [ "$SET_NO_LOG" ] && return

    LOG_FILE=/var/log/live/$(basename $0).log

    [ $# -gt 0 ] && LOG_FILE=$HOME/$(basename $0).log
    mkdir -p $(dirname $LOG_FILE)

    # tee stderr to log file.  Don't remove the space.
    # FIXME: comment out for now to avoid err message when called from inside initrd
    exec 2> >(tee -a $LOG_FILE)
    echo "--------------------------------------------------------------------" >> $LOG_FILE
}

# Verbose console messages
vmsg() {
    local text="$(markup_text "$@")"
    [ "$SET_VERBOSE" ] && echo -e "$SCRIPT_NAME_COLOR$ME$NO_COLOR: $text"

    [ "$LOG_FILE" ]   || return
    [ "$SET_NO_LOG" ] && return

    #echo -e "$(date "+%F %T"): $text"  | sed -r "s:\x1B\[[0-9;]*[mK]::g" >> $LOG_FILE
    echo -e "$(date "+%F %T"): $text" >> $LOG_FILE
}

# Verbose exit, explaining why we are leaving.
vexit() {
    local fmt="$(gettext "$1")" && shift
    local msg="$(printf "$fmt" "$@")"
    vmsg "$msg  Exiting."
    exit 0
}

warn() {
    local text="$(markup_text "$@")"
    echo -n "$SCRIPT_NAME_COLOR$ME ${WARN_COLOR}$(gt_gui "warning"):$NO_COLOR "
    echo -e "$text"
}

pf() {
    printf "$@"
}

vpf() {
    vmsg "$(pf "$@")"
}

vpfgt() {
    vmsg "$(pfgt "$@")"
}

get_text() {
    unset UI_RESULT
    if [ "$SET_GUI" ]; then
        _dialog_box_gui text "$@"
        return $?
    else
        get_text_cli "$@"
        return $?
    fi
}

combo_box() {
    unset UI_RESULT
    if [ "$SET_GUI" ]; then
        _dialog_box_gui combo "$@"
        return $?
    else
        combo_box_cli "$@"
        return $?
    fi
}

error_box_pf() {
    local fmt="$(gettext "$1")" && shift
    error_box "$(printf "$fmt" "$@")"
}

error_box() {
    kill_bg_info_box -f
    [ "$SET_GUI" ] && _dialog_box error "$(ctitle "$TITLE [e]Error[/]")" "" "$@"

    [ "$SET_QUIET" ] || echo "$ME ${ERROR_COLOR}error$NO_COLOR:" >&2
    echo -e "$(markup_text "$@")" >&2
    exit 2
}

yes_no_box() {
    _dialog_box "yes_no" "$@"
}

no_yes_box() {
    _dialog_box "no_yes" "$@"
}

info_box() {
    _dialog_box "info" "$@" || confirm_quit
}

okay_box() {
    _dialog_box "okay" "$@" || confirm_quit
}

warn_box() {
    _dialog_box "okay" "$(ctitle "[e]Warning[/]")" "$@" || confirm_quit
}

noisy_yes_no_box() {
    [ "$SET_QUIET" ] && return 0
    yes_no_box "$@" 
    return $?
}

confirm_quit() {
    vmsg "Confirming quit ..."
    [ "$SET_QUIET" ] && vexit "quietly quiting."

    yes_no_box -c -o --undecorated "[title]$TITLE[/]" \
        ""                                            \
        "$(gt_gui "Really Quit?")"   \
        && vexit "At user's request."
    return 0
}

#------------------------------------------------------------------------------
# Function: bg_info text text text
#
# In grapics mode we launch a yad info box in the background and record its PID
# in $GUI_PID.  In text mode we simply display the text.
#------------------------------------------------------------------------------
bg_info_box() {
    unset GUI_PID
    local opts center title
    # FIXME: should SET_QUIET disable this?
    #-jbb??[ "$SET_QUIET" ] && return

    # FIXME: do we really want to kill parent?
    local opts="$YAD_STD_OPTS $YAD_BG_INFO_OPTS --kill-parent"
    while [ $# -gt 0 ]; do
        case "$1" in
            -c) center=true     && shift;;
            -o) opts="$opts $2" && shift 2;;
             *) break;;
         esac
    done

    if [ "$SET_GUI" ]; then
        [ "$1" = "--" ] || title="$1"
        shift

        local text="$(center_strings "$@")"
        [ "$title" ] && text="$(center_strings "[title]$title[/]")\n$text"

        # Need to call yad directly to get proper PID.  :-(
        ($YAD --title="$TITLE" $opts --text="$text") &
        GUI_PID=$!
        disown
    else
        shift
        info_box "" "$@"
    fi
}

kill_bg_info_box() {
    [ "$SET_GUI" ] || return
    [ "$1" = "-f" ] || sleep $BG_INFO_SLEEP
    [ "$GUI_PID" ] && kill -9 $GUI_PID &> /dev/null
    unset GUI_PID
}

#------------------------------------------------------------------------------
# Function: _dialog_box [yes_no|info|error] [-c] [-o <yad-option> text text text
#
# Makes CLI and GUI yes_no, info, and error dialog boxes.  The $SET_GUI variable
# determines if we use CLI or GUI.  The type of box is the first parameter.
# A -c means the text in GUI mode is roughly centered.
#------------------------------------------------------------------------------
_dialog_box() {
    if [ "$SET_GUI" ]; then
        _dialog_box_gui "$@"
        return $?
    else
        _dialog_box_cli "$@"
        return $?
    fi
}

#==============================================================================

_dialog_box_gui() {
    local opts center text title notitle
    local field_type label choice form retval

    local type="$1" && shift

    opts="$YAD_STD_OPTS"

    case "$type" in
        text|combo)
            opts="$opts $YAD_MULTI_OPTS"
            label="$1"
            choice="$2"
            form=true
            choice="$(echo "$choice" | sed 's/^!//')"
            shift 2
            ;;
    esac

    while [ $# -gt 0 ]; do
        case "$1" in
            -c) center=true     && shift;;
            -o) opts="$opts $2" && shift 2;;
            --) notitle=true    && shift;;
            -a) shift;;
            -q) shift;;
             *) break;;
         esac
    done

    case "$type" in
        no_yes)  opts="$opts $YAD_YES_NO_OPTS";;
        yes_no)  opts="$opts $YAD_YES_NO_OPTS";;
     info|okay)  opts="$opts $YAD_INFO_OPTS";;
         error)  opts="$opts $YAD_ERROR_OPTS";;
          text)  field_type="";;
         combo)  field_type="CB";;

             *)  echo "$ME: internal error: no \"$1\" _multi_box"
                 exit 10;;
    esac

    [ "$notitle" ] || title="$1" && shift

    [ "$center" ]  && text="$(center_strings "$@")"
    [ "$center" ]  || text="$(concat_strings "$@")"

    [ "$title" ]   && text="$(ctitle "$title")\n$text"

    if [ "$form" ]; then
        while true; do
            unset UI_RESULT
            [ "$SET_DEBUG" ] && echo -e "$text" >&2

            local result="$($YAD --title="$TITLE" $opts --text="$text" --form \
                --field="$label:$field_type" "$choice")"
            retval=$?

            if ! [ "$result" ]; then
                confirm_quit
                continue
            fi
            UI_RESULT="${result%|}"
            break
        done
    else
        while true; do
            [ "$SET_DEBUG" ] && echo -e "$text" >&2
            $YAD --title="$TITLE" $opts --text="$text"
            retval=$?

            [ "$retval" -gt "100" ] && confirm_quit && continue
            break
        done
    fi

    [ "$SET_DEBUG" ] && echo -e "\n$TBAR\n" >&2
    return $retval
}


ctitle() {
    center_strings "[title]$(gettext "$1")[/]"
}


center() {
    local width=$MIN_WIDTH
    case "$1" in
        [0-9]|[0-9][0-9]|[0-9][0-9][0-9])
            width=$1 && shift;;
    esac

    # Assemble remaining parameters into one string
    local text="$1" && shift;
    while [ "$#" -gt "0" ]; do
        text="$text $1" && shift;
    done
    local copy="$(echo "$text" | sed 's/\[[^]]*\]//g')"
    local len=${#copy}

    # Pad both sides to make string $width chars wide
    if [ "$SET_GUI" ] && [ "$len" -lt "$width" ]; then
        local spaces=$(( ($width - $len) / 2))
        for i in $(seq $spaces); do
            text=" $text "
        done
    fi
    echo "$text"
    return
}

#==============================================================================
# CLI Stuff
#==============================================================================

_dialog_box_cli() {
    local prompt want default input text title notitle

    local type="$1"
    shift

    while [ $# -gt 0 ]; do
        case "$1" in
            -c) shift;;
            -o) shift 2;;
            --) notitle=true && shift;;
             *) break;;
         esac
    done

    local upper_yes=$(gt_gui "Y")
    local lower_yes=$(gt_gui "y")
    local upper_no=$(gt_gui "N")
    local lower_no=$(gt_gui "n")
    case "$type" in
        yes_no)
            prompt="\n$PROMPT_COLOR[$upper_yes|$lower_no]"
            want="[$lower_yes$upper_yes]*"
            default="$upper_yes";;
        no_yes)
            prompt="\n$PROMPT_COLOR[$lower_yes|$upper_no]"
            want="[$lower_yes$upper_yes]*"
            default="$upper_no";;

        okay)
            prompt="\n${CYAN}$(gt_gui "Press <Enter> to Continue")"
            want="*";;

        info)
            #prompt="\n${CYAN}Press <Enter> to Continue"
            prompt=""
            want="";;
        *)
            echo "$ME: internal error: no \"$type\" CLI _dialog_box"
            exit 10;;
    esac

    [ "$notitle" ] || title="$1" && shift

    text="$(concat_strings -t "$@")"

    [ "$title" ] && text="$(concat_strings -t "[title]$title[/]")\n$text"

    #echo
    echo -ne "$text$prompt$NO_COLOR "
    if ! [ "$want" ]; then
        echo
        return 0
    fi

    read input
    echo
    [ "$input" ] || input="$default"

    case "$input" in
        $want) return 0;;
    esac
    return 1
}

markup_text() {
    for line in "$@"; do
        echo "$line" | sed "$TEXT_MARKUP"
    done
}

underline() {
    local len width line char
    char="="
    [ "$1" = "-c" ] && char="$2" && shift 2

    width=${#1}
    len=0
    while [ "$len" -lt "$width" ]; do
        line="$line$char"
        len=${#line}
    done
    echo "$line"
}

show_cli_title() {
    [ "$SET_GUI" ]   && return
    #[ "$SET_QUIET" ] && return

    echo -e "\n$SCRIPT_TITLE_COLOR$UNDERLINE$TITLE$NO_COLOR"
}

# FIXME: this shouldn't be needed.  It could be vastly improved.
center_strings() {
    local width=$MIN_WIDTH
    local len text
    for s in "$@"; do
        text="$(echo "$text" | sed 's/\[[^]]*\]//g')"
        len=${#text}
        [ "$width" -lt "$len" ] && width=$len
    done
    [ "$TEXT_MARGIN" ] && width=$(( $width + $TEXT_MARGIN))

    for s in "$@"; do
        text="$(echo "$s"    | sed 's/\[[^]]*\]//g')"

        len=${#text}
        while [ "$len" -lt "$width" ]; do
            s=" $s "
            text=" $text "
            len=${#text}
        done
        concat_strings "$s"
    done
}

concat_strings() {
    local tmode line markup
    [ "$1" = "-t" ] && tmode=true && shift

    if [ "$SET_GUI" -a -z "$tmode" ]; then
        markup="$PANGO_MARKUP"
    else
        markup="$TEXT_MARKUP"
    fi
    for line in "$@"; do
        echo -e "$line" | sed "$markup"
    done
}

get_text_cli() {
    local label="$1" choice="$2"
    shift 2

    local input text title notitle no_check

    vmsg "$1"
    while [ $# -gt 0 ]; do
        case "$1" in
            -q) no_check=true; shift;;
            -c) shift;;
            -o) shift 2;;
            --) notitle=true    && shift;;
             *) break;;
         esac
    done

    [ "$notitle" ] || title="$1" && shift

    text="$(concat_strings -t "$@")"

    [ "$title" ] && text="$(concat_strings -t "[title]$title[/]")\n$text"

    echo -e "$text"
    local try_again
    while true; do
        echo
        echo -n "${PROMPT_COLOR}$try_again >$NO_COLOR "
        read input
        echo

        [ "$no_check" ] || get_text_cli_check "$input" || continue

        try_again="$(gt_gui "Try again")"
        UI_RESULT="$input"
        break
    done
}

get_text_cli_check() {
    local input="$1"
    pfgt_gui "you entered: %s" "$WHITE$input$NO_COLOR"
    yes_no_box "$(gt_gui "Is this correct?")"
    return $?
}

combo_box_cli() {
    local label=$1 choice=$2
    choice="$(echo "$choice" | sed 's/^!//')"
    shift 2

    local input text abbreviate title notitle lead_num
    while [ $# -gt 0 ]; do
        case $1 in
            -c) shift;;
            -o) shift 2;;
            -a) abbreviate=true ; shift;;
            -n) lead_num=true   ; shift;;
            --) notitle=true    ; shift;;
             *) break;;
         esac
    done
    local i c this_choice choice_array input or_letter first remain
    for i in $(seq 30); do
        this_choice="$(echo "$choice" | cut -d"!" -f $i)"
        [ "$this_choice" ] || break
        choice_array[$i]="$this_choice"
    done

    [ "$notitle" ] || title="$1" && shift
    text="$(concat_strings -t "$@")"
    [ "$title" ] && text="$(concat_strings -t "[title]$title[/]")\n$text"

    echo -e "$text"

    local opts
    [ "$abbreviate" ] && opts="-a"
    [ "$lead_num"   ] && opts="$opts -n"
    select_choice_cli $opts "${choice_array[@]}"
}

select_choice_cli() {
    local abbreviate quiet not_a_number this_choice lead_num
    local enter_number="$(gt_gui "Enter a number")"

    while [ $# -gt 0 ]; do
        case "$1" in
            -a)  abbreviate=true ; shift ;;
            -n)  lead_num=true   ; shift ;;
            -q)  quiet=true      ; shift ;;
             *)  break                   ;;
        esac
    done

    local choice_array=("" "$@")

    while true; do
        #echo
        for i in $(seq 30); do
            this_choice="${choice_array[$i]}"
            [ "$this_choice" ] || break
            if [ "$abbreviate" ]; then
                local first=${this_choice:0:1} remain=${this_choice:1}
                case "$first" in
                    [a-zA-Z])
                    this_choice="$PROMPT_COLOR$first$NO_COLOR$remain"
                    or_letter="$(gt_gui " (or a letter)")"
                    ;;
                esac
            fi

            [ "$lead_num" ] && this_choice=${this_choice#[0-9] }
            [ "$quiet" ] || printf "$PROMPT_COLOR%5d$NO_COLOR) $this_choice\n" $i

        done

        echo
        #echo "$UNDERLINE${PROMPT_COLOR}$enter_number$or_letter >$NO_COLOR "
        echo -n "$(markup_text "[u][?]$enter_number$or_letter >[/] ")"
        read input
        echo

        unset c this_choice not_a_number
        case "$input" in
            ""|0)
                ;;
            [0-9]|[0-9][0-9])
                this_choice="${choice_array[$input]}"
                ;;
            *)
                if ! [ "$abbreviate" ]; then
                    not_a_number=true
                fi
                local abbrev="$(echo "$input" | tr "[A-Z]" "[a-z]")"
                for c in "${choice_array[@]}"; do
                    first=$( echo ${c:0:1} | tr "[A-Z]" "[a-z]")
                    [ "$first" = "$abbrev" ] || continue
                    this_choice="$c"
                    break
                done
                ;;
        esac

        if [ "$this_choice" ]; then
            UI_RESULT="$this_choice"
            return
        fi
        echo $TBAR
        if [ -z "$input" ]; then
            pfgt_gui "Your selection was empty.\n"

        elif [ "$not_a_number" ]; then
            pfgt_gui "You must select a number.\n"

        else
            local selection="$NO_COLOR<$PROMPT_COLOR$input$NO_COLOR>"
            pfgt_gui "Your selection %s was out of range.\n" "$selection"
        fi
        echo $TBAR

        echo "${CYAN}$(gt_gui "Press <Enter> to Continue")$NO_COLOR"
        read input
        [ "$quiet" ] && return
        continue
    done
}

