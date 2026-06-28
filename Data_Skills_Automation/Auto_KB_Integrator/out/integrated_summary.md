# Auto KB Integrated Daily Summary

- Overall health: **blocked**
- Implication rows source: `Data_Skills_Automation\Auto_KB_Integrator\out\implications_rows_latest_run.csv`

## Inputs (5 outputs)
- `genie` manifest: `Data_Skills_Automation\Genie_Watcher\out\daily_manifest.json`
- `uc_object` manifest: `Data_Skills_Automation\UC_Object_Watcher\out\daily_manifest.json`
- `dbschema` manifest: `Data_Skills_Automation\DBSchema_Lake_Watcher\out\daily_manifest.json`
- `confluence` manifest: `Data_Skills_Automation\Confluence_Watcher\out\retest_mcp_agent_manifest_2.json`
- implications rows: `Data_Skills_Automation\Auto_KB_Integrator\out\implications_rows_latest_run.csv`

## App Stats
- `genie`: new=0, changed=0, removed=0, processed_items=0
- `uc_object`: new=355, changed=0, removed=0, processed_items=1
- `dbschema`: new=0, changed=0, removed=0, processed_items=0
- `confluence`: new=3, changed=0, removed=0, processed_items=1

## Implication Counts
- `BLOCKER`: 1
- `NO_CHANGE_SKIPPED`: 3

## Blockers
- `uc_object` `uc_object:uc_new_object:main.bi_output.australia_tag_ob_june26`: exception: cursor_sdk Agent.prompt timed out after 60s
