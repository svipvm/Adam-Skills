#!/bin/bash

set -e

SKILL_DIR="${1:-.}"

echo "Validating skill structure: $SKILL_DIR"

ERRORS=0

if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
  echo "ERROR: SKILL.md not found"
  ERRORS=$((ERRORS + 1))
  exit 1
fi

if [ ! -d "$SKILL_DIR/includes" ]; then
  echo "WARNING: includes/ directory not found"
fi

if [ ! -d "$SKILL_DIR/scripts" ]; then
  echo "WARNING: scripts/ directory not found"
fi

if [ ! -d "$SKILL_DIR/context" ]; then
  echo "WARNING: context/ directory not found"
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
  INCLUDES_IN_FM=$(grep -c "^includes:" "$SKILL_DIR/SKILL.md" || echo "0")
  if [ "$INCLUDES_IN_FM" -gt 0 ]; then
    for inc in "$SKILL_DIR/includes"/*.md; do
      if [ -f "$inc" ]; then
        INC_NAME=$(basename "$inc" .md)
        if ! grep -q "\[\[include:${INC_NAME}\]\]" "$SKILL_DIR/SKILL.md"; then
          echo "WARNING: include file exists but not referenced: ${INC_NAME}.md"
        fi
      fi
    done
  fi
fi

if [ -d "$SKILL_DIR/context" ]; then
  CTX_IN_FM=$(grep -c "^context:" "$SKILL_DIR/SKILL.md" || echo "0")
  if [ "$CTX_IN_FM" -gt 0 ]; then
    for ctx in "$SKILL_DIR/context"/*.md; do
      if [ -f "$ctx" ]; then
        CTX_NAME=$(basename "$ctx" .md)
        if ! grep -q "\[\[load:context/${CTX_NAME}\]\]" "$SKILL_DIR/SKILL.md"; then
          echo "WARNING: context file exists but not referenced: ${CTX_NAME}.md"
        fi
      fi
    done
  fi
fi

if [ $ERRORS -eq 0 ]; then
  echo "✓ Validation passed"
  exit 0
else
  echo "✗ Validation failed with $ERRORS error(s)"
  exit 1
fi
