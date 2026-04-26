# BI_DB_dbo.BI_DB_BODailyCompensations

**Schema**: BI_DB_dbo | **Batch**: 56 | **Generated**: 2026-04-23

## Purpose

Daily compensation credit ledger for the Back Office (BO) domain. Records every etoro credit transaction classified as a compensation (CreditTypeID=6) at the individual customer level, enriched with manager attribution, compensation category, customer country, and regulatory regime. Feeds BO compensation reporting, regulatory analysis by jurisdiction, and manager performance dashboards.

## Shape

| Property | Value |
|----------|-------|
| Rows | ~22,392,972 |
| Columns | 11 |
| Distribution | ROUND_ROBIN |
| Index | HEAP |
| Grain | One row per compensation credit transaction (CreditID) |

## Load Pattern

**Daily window replace** — `SP_BI_DB_BODailyCompensations(@Date)` deletes all rows where `Occurred >= @Date AND < @Date+1`, then re-inserts from the source for that same window. Each run refreshes exactly one day of compensations; re-running a date corrects any upstream data changes. `UpdateDate` reflects the INSERT timestamp, not the business event date; the spread of UpdateDate values (2022-09-13 to 2026-04-13) confirms historical backfills were performed at initial load.

## Columns

| # | Column | Type | Nullable | Description | Tier |
|---|--------|------|----------|-------------|------|
| 1 | ID | int IDENTITY(1,1) | NOT NULL | Surrogate key auto-incremented by Synapse at INSERT; has no upstream business meaning | Propagation |
| 2 | CID | int | NULL | Customer identifier — FK to DWH_dbo.Dim_Customer.CID | Tier 2 |
| 3 | CreditID | bigint | NULL | Source compensation credit record identifier from etoro.History.Credit | Tier 2 |
| 4 | Occurred | datetime | NULL | Date and time the compensation credit occurred in the source system | Tier 2 |
| 5 | Payment | money | NULL | Compensation payment amount in USD; positive = credit to customer, negative = fee or deduction | Tier 2 |
| 6 | Description | varchar(max) | NULL | Free-text description of the compensation as entered in the source credit system | Tier 2 |
| 7 | Manager | varchar(max) | NULL | Full name (FirstName + LastName) of the Back Office manager attributed to the compensation; NULL for system-generated compensations | Tier 2 |
| 8 | Category | varchar(max) | NULL | Compensation reason category name from etoro.BackOffice.CompensationReason (e.g., "Interest Payment", "Staking", "Administration fee", "Promotion", "Position Airdrop", "Dormant Fee") | Tier 2 |
| 9 | Country | varchar(max) | NULL | Customer's country of residence name, resolved via Dim_Customer → Dim_Country | Tier 2 |
| 10 | Regulation | varchar(max) | NULL | Customer's designated regulatory regime name, resolved via Dim_Customer → Dim_Regulation | Tier 2 |
| 11 | UpdateDate | datetime | NULL | Timestamp when this row was last inserted by the ETL pipeline (GETDATE() at INSERT time) | Propagation |

## Key Relationships

| Column | Joins To | Cardinality |
|--------|----------|-------------|
| CID | DWH_dbo.Dim_Customer.CID | Many-to-one |
| CreditID | etoro.History.Credit.CreditID | One-to-one (source PK) |
| Manager | DWH_dbo.Dim_Manager (resolved at load, not a stored FK) | — |
| Country | DWH_dbo.Dim_Country (resolved at load, not a stored FK) | — |
| Regulation | DWH_dbo.Dim_Regulation (resolved at load, not a stored FK) | — |

## Data Observations

- Occurred spans 2022-06-01 to 2026-04-12; UpdateDate spans 2022-09-13 to 2026-04-13
- Payment is predominantly positive (credits to customers); a material subset is negative (administration fees, dormant fees)
- Manager is NULL for approximately 39% of recent rows — system-automated compensation rules (interest payments, staking rewards) carry no manager attribution
- Category has 67 distinct values; representative high-volume categories include Interest Payment, Staking, Administration fee, Promotion, Position Airdrop, and Dormant Fee
- CreditTypeID=6 filter applied at source — only compensation credits flow into this table; deposits, bonuses, and other credit types are excluded

## Quality Notes

| Dimension | Assessment |
|-----------|-----------|
| Tier Distribution | 9 Tier 2, 2 Propagation |
| Completeness | All 11 columns documented |
| Tier 1 | 0 — no upstream wiki for etoro.History.Credit |
| Known Gaps | No upstream wiki for etoro.History.Credit or etoro.BackOffice.CompensationReason; column semantics derived from SP code only |

**Quality Score**: 8.2/10
