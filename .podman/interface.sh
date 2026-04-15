#!/bin/sh

image="${1:-docker.io/taylorabarnes/devenv:latest}"
port="${2:-56610}"

# Check if host has X11 available
if [ -n "$DISPLAY" ] && [ -e "/tmp/.X11-unix/X${DISPLAY#:}" ]; then
  # Use Vulkan backend with host X11 (Intel GPU has good Vulkan support)
  # Force X11 backend for winit (not Wayland)
  DRI_ARGS=""
  if [ -e /dev/dri ]; then
    DRI_ARGS="--device /dev/dri --group-add keep-groups"
  fi
  X11_ARGS="-e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -e XDG_RUNTIME_DIR=/tmp/runtime -e WINIT_UNIX_BACKEND=x11 ${DRI_ARGS} --security-opt label=disable"
  XVFB_PREFIX="mkdir -p /tmp/runtime && "
  echo "Note: Host X11 display detected. GPU acceleration enabled."
else
  # No host X11 - use Xvfb inside the container
  # Note: GPU apps (Bevy, wgpu) won't work properly with Xvfb due to lack of DRI3 support
  # Force OpenGL software rendering for basic X11 apps
  DRI_ARGS=""
  if [ -e /dev/dri ]; then
    DRI_ARGS="--device /dev/dri --group-add keep-groups"
  fi
  X11_ARGS="-e DISPLAY=:99 -e WGPU_BACKEND=gl -e WINIT_UNIX_BACKEND=x11 -e LIBGL_ALWAYS_SOFTWARE=1 -e XDG_RUNTIME_DIR=/tmp/runtime ${DRI_ARGS} --security-opt label=disable"
  XVFB_PREFIX="mkdir -p /tmp/runtime && Xvfb :99 -screen 0 1024x768x24 & sleep 1 && "
  echo "Note: No host X11 display detected. Using virtual framebuffer (Xvfb)."
  echo "Warning: GPU-accelerated apps (Bevy, wgpu) require a host X11 display."
  echo ""
fi

echo "Which of the following would you like to open?"
echo "1) Neovim"
echo "2) VS Code"
echo "3) Terminal (default)"
echo ""
echo "Note: VS Code requires the Remote Development extension pack:"
echo "      https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack"
echo ""
read -p "Enter your choice [1-3]: " choice
echo ""

# Set default if input is empty
choice=${choice:-3}

case $choice in
  1)
    echo "Opening Neovim"
    echo ""
    podman run --rm -it -v $(pwd):/work ${X11_ARGS} -v ~/.claude:/root/.claude:cached -v ~/.claude.json:/root/.claude.json ${image} bash -c "${XVFB_PREFIX}bash /.nvim/entrypoint.sh"
    ;;
  2)
    # Ensure podman socket is running (required by Dev Containers extension)
    if ! systemctl --user is-active --quiet podman.socket 2>/dev/null; then
      echo "Enabling podman socket..."
      systemctl --user enable --now podman.socket
    fi

    # Ensure VS Code user settings have podman configured
    # (workspace settings are too late - the extension reads these before opening the workspace)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      # WSL2: find the Windows-side VS Code user settings
      WIN_USER=$(wslpath "$(cmd.exe /C "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')")
      VSCODE_SETTINGS="${WIN_USER}/AppData/Roaming/Code/User/settings.json"
    else
      VSCODE_SETTINGS="${HOME}/.config/Code/User/settings.json"
    fi

    IS_WSL=false
    if grep -qi microsoft /proc/version 2>/dev/null; then
      IS_WSL=true
    fi

    if [ -f "$VSCODE_SETTINGS" ]; then
      NEEDS_DOCKER_PATH=false
      NEEDS_WSL_SETTING=false

      # Check value, not just key presence — a user may have "dockerPath": "docker"
      if ! grep -q '"dev.containers.dockerPath".*"podman"' "$VSCODE_SETTINGS" 2>/dev/null; then
        NEEDS_DOCKER_PATH=true
      fi
      if [ "$IS_WSL" = true ] && ! grep -q '"dev.containers.executeInWSL".*true' "$VSCODE_SETTINGS" 2>/dev/null; then
        NEEDS_WSL_SETTING=true
      fi

      if [ "$NEEDS_DOCKER_PATH" = true ] || [ "$NEEDS_WSL_SETTING" = true ]; then
        echo "WARNING: This will modify your VS Code USER settings (not workspace settings)."
        echo "This affects ALL Dev Container sessions on this machine, not just this project."
        echo "If you also use Docker-based Dev Containers, you will need to revert these settings."
        echo ""
        echo "File: $VSCODE_SETTINGS"
        echo ""
        echo "The following settings will be added or updated:"
        if [ "$NEEDS_DOCKER_PATH" = true ]; then
          echo '  "dev.containers.dockerPath": "podman"'
        fi
        if [ "$NEEDS_WSL_SETTING" = true ]; then
          echo '  "dev.containers.executeInWSL": true'
        fi
        echo ""
        echo "To revert later, open VS Code Settings (Ctrl+,) and:"
        echo '  - Remove or change "dev.containers.dockerPath" back to "docker"'
        if [ "$IS_WSL" = true ]; then
          echo '  - Remove "dev.containers.executeInWSL"'
        fi
        echo ""
        read -p "Apply these settings? [Y/n]: " apply
        apply=${apply:-Y}
        if echo "$apply" | grep -qi '^y'; then
          if [ "$NEEDS_DOCKER_PATH" = true ]; then
            if grep -q '"dev.containers.dockerPath"' "$VSCODE_SETTINGS" 2>/dev/null; then
              # Key exists with wrong value — update it in place
              sed -i 's/"dev.containers.dockerPath".*:.*"[^"]*"/"dev.containers.dockerPath": "podman"/' "$VSCODE_SETTINGS"
            else
              # Key missing — insert before closing brace
              sed -i '$ s/}$/,\n    "dev.containers.dockerPath": "podman"\n}/' "$VSCODE_SETTINGS"
            fi
          fi
          if [ "$NEEDS_WSL_SETTING" = true ]; then
            if grep -q '"dev.containers.executeInWSL"' "$VSCODE_SETTINGS" 2>/dev/null; then
              sed -i 's/"dev.containers.executeInWSL".*:.*\(true\|false\)/"dev.containers.executeInWSL": true/' "$VSCODE_SETTINGS"
            else
              sed -i '$ s/}$/,\n    "dev.containers.executeInWSL": true\n}/' "$VSCODE_SETTINGS"
            fi
          fi
          echo "Settings updated."
        else
          echo "Skipped. You may need to manually add these settings."
        fi
        echo ""
      fi
    else
      echo "Warning: Could not find VS Code user settings at: $VSCODE_SETTINGS"
      echo "You may need to manually set \"dev.containers.dockerPath\" to \"podman\" in your VS Code settings."
      echo ""
    fi

    echo "Setup complete. Open this folder in VS Code to get started."
    echo "Look for the \"Reopen in Container\" prompt in the bottom-right corner."
    ;;
  3)
    echo "Entering an interactive terminal session"
    echo ""
    podman run --rm -it -v $(pwd):/work ${X11_ARGS} -v ~/.claude:/root/.claude:cached -v ~/.claude.json:/root/.claude.json ${image} bash -c "${XVFB_PREFIX}exec bash"
    ;;
  *)
    echo "Invalid option."
    exit 1
    ;;
esac
