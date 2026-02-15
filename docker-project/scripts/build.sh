#!/bin/bash

set -e

SKILL_DIR="${1:-.}"

echo "Building docker-project skill: $SKILL_DIR"

if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
  echo "ERROR: SKILL.md not found"
  exit 1
fi

OUTPUT_DIR="$SKILL_DIR/.output"
mkdir -p "$OUTPUT_DIR"

echo "Parsing SKILL.md..."
cat "$SKILL_DIR/SKILL.md" > "$OUTPUT_DIR/parsed.md"

echo "Processing includes..."
if [ -d "$SKILL_DIR/includes" ]; then
  for inc in "$SKILL_DIR/includes"/*.md; do
    if [ -f "$inc" ]; then
      echo "  - $(basename $inc)"
    fi
  done
fi

echo "Processing context fragments..."
if [ -d "$SKILL_DIR/context" ]; then
  for ctx in "$SKILL_DIR/context"/*.md; do
    if [ -f "$ctx" ]; then
      echo "  - $(basename $ctx)"
    fi
  done
fi

echo "Processing types..."
if [ -d "$SKILL_DIR/types" ]; then
  for t in "$SKILL_DIR/types"/*.ts; do
    if [ -f "$t" ]; then
      echo "  - $(basename $t)"
    fi
  done
fi

echo "Generating INDEX.md..."
{
  echo "# Docker Project Skill Index"
  echo ""
  echo "## Main File"
  echo "- [SKILL.md](SKILL.md)"
  echo ""
  echo "## Includes (Templates)"
  find "$SKILL_DIR/includes" -type f -name "*.md" 2>/dev/null | while read f; do
    echo "- [$(basename $f)](includes/$(basename $f))"
  done
  echo ""
  echo "## Context (Examples)"
  find "$SKILL_DIR/context" -type f -name "*.md" 2>/dev/null | while read f; do
    echo "- [$(basename $f)](context/$(basename $f))"
  done
  echo ""
  echo "## Types"
  find "$SKILL_DIR/types" -type f -name "*.ts" 2>/dev/null | while read f; do
    echo "- [$(basename $f)](types/$(basename $f))"
  done
  echo ""
  echo "## Scripts"
  find "$SKILL_DIR/scripts" -type f -name "*.sh" 2>/dev/null | while read f; do
    echo "- [$(basename $f)](scripts/$(basename $f))"
  done
} > "$SKILL_DIR/INDEX.md"

echo ""
echo "✓ Build complete"
echo "Output: $OUTPUT_DIR/"
echo "Index: $SKILL_DIR/INDEX.md"
