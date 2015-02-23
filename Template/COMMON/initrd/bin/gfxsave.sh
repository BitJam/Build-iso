#!/bin/sh

GFX_CONFIG_FILE="/live/config/gfxsave.conf"
     GFX_SUFFIX=".def"
    GFX_SAVE_ON="gfxsave.on"

NEW_CONFIG_FILE=/live/boot-dev/boot/syslinux/gfxsave.cfg 

test -e $NEW_CONFIG_FILE && GFX_CONFIG_FILE=$NEW_CONFIG_FILE

hbar="======================================================================"
tab="----------------------------------------------------------------------"


set_colors() {
    local noco=$1 loco=$2

    [ "$noco" ] && return

    # Adjust this printf width for added color codes
    MSG8_W=$((MSG8_W + 14))

    local e=$(printf "\e")
     black="$e[0;30m";    blue="$e[0;34m";    green="$e[0;32m";    cyan="$e[0;36m";
       red="$e[0;31m";  purple="$e[0;35m";    brown="$e[0;33m"; lt_gray="$e[0;37m";
   dk_gray="$e[1;30m"; lt_blue="$e[1;34m"; lt_green="$e[1;32m"; lt_cyan="$e[1;36m";
    lt_red="$e[1;31m"; magenta="$e[1;35m";   yellow="$e[1;33m";   white="$e[1;37m";
        nc="$e[0m";

    cheat_co=$white;      err_co=$red;       hi_co=$white;      nc_co=$nc;
      cmd_co=$white;     from_co=$lt_green;  mp_co=$magenta;   num_co=$magenta;
      dev_co=$magenta;   head_co=$yellow;     m_co=$lt_cyan;    ok_co=$lt_green;

    [ "$loco" ] || return

    from_co=$brown
      hi_co=$white
       m_co=$nc_co
     num_co=$white
}

warn() { vmsg 3 "$high_co$@";    }
err()  { vmsg 1 "$err_co$@" >&2; }

vmsg() {
    local level="$1"
    shift;

    local msg
    if [ "$1" = "-n" ]; then
        shift;
        msg="$m_co$@$nc_co"
        vsay $level -n "$msg"
    else
        msg="$m_co$@$nc_co"
        vsay $level "$msg"
        msg="$msg\n"
    fi

    [ -n "$NO_LOG" ] || LOG="$LOG$msg"
    return 0
}

vmsg_if() {
    local level="$1"
    shift
    [ "$VERBOSE" -ge "$level" ] || return
    vmsg $level "$@"
}

msg()    { vmsg 5 "$@"; }
msg_nc() { vmsg 5 "$nc_co$@"; }

vmsg_nc() {
    local level="$1"
    shift;
    vmsg $level "$nc_co$@"
}

heading() {
    vmsg_nc 6 $tab
    vmsg 3 "${head_co}$_Start_ $@"
}

vsay() {
    local msg_level="$1"
    shift;
    [ "$msg_level" -le "$VERBOSE" ] && echo "$@"
    return 0
}

plural() {
    local n=$1 str="$2"
    case "$n" in
        1) local s=  ies=y   are=is;;
        *) local s=s ies=ies are=are;;
    esac
    echo "$str" | sed -e "s/%s/$s/g" -e "s/%ies/$ies/g" -e "s/%are/$are/g" -e "s/%n/$n/g"
}

pmsg() { msg "$(plural "$@")"; }

vpmsg() {
    local v=$1; shift
    vmsg $v "$(plural "$@")"
}


#============================================================

