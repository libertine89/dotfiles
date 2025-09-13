#!/bin/bash
## Swapping to Hyprscroller

CONF_DIR="$HOME/.config/hypr/conf"

## Array of files to configure: Name | File to write to | Included file (based on hyprscroller)
configs=(
  "keybindings|keybindings.conf|keybindings/hyprscroller-bindings.conf"
  "layout|layout.conf|layouts/hyprscroller-layout.conf"
  "animation|animation.conf|animations/hyprscroller-animations.conf"
)

for config in "${configs[@]}"; do
  IFS='|' read -r name config_file included_file <<< "$config"

  full_config_path="${CONF_DIR}/${config_file}"
  full_included_path="${CONF_DIR}/${included_file}"

  if [[ ! -f "$full_included_path" ]]; then
    echo "Warning: $full_included_path does not exist. Skipping $name."
    continue
  fi

  short_included_path=$(echo "$full_included_path" | sed "s|^$HOME|~|")

  echo "DEBUG: HOME is $HOME"
  echo "DEBUG: full_included_path is $full_included_path"
  echo "DEBUG: short_included_path is $short_included_path"

  sed -i "s|^source = .*|source = $short_included_path|" "$full_config_path"
  echo "Switched $name to hyprscroller: $short_included_path"
  
done

hyprctl reload
