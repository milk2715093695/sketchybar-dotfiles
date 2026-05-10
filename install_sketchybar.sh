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
(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)