dispatch_gfxsave() {
    local GFX_BOOT_DIR=$1
    local gfx_cmd=$2
    local GFX_MESSAGE_FILE
    local GRUB_MESSAGE_DIR=/live/tmp/grub.message
    local GFX_OUTPUT_DIRS GRUB_DIR GRUB_CFG
    local GFX_REPACK_GRUB CMDLINE
    local SYSLINUX_DIR SYSLINUX_CFG
    local EXTLINUX_DIR EXTLINUX_CFG

    # We luck out because cpio only depends on libc
    local GFX_CPIO=/live/linux/bin/cpio

    case $VERBOSE in
        [0-9]|[0-9][0-9]) ;;
                       *) VERBOSE=5 ;;
    esac

    # Width of some printfs with no color codes
    MSG8_W=30
    set_colors "$NO_COLOR" "$LO_COLOR"


    case "$gfx_cmd" in
        menus|custom|both|reset) ;;
        *)  err "Bad gfxsave parameter $cheat_co$gfx_cmd$CO_ERR. \
Expected$cheat_co menus custom both$err_co or$cheat_co reset"
            return ;;
    esac

    if ! [ -r "$GFX_CONFIG_FILE" ]; then
        err "Could not find gfxsave config file: $GFX_CONFIG_FILE"
        return
    fi

    [ -n "$CMDLINE" ] || CMDLINE="$(cat /proc/cmdline)"
    vmsg 6 "Current bootcodes:"
    vmsg 6 "$cheat_co$CMDLINE"

    GFX_MESSAGE_FILE=$GFX_BOOT_DIR/grub/message

    case "$gfx_cmd" in
        custom|both) create_custom_main_entry ;;
    esac

    case "$gfx_cmd" in
        reset|menus|both) reset_gfxmenus  ;;
    esac

    case "$gfx_cmd" in
        menus|both) update_gfxmenus ;;
    esac

    case "$gfx_cmd" in
        custom|menus|both) update_main_menu_default ;;
    esac

   repack_grub_cpio

    if [ -n "$GFX_LOG_FILE" -a -z "$NO_LOG" ]; then
        mkdir -p $(dirname $GFX_LOG_FILE)
        echo -e "$LOG" | /bin/sed -r "s:\x1B\[[0-9;]*[mK]::g" > $GFX_LOG_FILE
        [ -n "$NO_COLOR" ] || echo -e "$LOG" > $GFX_LOG_FILE.color
    fi

}

#==============================================================================
# Update Panel menus defaults
#==============================================================================

update_gfxmenus() {
    msg
    warn "Update bootloader menu defaults"

    for param in $CMDLINE; do
        param=$(echo $param | sed -r -e 's/^(nouveau|video)\./\1_/')
        # only let through parameter names made of word chars
        # so we can turn them into variables names.  This is
        # a poor man's ash hash.

        # skip parameter names with non-word characters
        echo $param | grep -q "^[^=]*[^A-Za-z0-9_=]" && continue
        case "$param" in
            *=*)
                nam=${param%%=*}
                val=${param#*=}
                eval local GFX_P_$nam="$val";;
              *)
                eval local GFX_F_$param=true;;
        esac
    done

    # No output dirs, just check if anything needs to be done
    write_gfx_menu_defaults

    if [ $GFX_MENU_CNT -eq 0 ]; then
        msg "No defaults were found to update"
        return
    fi

    pmsg $GFX_MENU_CNT "Found $num_co%n$m_co default setting%s to update"

    find_gfx_output_dirs || return

    # This time it's for real
    write_gfx_menu_defaults "$GFX_OUTPUT_DIRS"
}

write_gfx_menu_defaults() {
    GFX_MENU_CNT=0
    local output_dirs="$1"

    for m_config in $(grep '^[A-Za-z]' $GFX_CONFIG_FILE); do
        local title=$(echo $m_config | cut -d"|" -f1)
        local fname=$(echo $m_config | cut -d"|" -f2)
        local out=
        fields=$(echo $m_config | cut -d"|" -f3-30)
        for field in $(echo $fields | sed 's/|/ /g'); do
            eval local nam="\$GFX_P_$field"
            [ -n "$nam" ] && out="$out $field=$nam"
            eval local cmd="\$GFX_F_$field"
            [ -n "$cmd" ] && out="$out $field"
        done
        out=$(echo "$out" | sed -r          \
            -e 's/^ //'                     \
            -e 's/\<(nouveau|video)_/\1./g' \
            -e 's/\<lang=//'                \
            -e 's/^<nouveau\.modeset=0$//'  \
            -e 's/\<tz=//')

        [ -n "$out" ] || continue
        GFX_MENU_CNT=$(($GFX_MENU_CNT + 1))
        [ -n "$output_dirs" ] || continue

        msg "$(printf " %10s:$from_co %-18s $cheat_co%s\n" \
            "$title" "$fname$GFX_SUFFIX" "$out")"

        for dir in $output_dirs; do
            echo "$out" > $dir/$fname$GFX_SUFFIX
        done
    done
}

