#!/usr/bin/env bash
# Install CocoaPods into the mise-managed ruby at the reviewed version.
#
# CocoaPods 1.15.2 was installed as gems inside the rbenv rubies (inventory
# baseline). Gems do not move with a ruby runtime, so the ruby migration
# (issue 03) reinstalls the reviewed version deliberately into the mise ruby;
# the rbenv state stays on disk untouched and can be retired later with
# explicit human approval.
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/mise-stage-helpers.sh"

COCOAPODS_VERSION="1.15.2"

mise_stage_resolve
mise_stage_cd_home

# mise which only reports mise-managed executables (system fallback is
# disabled), so this skips only when CocoaPods is actually installed under the
# mise ruby — not when a manager from the old ownership still shadows it.
if mise which pod &>/dev/null; then
  version="$(mise x -- pod --version)"
  if [ "$version" != "$COCOAPODS_VERSION" ]; then
    echo "pod $version is installed under the mise ruby, but the reviewed version is $COCOAPODS_VERSION. Upgrading is a deliberate reviewed change (docs/mise-runtime-migration.md)." >&2
    exit 1
  fi
  echo "CocoaPods already installed under the mise ruby: pod $version. Skipping installation."
  exit 0
fi

echo "Installing CocoaPods $COCOAPODS_VERSION into the mise-managed ruby..."
MISE_YES=1 mise x -- gem install cocoapods --version "$COCOAPODS_VERSION" --no-document
mise reshim

resolved="$(mise which pod)" || {
  echo "CocoaPods did not resolve under mise after installation." >&2
  exit 1
}
mise_stage_check_path "$resolved" "pod"
version="$(mise x -- pod --version)"
if [ "$version" != "$COCOAPODS_VERSION" ]; then
  echo "pod resolves to $version but the reviewed version is $COCOAPODS_VERSION." >&2
  exit 1
fi
echo "pod $version at $resolved"
