---
object: EXW_dbo.EXW_ReimbursementSumTable
type: Table
generated: 2026-04-20
schema: EXW_dbo
phase: 11
---

# EXW_dbo.EXW_ReimbursementSumTable

## 1. Object Summary

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED COLUMNSTORE INDEX |
| **Row Count** | 7 (static structure — exactly one row per population segment) |
| **UC Target** | `_Not_Migrated` — regulatory reimbursement KPI summary; Synapse-only |
| **Primary Source** | SP_EXW_CompensationClosingCountries (TRUNCATE + INSERT, no date parameter) |
| **Load Pattern** | Full rebuild on each SP run; 7 rows always inserted |
| **Downstream** | BI/reporting dashboards (no downstream SSDT SP found) |

## 2. Business Purpose

`EXW_ReimbursementSumTable` is the **top-line KPI summary table** for eToro's wallet reimbursement and compensation monitoring. It aggregates the entire AML/country-closure compensation universe into exactly **7 population segments**, each representing a distinct cohort of wallet users in terms of their compensation status, wallet open/closed status, and whether they are AML-limited.

The table is the final output of `SP_EXW_CompensationClosingCountries` — the same SP that populates `EXW_CompensationClosingCountries` and `EXW_ReimbursementFollowUp`. It provides management-level visibility into:
- How many users are **closed and not yet compensated** (AML vs. unknown reason vs. compliance-event closure)
- How many compensated users are **still holding crypto** (allowed wallets with remaining balance)
- The **current USD value** of balances and compensation amounts using live crypto prices

### Population Segments (7 rows)

| # | Population Label | Business Meaning |
|---|-----------------|------------------|
| 1 | Customer not Allowed, not Compensated and have funds, Closed due to AML reasons | AML-limited users (from EXW_Aml_Limited_Accounts or Fivetran AML source) with closed wallet (SelectedValue 0/1) and positive balance, NOT yet in EXW_CompensationClosingCountries |
| 2 | Customer not Allowed, not Compensated and have funds, Closed due to Unknown Reason | Closed wallet users (SelectedValue 0/1) with balance, NOT in EXW_CompensationClosingCountries AND NOT AML-limited |
| 3 | Customer in Closed Country (Compliance Event Closure), but was not compensated | Users in a country closed via a compliance event (EXW_WalletClosedCountryProjects) with balance, NOT in EXW_CompensationClosingCountries |
| 4 | Customer Currently Allowed, but was Compensated, exclude AML compensated | Compensated users from non-AML projects (FrenchTerr, Germany, Russia, etc.) who now have open wallets (SelectedValue 2/3) |
| 5 | Customer Currently Allowed, but was Compensated by AML | Compensated users from AML* projects who now have open wallets |
| 6 | Customer Currently Closed and was Compensated, exl AML | Compensated users from non-AML projects who remain with closed wallets |
| 7 | Customer Currently Closed and was Compensated by AML | Compensated users from AML* projects who remain with closed wallets |

### Key Data Gotchas

- **Exactly 7 rows**: The table always has exactly 7 rows after each SP run. `Compensated By Current USD Price` is 0 for segments 1–3 (uncompensated cohorts). A zero in this column is meaningful — it means no compensation record exists for those users.
- **BalanceUSD uses a snapshot**: Balances come from `EXW_FinanceReportsBalancesNew` at `MAX(BalanceDateID)`. Crypto prices come from `EXW_PriceDaily` at the same date. Both are point-in-time; they change on each SP run as prices move.
- **[Compensated By Current USD Price] is NOT the original compensation amount**: It is the _current_ USD value of the compensation crypto (FinalBalance × current price). It can differ significantly from the actual payment amount (Rate × FinalBalance) due to crypto price movement since compensation date.
- **ROUND_ROBIN + CCI**: Appropriate for a 7-row analytics target — CCI enables efficient columnar aggregation for BI tools scanning all 7 rows; ROUND_ROBIN is fine for tiny tables.
- **EXW_Aml_Limited_Accounts dual-source**: AML-limited population (for segment 1) is a UNION of both the legacy table and the live Fivetran feed.

## 3. ETL / Lineage Summary

```
EXW_dbo.EXW_FinanceReportsBalancesNew (balance at MAX BalanceDateID)
EXW_Wallet.EXW_PriceDaily (crypto price at same date)
EXW_dbo.EXW_CompensationClosingCountries (who was compensated, FinalBalance)
EXW_dbo.EXW_Aml_Limited_Accounts + Fivetran AML source (#Aml_Limited UNION)
EXW_dbo.EXW_UserSettingsWalletAllowance (SelectedValue 0/1=closed, 2/3=open)
EXW_dbo.EXW_DimUser, EXW_dbo.EXW_WalletClosedCountryProjects
DWH_dbo.Fact_CustomerAction, DWH_dbo.Dim_Customer
  |
  | SP_EXW_CompensationClosingCountries (full rebuild)
  | TRUNCATE + INSERT 7 rows
  v
EXW_dbo.EXW_ReimbursementSumTable
```

See [`EXW_ReimbursementSumTable.lineage.md`](./EXW_ReimbursementSumTable.lineage.md) for column-level lineage.

