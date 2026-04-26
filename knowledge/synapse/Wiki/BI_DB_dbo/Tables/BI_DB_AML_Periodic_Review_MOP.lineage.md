# Column Lineage: BI_DB_dbo.BI_DB_AML_Periodic_Review_MOP

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_AML_Periodic_Review_MOP` |
| **UC Target** | Not_Migrated |
| **Primary Source** | `DWH_dbo.Fact_CustomerAction` (ActionTypeID=7 deposits since 2023) |
| **ETL SP** | Unknown — no SSDT writer SP found. Likely materialized from `SP_AML_Periodic_Review`'s `#mop` temp table logic via a separate extraction step not tracked in SSDT or OpsDB. |
| **Secondary Sources** | `DWH_dbo.Dim_Customer` (population filter), `DWH_dbo.Dim_PlayerStatus` (status filter), `DWH_dbo.Dim_FundingType` (MOP name resolution) |
| **Generated** | 2026-04-23 |

## Lineage Chain

```
DWH_dbo.Dim_Customer dc
    │  WHERE IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3
    │  JOIN Dim_PlayerStatus — exclude PlayerStatusID IN (2,4) [Blocked, Blocked Upon Request]
    │
    ├── JOIN DWH_dbo.Fact_CustomerAction fca
    │     ON pp.CID = fca.RealCID
    │     AND fca.ActionTypeID = 7                [Deposit events]
    │     AND fca.DateID >= 20230101              [Since 2023 only]
    │     AND fca.FundingTypeID NOT IN (1,2,3,4,11,13,15,17,29,30,32,33,34,35,36,37,38)
    │                                             [Exclude common/safe methods; keep high-risk MOPs]
    │
    ├── JOIN DWH_dbo.Dim_FundingType dft
    │     ON dft.FundingTypeID = fca.FundingTypeID
    │     → MOP name (OnlineBanking, MoneyBookers, Neteller, SEPA, etc.)
    │
    └─ [Extraction step] — SP or standalone job (not in SSDT)
        ├─ TRUNCATE TABLE target
        └─ INSERT → BI_DB_dbo.BI_DB_AML_Periodic_Review_MOP
```

> **Note**: The table contains one row per (CID, MOP) combination for fully-verified active customers who used a "high-risk" payment method (i.e., methods not on the exclusion list) for deposits since January 2023. The FundingTypeID exclusion list effectively selects non-standard or regionally high-risk MOPs.

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **join-enriched** | Joined from a secondary source table during ETL. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| CID | DWH_dbo.Dim_Customer | RealCID | join-enriched | `pp.CID` from verified customer population (VerificationLevelID=3, IsValidCustomer=1, IsDepositor=1, PlayerStatus not Blocked) | eToro customer Real account ID |
| MOP | DWH_dbo.Dim_FundingType | Name | join-enriched | `dft.Name` via `fca.FundingTypeID = dft.FundingTypeID` | Method of Payment name — the high-risk deposit method used since 2023 |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Join-enriched** | 2 |
| **ETL-computed** | 1 |
| **Total** | 3 |
