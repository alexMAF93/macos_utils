#!/bin/zsh
set -euo pipefail

############################################
# Magic device reconnect helper
#
# Default:
# - Try to connect paired Magic devices
# - NEVER unpair automatically
#
# Optional:
#   --force   Allow unpair + re-pair (mouse/trackpad only)
############################################

FORCE=false

if [[ "${1:-}" == "--force" ]]; then
    FORCE=true
    echo "⚠️  FORCE mode enabled: unpairing allowed (except keyboards)"
fi

############################################
# Helpers
############################################

log() {
    echo "➡️  $1"
}

is_keyboard() {
    echo "$1" | grep -iq "keyboard"
}

is_connected() {
    local mac="$1"
    blueutil --is-connected "$mac" 2>/dev/null
}

############################################
# Discover paired Magic devices
############################################

find_paired_magic_devices() {
    blueutil --paired |
        grep -i "Magic" |
        sed -E 's/address: ([^,]+).*name: "([^"]+)".*/\1;\2/'
}

############################################
# Actions
############################################

connect_device() {
    local name="$1"
    local mac="$2"

    log "Connecting to $name"
    blueutil --connect "$mac"
}

unpair_and_repair_device() {
    local name="$1"
    local mac="$2"

    log "Unpairing $name"
    blueutil --unpair "$mac"
    sleep 2

    log "Re-pairing $name"
    blueutil --pair "$mac"
}

############################################
# Main logic
############################################

devices=$(find_paired_magic_devices)

if [[ -z "$devices" ]]; then
    log "No paired Magic devices found"
    exit 0
fi

while IFS=';' read -r mac name; do
    log "Processing: $name ($mac)"

    if is_connected "$mac"; then
        log "$name already connected"
        continue
    fi

    if is_keyboard "$name"; then
        log "Keyboard detected — connect only (never unpair)"
        connect_device "$name" "$mac" || log "Failed to connect keyboard"
        continue
    fi

    # Mouse / Trackpad
    if connect_device "$name" "$mac"; then
        log "$name connected successfully"
        continue
    fi

    if $FORCE; then
        log "Connect failed — FORCE enabled, retrying with unpair + pair"
        unpair_and_repair_device "$name" "$mac" \
            && connect_device "$name" "$mac" \
            || log "Failed to reconnect $name even in FORCE mode"
    else
        log "Connect failed — not unpairing (use --force to override)"
    fi

done <<< "$devices"

log "Done"
