#!/bin/bash
## Toggle Hyprland & Hyprscroller Modes

## Array of files to toggle between. -- Key Name | File to Write to | File 1 | FIle 2 |
configs=(
  "keybindings|keybindings.conf|keybindings/hyprland-bindings.conf|keybindings/hyprscroller-bindings.conf"
  "layout|layout.conf|layouts/hyprland-layout.conf|layouts/hyprscroller-layout.conf"
  "animation|animation.conf|animations/hyprland-animations.conf|animations/hyprscroller-animations.conf"
)

CONF_DIR="$HOME/.config/hypr/conf/"

for config in "${configs[@]}"; do
  IFS='|' read -r name config_file file1 file2 <<< "$config"

  config_file="$CONF_DIR$config_file"
  file1="$CONF_DIR$file1"
  file2="$CONF_DIR$file2"

  CURRENT=$(grep -oP "(?<=source = ).*" "$config_file")

  if [[ "$CURRENT" == "$file1" ]]; then
    NEW="$file2"
  else
    NEW="$file1"
  fi

  sed -i "s|^source = .*|source = $NEW|" "$config_file"
  echo "Toggled $name: Current = $CURRENT, New = $NEW"
done

hyprctl reload
