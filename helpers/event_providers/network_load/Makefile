# Derived from FelixKratz/dotfiles (GPL-3.0-only).
# Copyright (C) Felix Kratz.
# Copyright (C) 2026 MRK (modifications).
# SPDX-License-Identifier: GPL-3.0-only

bin/network_load: network_load.c network.c network.h ../sketchybar.h | bin
	clang -std=c99 -O3 network_load.c network.c -o $@

bin:
	mkdir bin
