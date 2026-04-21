# Column Lineage — eMoney_dbo.eMoneyProcessStatusLog

Generated: 2026-04-21

## Source Objects

| Object | Type | Role |
|--------|------|------|
| `eMoney_dbo.SP_eMoneyProcessStatusLog` | Stored Procedure | ETL writer (INSERT-only, append log) |
| `eMoney_dbo.SP_eMoney_Execute_Group_One` | Stored Procedure | Primary caller — CATCH block (active) + 15 SP wrapper calls (commented out since 2023-10-30) |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | ProcessName | SP parameter | @ProcessName | Passthrough of input parameter NVARCHAR(500) | 2 |
| 2 | ProcessStatus | SP parameter | @ProcessStatus | Passthrough of input parameter NVARCHAR(50) | 2 |
| 3 | ProcessStatusTime | System function | GETDATE() | Timestamp at INSERT time | 2 |
| 4 | ProcessStatusDate | System function | GETDATE() | CAST(GETDATE() AS DATE) — date portion of ProcessStatusTime | 2 |
| 5 | ErrorDescription | SP parameter | @ErrorDescription | SUBSTRING(@ErrorDescription, 1, 4000) — truncated to 4000 chars | 2 |

## External Lineage (UC)

UC Target: `_Not_Migrated`

This table has no Unity Catalog target. It is an operational ETL infrastructure log, not included in the Databricks Gold layer.

## Notes

- Table is FROZEN since 2023-10-30 — all SP calls in SP_eMoney_Execute_Group_One were commented out by Katy F on that date.
- The CATCH block in SP_eMoney_Execute_Group_One (lines 153-154) remains ACTIVE (not commented) — new Fail entries would appear if the orchestrator SP were called and encountered an error.
- 16,726 total rows; 17 distinct ProcessName values logged; 32 Fail entries.
