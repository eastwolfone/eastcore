#!/bin/bash
# EastCore module updater — pulls latest for all installed community modules
set -e

MODULES_DIR=~/eastcore/azerothcore/modules

echo "=== EastCore Module Update ==="

for mod_dir in "$MODULES_DIR"/mod-*/; do
  mod_name=$(basename "$mod_dir")

  # Skip if not a git repo (e.g., custom modules tracked by main repo)
  if [ ! -d "$mod_dir/.git" ]; then
    echo "  $mod_name: skipped (not an independent git repo)"
    continue
  fi

  echo -n "  $mod_name: "
  cd "$mod_dir"

  BEFORE=$(git rev-parse --short HEAD)
  git pull --quiet 2>&1
  AFTER=$(git rev-parse --short HEAD)

  if [ "$BEFORE" = "$AFTER" ]; then
    echo "up to date ($BEFORE)"
  else
    echo "updated $BEFORE -> $AFTER"
  fi
done

echo ""
echo "Done. If any modules updated, rebuild with:"
echo "  ~/eastcore/custom/tools/build.sh"