reset_gfxmenus() {
    warn
    warn "Reset bootloader menu defaults"
    find_gfx_output_dirs || return

    reset_one_dir Grub     $GRUB_DIR
    reset_one_dir sysLinux $SYSLINUX_DIR
    reset_one_dir extLinux $EXTLINUX_DIR
}

reset_one_dir() {
    local type=$1
    local dir=$2

    [ -n "$dir" ] || return

    local fcnt=0
    for file in $(grep '^[A-Za-z]' $GFX_CONFIG_FILE | cut -d"|" -f2); do
        local full=$dir/$file$GFX_SUFFIX
        [ -e "$full" ] && fcnt=$(( $fcnt + 1 ))
        rm -rf $full
    done
    pmsg  $fcnt "Deleted$num_co %n$from_co $type$m_co file%s"

}

find_gfx_output_dirs() {

    [ -n "$FOUND_OUTPUT_DIRS" ] && return
    FOUND_OUTPUT_DIRS=true

    GFX_OUTPUT_DIRS=
    find_any_linux_dir sys SYSLINUX_DIR
    find_any_linux_dir ext EXTLINUX_DIR
    find_grub_dir

    if ! [ -n "$GFX_OUTPUT_DIRS" ]; then
        err "No valid output directories found"
        return 1
    fi

    return 0
}

find_cfg_files() {
    [ -n "$FOUND_CFG_FILES" ] && return
    find_gfx_output_dirs      || return

    FOUND_CFG_FILES=true

    if [ -n "$GRUB_DIR" ]; then
        local grub_cfg=$GFX_BOOT_DIR/grub/menu.lst
        is_writable $grub_cfg "file" Grub && GRUB_CFG=$grub_cfg
    fi

    if [ -n "$SYSLINUX_DIR" ] ;then
        local syslinux_cfg=$GFX_BOOT_DIR/syslinux/syslinux.cfg
        is_writable $syslinux_cfg "file" sysLinux && SYSLINUX_CFG=$syslinux_cfg
    fi

    if [ -n "$EXTLINUX_DIR" ] ;then
        local extlinux_cfg=$GFX_BOOT_DIR/extlinux/extlinux.cfg
        is_writable $extlinux_cfg "file" extLinux && EXTLINUX_CFG=$extlinux_cfg
    fi
}

find_any_linux_dir() {
    local pre=$1 var=$2
    local dir=$GFX_BOOT_DIR/${pre}linux
    is_writable $dir/ dir ${pre}Linux || return
    if [ -e $dir/$GFX_SAVE_ON ]; then
        GFX_OUTPUT_DIRS="$GFX_OUTPUT_DIRS $dir"
        eval $var=\$dir
    else
        err "No $GFX_SAVE_ON file found.  Skip ${pre}Linux."
        return
    fi
}

