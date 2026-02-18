#!/bin/sh

image="${1:-docker.io/taylorabarnes/devenv:latest}"
port="${2:-56610}"

# Check if host has X11 available
if [ -n "$DISPLAY" ] && [ -e "/tmp/.X11-unix/X${DISPLAY#:}" ]; then
  # Use Vulkan backend with host X11 (Intel GPU has good Vulkan support)
  # Force X11 backend for winit (not Wayland)
  X11_ARGS="-e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -e XDG_RUNTIME_DIR=/tmp/runtime -e WINIT_UNIX_BACKEND=x11 --device /dev/dri --group-add keep-groups --security-opt label=disable"
  XVFB_PREFIX="mkdir -p /tmp/runtime && "
  echo "Note: Host X11 display detected. GPU acceleration enabled."
else
  # No host X11 - use Xvfb inside the container
  # Note: GPU apps (Bevy, wgpu) won't work properly with Xvfb due to lack of DRI3 support
  # Force OpenGL software rendering for basic X11 apps
  X11_ARGS="-e DISPLAY=:99 -e WGPU_BACKEND=gl -e WINIT_UNIX_BACKEND=x11 -e LIBGL_ALWAYS_SOFTWARE=1 -e XDG_RUNTIME_DIR=/tmp/runtime --device /dev/dri --group-add keep-groups --security-opt label=disable"
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
echo "Note: If you select VS Code, this container will launch a VS Code server."
echo "      You can then access the server by point a web browser to http://localhost:${port}"
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
    # Check if any container is already using the port
    CID=$(podman ps --filter "publish=${port}" -q)
    if [ -n "$CID" ]; then
      echo "Cleaning up old container on port ${port}..."
      podman stop "$CID"
      echo ""
    fi

    # Launch the container
    echo "Launching VS Code through code-server."
    echo "To use it, open a web browser to http://localhost:${port}"
    echo ""
    podman run --rm -it -v $(pwd):/work ${X11_ARGS} -v ~/.claude:/root/.claude:cached -v ~/.claude.json:/root/.claude.json -p 127.0.0.1:${port}:8080 ${image} bash -c "${XVFB_PREFIX}bash /.code-server/entrypoint.sh"
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
