#!/usr/bin/env bash
# macOS defaults, grouped. Must stay compatible with the stock /bin/bash (3.2)
# because this runs on a fresh Mac before any newer bash is installed.

set -euo pipefail

DRY_RUN=false
CHANGES=0
RESTART_SERVICES=()

note() { echo "[defaults] $*"; }

# write_default [-currentHost] <domain> <key> <type> <value>
# Reads the current value first and only writes when it differs, so re-runs
# are quiet and --dry-run shows exactly what would change.
write_default() {
    local host=()
    if [[ "$1" == "-currentHost" ]]; then host=(-currentHost); shift; fi
    local domain="$1" key="$2" type="$3" value="$4" want current

    case "$type" in
        -bool) if [[ "$value" == "true" ]]; then want=1; else want=0; fi ;;
        *) want="$value" ;;
    esac

    # ${host[@]+...} guards against "unbound variable" for empty arrays in bash 3.2
    current="$(defaults ${host[@]+"${host[@]}"} read "$domain" "$key" 2>/dev/null)" || current="<unset>"

    if [[ "$current" == "$want" ]]; then
        return 0
    fi
    # Numeric types can read back as 2 vs 2.0 etc.
    if [[ "$type" == "-int" || "$type" == "-float" ]] && [[ "$current" != "<unset>" ]] &&
        awk -v a="$current" -v b="$want" 'BEGIN { exit !(a + 0 == b + 0) }'; then
        return 0
    fi

    CHANGES=$((CHANGES + 1))
    if $DRY_RUN; then
        note "(dry) $domain $key: $current -> $want"
    else
        note "$domain $key: $current -> $want"
        defaults ${host[@]+"${host[@]}"} write "$domain" "$key" "$type" "$value"
    fi
}

needs_restart() {
    local svc="$1" s
    for s in ${RESTART_SERVICES[@]+"${RESTART_SERVICES[@]}"}; do
        [[ "$s" == "$svc" ]] && return 0
    done
    RESTART_SERVICES+=("$svc")
}

# Each group restarts its app only if it actually changed something.
apply_finder() {
    note "Finder: path/status bar, folders first, show extensions, search current folder"
    local before=$CHANGES
    write_default com.apple.finder ShowPathbar -bool true
    write_default com.apple.finder ShowStatusBar -bool true
    write_default com.apple.finder _FXSortFoldersFirst -bool true
    write_default NSGlobalDomain AppleShowAllExtensions -bool true
    write_default com.apple.finder FXEnableExtensionChangeWarning -bool false
    write_default com.apple.finder FXDefaultSearchScope -string SCcf
    # Don't litter network shares and USB drives with .DS_Store files
    write_default com.apple.desktopservices DSDontWriteNetworkStores -bool true
    write_default com.apple.desktopservices DSDontWriteUSBStores -bool true
    if ls -lOd "$HOME/Library" | grep -q hidden; then
        CHANGES=$((CHANGES + 1))
        if $DRY_RUN; then note "(dry) unhide ~/Library"; else note "unhide ~/Library"; chflags nohidden "$HOME/Library"; fi
    fi
    if [[ $CHANGES -gt $before ]]; then needs_restart Finder; fi
}

apply_textedit() {
    note "TextEdit: plain text UTF-8"
    write_default com.apple.TextEdit RichText -int 0
    write_default com.apple.TextEdit PlainTextEncoding -int 4
    write_default com.apple.TextEdit PlainTextEncodingForWrite -int 4
}

apply_keyboard() {
    note "Keyboard: fast repeat"
    # Reasonable fast values (Apple typical fast ~2, initial ~15)
    write_default NSGlobalDomain KeyRepeat -int 2
    write_default NSGlobalDomain InitialKeyRepeat -int 15
}

apply_typing() {
    note "Typing: no auto-correct, smart quotes, smart dashes, or double-space period"
    write_default NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    write_default NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    write_default NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    write_default NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
}

apply_dialogs() {
    note "Dialogs: expand save and print panels by default"
    write_default NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    write_default NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
    write_default NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    write_default NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
}

