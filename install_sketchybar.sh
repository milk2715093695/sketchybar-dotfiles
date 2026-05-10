#!/usr/bin/env bash
set -euo pipefail

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

# Detect latest sketchybar-app-font version
FALLBACK_FONT_VERSION="v2.0.56"
FONT_VERSION=$(curl -fsSL --connect-timeout 10 https://api.github.com/repos/kvndrsslr/sketchybar-app-font/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4 || true)
if [ -z "$FONT_VERSION" ]; then
    echo "Warning: Could not detect latest font version, using fallback $FALLBACK_FONT_VERSION"
    FONT_VERSION="$FALLBACK_FONT_VERSION"
else
    echo "Detected latest sketchybar-app-font version: $FONT_VERSION"
fi

# Packages
brew install lua
brew install switchaudio-osx
brew install nowplaying-cli

brew tap FelixKratz/formulae
brew install sketchybar

# Fonts
brew install --cask font-jetbrains-mono-nerd-font

FONT_URL="https://github.com/kvndrsslr/sketchybar-app-font/releases/download/${FONT_VERSION}/sketchybar-app-font.ttf"
ICON_MAP_URL="https://github.com/kvndrsslr/sketchybar-app-font/releases/download/${FONT_VERSION}/icon_map.lua"

mkdir -p "$HOME/Library/Fonts"
mkdir -p "$HOME/.config/sketchybar/config"

curl -fSL --connect-timeout 10 "$FONT_URL" -o "$HOME/Library/Fonts/sketchybar-app-font.ttf"
curl -fSL --connect-timeout 10 "$ICON_MAP_URL" -o "$HOME/.config/sketchybar/config/icon_map.lua"

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

# Verification
echo ""
echo "Verification:"
brew list lua &>/dev/null && print_status "OK" "lua" || print_status "FAIL" "lua"
brew list switchaudio-osx &>/dev/null && print_status "OK" "switchaudio-osx" || print_status "FAIL" "switchaudio-osx"
brew list nowplaying-cli &>/dev/null && print_status "OK" "nowplaying-cli" || print_status "FAIL" "nowplaying-cli"
brew list sketchybar &>/dev/null && print_status "OK" "sketchybar" || print_status "FAIL" "sketchybar"
brew list --cask font-jetbrains-mono-nerd-font &>/dev/null && print_status "OK" "font-jetbrains-mono-nerd-font" || print_status "FAIL" "font-jetbrains-mono-nerd-font"
[ -f "$HOME/Library/Fonts/sketchybar-app-font.ttf" ] && print_status "OK" "sketchybar-app-font.ttf" || print_status "FAIL" "sketchybar-app-font.ttf"
[ -f "$HOME/.config/sketchybar/config/icon_map.lua" ] && print_status "OK" "icon_map.lua" || print_status "FAIL" "icon_map.lua"
[ -f "$SBARLUA_SO" ] && print_status "OK" "SbarLua" || print_status "FAIL" "SbarLua"
