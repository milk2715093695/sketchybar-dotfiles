#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[32m'
RED='\033[31m'
RESET='\033[0m'

supports_color() {
    [ -z "${NO_COLOR:-}" ] && [ -t 1 ]
}

print_status() {
    local status="$1" item="$2"
    if supports_color; then
        local color="$GREEN"
        [ "$status" = "FAIL" ] && color="$RED"
        printf '%b[%s]%b   %s\n' "$color" "$status" "$RESET" "$item"
    else
        printf '[%s]   %s\n' "$status" "$item"
    fi
}

echo "Installing Dependencies"

# Packages
brew install lua
brew install switchaudio-osx
brew install nowplaying-cli

brew tap FelixKratz/formulae
brew install sketchybar

# Fonts
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-sketchybar-app-font

# icon_map.lua 由 brew 管理字体版本；手动同步以匹配已安装字体
FONT_VERSION=$(brew list --cask --versions font-sketchybar-app-font 2>/dev/null | awk '{print $2}' || true)
if [ -z "$FONT_VERSION" ]; then
    echo "Warning: font-sketchybar-app-font not installed, skipping icon_map download"
else
    echo "Syncing icon_map.lua for sketchybar-app-font v$FONT_VERSION"
    curl -fSL --connect-timeout 10 \
        "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v${FONT_VERSION}/icon_map.lua" \
        -o "$SCRIPT_DIR/config/icon_map.lua"
fi

# SbarLua
SBARLUA_DIR="/tmp/SbarLua"
SBARLUA_SO="$HOME/.local/share/sketchybar_lua/sketchybar.so"

if [ -f "$SBARLUA_SO" ]; then
    if [ -d "$SBARLUA_DIR" ]; then
        git -C "$SBARLUA_DIR" fetch origin 2>/dev/null
    else
        git clone --depth 1 https://github.com/FelixKratz/SbarLua.git "$SBARLUA_DIR"
    fi
    if ! git -C "$SBARLUA_DIR" diff --quiet HEAD..origin/main; then
        echo "SbarLua: update available, rebuilding..."
        git -C "$SBARLUA_DIR" pull origin main && make -C "$SBARLUA_DIR" install
    else
        echo "SbarLua: already up to date, skip"
    fi
else
    rm -rf "$SBARLUA_DIR"
    git clone https://github.com/FelixKratz/SbarLua.git "$SBARLUA_DIR"
    make -C "$SBARLUA_DIR" install
fi

# Build helpers (soft failure — bar skips affected widgets at runtime)
echo "Building helper binaries..."
make -C "$SCRIPT_DIR/helpers" || echo "Warning: helper build failed (check Xcode CLI tools)"

# Verification
echo ""
echo "Verification:"
brew list lua &>/dev/null && print_status "OK" "lua" || print_status "FAIL" "lua"
brew list switchaudio-osx &>/dev/null && print_status "OK" "switchaudio-osx" || print_status "FAIL" "switchaudio-osx"
brew list nowplaying-cli &>/dev/null && print_status "OK" "nowplaying-cli" || print_status "FAIL" "nowplaying-cli"
brew list sketchybar &>/dev/null && print_status "OK" "sketchybar" || print_status "FAIL" "sketchybar"
brew list --cask font-jetbrains-mono-nerd-font &>/dev/null && print_status "OK" "font-jetbrains-mono-nerd-font" || print_status "FAIL" "font-jetbrains-mono-nerd-font"
brew list --cask font-sketchybar-app-font &>/dev/null && print_status "OK" "font-sketchybar-app-font" || print_status "FAIL" "font-sketchybar-app-font"
[ -f "$SCRIPT_DIR/config/icon_map.lua" ] && print_status "OK" "icon_map.lua" || print_status "FAIL" "icon_map.lua"
[ -f "$SBARLUA_SO" ] && print_status "OK" "SbarLua" || print_status "FAIL" "SbarLua"
[ -f "$SCRIPT_DIR/helpers/menus/bin/menus" ] && print_status "OK" "menus" || print_status "FAIL" "menus"
[ -f "$SCRIPT_DIR/helpers/event_providers/cpu_load/bin/cpu_load" ] && print_status "OK" "cpu_load" || print_status "FAIL" "cpu_load"
[ -f "$SCRIPT_DIR/helpers/event_providers/network_load/bin/network_load" ] && print_status "OK" "network_load" || print_status "FAIL" "network_load"
