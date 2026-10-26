# Derived from FelixKratz/dotfiles (GPL-3.0-only).
# Copyright (C) Felix Kratz.
# Copyright (C) 2026 MRK (modifications).
# SPDX-License-Identifier: GPL-3.0-only

bin/cpu_load: cpu_load.c cpu.c cpu.h ../sketchybar.h | bin
	clang -std=c99 -O3 cpu_load.c cpu.c -o $@

bin:
	mkdir bin
