#!/bin/bash

# Setup script for obra/superpowers TDD skill integration
# Downloads and installs the test-driven-development skill for benchmarking

set -e
set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== obra/superpowers TDD Skill Setup ===${NC}"
echo ""

# Check if we should install globally or locally
INSTALL_MODE="${1:-local}"

if [ "$INSTALL_MODE" = "global" ]; then
    INSTALL_DIR="$HOME/.claude/skills"
    echo "Installing globally to: $INSTALL_DIR"
elif [ "$INSTALL_MODE" = "local" ]; then
    INSTALL_DIR=".claude/skills"
    echo "Installing locally to: $INSTALL_DIR"
else
    echo -e "${RED}Error: Invalid install mode '$INSTALL_MODE'${NC}"
    echo "Usage: $0 [local|global]"
    exit 1
fi

# Create skills directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Save absolute path before changing directories
INSTALL_DIR_ABS="$(cd "$INSTALL_DIR" && pwd)"

# Create a temporary directory for download
TEMP_DIR=$(mktemp -d)
echo -e "${YELLOW}Using temporary directory: $TEMP_DIR${NC}"

cd "$TEMP_DIR"

# Clone obra/superpowers
echo -e "${BLUE}Cloning obra/superpowers repository...${NC}"
if git clone https://github.com/obra/superpowers.git --quiet 2>/dev/null; then
    echo -e "  ${GREEN}✓ Successfully cloned${NC}"
else
    echo -e "${RED}Error: Failed to clone obra/superpowers${NC}"
    echo "Please check your internet connection and that the repository exists."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Check if the TDD skill exists
OBRA_SKILLS_DIR="superpowers/skills"
TDD_SKILL="test-driven-development"

if [ ! -d "$OBRA_SKILLS_DIR/$TDD_SKILL" ]; then
    echo -e "${RED}Error: TDD skill not found at $OBRA_SKILLS_DIR/$TDD_SKILL${NC}"
    echo "The obra/superpowers repository structure may have changed."
    ls -la "$OBRA_SKILLS_DIR/" || echo "Skills directory not found"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Copy the TDD skill
echo -e "${BLUE}Installing test-driven-development skill...${NC}"
TARGET_DIR="$INSTALL_DIR_ABS/$TDD_SKILL"

if [ -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Warning: Skill already exists at $TARGET_DIR${NC}"
    echo -n "Overwrite? (y/N): "
    read -r RESPONSE
    if [ "$RESPONSE" != "y" ] && [ "$RESPONSE" != "Y" ]; then
        echo "Skipping installation."
        rm -rf "$TEMP_DIR"
        exit 0
    fi
    rm -rf "$TARGET_DIR"
fi

cp -r "$OBRA_SKILLS_DIR/$TDD_SKILL" "$TARGET_DIR"

if [ -d "$TARGET_DIR" ]; then
    echo -e "  ${GREEN}✓ Successfully installed to $TARGET_DIR${NC}"
else
    echo -e "${RED}Error: Failed to copy skill${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Verify the skill has a SKILL.md file
if [ ! -f "$TARGET_DIR/SKILL.md" ]; then
    echo -e "${YELLOW}Warning: No SKILL.md found in the installed skill${NC}"
    echo "Contents of $TARGET_DIR:"
    ls -la "$TARGET_DIR"
fi

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "Installed skill: test-driven-development"
echo "Location: $TARGET_DIR"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo "The TDD skill is available for Claude Code sessions."
echo "It's designed for NEW feature development (test-first)."
echo ""
echo -e "${BLUE}Manual testing:${NC}"
echo "cd your-project"
echo "claude"
echo "# Describe new feature to implement"
echo ""
echo -e "${YELLOW}Important Note:${NC}"
echo "The TDD skill is designed for NEW feature development, not test suite improvement."
echo "It follows RED-GREEN-REFACTOR cycle:"
echo "  1. Write a failing test (RED)"
echo "  2. Write code to pass it (GREEN)"
echo "  3. Refactor (REFACTOR)"
echo ""
echo "This is complementary to aTSR, not competitive:"
echo "  - obra TDD: Best for NEW features (test-first, incremental)"
echo "  - aTSR: Best for EXISTING codebases (batch analysis, coverage-driven)"
echo ""
echo "For benchmark comparison of test improvement strategies, see the"
echo "'incremental' strategy which uses a step-by-step approach without"
echo "requiring test-first workflow."
