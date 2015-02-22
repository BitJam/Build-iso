#!/bin/bash

files="antiX-style-default.sh antiX-gui-cli.sh antiX-common.sh"
dir="/usr/local/lib/antiX"


head_line="#######################################################################"
head_start="##########"
head_char="#"
head_len=${#head_line}

print_header() {
    local title="$head_start  $1  "
    while [ "${#title}" -lt "$head_len" ]; do
        title="$title$head_char"
    done

    echo 
    echo "$head_line"
    echo "$head_line"
    echo "$title"
    echo "$head_line"
    echo "$head_line"
    echo
}

for file in $files; do
    full=$dir/$file
    [ -e "$full" ] && continue
    echo "File $file NOT FOUND in directory $dir"     >&2
    file_error="true"
done

if [ "$1" ] && ! [ -f "$1" ]; then
    echo "File $1 NOT FOUND!" >&2
    file_error="true"
fi

[ "$file_error" ] && exit 1

echo "#!/bin/bash"
echo
echo "Static_antiX_Libs=\"true\""
for file in $files; do
    full=$dir/$file
    print_header $file
    #cat $full
done

if [ "$1" ]; then
    print_header "$1"
    sed 's=\(^source.*lib/antiX.*\)=#--STATIC \1=' $1
else
    print_header "YOUR CODE GOES HERE"
fi

