#!/usr/bin/env bash
set -euo pipefail

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
