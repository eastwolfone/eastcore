#!/bin/bash
# EastCore Lua deploy — copies Lua scripts from custom/lua/ to the server's lua_scripts/
set -e

SOURCE=~/eastcore/custom/lua/scripts
DEST=~/eastcore/build/install/bin/lua_scripts

if [ ! -d "$SOURCE" ]; then
  echo "No Lua scripts found in $SOURCE"
  exit 0
fi

SCRIPT_COUNT=$(find "$SOURCE" -name '*.lua' 2>/dev/null | wc -l)
if [ "$SCRIPT_COUNT" -eq 0 ]; then
  echo "No .lua files found in $SOURCE"
  exit 0
fi

mkdir -p "$DEST"
cp -rv "$SOURCE"/*.lua "$DEST/" 2>/dev/null || true
cp -rv "$SOURCE"/**/*.lua "$DEST/" 2>/dev/null || true

echo ""
echo "Deployed $SCRIPT_COUNT Lua script(s) to $DEST/"
echo "Reload in-game with: .reload eluna"
