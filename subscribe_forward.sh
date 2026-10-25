#!/usr/bin/env bash
# 将 aerospace subscribe 的增量事件转发为 sketchybar trigger。
# 由 aerospace after-startup-command 拉起；subscribe 进程退出后不会自动重启。
# 不用 set -e —— sketchybar 重启瞬间 trigger 会失败，set -e 会杀掉整个管道。
# --no-send-initial：初始态事件会折叠 menus.lua 的菜单（原版启动无事件），aero_ws 有 init 全量刷新兜底。
# AeroSpace 重启但 sketchybar 未重启时，主动触发一次全量 resync；冷启动事件丢失由 aero_ws init 兜底。
sketchybar --trigger aerospace_resync 2>/dev/null || true
aerospace subscribe --all --no-send-initial | while IFS= read -r line; do
    sketchybar --trigger aerospace_event EVENT_JSON="$line" || true
    case "$line" in
        *focused-workspace-changed*) sketchybar --trigger aerospace_workspace_change || true ;;
    esac
done
