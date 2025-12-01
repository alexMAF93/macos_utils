#!/bin/zsh


# Do you happen to have multiple macos devices (like mac mini and a macbook) and only 
# one set of peripherals?
# I sure do have this issue.
# So, this script reconnects your peripherals to the current device that you're using.

# NOTE: In order for this script to work, you must install bluetil: brew install bluetil
# NOTE2: Make sure you turn the peripherals OFF and then back ON before switching.
# NOTE3: The peripherals should have already been paired to the device you're running the script on.


find_paired_magic_devices() {
    devices=$(blueutil --connected | grep "Magic" | sed -E 's/address: ([^,]+).*name: "([^"]+)".*/\1;\2/')
    echo $devices
}


unpair_device() {
    device=$1
    device_mac=$2
    blueutil --unpair $device_mac && { echo "Successfully unpaired $device"; } || { echo "Could not unpair $device";  return 1;}
}


pair_device() {
    device=$1
    device_mac=$2
    blueutil --pair $device_mac && { echo "Successfully paired $device"; } || { echo "Could not pair $device"; return 1;}
}


devices=$(find_paired_magic_devices)

while IFS=';' read -r mac name; do
    unpair_device  "$name" $mac
    sleep 3
    pair_device "$name" $mac
done <<< "$devices"
