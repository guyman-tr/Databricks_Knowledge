---
object: EXW_dbo.EXW_Aml_Limited_Accounts
type: Table
generated: 2026-04-20
schema: EXW_dbo
phase: 11
---

# EXW_dbo.EXW_Aml_Limited_Accounts

## 1. Object Summary

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Type** | Table |
| **Distribution** | HASH(GCID) |
| **Index** | HEAP |
| **Row Count** | 3,650 (static since 2023-11-13) |
| **UC Target** | `_Not_Migrated` — AML reference table; Synapse-only |
| **Primary Source** | External source (unknown — manual import or ADF pipeline, not tracked in SSDT) |
| **Load Pattern** | No active ETL; table appears frozen/archived as of November 2023 |
| **Downstream** | SP_EXW_CompensationClosingCountries → #Aml_Limited UNION (AML limited user coverage) |

## 2. Business Purpose

`EXW_Aml_Limited_Accounts` is the **legacy AML-limited accounts registry** for eToro's crypto wallet platform (EXW). It stores a historical list of wallet users who have had AML-related restrictions applied to their accounts — including read-only access, full blocking, and SAR (Suspicious Activity Report) submission records.

The table is now **frozen**: the last `UpdateDate` is 2023-11-13. Since then, the parallel Fivetran-imported source (`BI_DB_dbo.External_Fivetran_google_sheets_exw_aml_limited_accounts`) has been the live AML-limited accounts feed. Both sources are unioned by `SP_EXW_CompensationClosingCountries` to construct the complete AML-limited user population for downstream reimbursement and compensation logic.

### Key Data Gotchas

- **Units and USD are text (`nvarchar`)**, not numeric types. Arithmetic operations require explicit `CAST`/`CONVERT`. Stored as text likely due to the manual-import origin (Google Sheet or CSV export).
- **1899-12-30 date sentinel** appears in `LastUpdateDate`. This is a SQL Server zero-date artifact — it represents a `NULL` or zero-date value from the source system (date serial 0 in Excel/legacy systems maps to 1899-12-30 in SQL Server date arithmetic).
- **`LatestStatus` values (0, 1, 2, NULL)** are not formally documented in the SSDT codebase. Based on AML-domain context: 0 = active watchlist (no restriction yet applied), 1 = read-only wallet, 2 = fully blocked wallet. NULL = unknown/pre-restriction status.
- **`SarSubmitted` is `nvarchar`** — likely stores 'Yes', 'No', or free-text values rather than a boolean.
- **No SSDT SP writes to this table.** `SP_EXW_CompensationClosingCountries` is the only SP referencing it, and only as a reader. Loading origin is unknown from available code.

## 3. ETL / Lineage Summary

```
External source (unknown — not tracked in SSDT SPs)
  Likely: manual import / ADF pipeline / legacy script
  OR: legacy Google Sheet import before Fivetran integration
    |
    | No SSDT SP found that writes to this table
    | Last UpdateDate: 2023-11-13 — frozen/archived
    v
EXW_dbo.EXW_Aml_Limited_Accounts
    |
    | consumed by:
    +-- SP_EXW_CompensationClosingCountries → #Aml_Limited UNION
        (combined with External_Fivetran_google_sheets_exw_aml_limited_accounts
         for complete AML limited user population in EXW_ReimbursementSumTable)
```

See [`EXW_Aml_Limited_Accounts.lineage.md`](./EXW_Aml_Limited_Accounts.lineage.md) for column-level lineage.