find_grub_dir() {

    is_writable $GFX_MESSAGE_FILE "file" Grub || return

    if ! [ -x "$GFX_CPIO" ]; then
        err "Could not find cpio program at $GFX_CPIO."
        return
    fi

    if ! rm -rf $GRUB_MESSAGE_DIR; then
        err "Could not remove $GRUB_MESSAGE_DIR"
    fi

    if ! mkdir -p $GRUB_MESSAGE_DIR; then
        err "Could not make temporary dir$to_co $GRUB_MESSAGE_DIR"
        return
    fi

    msg7 "" "Made dir" "$to_co" $GRUB_MESSAGE_DIR

    vmsg 7 "Unpack$from_co Grub$m_co cpio archive"
    (cd $GRUB_MESSAGE_DIR && $GFX_CPIO -idum --quiet --file=$GFX_MESSAGE_FILE)
    if [ $? -eq 0 ]; then
        if [ -e $GRUB_MESSAGE_DIR/$GFX_SAVE_ON ]; then
            GFX_OUTPUT_DIRS="$GFX_OUTPUT_DIRS $GRUB_MESSAGE_DIR"
            GFX_REPACK_GRUB=true
            GRUB_DIR=$GRUB_MESSAGE_DIR
        else
            err "No Grub $GFX_SAVE_ON file found.  Skip Grub."
        fi
    else
        err "Failed to unpack cpio archive.  Skip Grub."
    fi
}

is_writable() {
    local file=$1 name=$2 type=$3

    #msg8e  "Could not find" $type "$name" $file
    #msg8e "Cannot write to" $type "$name" $file
    if ! [ -e "$file" ]; then
        msg8e "Could not find" $type "$name"  $file
        return 1
    fi

    [ -w "$file" ] || chmod u+w $file

    if ! [ -w "$file" ]; then
        msg8e "Cannot write to" $type "$name" $file
        return 1
    fi

    [ -n "$name" ] && msg8 "Found" $type "$name" $file
    return 0
}

_msg8() { vmsg 7 "$1$(printf %${MSG8_W}s "$2$from_co $3$1 $4")$to_co $5" ; }
msg8()  { _msg8 "$m_co" "$@"; }
msg8e() { _msg8 "$err_co" "$@"; }

msg7() {
    local c1=$1 pre=$2 c2=$3 file=$4
    vmsg 7 "$c1$(printf %30s "$pre")$c2 $file"
}
#==============================================================================
# Update default main menu entry
#==============================================================================

update_main_menu_default() {
    warn
    warn "Update main menu default"

    find_cfg_files

    set_main_menu_default sysLinux "$SYSLINUX_CFG" LABEL APPEND 2
    set_main_menu_default extLinux "$EXTLINUX_CFG" LABEL APPEND 2
    set_main_menu_default Grub     "$GRUB_CFG"     title kernel 3
}

set_main_menu_default() {
    local type=$1; shift
    local file=$1

    [ -n "$file" ] || return

    local sorted_params="$(get_all_cfg_params $@ | sort -u)"

    cmdline_params=$(cmdline_only $sorted_params)
    cmdline_params=$(echo $cmdline_params)
    vmsg 8 "Cmdline params: $cmdline_params"

    find_main_entry "$cmdline_params" "$@"

    if ! [ -n "$FOUND_ENTRY" ]; then
        msg "Failed to resolve default$from_co $type$m_co entry"
        return
    fi
    local pre="Set$from_co $type$m_co default to"
    msg "$(printf %${MSG8_W}s "$pre") ($num_co$FOUND_ENTRY$m_co)$high_co $FOUND_TITLE"

    if grep -q "^\s*default\>" $file; then
        sed -i -r "s/^(\s*default\>).*/\1 $FOUND_ENTRY/" $file
    else
        sed -i "1i\
default $FOUND_ENTRY" $file
    fi
}

get_all_cfg_params() {
    local file=$1
    local counter=$2
    local target=$3
    local first=$4

    while read a1 a2 a3 a4 a5 a6 a7 a8 a9; do
        [ "$a1" = "$target" ] || continue
        for i in $(seq $first 9); do
            eval val=\$a$i
            [ -n "$val" ] || break
            echo $val
        done | sort
    done <<Config_File
$(cat $file)
Config_File
}

cmdline_only() {
    for param; do
        case " $CMDLINE " in
            *" $param "*) echo $param;;
        esac
    done
}

