# Review Needed: BI_DB_dbo.BI_DB_AdvancedDeposit_Ext

## Critical: Table is Empty / No Writer SP

1. **0 rows**: Table has no data.
2. **No writer SP**: No stored procedure in the SSDT repo writes to this table.
3. **Backup cleanup**: A backup table was cleaned up on 2024-12-01 (original backup from 2024-11-17).
4. **All Tier 4**: Every column description is inferred from column names only — no SP code to trace.

## Questions for Reviewer

- Was this table formally decommissioned? Should the DDL be removed from the SSDT repo?
- What process originally populated this table? Was it a scheduled SP, an ADF pipeline, or a manual ad-hoc query?
- Is there a replacement table or report that serves the same purpose (advanced deposit analysis with credit card BIN data)?
- Contains PII fields (IPAddress, BinCode) — ensure proper handling if table is ever repopulated.

## Decommission Candidate

This table appears to be a strong candidate for decommissioning based on:
- 0 rows
- No writer SP
- Backup already cleaned up
- Wide schema (47 cols) suggests it was a purpose-built analysis table, not a core pipeline component
