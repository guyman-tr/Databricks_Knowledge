---
object: BI_DB_dbo.BI_DB_AMLComment_Risk_Score_Report_Ext
type: Table
lineage_version: 1
generated: 2026-04-23
---

# Column Lineage — BI_DB_AMLComment_Risk_Score_Report_Ext

## Source Summary

| Property | Value |
|----------|-------|
| **Production Source** | Unknown external AML compliance tool (pushes CID + AuditDate parameter sets) |
| **Writer SP** | None found in SSDT — external system feed |
| **ETL Pattern** | Unknown — external system populates; table acts as parameter/control set |
| **UC Target** | _Not_Migrated |

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | Unknown external AML tool | CID / customer_id | Passthrough — identifies the customer for AML comment risk score reporting | Tier 4 |
| 2 | AuditDate | Unknown external AML tool | audit_date | Passthrough — date of the AML comment audit event | Tier 4 |

## Notes

- Table has only 2 columns and 0 rows as of 2026-04-23.
- "Ext" suffix indicates external system feed (AML compliance tool pushes data rather than internal ETL SP).
- No SSDT stored procedure writes to this table; no references in any other SSDT object found.
- Likely a parameter/control table — the CID + AuditDate pairs would drive some AML comment risk score report process.
- Both columns assigned Tier 4 (no writer SP, no upstream wiki, unknown external source).
