#!/bin/bash
# EastCore server launcher — starts auth + world servers in tmux sessions
set -e

INSTALL_DIR=~/eastcore/build/install
BIN_DIR="$INSTALL_DIR/bin"

# Ensure MySQL is running
sudo service mysql start > /dev/null 2>&1
echo "MySQL: running"

# Check binaries exist
if [ ! -f "$BIN_DIR/worldserver" ] || [ ! -f "$BIN_DIR/authserver" ]; then
  echo "Error: Server binaries not found. Run build.sh first."
  exit 1
fi

# Check configs exist
if [ ! -f "$INSTALL_DIR/etc/worldserver.conf" ]; then
  echo "Error: worldserver.conf not found. Copy from .conf.dist first:"
  echo "  cp $INSTALL_DIR/etc/worldserver.conf.dist $INSTALL_DIR/etc/worldserver.conf"
  exit 1
fi

if [ ! -f "$INSTALL_DIR/etc/authserver.conf" ]; then
  echo "Error: authserver.conf not found. Copy from .conf.dist first:"
  echo "  cp $INSTALL_DIR/etc/authserver.conf.dist $INSTALL_DIR/etc/authserver.conf"
  exit 1
fi

# Kill existing sessions if running
tmux kill-session -t eastcore-auth 2>/dev/null || true
tmux kill-session -t eastcore-world 2>/dev/null || true

# Start authserver in tmux
echo "Starting authserver..."
tmux new-session -d -s eastcore-auth -c "$BIN_DIR" "./authserver"

# Wait a moment for auth to initialize
sleep 2

# Start worldserver in tmux
echo "Starting worldserver..."
tmux new-session -d -s eastcore-world -c "$BIN_DIR" "./worldserver"

echo ""
echo "=== EastCore server started ==="
echo "  Auth:  tmux attach -t eastcore-auth"
echo "  World: tmux attach -t eastcore-world"
echo ""
echo "To send commands to worldserver:"
echo "  tmux send-keys -t eastcore-world 'account create admin password' Enter"
echo ""
echo "To stop: ~/eastcore/custom/tools/stop-server.sh"
