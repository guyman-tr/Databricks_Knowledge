# Review Needed: BI_DB_dbo.BI_DB_AdvancedDeposit_Ext

## Critical: Table is Dormant — No Active Writer

1. **0 rows**: Table has no data. Confirmed via live Synapse query (2026-04-27).
2. **No direct writer SP**: SP_H_Deposits creates `#AdvancedDeposit_Ext` temp table with identical structure but writes to `BI_DB_Deposits`, not this table.
3. **Backup cleanup**: `BI_DB_AdvancedDeposit_Ext_Backup_20241117` was cleaned up on 2024-12-01, suggesting decommissioning around November 2024.

## Lineage Confidence

- Column lineage is **indirect**: traced from SP_H_Deposits temp table construction, not from a direct writer to this table. The temp table `#AdvancedDeposit_Ext` matches this table's DDL for 47 of 52 temp columns (the extra 5 — ResponseName, ResponseRN, Date, DateID, UpdateDate — are not in this table's DDL).
- **All 47 columns are Tier 2**: No upstream wiki was resolvable in the pre-resolved bundle. Tier 1 verbatim inheritance is impossible without a wiki document to quote from. All descriptions are grounded in SP_H_Deposits code analysis, DDL structure, and JOIN patterns.

## Questions for Reviewer

- **Decommission decision**: Should this DDL be removed from SSDT? The table has been empty since ~Nov 2024 with no active writer.
- **Relationship to BI_DB_Deposits**: Is `BI_DB_Deposits` the formal replacement? The SP writes to BI_DB_Deposits with the same column set plus ResponseName, ResponseRN, Date, DateID, UpdateDate.
- **CID type discrepancy**: The current DDL defines CID as `int`, but the backup table defines it as `bigint`. Was the DDL modified after decommissioning?
- **IsFTD type narrowing**: Fact_BillingDeposit stores IsFTD as `int`; this DDL uses `bit`. Confirm no data loss occurred historically.
- **PII fields**: IPAddress (numeric representation of IP) and BinCode are present. If the table is ever repopulated, ensure PII classification and masking are applied.

## Decommission Candidate

Strong candidate for DDL removal based on:
- 0 rows since at least November 2024
- No active writer SP targets this table
- Backup already cleaned up
- Active replacement exists (`BI_DB_Deposits`)
- Wide schema (47 columns) suggests purpose-built analysis table, not a core pipeline component
