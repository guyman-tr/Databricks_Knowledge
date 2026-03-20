#!/usr/bin/env bash
# Semantic validation: cross-references DWH wiki tier assignments against upstream DB_Schema wikis.
# Exit 0=PASS, 1=FAIL, 2=WARNING
# Bash version for Claude CLI / Linux agents.

set -euo pipefail

PATH_ARG="${1:?Usage: validate-tier1-coverage.sh <wiki-file-path>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

DB_SCHEMA_BASE="${REPO_ROOT}/../DB_Schema/etoro/Wiki"
if [ ! -d "$DB_SCHEMA_BASE" ]; then
    DB_SCHEMA_BASE="$HOME/Documents/github/DB_Schema/etoro/Wiki"
fi
if [ ! -d "$DB_SCHEMA_BASE" ]; then
    echo "ERROR: DB_Schema wiki not found"
    exit 1
fi

if [ ! -f "$PATH_ARG" ]; then
    echo "ERROR: File not found: $PATH_ARG"
    exit 1
fi

FILE_NAME=$(basename "$PATH_ARG" .md)

# Extract Production Source
PROD_SOURCE=$(grep -oP '\*\*Production Source\*\*\s*\|\s*`?([A-Za-z_]+\.[A-Za-z_]+)`?' "$PATH_ARG" | grep -oP '[A-Za-z_]+\.[A-Za-z_]+' | head -1 || true)

# Count tiers from Elements table
IN_ELEMENTS=0
TOTAL_COLS=0
TIER1=0
TIER2=0
declare -A DWH_COLS

