#!/bin/bash

set -e

SKILL_DIR="${1:-.}"

echo "Validating docker-project skill structure: $SKILL_DIR"

ERRORS=0

if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
  echo "ERROR: SKILL.md not found"
  ERRORS=$((ERRORS + 1))
  exit 1
fi

if ! grep -q "^---" "$SKILL_DIR/SKILL.md"; then
  echo "ERROR: SKILL.md missing frontmatter"
  ERRORS=$((ERRORS + 1))
fi

if ! grep -q "^name:" "$SKILL_DIR/SKILL.md"; then
  echo "ERROR: SKILL.md missing 'name' field"
  ERRORS=$((ERRORS + 1))
fi

if ! grep -q "^description:" "$SKILL_DIR/SKILL.md"; then
  echo "ERROR: SKILL.md missing 'description' field"
  ERRORS=$((ERRORS + 1))
fi

if [ -d "$SKILL_DIR/includes" ]; then
  echo "Checking includes..."
  for inc in "$SKILL_DIR/includes"/*.md; do
    if [ -f "$inc" ]; then
      echo "  ✓ $(basename $inc)"
    fi
  done
fi

if [ -d "$SKILL_DIR/context" ]; then
  echo "Checking context..."
  for ctx in "$SKILL_DIR/context"/*.md; do
    if [ -f "$ctx" ]; then
      echo "  ✓ $(basename $ctx)"
    fi
  done
fi

if [ -d "$SKILL_DIR/types" ]; then
  echo "Checking types..."
  for t in "$SKILL_DIR/types"/*.ts; do
    if [ -f "$t" ]; then
      echo "  ✓ $(basename $t)"
    fi
  done
fi

if [ -d "$SKILL_DIR/scripts" ]; then
  echo "Checking scripts..."
  for s in "$SKILL_DIR/scripts"/*.sh; do
    if [ -f "$s" ]; then
      if [ -x "$s" ]; then
        echo "  ✓ $(basename $s) (executable)"
      else
        echo "  ✓ $(basename $s)"
      fi
    fi
  done
fi

if [ $ERRORS -eq 0 ]; then
  echo ""
  echo "✓ Validation passed"
  exit 0
else
  echo ""
  echo "✗ Validation failed with $ERRORS error(s)"
  exit 1
fi