find_main_entry() {
    local cmdline=$1
    local    file=$2
    local counter=$3
    local  target=$4
    local   first=$5
    local title val

    FOUND_ENTRY=
    FOUND_TITLE=

    [ -n "$file" ] || return

    local count=-1
    while read a1 a2 a3 a4 a5 a6 a7 a8 a9; do
        if [ "$a1" = "$counter" ]; then
            count=$(($count + 1))
            local title=
            for i in $(seq 2 9); do
                eval val=\$a$i
                [ -n "$val" ] || break
                title="$title $val"
            done
            title=${title# }
            #echo "$count: $title"
        fi
        [ "$a1" = "$target" ] || continue
        local params=$(
            for i in $(seq $first 9); do
                eval val=\$a$i
                [ -n "$val" ] || break
                echo $val
            done | sort)

        # Ignore entries with no parameters
        [ -n "$params" ] || continue

        params=$(echo $params)
        #echo "params: $params"
        #continue
        [ "$params" = "$cmdline" ] || continue
        #vmsg 8 "Found entry $count: $title"
        FOUND_TITLE=$title
        FOUND_ENTRY=$count
        break
    done <<Config_File
$(cat $file)
Config_File
}

#==============================================================================
# Create custom main menu entry
#==============================================================================
create_custom_main_entry() {
    warn
    warn "Create Custom bootloader entry"
    find_cfg_files

    local mparam
    local menu_params=$(get_all_menu_params | sort -u)
    menu_params=$(echo $menu_params)

    vmsg 9 "Menu params:$cheat_co $menu_params"

    # Always skip gfxsave=
    menu_params="$menu_params gfxsave"

    local alpha_params=$(extra_cmdline_params "$menu_params" | sort -u)

    if ! [ -n "$alpha_params" ]; then
        msg "No non-menu parameters found"
        return
    fi
    alpha_params=$(echo $alpha_params)
    vmsg 9 "Alpha params:$cheat_co $alpha_params"

    local ordered_params=$(cmdline_order "$alpha_params")
    ordered_params=$(echo $ordered_params)

    find_main_entry "$alpha_params" "$SYSLINUX_CFG" LABEL APPEND 2
    if ! [ -n "$FOUND_ENTRY" ]; then
        add_custom_entry sysLinux "$SYSLINUX_CFG" LABEL KERNEL "" "\tAPPEND" INITRD "$ordered_params"
    else
        pre="${from_co}sysLinux$m_co entry already exists"
        msg "$(printf %${MSG8_W}s "$pre") ($num_co$FOUND_ENTRY$m_co)$high_co $FOUND_TITLE"
    fi

    find_main_entry "$alpha_params" "$EXTLINUX_CFG" LABEL APPEND 2
    if ! [ -n "$FOUND_ENTRY" ]; then
        add_custom_entry extLinux "$EXTLINUX_CFG" LABEL KERNEL "" "\tAPPEND" INITRD "$ordered_params"
    else
        pre="${from_co}extLinux$m_co entry already exists"
        msg "$(printf %${MSG8_W}s "$pre") ($num_co$FOUND_ENTRY$m_co)$high_co $FOUND_TITLE"
    fi

    find_main_entry "$alpha_params" "$GRUB_CFG" title kernel 3
    if ! [ -n "$FOUND_ENTRY" ]; then
        add_custom_entry Grub "$GRUB_CFG" title kernel "(kernel\s+[^ ]+)\s.*" "" initrd "$ordered_params"
    else
        pre="${from_co}Grub$m_co entry already exists"
        msg "$(printf %${MSG8_W}s "$pre") ($num_co$FOUND_ENTRY$m_co)$high_co $FOUND_TITLE"
    fi
}

add_custom_entry() {

    local       type=$1
    local       file=$2

    local  title_tag=$3
    local kernel_tag=$4
    local kernel_sed=$5
    local append_tag=$6
    local initrd_tag=$7
    local     params=$8

    [ -n "$file" ] || return

    local date=$(date "+%e %B %Y")
    local title_text="Custom ($date)"
    local title="$title_tag $title_text\n"
    local state=1 kernel append initrd

    case $type in
        *Linux) title="LABEL custom\n    MENU LABEL $title_text\n" ;;
    esac

    [ -n "$append_tag" ] && append="$append_tag $params\n"

    local replace target pre="$from_co $type$m_co entry with"
    if grep -q "^\s*$title_tag\s\+Custom" $file; then
        replace=true
        target="$title_tag\s\+Custom"
        msg "$(printf %${MSG8_W}s "Replace$pre")$high_co $title_text"
    else
        target="$title_tag"
        msg "$(printf %${MSG8_W}s "Create$pre")$high_co $title_text"
    fi

    msg "$(printf %30s "Params")$cheat_co $params"
    local backup=${file%.*}.bak
    local file2=${file%.*}.tmp
    [ -e "$backup" ] || cp $file $backup
    rm -f $file2

    local old_ifs=$IFS
    IFS=''
    while read line; do
        case $state in

        1)  if echo $line | grep -q "^\s*$target"; then
                state=2
                [ -n "$replace" ] && continue
            fi;;

        2)  if echo $line | grep -q "^\s*$kernel_tag"; then
                if [ -n "$kernel_sed" ]; then
                    kernel="$(echo $line | sed -r "s/$kernel_sed/\1 $params/")\n"
                else
                    kernel="$line\n"
                fi
            fi

            echo $line | grep -q "^\s*$initrd_tag" && initrd="$line\n"

            if echo $line | grep -q "^\s*$title_tag"; then
                echo -e "$title$kernel$append$initrd" >> $file2
                vmsg_nc 8 "$(echo -e "$title$kernel$append$initrd \n")"
                state=3
            else
                [ -n "$replace" ] && continue
            fi;;

        3)  ;;

        esac

        echo "$line" >> $file2
        vmsg_nc 8 "$line"

    done <<Config_File