## 4. Column Definitions

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | LastUpdateDate | date | YES | T2 | Date when the AML case status was last updated in the source system. Contains 1899-12-30 sentinel values — SQL zero-date artifact representing null/zero-date entries from the source (Excel serial 0). |
| 2 | RealCID | int | YES | T2 | Platform customer ID (CID on eToro's trading platform). Links the AML case to the customer's trading account identity. No upstream wiki for source. |
| 3 | GCID | int | YES | T2 | Wallet customer ID (GCID in EXW). Distribution key (HASH). Used as join key in SP_EXW_CompensationClosingCountries UNION with the Fivetran external table. |
| 4 | Reason | nvarchar(512) | YES | T2 | Free-text description of the AML limitation reason. Analyst-entered. Content not validated by known ETL code. |
| 5 | LatestStatus | int | YES | T2 | Current AML restriction status code. Observed values: 0 (active watchlist/no restriction applied yet), 1 (read-only wallet access), 2 (fully blocked wallet), NULL (unknown). Status semantics inferred from domain context — not formally documented in SSDT code. |
| 6 | SetToReadOnlyDate | date | YES | T2 | Date when the wallet was set to read-only access. NULL if the account was never placed in read-only status. |
| 7 | SetToBlockedDate | date | YES | T2 | Date when the wallet was set to fully blocked status. NULL if the account was never fully blocked. |
| 8 | Units | nvarchar(256) | YES | T2 | Crypto asset balance in native units at time of AML action. Stored as `nvarchar` (text) — likely due to manual import origin. Must be cast to numeric before arithmetic. |
| 9 | USD | nvarchar(256) | YES | T2 | USD equivalent of the crypto balance at time of AML action. Stored as `nvarchar` (text). Must be cast to numeric before arithmetic. |
| 10 | TradingRestriction | nvarchar(256) | YES | T2 | Type of trading restriction applied to this user. Free-text; content reflects analyst classification. |
| 11 | AmlComment | nvarchar(1024) | YES | T2 | Analyst comment or note about the AML case. Free-text narrative field. |
| 12 | SarSubmitted | nvarchar(256) | YES | T2 | Whether a Suspicious Activity Report (SAR) was filed for this account. Stored as `nvarchar` — likely 'Yes', 'No', or free-text values rather than a boolean flag. |
| 13 | DateSubmitted | date | YES | T2 | Date the SAR was submitted to the relevant authority. NULL if no SAR was filed. |
| 14 | UpdateDate | datetime | NOT NULL | T2 | Datetime of the last DWH record update. NOT NULL (DDL constraint). Likely set to `GETDATE()` at insert time by the (now-unknown) loading mechanism. Last observed value: 2023-11-13 — confirming the table is frozen. |

## 5. Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| T1 | 0 | No upstream DB_Schema wiki exists for this table's source. Origin is external (manual import or legacy pipeline) with no SSDT lineage. |
| T2 | 14 | All columns documented via DDL analysis, MCP live data inspection, and domain context. Source attribution: "External source (unknown)." |
| T3 | 0 | — |
| T4 | 0 | — |

## 6. Distribution & Indexing

| Property | Value |
|----------|-------|
| Distribution | HASH(GCID) |
| Index | HEAP |
| Rationale | GCID-hashed for join performance in SP_EXW_CompensationClosingCountries UNION. HEAP is appropriate for small, static reference table (3,650 rows). |

## 7. Relationships

| Related Object | Relationship | Notes |
|----------------|--------------|-------|
| `BI_DB_dbo.External_Fivetran_google_sheets_exw_aml_limited_accounts` | Parallel/complementary source | Live AML-limited accounts feed via Fivetran. This table is the legacy predecessor; both are unioned to get complete population. |
| `EXW_dbo.EXW_ReimbursementSumTable` | Indirect consumer | SP_EXW_CompensationClosingCountries uses the UNION of this table + Fivetran source as part of EXW_ReimbursementSumTable population. |
| `SP_EXW_CompensationClosingCountries` | Reader (not writer) | Only known SP referencing this table — reads GCID via `#Aml_Limited` temp table in UNION. |

## 8. Known Limitations

1. **Origin unknown**: No SSDT SP writes to this table. The loading mechanism (ADF pipeline, manual import, legacy script, or pre-Fivetran Google Sheet export) cannot be determined from available code artifacts.
2. **Frozen data**: All 3,650 rows reflect AML status as of November 2023. The table should be treated as historical/archived — not as a current AML status source.
3. **Unvalidated free-text fields**: `Reason`, `AmlComment`, `TradingRestriction`, `SarSubmitted`, `Units`, `USD` are unconstrained `nvarchar` columns. No ETL normalization is applied — values are analyst-entered or source-imported as-is.
4. **LatestStatus semantics undocumented**: The integer codes 0/1/2 are not documented in any known SSDT script or comment. The interpretations (watchlist/read-only/blocked) are inferred from domain context.
5. **Units/USD as text**: Cannot aggregate or compare these columns without explicit numeric casting. Division by zero, non-numeric values, or empty strings may be present.

## Self-Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| D1 Tier Accuracy (25%) | 10 | 0 T1, 14 T2 — correct; no upstream wiki exists for source |
| D2 Upstream Fidelity (20%) | 7 | N/A for T1 (no upstream wiki). T2 sourced from DDL + MCP. Neutral score. |
| D3 Completeness (20%) | 10 | No snapshot stats in element descriptions. All 14 columns documented. |
| D4 Business Meaning (15%) | 9 | Strong business context: AML-limited registry, frozen state, SAR documentation, read-only vs blocked distinction |
| D5 Data Evidence (10%) | 9 | MCP confirms: 3,650 rows, 2023-11-13 freeze, LatestStatus distribution, 1899-12-30 sentinels |
| D6 Shape Fidelity (10%) | 10 | 14 columns match DDL exactly; HASH(GCID), HEAP, nullable/NOT NULL flags correct |
| **Weighted Total** | **9.2/10** | PASS |
