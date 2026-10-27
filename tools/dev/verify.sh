#!/bin/bash
# SPDX-FileCopyrightText: 2026 Martin Pluskal <martin@pluskal.org>
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Development helper for test machines: it changes the desktop's settings.
# Packages install the theme with tools/install.py (make install) instead.
#
# Report which halloween-openSUSE pieces are active. Run as the desktop user;
# the login-screen and initrd checks use `sudo -n` when it is available.
# Worth re-running after every `zypper dup`.
set -uo pipefail
. "$(dirname "$0")/common.sh"
session_env

DATA=${XDG_DATA_HOME:-$HOME/.local/share}
URL="file://$DATA/wallpapers/$WALLPAPER_ID#day-night"
problems=0

check() {
    local label=$1 actual=$2 expected=$3
    if [ "$actual" = "$expected" ]; then
        printf '  ok    %-28s %s\n' "$label" "${actual:-<unset>}"
    else
        printf '  FAIL  %-28s %s (expected %s)\n' "$label" "${actual:-<unset>}" "${expected:-<unset>}"
        problems=$((problems + 1))
    fi
}
kread() { kreadconfig6 --file "$@"; }

echo "Plasma session"
check "look-and-feel" "$(kread kdeglobals --group KDE --key LookAndFeelPackage)" "$LNF_ID"
check "Plasma style" "$(kread plasmarc --group Theme --key name)" "$STYLE_ID"
check "colour scheme" "$(kread kdeglobals --group General --key ColorScheme)" "$SCHEME_ID"
check "custom accent colour" "$(kread kdeglobals --group General --key AccentColor)" ""
check "icon theme" "$(kread kdeglobals --group Icons --key Theme)" "$ICONS_ID"
check "splash" "$(kread ksplashrc --group KSplash --key Theme)" "$LNF_ID"
i=0
for image in $(plasma_script 'print(desktops().map(d => { d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"]; return d.readConfig("Image") }).join(" "))'); do
    check "desktop $i wallpaper" "$image" "$URL"
    i=$((i + 1))
done
check "lock screen wallpaper" "$(kread kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image)" "$URL"
# Plasma looks in ~/.local/share first and /usr/local/share after, per file:
# a stale system copy shows through wherever the user copy lacks a file
for d in "plasma/desktoptheme/$STYLE_ID" "icons/$ICONS_ID" "plasma/look-and-feel/$LNF_ID" "wallpapers/$WALLPAPER_ID"; do
    [ -d "/usr/local/share/$d" ] && [ -d "$DATA/$d" ] || continue
    diff -rq "$DATA/$d" "/usr/local/share/$d" >/dev/null && v=same || v=different
    check "system copy, $(basename "$d")" "$v" same
done

dm=$(systemctl show -P Id display-manager.service 2>/dev/null)
if [ "$dm" = sddm.service ]; then
    echo "Login screen (SDDM)"
    current=$(cat /usr/lib/sddm/sddm.conf.d/*.conf /etc/sddm.conf.d/*.conf /etc/sddm.conf 2>/dev/null \
        | awk -F= '/^\[/ { s = $0; next } s == "[Theme]" && $1 == "Current" { c = $2 } END { print c }')
    check "effective theme" "$current" "$SDDM_ID"
    check "dangling theme symlinks" "$(find "/usr/share/sddm/themes/$SDDM_ID" -xtype l 2>/dev/null | wc -l)" 0
    sddm_home=$(getent passwd sddm | cut -d: -f6)
    if sudo -n true 2>/dev/null; then
        check "greeter colour scheme" "$(sudo -n kreadconfig6 --file "$sddm_home/.config/kdeglobals" --group General --key ColorScheme)" "$SCHEME_ID"
        check "greeter Plasma style" "$(sudo -n kreadconfig6 --file "$sddm_home/.config/plasmarc" --group Theme --key name)" "$STYLE_ID"
    else
        echo "  skip  greeter settings (needs sudo)"
    fi
elif [ "$dm" = plasmalogin.service ]; then
    echo "Login screen (Plasma Login Manager)"
    # What the greeter reads, in its order (settings/plasmaloginsettings.cpp):
    # every file in its drop-in folders, and a later file wins (KConfig)
    plm_files=()
    for f in /etc/plasmalogin.conf.d/* /usr/lib/plasmalogin/defaults.conf /usr/lib/plasmalogin/plasmalogin.conf.d/* /etc/plasmalogin.conf; do
        [ -f "$f" ] && plm_files+=("$f")
    done
    plm_get() {  # plm_get GROUP KEY
        [ ${#plm_files[@]} -gt 0 ] || return 0
        awk -v g="$1" -v k="$2" '
            /^[ \t]*\[/ { s = $0; sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); next }
            s == g && index($0, "=") {
                key = substr($0, 1, index($0, "=") - 1); gsub(/^[ \t]+|[ \t]+$/, "", key)
                if (key == k) { v = substr($0, index($0, "=") + 1); gsub(/^[ \t]+|[ \t]+$/, "", v) }
            }
            END { print v }' "${plm_files[@]}"
    }
    plugin=$(plm_get "[Greeter]" WallpaperPluginId)
    check "wallpaper plugin" "${plugin:-org.kde.image}" org.kde.image
    check "effective background" "$(plm_get "[Greeter][Wallpaper][org.kde.image][General]" Image)" "$PLASMALOGIN_IMAGE"
    plm_home=$(getent passwd plasmalogin | cut -d: -f6)
    if sudo -n true 2>/dev/null; then
        check "greeter global theme" "$(sudo -n kreadconfig6 --file "$plm_home/.config/kdeglobals" --group KDE --key LookAndFeelPackage)" "$LNF_ID"
        scheme=$(sudo -n kreadconfig6 --file "$plm_home/.config/kdeglobals" --group General --key ColorScheme)
        [ -n "$scheme" ] || scheme=$(sudo -n kreadconfig6 --file "$plm_home/.config/kdedefaults/kdeglobals" --group General --key ColorScheme)
        check "greeter colour scheme" "$scheme" "$SCHEME_ID"
    else
        echo "  skip  greeter settings (needs sudo)"
    fi
else
    echo "Login screen: ${dm:-no display manager} (not checked)"
fi

echo "Boot splash (Plymouth)"
check "default theme" "$(plymouth-set-default-theme)" "$PLYMOUTH_ID"
grep -qw splash=silent /proc/cmdline && v=yes || v=no
check "splash=silent on command line" "$v" yes
if sudo -n true 2>/dev/null; then
    esp=$(sudo -n bootctl --print-esp-path 2>/dev/null)
    initrd=$(sudo -n bootctl list --json=short 2>/dev/null | jq -r '[.[] | select(.isDefault)][0].initrd[0] // empty')
    if [ -n "$initrd" ]; then
        contents=$(sudo -n lsinitrd "$esp$initrd" 2>/dev/null)
        grep -q "plymouth/themes/$PLYMOUTH_ID/" <<<"$contents" && v=yes || v=no
        check "theme in default initrd" "$v" yes
    else
        echo "  skip  initrd contents (no default boot entry found)"
    fi
else
    echo "  skip  initrd contents (needs sudo)"
fi

echo
if [ "$problems" = 0 ]; then echo "everything is active"; else echo "$problems problem(s)"; fi
exit $((problems > 0))