$(cat $file)
Config_File

    IFS=$old_ifs

    if [ "$state" -lt 3 ]; then
        err "Failed to update$from_co $type$err_co config file"
        return
    fi

    mv $file2 $file
}

get_all_menu_params() {
    for m_config in $(grep '^[A-Za-z]' $GFX_CONFIG_FILE); do
        fields=$(echo $m_config | cut -d"|" -f3-30)
        for field in $(echo $fields | sed 's/|/ /g'); do
            echo $field | sed -r -e 's/^(nouveau|video)_/\1./'
        done
    done
}

cmdline_order() {
    local list=$1
    for param in $CMDLINE; do
        case " $list " in
            *" $param "*) echo $param;;
        esac
    done
}
#------------------------------------------------------------------------------
# Only echo cmdline params that *don't* match any of the names in menu_params.
# Equal signs and values after equal signs are ignored.
#------------------------------------------------------------------------------
extra_cmdline_params() {
    local param menu_params=$1
    for param in $CMDLINE; do
        case $param in
            nouveau.modeset=0) continue ;;
        esac
        case " $menu_params " in
            *" ${param%%=*} "*) ;;
            *) echo $param ;;
        esac
    done
}

repack_grub_cpio() {
    [ -n "$GFX_REPACK_GRUB" -a -e "$GRUB_MESSAGE_DIR/gfxboot.cfg" ] || return

    vmsg 6 "Repack$from_co Grub$m_co cpio archive"
    cp $GFX_MESSAGE_FILE $GFX_MESSAGE_FILE.bak
    (cd $GRUB_MESSAGE_DIR && find . | $GFX_CPIO -o --quiet --file=$GFX_MESSAGE_FILE.new)
    if [ $? = 0 ]; then
        vmsg 7 "Update$to_co $GFX_MESSAGE_FILE"
        mv $GFX_MESSAGE_FILE.new $GFX_MESSAGE_FILE
    else
        err "Failed to repack Grub cpio archive.  Not updating Grub."
    fi
}

dispatch_gfxsave "$@"
