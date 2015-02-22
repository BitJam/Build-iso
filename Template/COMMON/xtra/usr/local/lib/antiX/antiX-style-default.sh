# This prevents gtk2 themes from interfering with Pango colors
export GTK2_RC_FILES=/usr/share/themes/Default/gtk-2.0-key/gtkrc

LOADED_STYLE="true"

       SYS_TYPE="LiveUSB/HD"
          TITLE="antiX"
      MIN_WIDTH=50
    TEXT_MARGIN=8
        PULSATE="--progress --pulsate"
       SIZE_FMT='%22s: [n]%7s[/] meg'

    ANTIX_IMAGE="/usr/local/lib/antiX/antiX-logo.png"

if [ "$Static_antiX_Libs" ]; then
    YAD_STD_OPTS="--center --on-top --width=680"
else
    YAD_STD_OPTS="--center --on-top --width=680 --image=$ANTIX_IMAGE"
fi


#--image=gtk-dialog-question
#--image=gtk-dialog-info

YAD_DEVICE_OPTS="
    --width=680 --height=400
    --button=gtk-ok:0
    --button=gtk-cancel:1"

YAD_YES_NO_OPTS="
    --button=gtk-yes:0
    --button=gtk-no:1"

YAD_ERROR_OPTS="
    --image=gtk-dialog-error
    --button=gtk-ok:0"

YAD_INFO_OPTS="
    --button=gtk-ok:0"

YAD_BG_INFO_OPTS="
    --button=gtk-cancel"

YAD_MULTI_OPTS="
    --button=gtk-ok:0
    --button=gtk-cancel:1"

set_color() {

    case "$1" in
        n|noco|nocolor)
            unset BLUE CYAN GREEN MAGENTA RED WHITE YELLOW NO_COLOR UNDERLINE
            ;;
        m|mute|dim)
            BLUE="[0;34m"
            CYAN="[0;36m"
            GREEN="[0;32m"
            MAGENTA="[0;35m"
            RED="[0;31m"
            YELLOW="[0;33m"

            WHITE="[1;37m"
            NO_COLOR="[0;39m"
            ;;
         b|bright)
            BLUE="[1;34m"
            CYAN="[1;36m"
            GREEN="[1;32m"
            MAGENTA="[1;35m"
            RED="[1;31m"
            YELLOW="[1;33m"

            WHITE="[1;37m"
            UNDERLINE="[04m"
            NO_COLOR="[0m"
            ;;
        *)
            echo "Unknown color scheme \"$1\"" >&2
            ;;
    esac

   SCRIPT_NAME_COLOR=$WHITE
  SCRIPT_TITLE_COLOR=$MAGENTA
         TITLE_COLOR=$CYAN
  TITLE_BORDER_COLOR=$CYAN
        PROMPT_COLOR=$GREEN
        NUMBER_COLOR=$MAGENTA
          BOLD_COLOR=$YELLOW
        ITALIC_COLOR=$MAGENTA
           BAR_COLOR=$CYAN
          FILE_COLOR=$GREEN
         ERROR_COLOR=$RED
          WARN_COLOR=$MAGENTA
         PARAM_COLOR=$CYAN

    TBAR="$BAR_COLOR------------------------------------------------$NO_COLOR"

    TEXT_MARKUP="
        s/\[title\]/$TITLE_COLOR/g
        s/\[n\]/$NUMBER_COLOR/g
        s/\[fixed\]//g
        s/\[b\]/$BOLD_COLOR/g
        s/\[f\]/$FILE_COLOR/g
        s/\[i\]/$ITALIC_COLOR/g
        s/\[e\]/$ERROR_COLOR/g
        s/\[w\]/$WARN_COLOR/g
        s/\[p\]/$PARAM_COLOR/g
        s/\[u\]/$UNDERLINE/g
        s/\[?\]/$PROMPT_COLOR/g
        s=\[/.\?\]=$NO_COLOR=g"

    PANGO_MARKUP="
        s/\[title\]/<span color=\"darkcyan\" size=\"large\" weight=\"bold\" font=\"DejaVu Sans\">/g
        s/\[fixed\]/<span weight=\"normal\" font=\"DejaVu Sans Mono\">/g
        s/\[n\]/<span color=\"darkblue\" weight=\"ultrabold\">/g
        s/\[f\]/<span color=\"darkgreen\" weight=\"bold\">/g
        s/\[b\]/<span weight=\"bold\">/g
        s/\[i\]/<span color=\"black\" style=\"italic\">/g
        s/\[p\]/<span color=\"darkcyan\" weight=\"bold\">/g
        s/\[e\]/<span color=\"#CC0000\" weight=\"bold\">/g
        s/\[w\]/<span color=\"darkorange\" weight=\"bold\">/g
        s=\[/.\?\]=</span>=g"
}


case "$( tty )" in
    */pts/*)
        set_color bright
        ;;
    *)
        set_color mute
        ;;
esac


