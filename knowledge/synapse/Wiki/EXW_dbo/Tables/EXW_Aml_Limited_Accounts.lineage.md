---
object: EXW_dbo.EXW_Aml_Limited_Accounts
type: Table
generated: 2026-04-20
phase: 10B
---

# Column Lineage — EXW_dbo.EXW_Aml_Limited_Accounts

## ETL Chain

```
External source (unknown — not tracked in SSDT SSDT SPs)
  Likely: manual import / ADF pipeline / legacy script
  OR: legacy Google Sheet import before Fivetran integration
    |
    | No SSDT SP found that writes to this table
    | (SP_EXW_CompensationClosingCountries only READS from it)
    | Last UpdateDate: 2023-11-13 — appears to be frozen/archived
    v
EXW_dbo.EXW_Aml_Limited_Accounts (3,650 rows — static since 2023-11)
    |
    | consumed by:
    +-- SP_EXW_CompensationClosingCountries → #Aml_Limited UNION
        (combined with External_Fivetran_google_sheets_exw_aml_limited_accounts
         for complete AML limited user population in EXW_ReimbursementSumTable)
```

## Column Lineage

| # | DWH Column | Tier | Source Table | Source Column | Transform |
|---|------------|------|-------------|---------------|-----------|
| 1 | LastUpdateDate | T2 | External source (unknown) | — | Date when AML status was last updated; 1899-12-30 sentinel values present (SQL zero-date artifact) |
| 2 | RealCID | T2 | External source (unknown) | — | Platform customer ID; no upstream wiki for source |
| 3 | GCID | T2 | External source (unknown) | — | Wallet customer ID; distribution key |
| 4 | Reason | T2 | External source (unknown) | — | AML limitation reason text |
| 5 | LatestStatus | T2 | External source (unknown) | — | Current AML status code; observed values: 0, 1, 2, NULL |
| 6 | SetToReadOnlyDate | T2 | External source (unknown) | — | Date when wallet was set to read-only access |
| 7 | SetToBlockedDate | T2 | External source (unknown) | — | Date when wallet was set to fully blocked |
| 8 | Units | T2 | External source (unknown) | — | Crypto balance in native units (stored as nvarchar — text) |
| 9 | USD | T2 | External source (unknown) | — | USD equivalent of crypto balance (stored as nvarchar — text) |
| 10 | TradingRestriction | T2 | External source (unknown) | — | Trading restriction applied to this user |
| 11 | AmlComment | T2 | External source (unknown) | — | Analyst comment/note about the AML case |
| 12 | SarSubmitted | T2 | External source (unknown) | — | Whether a Suspicious Activity Report was submitted (nvarchar — likely 'Yes'/'No'/text) |
| 13 | DateSubmitted | T2 | External source (unknown) | — | Date the SAR was submitted |
| 14 | UpdateDate | T2 | ETL-computed | — | Datetime of last DWH update; NOT NULL (DDL constraint) |

## Tier Summary

- **Tier 1**: 0 columns — no upstream wiki for the source (external manual import, origin unknown from SSDT code)
- **Tier 2**: 14 columns — all from external source not tracked in SSDT; UpdateDate is ETL-computed GETDATE()
- **Tier 3**: 0
- **Tier 4**: 0

## UC Target

- **Synapse**: EXW_dbo.EXW_Aml_Limited_Accounts
- **UC Target**: `_Not_Migrated` (no UC mapping found — AML reference, Synapse-only)
