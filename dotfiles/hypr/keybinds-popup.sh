#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  ~/.config/hypr/keybinds-popup.sh
#  Keybind cheatsheet popup for Hyprland
#  Requires: yad  →  sudo pacman -S yad
#  Triggered by: SUPER + /
#  The window rule "class:^(keybind-popup)$" in hyprland.lua
#  will float and pin it automatically.
# ─────────────────────────────────────────────────────────────

yad --title="Keybind Cheatsheet" \
    --class="keybind-popup" \
    --geometry=700x520 \
    --center \
    --no-buttons \
    --list \
    --column="Keys:100" \
    --column="Action:500" \
    --separator="" \
    --print-column="" \
    --no-selection \
    \
    "── CORE ───────────────────────────────────────" "" \
    "SUPER + Return"        "Open terminal (Kitty)" \
    "SUPER + E"             "Open file manager (Nemo)" \
    "SUPER + Space"         "Open app launcher (Hyprlauncher)" \
    "SUPER + Q"             "Close active window" \
    "SUPER + F"             "Toggle fullscreen" \
    "SUPER + V"             "Toggle floating" \
    "SUPER + P"             "Toggle dwindle split" \
    "SUPER + Tab"           "Cycle / bring window to top" \
    \
    "── SESSION ────────────────────────────────────" "" \
    "SUPER + L"             "Lock screen (hyprlock)" \
    "SUPER + SHIFT + R"     "Reload Hyprland config" \
    "SUPER + SHIFT + E"     "Exit Hyprland" \
    \
    "── FOCUS ──────────────────────────────────────" "" \
    "SUPER + H / ←"         "Focus left" \
    "SUPER + J / ↓"         "Focus down" \
    "SUPER + K / ↑"         "Focus up" \
    "SUPER + L / →"         "Focus right" \
    \
    "── MOVE WINDOW ────────────────────────────────" "" \
    "SUPER + SHIFT + H / ←" "Move window left" \
    "SUPER + SHIFT + J / ↓" "Move window down" \
    "SUPER + SHIFT + K / ↑" "Move window up" \
    "SUPER + SHIFT + L / →" "Move window right" \
    \
    "── RESIZE WINDOW ──────────────────────────────" "" \
    "SUPER + CTRL + H"      "Resize window left" \
    "SUPER + CTRL + J"      "Resize window down" \
    "SUPER + CTRL + K"      "Resize window up" \
    "SUPER + CTRL + L"      "Resize window right" \
    \
    "── WORKSPACES ─────────────────────────────────" "" \
    "SUPER + 1–9"            "Go to workspace 1–9" \
    "SUPER + SHIFT + 1–9"    "Move window to workspace 1–9" \
    "SUPER + S"              "Toggle scratchpad (special)" \
    "SUPER + SHIFT + S"      "Move window to scratchpad" \
    "SUPER + Scroll ↑/↓"    "Cycle workspaces with mouse wheel" \
    \
    "── SCREENSHOTS ────────────────────────────────" "" \
    "Print"                 "Full-screen screenshot (clipboard)" \
    "SUPER + Print"         "Select-area screenshot (clipboard)" \
    "SUPER + SHIFT + Print" "Select-area screenshot (save to file)" \
    \
    "── AUDIO ──────────────────────────────────────" "" \
    "Fn + F2 / F3"          "Volume down / up" \
    "Fn + F4"               "Mute audio" \
    "Fn + F5"               "Mute microphone" \
    \
    "── BRIGHTNESS ─────────────────────────────────" "" \
    "Fn + F5 / F6"          "Brightness down / up" \
    \
    "── MOUSE ──────────────────────────────────────" "" \
    "SUPER + LMB drag"      "Move floating window" \
    "SUPER + RMB drag"      "Resize floating window" \
    \
    "── MISC ───────────────────────────────────────" "" \
    "SUPER + /"             "This cheatsheet" \
    "SUPER + XF86Display"   "Open display settings (wdisplays)"
