#!/usr/bin/env bash

set -euo pipefail

ACTION="${1:-help}"
DRY_RUN=false

if [[ "${2:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

note() { echo "[defaults] $*"; }
run() {
    if $DRY_RUN; then
        note "(dry) $*"
    else
        eval "$@"
    fi
}

apply_finder() {
    note "Finder: path bar + folders first"
    run "defaults write com.apple.finder ShowPathbar -bool true"
    run "defaults write com.apple.finder _FXSortFoldersFirst -bool true"
    RESTART_SERVICES+=(Finder)
}

apply_textedit() {
    note "TextEdit: plain text UTF-8"
    run "defaults write com.apple.TextEdit RichText -int 0"
    run "defaults write com.apple.TextEdit PlainTextEncoding -int 4"
    run "defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4"
}

apply_keyboard() {
    note "Keyboard: fast repeat"
    # Reasonable fast values (Apple typical fast ~2, initial ~15)
    run "defaults write -g KeyRepeat -int 2"
    run "defaults write -g InitialKeyRepeat -int 15"
}

apply_dock() {
    note "Dock: scale minimize, minimize to app, hide recents"
    run "defaults write com.apple.dock mineffect -string 'scale'"
    run "defaults write com.apple.dock minimize-to-application -bool true"
    run "defaults write com.apple.dock show-recents -bool false"
    RESTART_SERVICES+=(Dock)
}

apply_trackpad() {
    note "Trackpad: tap to click + app expose gesture"
    run "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true"
    run "defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1"
    run "defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1"
    run "defaults write com.apple.dock showAppExposeGestureEnabled -bool true"
    RESTART_SERVICES+=(Dock)
}

LIST_ORDER=(finder textedit keyboard dock trackpad)

apply_all() {
    RESTART_SERVICES=()
    apply_finder
    apply_textedit
    apply_keyboard
    apply_dock
    apply_trackpad
    if ! $DRY_RUN; then
        # Deduplicate services
        mapfile -t UNIQUE < <(printf '%s\n' "${RESTART_SERVICES[@]}" | awk '!seen[$0]++')
        for svc in "${UNIQUE[@]}"; do
            note "Restarting $svc"
            killall "$svc" 2>/dev/null || true
        done
    else
        note "(dry) Would restart: ${RESTART_SERVICES[*]:-none}"
    fi
    note "Done. Some changes may require log out / log in."
}

list() {
    cat <<EOF
Available groups:
    finder     - Path bar, folders first
    textedit   - Plain text UTF-8 defaults
    keyboard   - Fast key repeat
    dock       - Scale minimize, minimize-to-app, hide recents
    trackpad   - Tap to click, App Exposé gesture
Usage:
    $(basename "$0") apply [--dry-run]
    $(basename "$0") list
    $(basename "$0") apply <group> [--dry-run]
EOF
}

case "$ACTION" in
    list|help|-h|--help) list ;;
    apply)
        TARGET="${2:-all}"
        if [[ "$TARGET" == "--dry-run" ]]; then TARGET=all; fi
        if [[ "${3:-}" == "--dry-run" ]]; then DRY_RUN=true; fi
        if [[ "$TARGET" == "all" ]]; then
            apply_all
        else
            # single group
            RESTART_SERVICES=()
            fn="apply_${TARGET}"
            if declare -f "$fn" >/dev/null 2>&1; then
                "$fn"
                if ! $DRY_RUN; then
                    for svc in "${RESTART_SERVICES[@]}"; do
                        note "Restarting $svc"
                        killall "$svc" 2>/dev/null || true
                    done
                fi
            else
                echo "Unknown group: $TARGET" >&2
                list
                exit 1
            fi
        fi
        ;;
    *)
        echo "Unknown action: $ACTION" >&2
        list
        exit 1
        ;;
esac