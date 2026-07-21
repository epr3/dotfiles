#!/usr/bin/env bash
# Initialize RTK integration for the Pi coding agent.
set -euo pipefail

if ! command -v rtk &>/dev/null; then
  echo "rtk not available. Skipping Pi RTK initialization."
  exit 0
fi

echo "Initializing RTK for Pi..."
rtk init --agent pi --global --auto-patch
