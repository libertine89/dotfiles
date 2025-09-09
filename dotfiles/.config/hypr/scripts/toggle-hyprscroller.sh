#!/bin/bash
## Toggle Hyprland & Hyprscroller Modes

# Define base configuration directory
CONF_DIR="$HOME/.config/hypr/conf/"

# Define an array of configurations (keybindings, layout, and animation)
configs=(
  "keybindings|keybindings.conf|keybindings/hyprland-bindings.conf|keybindings/hyprscroller-bindings.conf"
  "layout|layout.conf|layouts/hyprland-layout.conf|layouts/hyprscroller-layout.conf"
  "animation|animation.conf|animations/hyprland-animations.conf|animations/hyprscroller-animations.conf"
)

# Loop through each config and toggle
for config in "${configs[@]}"; do
  IFS='|' read -r name config_file current_file alt_file <<< "$config"

  # Construct full paths for each config
  config_file="$CONF_DIR$config_file"
  current_file="$CONF_DIR$current_file"
  alt_file="$CONF_DIR$alt_file"

  # Get the current source path
  CURRENT=$(grep -oP "(?<=source = ).*" "$config_file")

  # Determine which file to switch to
  if [[ "$CURRENT" == "$current_file" ]]; then
    NEW="$alt_file"
  else
    NEW="$current_file"
  fi

  # Update the config file
  sed -i "s|^source = .*|source = $NEW|" "$config_file"

  # Print debugging info for each config
  echo "Toggled $name: Current = $CURRENT, New = $NEW"
done

# Reload Hyprland to apply changes
hyprctl reload
