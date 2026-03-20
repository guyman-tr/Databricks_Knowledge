#!/usr/bin/env bash
# Validates a DWH wiki .md file against the Phase 11 spec.
# Deterministic checks that MUST pass before a wiki doc is considered complete.
# Exit code 0 = PASS, 1 = FAIL.
#
# Usage: bash .cursor/scripts/validate-wiki.sh "path/to/Object.md" [Table|View]

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-wiki.md> [Table|View]"
    exit 1
fi

FILE="$1"
OBJECT_TYPE="${2:-}"

if [ ! -f "$FILE" ]; then
    echo "ERROR: File not found: $FILE"
    exit 1
fi

FILENAME=$(basename "$FILE")
BASEPATH="${FILE%.md}"
DIR=$(dirname "$FILE")
BASEFILE=$(basename "$BASEPATH")

TOTAL_CHECKS=0
FAILED_CHECKS=0
FAIL_DETAILS=()

echo ""
echo "VALIDATE: $FILENAME"

# --- Auto-detect object type if not provided ---
if [ -z "$OBJECT_TYPE" ]; then
    if grep -q '**Object Type**.*Table' "$FILE" 2>/dev/null; then
        OBJECT_TYPE="Table"
    elif grep -q '**Object Type**.*View' "$FILE" 2>/dev/null; then
        OBJECT_TYPE="View"
    elif echo "$DIR" | grep -q 'Tables'; then
        OBJECT_TYPE="Table"
    elif echo "$DIR" | grep -q 'Views'; then
        OBJECT_TYPE="View"
    else
        OBJECT_TYPE="Table"
    fi
fi

# ============================================================
# CHECK 1: 8 mandatory section headers
# ============================================================
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
REQUIRED_SECTIONS=(
    "## 1. Business Meaning"
    "## 2. Business Logic"
    "## 3. Query Advisory"
    "## 4. Elements"
    "## 5. Lineage"
    "## 6. Relationships"
    "## 7. Sample Queries"
    "## 8. Atlassian Knowledge Sources"
)

MISSING_SECTIONS=()
for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -qF "$section" "$FILE"; then
        MISSING_SECTIONS+=("$section")
    fi
done

if [ ${#MISSING_SECTIONS[@]} -eq 0 ]; then
    echo "  [PASS] 8 sections present"
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    PRESENT=$((${#REQUIRED_SECTIONS[@]} - ${#MISSING_SECTIONS[@]}))
    echo "  [FAIL] Sections: $PRESENT/${#REQUIRED_SECTIONS[@]} present"
    for s in "${MISSING_SECTIONS[@]}"; do
        echo "         Missing: $s"
    done
    FAIL_DETAILS+=("Missing sections: ${MISSING_SECTIONS[*]}")
fi

# ============================================================
# CHECK 2: Tier suffix on every element row
# ============================================================
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

IN_ELEMENTS=false
TOTAL_ELEMENTS=0
MISSING_TIER=0
MISSING_NAMES=()

while IFS= read -r line; do
    trimmed=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    if [ "$trimmed" = "## 4. Elements" ]; then
        IN_ELEMENTS=true
        continue
    fi

    if $IN_ELEMENTS && echo "$trimmed" | grep -qE '^## [0-9]+\.'; then
        IN_ELEMENTS=false
        continue
    fi

    if $IN_ELEMENTS && echo "$line" | grep -qE '^\|\s*[0-9]+\s*\|'; then
        TOTAL_ELEMENTS=$((TOTAL_ELEMENTS + 1))
        if ! echo "$line" | grep -q '(Tier'; then
            MISSING_TIER=$((MISSING_TIER + 1))
            COL_NUM=$(echo "$line" | sed -n 's/^|\s*\([0-9]*\)\s*|.*/\1/p')
            COL_NAME=$(echo "$line" | sed -n 's/^|\s*[0-9]*\s*|\s*\([^|]*\)\s*|.*/\1/p' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            MISSING_NAMES+=("#${COL_NUM} ${COL_NAME}")
        fi
    fi
done < "$FILE"

PASSING=$((TOTAL_ELEMENTS - MISSING_TIER))

if [ "$TOTAL_ELEMENTS" -eq 0 ]; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    echo "  [FAIL] Tier suffix: No element rows found in ## 4. Elements"
    FAIL_DETAILS+=("No element rows found")
elif [ "$MISSING_TIER" -eq 0 ]; then
    echo "  [PASS] Tier suffix: $TOTAL_ELEMENTS/$TOTAL_ELEMENTS rows have (Tier N) suffix"
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    echo "  [FAIL] Tier suffix: $PASSING/$TOTAL_ELEMENTS rows have suffix ($MISSING_TIER MISSING)"
    PREVIEW="${MISSING_NAMES[*]:0:10}"
    echo "         Missing: $PREVIEW"
    if [ ${#MISSING_NAMES[@]} -gt 10 ]; then
        REMAINING=$((${#MISSING_NAMES[@]} - 10))
        echo "         ... and $REMAINING more"
    fi
    FAIL_DETAILS+=("Tier suffix missing on $MISSING_TIER elements")
fi

# ============================================================
# CHECK 3: Minimum line count
# ============================================================
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
LINE_COUNT=$(wc -l < "$FILE")

if [ "$OBJECT_TYPE" = "View" ]; then
    MIN_LINES=80
else
    MIN_LINES=100
fi

if [ "$LINE_COUNT" -ge "$MIN_LINES" ]; then
    echo "  [PASS] Line count: $LINE_COUNT (min $MIN_LINES for $OBJECT_TYPE)"
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    echo "  [FAIL] Line count: $LINE_COUNT (min $MIN_LINES for $OBJECT_TYPE)"
    FAIL_DETAILS+=("Line count $LINE_COUNT below minimum $MIN_LINES")
fi

# ============================================================
# CHECK 4: 3-file check
# ============================================================
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
REVIEW_FILE="$DIR/$BASEFILE.review-needed.md"
LINEAGE_FILE="$DIR/$BASEFILE.lineage.md"
MISSING_FILES=()

if [ ! -f "$REVIEW_FILE" ]; then
    MISSING_FILES+=("$BASEFILE.review-needed.md")
fi
if [ ! -f "$LINEAGE_FILE" ]; then
    MISSING_FILES+=("$BASEFILE.lineage.md")
fi

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo "  [PASS] 3 files exist (.md + .review-needed.md + .lineage.md)"
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    echo "  [FAIL] Missing companion files: ${MISSING_FILES[*]}"
    FAIL_DETAILS+=("Missing files: ${MISSING_FILES[*]}")
fi

# ============================================================
# CHECK 5: Quality footer
# ============================================================
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if tail -10 "$FILE" | grep -q 'Quality:[[:space:]]*[0-9]'; then
    echo "  [PASS] Quality footer present"
else
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    echo "  [FAIL] Quality footer missing (no 'Quality: N.N' in last 10 lines)"
    FAIL_DETAILS+=("Quality footer missing")
fi

# ============================================================
# RESULT
# ============================================================
echo ""
if [ "$FAILED_CHECKS" -eq 0 ]; then
    echo "RESULT: PASS ($TOTAL_CHECKS/$TOTAL_CHECKS checks passed)"
    exit 0
else
    echo "RESULT: FAIL ($FAILED_CHECKS check(s) failed)"
    for d in "${FAIL_DETAILS[@]}"; do
        echo "  - $d"
    done
    exit 1
fi
