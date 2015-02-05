#!/bin/sh

main() {
    echo "Block Device Nodes:"
    echo $(most_block_devices | sort | sed 's=.*/==')

    hcd_devices

    echo
    echo "/sys/block/s* devices"
    sys_block_devices | sort

    echo
    echo "input buses"
    grep /pci /proc/bus/input/devices | cut -d/ -f4 | sort -u
}

most_block_devices() { find /dev -type b | egrep -v "/ram|/loop" ; }

hcd_devices() {
    local dir sym
    for dir in /sys/bus/pci/drivers/*_hcd; do
        echo
        echo "$(basename $dir):"
        for sym in $dir/00*; do
            [ -e $sym ] || continue
            readlink -f $sym | cut -d/ -f5
        done
    done
}

sys_block_devices() {
    local sym
    for sym in /sys/block/s*; do
        [ -e $sym ] || continue
        readlink -f $sym
    done
}

main "$@"

