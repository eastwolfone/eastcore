#!/bin/bash
# EastCore update-and-rebuild — pulls upstream + modules, backs up configs, rebuilds, re-applies
set -e

EASTCORE_ROOT=~/eastcore
INSTALL_DIR="$EASTCORE_ROOT/build/install"
BACKUP_DIR="$EASTCORE_ROOT/backups/configs_$(date +%Y%m%d_%H%M%S)"

echo "=== EastCore Update & Rebuild ==="

# Step 1: Backup current configs
echo ""
echo "[1/5] Backing up configs..."
mkdir -p "$BACKUP_DIR"
cp -r "$INSTALL_DIR/etc/"*.conf "$BACKUP_DIR/" 2>/dev/null || true
cp -r "$INSTALL_DIR/etc/modules/"*.conf "$BACKUP_DIR/modules/" 2>/dev/null || true
echo "  Backed up to $BACKUP_DIR"

# Step 2: Pull upstream changes for AzerothCore
echo ""
echo "[2/5] Pulling upstream changes..."
cd "$EASTCORE_ROOT/azerothcore"
BEFORE=$(git rev-parse --short HEAD)
git fetch playerbots-upstream
git merge playerbots-upstream/Playerbot --no-edit 2>&1 || {
  echo "  MERGE CONFLICT — resolve manually, then re-run this script"
  exit 1
}
AFTER=$(git rev-parse --short HEAD)
if [ "$BEFORE" = "$AFTER" ]; then
  echo "  AzerothCore: already up to date ($BEFORE)"
else
  echo "  AzerothCore: updated $BEFORE -> $AFTER"
fi

# Step 3: Update modules
echo ""
echo "[3/5] Updating modules..."
"$EASTCORE_ROOT/custom/tools/update-modules.sh"

# Step 4: Rebuild
echo ""
echo "[4/5] Rebuilding..."
"$EASTCORE_ROOT/custom/tools/build.sh"

# Step 5: Re-apply config customizations
echo ""
echo "[5/5] Restoring configs..."
# Copy back the saved configs (preserves your customizations)
cp "$BACKUP_DIR/"*.conf "$INSTALL_DIR/etc/" 2>/dev/null || true
if [ -d "$BACKUP_DIR/modules" ]; then
  cp "$BACKUP_DIR/modules/"*.conf "$INSTALL_DIR/etc/modules/" 2>/dev/null || true
fi
echo "  Configs restored from backup"

# Check for new .conf.dist files that don't have a .conf counterpart
echo ""
echo "  Checking for new config files..."
for dist in "$INSTALL_DIR/etc/"*.conf.dist "$INSTALL_DIR/etc/modules/"*.conf.dist; do
  [ -f "$dist" ] || continue
  conf="${dist%.dist}"
  if [ ! -f "$conf" ]; then
    cp "$dist" "$conf"
    echo "  NEW: $(basename $conf) (copied from .dist)"
  fi
done

echo ""
echo "=== Update & Rebuild Complete ==="
echo "Config backup at: $BACKUP_DIR"
echo "Restart the server to apply changes."
