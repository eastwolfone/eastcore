#!/bin/bash
# EastCore build script — wraps CMake configure + build + install
set -e

EASTCORE_ROOT=~/eastcore
SOURCE_DIR="$EASTCORE_ROOT/azerothcore"
BUILD_DIR="$EASTCORE_ROOT/build"
INSTALL_DIR="$BUILD_DIR/install"
JOBS=$(nproc)

CLEAN=false
CONFIGURE_ONLY=false
BUILD_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --clean)       CLEAN=true; shift ;;
    --configure)   CONFIGURE_ONLY=true; shift ;;
    --build-only)  BUILD_ONLY=true; shift ;;
    --jobs|-j)     JOBS="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: build.sh [OPTIONS]"
      echo "  --clean        Remove build directory and rebuild from scratch"
      echo "  --configure    Only run CMake configure, don't build"
      echo "  --build-only   Skip CMake configure, only build"
      echo "  --jobs N       Number of parallel build jobs (default: $(nproc))"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ "$CLEAN" = true ]; then
  echo "Cleaning build directory..."
  rm -rf "$BUILD_DIR"
fi

# CMake configure
if [ "$BUILD_ONLY" = false ]; then
  echo "=== CMake Configure ==="
  cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DCMAKE_C_COMPILER=/usr/bin/clang \
    -DCMAKE_CXX_COMPILER=/usr/bin/clang++ \
    -DTOOLS_BUILD=all \
    -DSCRIPTS=static \
    -DMODULES=static \
    -DWITH_WARNINGS=0 \
    -DBUILD_TESTING=OFF

  if [ "$CONFIGURE_ONLY" = true ]; then
    echo "Configure complete."
    exit 0
  fi
fi

# Build lualib first (ensures Lua headers are available for mod-ale)
echo "=== Building Lua library ==="
cmake --build "$BUILD_DIR" --target lualib -j "$JOBS" 2>&1 | tail -3

# Full build
echo "=== Building EastCore (${JOBS} cores) ==="
START=$(date +%s)
cmake --build "$BUILD_DIR" --config RelWithDebInfo -j "$JOBS"
END=$(date +%s)
echo "Build completed in $((END - START)) seconds."

# Install
echo "=== Installing ==="
cmake --install "$BUILD_DIR" --config RelWithDebInfo 2>&1 | tail -3

echo ""
echo "=== Build complete ==="
ls -lh "$INSTALL_DIR/bin/worldserver" "$INSTALL_DIR/bin/authserver"
