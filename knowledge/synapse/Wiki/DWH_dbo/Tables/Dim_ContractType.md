# DWH_dbo.Dim_ContractType

> **FROZEN TABLE** — Affiliate contract type lookup (CPA, CPR, Rev, Hyb, etc.) with 9 manually loaded rows and no active ETL. NULL timestamps indicate one-time manual population.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) — **FROZEN** |
| **Key Identifier** | ContractTypeID (int, CLUSTERED INDEX) |
| **Row Count** | 9 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on ContractTypeID ASC |

---

## 1. Business Meaning

`Dim_ContractType` classifies affiliate partner contract models used in the marketing/affiliate domain:

| ID | Name | Description |
|----|------|-------------|
| 0 | N/A | Default placeholder |
| 1 | CPR | Cost Per Registration |
| 2 | CPA | Cost Per Acquisition (first deposit) |
| 3 | Rev | Revenue Share |
| 4 | Hyb | Hybrid (CPA + Rev Share combination) |
| 5 | Other | Unclassified contract type |
| 6 | eCost | Electronic cost model |
| 7 | ZeroCost | No-cost partnership |
| 8 | CPL | Cost Per Lead |

**No active ETL** — the table was manually populated and has NULL `InsertDate` and `UpdateDate` for all rows. Not found in `SP_Dictionaries_DL_To_Synapse` or any other SP.

---

## 2. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | ContractTypeID | int | YES | Tier 2 | Contract type identifier (0–8). |
| 2 | Name | varchar(20) | YES | Tier 2 | Short code for the contract model (CPA, CPR, Rev, Hyb, etc.). |
| 3 | InsertDate | datetime | YES | Tier 3 | NULL for all rows — not populated. |
| 4 | UpdateDate | datetime | YES | Tier 3 | NULL for all rows — not populated. |

---

*Generated: 2026-03-18 | Quality: 6.8/10 | Frozen Table: manually loaded, no ETL | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_ContractType.sql*
