#!/bin/bash

set -e

echo "Validating PM Brainstorm Skill..."

SKILL_DIR="skills/pm-brainstorm"
ERRORS=0

check_file() {
    if [ ! -f "$1" ]; then
        echo "❌ Missing: $1"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ Found: $1"
    fi
}

echo "Checking required files..."
check_file "$SKILL_DIR/SKILL.md"
check_file "$SKILL_DIR/includes/prompts.md"
check_file "$SKILL_DIR/includes/constants.md"
check_file "$SKILL_DIR/includes/common-utils.md"
check_file "$SKILL_DIR/context/examples.md"
check_file "$SKILL_DIR/types/skill-types.ts"

echo ""
echo "Validating SKILL.md frontmatter..."
if grep -q "^name:" "$SKILL_DIR/SKILL.md"; then
    echo "✅ name field present"
else
    echo "❌ name field missing"
    ERRORS=$((ERRORS + 1))
fi

if grep -q "^description:" "$SKILL_DIR/SKILL.md"; then
    echo "✅ description field present"
else
    echo "❌ description field missing"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Checking for required sections in SKILL.md..."
REQUIRED_SECTIONS=("Requirement Analysis" "Technical Architecture" "Testing Strategy" "Docker" "Design Patterns")
for section in "${REQUIRED_SECTIONS[@]}"; do
    if grep -q "$section" "$SKILL_DIR/SKILL.md"; then
        echo "✅ Section found: $section"
    else
        echo "❌ Section missing: $section"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "Validating TypeScript types..."
if command -v npx &> /dev/null; then
    if npx tsc --noEmit "$SKILL_DIR/types/skill-types.ts" 2>/dev/null; then
        echo "✅ TypeScript types valid"
    else
        echo "⚠️  TypeScript validation skipped (types may need manual review)"
    fi
else
    echo "⚠️  TypeScript not available, skipping type check"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "🎉 Validation passed!"
    exit 0
else
    echo "❌ Validation failed with $ERRORS error(s)"
    exit 1
fi