apply_dock() {
    note "Dock: scale minimize, minimize to app, hide recents"
    local before=$CHANGES
    write_default com.apple.dock mineffect -string scale
    write_default com.apple.dock minimize-to-application -bool true
    write_default com.apple.dock show-recents -bool false
    if [[ $CHANGES -gt $before ]]; then needs_restart Dock; fi
}

apply_trackpad() {
    note "Trackpad: tap to click + app expose gesture"
    local before=$CHANGES
    write_default com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    write_default -currentHost NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    write_default NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    write_default com.apple.dock showAppExposeGestureEnabled -bool true
    if [[ $CHANGES -gt $before ]]; then needs_restart Dock; fi
}

apply_screenshots() {
    local dir="$HOME/Screenshots"
    note "Screenshots: save PNGs to $dir, no window shadow"
    local before=$CHANGES
    if [[ ! -d "$dir" ]]; then
        if $DRY_RUN; then note "(dry) mkdir $dir"; else mkdir -p "$dir"; fi
    fi
    write_default com.apple.screencapture location -string "$dir"
    write_default com.apple.screencapture type -string png
    write_default com.apple.screencapture disable-shadow -bool true
    if [[ $CHANGES -gt $before ]]; then needs_restart SystemUIServer; fi
}

apply_activitymonitor() {
    note "Activity Monitor: show all processes, sort by CPU"
    local before=$CHANGES
    write_default com.apple.ActivityMonitor ShowCategory -int 0
    write_default com.apple.ActivityMonitor SortColumn -string CPUUsage
    write_default com.apple.ActivityMonitor SortDirection -int 0
    if [[ $CHANGES -gt $before ]]; then needs_restart "Activity Monitor"; fi
}

ALL_GROUPS=(finder textedit keyboard typing dialogs dock trackpad screenshots activitymonitor)

list() {
    cat <<EOF
Available groups:
    finder          - Path/status bar, folders first, show extensions, search current folder,
                      no .DS_Store on network/USB, unhide ~/Library
    textedit        - Plain text UTF-8 defaults
    keyboard        - Fast key repeat
    typing          - Disable auto-correct, smart quotes/dashes, double-space period
    dialogs         - Expanded save & print panels
    dock            - Scale minimize, minimize-to-app, hide recents
    trackpad        - Tap to click, App Exposé gesture
    screenshots     - Save PNGs to ~/Screenshots, no window shadow
    activitymonitor - Show all processes, sort by CPU
Usage:
    $(basename "$0") list
    $(basename "$0") apply [group ...] [--dry-run]     (no groups = all)
EOF
}

restart_services() {
    if [[ ${#RESTART_SERVICES[@]} -eq 0 ]]; then return 0; fi
    local svc
    for svc in "${RESTART_SERVICES[@]}"; do
        if $DRY_RUN; then
            note "(dry) would restart $svc"
        else
            note "Restarting $svc"
            killall "$svc" 2>/dev/null || true
        fi
    done
}

main() {
    local action="${1:-help}"
    [[ $# -gt 0 ]] && shift

    local groups=() arg
    for arg in "$@"; do
        case "$arg" in
            --dry-run) DRY_RUN=true ;;
            -*) echo "Unknown option: $arg" >&2; list; exit 1 ;;
            *) groups+=("$arg") ;;
        esac
    done

    case "$action" in
        list|help|-h|--help) list; return 0 ;;
        apply) ;;
        *) echo "Unknown action: $action" >&2; list; exit 1 ;;
    esac

    if [[ ${#groups[@]} -eq 0 ]]; then groups=("${ALL_GROUPS[@]}"); fi

    local g
    for g in "${groups[@]}"; do
        if ! declare -f "apply_$g" >/dev/null; then
            echo "Unknown group: $g" >&2; list; exit 1
        fi
    done

    # An open System Settings window can overwrite values we write.
    if ! $DRY_RUN && pgrep -xq "System Settings"; then
        note "Closing System Settings"
        osascript -e 'tell application "System Settings" to quit' || true
    fi

    for g in "${groups[@]}"; do "apply_$g"; done

    restart_services
    if $DRY_RUN; then
        note "Dry run: $CHANGES setting(s) would change."
    else
        note "Done: $CHANGES setting(s) changed. Some changes may require log out / log in."
    fi
}

main "$@"
