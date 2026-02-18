  #!/bin/bash
  # .claude/hooks/check-container.sh

  # Check if running in a container
  is_containerized() {
    # Check for Docker
    if [ -f /.dockerenv ]; then
      return 0
    fi

    # Check for Podman
    if [ -f /run/.containerenv ]; then
      return 0
    fi

    # Check for Podman via environment variable
    if [ "$container" = "podman" ]; then
      return 0
    fi

    # Check for container in cgroup (Docker, Podman, LXC, Kubernetes)
    if grep -qE 'docker|libpod|lxc|kubepods' /proc/1/cgroup 2>/dev/null; then
      return 0
    fi

    # Check cgroup v2 (used by newer Podman/Docker)
    if grep -qE 'docker|libpod|lxc|kubepods' /proc/self/mountinfo 2>/dev/null; then
      return 0
    fi

    # Check for Kubernetes
    if [ -n "$KUBERNETES_SERVICE_HOST" ]; then
      return 0
    fi

    return 1
  }

  if is_containerized; then
    # Containerized - allow prompt, optionally add context
    exit 0
  else
    # Not containerized - block with instructions
    jq -n '{
      decision: "block",
      reason: "⚠️  Not running in a containerized environment.\n\nTo containerize your work, first install podman by following the official installation instructions: https://podman.io/getting-started/installation\n\nYou can then launch an interactive container session with \"bash run.sh\"."
    }'
    exit 0
  fi