while IFS= read -r line; do
    if [[ "$line" =~ ^##\ 4\.\ Elements ]]; then IN_ELEMENTS=1; continue; fi
    if [[ $IN_ELEMENTS -eq 1 && "$line" =~ ^##\ [0-9] ]]; then break; fi
    if [[ $IN_ELEMENTS -eq 1 && "$line" =~ ^\|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*([A-Za-z0-9_]+)[[:space:]]*\| ]]; then
        COL_NAME="${BASH_REMATCH[1]}"
        TOTAL_COLS=$((TOTAL_COLS + 1))
        TIER=0
        if [[ "$line" =~ \(Tier[[:space:]]+([0-9]+) ]]; then
            TIER="${BASH_REMATCH[1]}"
        fi
        DWH_COLS[$COL_NAME]=$TIER
        if [[ $TIER -eq 1 ]]; then TIER1=$((TIER1 + 1)); fi
        if [[ $TIER -eq 2 ]]; then TIER2=$((TIER2 + 1)); fi
    fi
done < "$PATH_ARG"

echo ""
echo "SEMANTIC VALIDATE: $FILE_NAME"
echo "  Production Source: ${PROD_SOURCE:-NOT FOUND}"
echo "  DWH columns: $TOTAL_COLS (T1=$TIER1, T2=$TIER2)"

# Find upstream wikis
UPSTREAM_FILES=()
UPSTREAM_COLS=0
MATCH_COUNT=0
MATCHED_T1=0

if [[ -n "$PROD_SOURCE" && "$PROD_SOURCE" != "Derived" && "$PROD_SOURCE" != "Multiple" ]]; then
    SCHEMA=$(echo "$PROD_SOURCE" | cut -d. -f1)
    TABLE=$(echo "$PROD_SOURCE" | cut -d. -f2)

    TABLE_PATH="$DB_SCHEMA_BASE/$SCHEMA/Tables/$SCHEMA.$TABLE.md"
    VIEW_PATH="$DB_SCHEMA_BASE/$SCHEMA/Views/$SCHEMA.$TABLE.md"
    [ -f "$TABLE_PATH" ] && UPSTREAM_FILES+=("$TABLE_PATH")
    [ -f "$VIEW_PATH" ] && UPSTREAM_FILES+=("$VIEW_PATH")
fi

# Also check lineage file for additional sources
LINEAGE_MD="${PATH_ARG%.md}.lineage.md"
LINEAGE_PY="${PATH_ARG%.md}.lineage.py"
for LF in "$LINEAGE_MD" "$LINEAGE_PY"; do
    if [ -f "$LF" ]; then
        while IFS= read -r ll; do
            if [[ "$ll" =~ \"([A-Za-z]+\.[A-Za-z_]+)\":[[:space:]]*\[ ]]; then
                SRC="${BASH_REMATCH[1]}"
                S=$(echo "$SRC" | cut -d. -f1)
                T=$(echo "$SRC" | cut -d. -f2)
                TP="$DB_SCHEMA_BASE/$S/Tables/$S.$T.md"
                VP="$DB_SCHEMA_BASE/$S/Views/$S.$T.md"
                [ -f "$TP" ] && UPSTREAM_FILES+=("$TP")
                [ -f "$VP" ] && UPSTREAM_FILES+=("$VP")
            fi
        done < "$LF"
    fi
done

# Deduplicate
readarray -t UPSTREAM_FILES < <(printf '%s\n' "${UPSTREAM_FILES[@]}" | sort -u)

echo "  Upstream wikis found: ${#UPSTREAM_FILES[@]}"

# Extract upstream column names
declare -A UPSTREAM_MAP
for UF in "${UPSTREAM_FILES[@]}"; do
    echo "    - $(basename "$UF")"
    IN_EL=0
    while IFS= read -r ul; do
        if [[ "$ul" =~ ^##\ [34]\.\ (Elements|Data\ Overview) ]]; then IN_EL=1; continue; fi
        if [[ $IN_EL -eq 1 && "$ul" =~ ^##\ [0-9] ]]; then break; fi
        if [[ $IN_EL -eq 1 && "$ul" =~ ^\|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*([A-Za-z0-9_]+)[[:space:]]*\| ]]; then
            UC="${BASH_REMATCH[1]}"
            if [[ -z "${UPSTREAM_MAP[$UC]+x}" ]]; then
                UPSTREAM_MAP[$UC]="$(basename "$UF")"
                UPSTREAM_COLS=$((UPSTREAM_COLS + 1))
            fi
        fi
    done < "$UF"
done

echo "  Upstream columns documented: $UPSTREAM_COLS"

# Cross-reference
MISSES=()
for COL in "${!DWH_COLS[@]}"; do
    if [[ -n "${UPSTREAM_MAP[$COL]+x}" ]]; then
        MATCH_COUNT=$((MATCH_COUNT + 1))
        if [[ ${DWH_COLS[$COL]} -eq 1 ]]; then
            MATCHED_T1=$((MATCHED_T1 + 1))
        else
            MISSES+=("    MISS: $COL (Tier ${DWH_COLS[$COL]}) <- upstream: ${UPSTREAM_MAP[$COL]}")
        fi
    fi
done

echo "  DWH columns with upstream wiki match: $MATCH_COUNT"

EXIT_CODE=0
RESULT="PASS"

if [[ $MATCH_COUNT -gt 10 && $MATCHED_T1 -eq 0 ]]; then
    echo ""
    echo "  [FAIL] ZERO Tier 1 columns despite $MATCH_COUNT matchable upstream columns!"
    EXIT_CODE=1
    RESULT="FAIL"
elif [[ $MATCH_COUNT -gt 0 ]]; then
    THRESHOLD=$((MATCH_COUNT * 40 / 100))
    if [[ $MATCHED_T1 -lt $THRESHOLD ]]; then
        echo ""
        echo "  [WARN] Only $MATCHED_T1/$MATCH_COUNT matchable columns got Tier 1 (<40%)"
        EXIT_CODE=2
        RESULT="WARNING"
    else
        echo ""
        echo "  [PASS] Tier 1 coverage: $MATCHED_T1/$MATCH_COUNT matchable columns"
    fi
else
    echo ""
    echo "  [PASS] No upstream wiki matches found (legitimate Tier 2-only)"
fi

if [[ ${#MISSES[@]} -gt 0 && ${#MISSES[@]} -le 20 ]]; then
    echo ""
    echo "  Columns with upstream wiki match but NOT Tier 1:"
    printf '%s\n' "${MISSES[@]}"
fi

echo ""
echo "SEMANTIC RESULT: $RESULT"
echo ""
exit $EXIT_CODE
