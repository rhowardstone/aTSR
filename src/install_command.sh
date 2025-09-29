#!/bin/bash

# Install refine-tests command for Claude Code
set -e  # Exit on error

# Get script directory (cleaner approach)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if the source file exists
if [ ! -f "$SCRIPT_DIR/refine-tests.md" ]; then
    echo "Error: refine-tests.md not found in $SCRIPT_DIR"
    echo "Please ensure refine-tests.md is in the same directory as this script"
    exit 1
fi

# Create Claude commands directory if it doesn't exist
CLAUDE_CMD_DIR="$HOME/.claude/commands"
mkdir -p "$CLAUDE_CMD_DIR"

# Copy the command file
echo "Installing refine-tests command..."
cp "$SCRIPT_DIR/refine-tests.md" "$CLAUDE_CMD_DIR/"

# Verify installation
if [ -f "$CLAUDE_CMD_DIR/refine-tests.md" ]; then
    echo "✓ Successfully installed refine-tests command"
    echo ""
    echo "Usage:"
    echo "  1. Navigate to your target repository"
    echo "  2. Open Claude Code (run: claude)"
    echo "  3. Execute: /refine-tests auto"
    echo ""
    echo "Command installed at: $CLAUDE_CMD_DIR/refine-tests.md"
else
    echo "✗ Installation failed"
    exit 1
fi