## 4. Column Definitions

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | Population | varchar(540) | NOT NULL | T2 | Hardcoded string literal identifying the population cohort. One of 7 distinct values (see Section 2 Population Segments table). NOT NULL — each row must represent a named cohort. |
| 2 | Users | int | YES | T2 | Count of distinct wallet GCIDs in this population segment at the time of the SP run. COUNT(DISTINCT GCID) using segment-specific filter logic. |
| 3 | BalanceUSD | decimal(38,6) | YES | T2 | Current USD value of crypto holdings for users in this segment, computed as SUM(Balance × AvgPrice) from EXW_FinanceReportsBalancesNew × EXW_PriceDaily at the reference balance date. NULL if no users have positive balances. |
| 4 | Compensated By Current USD Price | numeric(38,6) | YES | T2 | Current USD value of the compensated crypto amount, computed as SUM(FinalBalance × AvgPrice) from EXW_CompensationClosingCountries × EXW_PriceDaily. This is NOT the original payment amount — it reflects the current market value of the compensation crypto. Always 0 for non-compensated segments (1–3). |
| 5 | UpdateDate | datetime | NOT NULL | T2 | Datetime of SP execution (GETDATE()). NOT NULL (DDL constraint). Refreshes on each SP run. |

## 5. Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| T1 | 0 | All columns are SP-computed aggregations. No upstream column is copied verbatim. |
| T2 | 5 | All derived via SP aggregation logic across 9+ source tables. |
| T3 | 0 | — |
| T4 | 0 | — |

## 6. Distribution & Indexing

| Property | Value |
|----------|-------|
| Distribution | ROUND_ROBIN |
| Index | CLUSTERED COLUMNSTORE INDEX |
| Rationale | ROUND_ROBIN is appropriate for a 7-row table with no join key. CCI enables efficient columnar scanning for BI aggregation queries. |

## 7. Relationships

| Related Object | Relationship | Notes |
|----------------|--------------|-------|
| `SP_EXW_CompensationClosingCountries` | Writer | TRUNCATE + INSERT — this SP is the sole writer. Runs as the final step after EXW_CompensationClosingCountries and EXW_ReimbursementFollowUp are updated. |
| `EXW_dbo.EXW_CompensationClosingCountries` | Upstream | FinalBalance values and GCID lists used for [Compensated By Current USD Price] and segment classification. |
| `EXW_dbo.EXW_FinanceReportsBalancesNew` | Upstream | Current balance snapshot; provides Balance × price for BalanceUSD. Also defines the reference date (@d). |
| `EXW_dbo.EXW_Aml_Limited_Accounts` | Upstream | Legacy AML-limited GCIDs; combined with Fivetran source to classify segment 1 users. |
| `EXW_dbo.EXW_UserSettingsWalletAllowance` | Upstream | SelectedValue (0/1 = closed, 2/3 = open) drives the allowed/closed split across segments. |
| `EXW_dbo.EXW_WalletClosedCountryProjects` | Upstream | Country-level compliance closure list; used to identify segment 3 users. |

## 8. Known Limitations

1. **No row-level detail**: The table contains only 7 summary rows. Drill-down requires joining `EXW_ReimbursementFollowUp` or querying source tables directly.
2. **Snapshot in time**: Both `BalanceUSD` and `Compensated By Current USD Price` change with each SP run as crypto prices and balances evolve. The table should not be treated as a stable historical record.
3. **[Compensated By Current USD Price] ≠ payment amount**: This column represents the current market value of the compensated crypto, not the actual USD paid. The actual payment amount is `USD_FinalBalance` in `EXW_CompensationClosingCountries`.
4. **Platform compensation included**: `DWH_dbo.Fact_CustomerAction` (ActionTypeID=36, CompensationReasonID IN 101,102) feeds platform-side compensation data into `EXW_ReimbursementFollowUp` but not directly into the 7 segments of this table. The `PlatformUSDCompensationPerGCID` metric is in `EXW_ReimbursementFollowUp`, not here.
5. **No downstream SSDT SP found**: This table is likely consumed by Power BI or Excel-based reporting. If the table is dropped, downstream reports may break without an SSDT alert.

## Self-Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| D1 Tier Accuracy (25%) | 10 | 0 T1, 5 T2 — correct; all columns are aggregations, no verbatim upstream column copies |
| D2 Upstream Fidelity (20%) | 7 | N/A for T1. T2 sourced from SP code analysis and MCP live query. Neutral. |
| D3 Completeness (20%) | 10 | All 5 columns documented; no snapshot stats in element descriptions; population segments documented in Section 2 |
| D4 Business Meaning (15%) | 9 | Strong: 7-segment KPI table explained, current-value vs. payment distinction, dual-source AML, snapshot semantics |
| D5 Data Evidence (10%) | 10 | MCP confirmed: 7 rows, all 7 Population values with user counts and USD amounts, UpdateDate today |
| D6 Shape Fidelity (10%) | 10 | 5 columns match DDL; ROUND_ROBIN, CCI, Population NOT NULL, UpdateDate NOT NULL correct |
| **Weighted Total** | **9.35/10** | PASS |
