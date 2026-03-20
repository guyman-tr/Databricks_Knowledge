#!/bin/bash

SCHEMA_NAME="${1:-}"
DOC_LEVEL="${2:-}"

if [ -z "$SCHEMA_NAME" ]; then
    read -p "Schema Name (default: DWH_dbo): " SCHEMA_NAME
    SCHEMA_NAME="${SCHEMA_NAME:-DWH_dbo}"
fi

# Pick the right command based on schema
if [ "$SCHEMA_NAME" = "BI_DB_dbo" ]; then
    BATCH_COMMAND="/build-wiki-bidb-batch"
    COMMAND_ARGS="$SCHEMA_NAME $DOC_LEVEL"
else
    BATCH_COMMAND="/build-wiki-dwh-batch"
    COMMAND_ARGS="$SCHEMA_NAME"
fi
COMMAND_ARGS=$(echo "$COMMAND_ARGS" | xargs)

echo ""
echo -e "\e[36m============================================================\e[0m"
echo -e "\e[36m  Wiki Batch Loop\e[0m"
echo -e "\e[36m  Schema:  $SCHEMA_NAME\e[0m"
echo -e "\e[36m  Command: $BATCH_COMMAND\e[0m"
[ -n "$DOC_LEVEL" ] && echo -e "\e[36m  Filter:  $DOC_LEVEL\e[0m"
echo -e "\e[36m  Started: $(date '+%Y-%m-%d %H:%M:%S')\e[0m"
echo -e "\e[36m============================================================\e[0m"
echo ""
echo -e "\e[90mEach iteration runs a fresh Claude Code session to document\e[0m"
echo -e "\e[90mthe next batch. Press Ctrl+C to stop between iterations.\e[0m"
echo ""

iteration=1
total_input_tokens=0
total_output_tokens=0
total_cost_usd=0

while true; do
    echo -e "\e[32m[$(date '+%H:%M:%S')] Iteration $iteration started...\e[0m"
    echo ""

    input_tokens=0
    output_tokens=0
    cost_usd=0

    while IFS= read -r line; do
        result=$(echo "$line" | python3 -c "
import sys, json
try:
    obj = json.load(sys.stdin)
    if obj.get('type') == 'assistant':
        for block in obj.get('message', {}).get('content', []):
            if block.get('type') == 'text':
                print(block.get('text', ''), end='', flush=True)
            elif block.get('type') == 'tool_use':
                print('\033[36m[Tool: ' + block.get('name', '') + ']\033[0m', flush=True)
    elif obj.get('type') == 'result':
        usage = obj.get('usage', {})
        cost = obj.get('cost_usd', 0)
        print('TOKENS:' + str(usage.get('input_tokens',0)) + ':' + str(usage.get('output_tokens',0)) + ':' + str(cost))
except: pass
" 2>/dev/null)
        if [[ "$result" == TOKENS:* ]]; then
            IFS=':' read -r _ input_tokens output_tokens cost_usd <<< "$result"
        elif [ -n "$result" ]; then
            echo "$result"
        fi
    done < <(claude --dangerously-skip-permissions --verbose --output-format stream-json --print "run $BATCH_COMMAND $COMMAND_ARGS")

    total_input_tokens=$((total_input_tokens + input_tokens))
    total_output_tokens=$((total_output_tokens + output_tokens))
    total_cost_usd=$(echo "$total_cost_usd + $cost_usd" | bc 2>/dev/null || echo "$total_cost_usd")

    echo ""
    echo -e "\e[33m----------------------------------------\e[0m"
    echo -e "\e[33m  Iteration $iteration complete\e[0m"
    echo -e "\e[33m    Input  : $input_tokens tokens\e[0m"
    echo -e "\e[33m    Output : $output_tokens tokens\e[0m"
    echo -e "\e[33m    Cost   : \$$cost_usd USD\e[0m"
    echo -e "\e[33m  Running totals:\e[0m"
    echo -e "\e[33m    Input  : $total_input_tokens tokens\e[0m"
    echo -e "\e[33m    Output : $total_output_tokens tokens\e[0m"
    echo -e "\e[33m    Cost   : \$$total_cost_usd USD\e[0m"
    echo -e "\e[33m----------------------------------------\e[0m"

    schema_complete=false
    index_path="knowledge/synapse/Wiki/${SCHEMA_NAME}/_index.md"
    if [ -f "$index_path" ]; then
        if grep -q "Pending" "$index_path"; then
            echo -e "\e[32m[$(date '+%H:%M:%S')] Objects still pending. Starting next batch...\e[0m"
        else
            schema_complete=true
        fi
    fi

    if [ "$schema_complete" = true ]; then
        echo ""
        echo -e "\e[35m============================================================\e[0m"
        echo -e "\e[35m  SCHEMA COMPLETE - $SCHEMA_NAME\e[0m"
        echo -e "\e[35m  Total iterations: $iteration\e[0m"
        echo -e "\e[35m  Total input tokens:  $total_input_tokens\e[0m"
        echo -e "\e[35m  Total output tokens: $total_output_tokens\e[0m"
        echo -e "\e[35m  Total cost: \$$total_cost_usd USD\e[0m"
        echo -e "\e[35m============================================================\e[0m"
        break
    fi

    echo ""
    ((iteration++))
done
