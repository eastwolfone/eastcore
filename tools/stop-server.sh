#!/bin/bash
# EastCore server stop — gracefully shuts down auth + world servers

echo "Stopping worldserver..."
tmux send-keys -t eastcore-world "server shutdown 0" Enter 2>/dev/null || echo "  (not running)"
sleep 3

echo "Stopping authserver..."
tmux send-keys -t eastcore-auth "exit" Enter 2>/dev/null || echo "  (not running)"
sleep 2

# Kill any remaining sessions
tmux kill-session -t eastcore-world 2>/dev/null || true
tmux kill-session -t eastcore-auth 2>/dev/null || true

echo "EastCore server stopped."
