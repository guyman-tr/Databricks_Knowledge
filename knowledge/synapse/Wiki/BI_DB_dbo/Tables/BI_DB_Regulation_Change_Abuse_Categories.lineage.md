# Lineage: BI_DB_dbo.BI_DB_Regulation_Change_Abuse_Categories

## Source Chain

| Level | Object | Type | Role |
|-------|--------|------|------|
| L0 | etoro.Fact_SnapshotCustomer (production, via DWH_dbo staging) | DWH Fact | Daily customer regulatory snapshot; LAG pattern detects regulation changes |
| L1 | DWH_dbo.Fact_SnapshotCustomer | DWH Fact Table | Source of regulation change history (RegulationID LAG over UpdateDate) |
| L1 | DWH_dbo.Dim_Customer | DWH Dimension | Population gate (IsValidCustomer=1, IsDepositor=1) + FTDDate, CID |
| L1 | DWH_dbo.Dim_Regulation | DWH Dimension | RegulationID → Regulation name |
| L1 | DWH_dbo.Dim_Country | DWH Dimension | CountryID → Country, Region |
| L1 | DWH_dbo.Dim_AccountType | DWH Dimension | AccountTypeID → AccountType |
| L1 | DWH_dbo.Dim_PlayerLevel | DWH Dimension | PlayerLevelID → PlayerLevel |
| L1 | DWH_dbo.Dim_PlayerStatus | DWH Dimension | PlayerStatusID → PlayerStatus |
| L2 | BI_DB_dbo.BI_DB_Regulation_Change_Abuse_Categories | **THIS TABLE** | Demographic frequency distribution of regulation change counts |

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (daily regulatory snapshot per customer)
  |-- LAG(RegulationID,1,0) OVER(PARTITION BY RealCID ORDER BY UpdateDate) ---|
  |   WHERE RegulationID <> Previous_RegulationID → regulation change event   |
  v
#regulation01 (change events: CID, old Reg, new Reg, RegChangeRowNum)
  |-- ROW_NUMBER() OVER(PARTITION BY CID ORDER BY UpdateDate) ---|
  v
#regulation02 (per-change rows with RegChangeRowNum 1..N per CID)
  |-- MAX(RegChangeRowNum) per CID ---|
  v
#maxchanges (CID → Total_RegChangeCount)

DWH_dbo.Dim_Customer (IsValidCustomer=1, IsDepositor=1) → #ftdpop
  + Dim_Regulation, Dim_Country, Dim_AccountType, Dim_PlayerLevel, Dim_PlayerStatus (enrichment)
  |-- LEFT JOIN #maxchanges ON CID ---|
  v
#categorytable (CID-level: all depositor attributes + Total_RegChangeCount [NULL if no changes])
  |-- GROUP BY all dimensions + Total_RegChangeCount, COUNT(CID) AS CIDsCount ---|
  v
#finalagg

  |-- TRUNCATE + INSERT (SP_Regulation_Change_Abuse, @Date, daily) ---|
  v
BI_DB_dbo.BI_DB_Regulation_Change_Abuse_Categories (260,077 rows — 2026-04-13 snapshot)
  └── UC: Not Migrated
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | FTDMonthYear | Dim_Customer | FirstDepositDate | `FORMAT(FirstDepositDate, 'MMM-yyyy')` or equivalent — text label for FTD cohort month | Tier 2 |
| 2 | Regulation | Dim_Regulation | Name | Direct — regulation name for this demographic segment | Tier 1 |
| 3 | Country | Dim_Country | Country | Direct — country name | Tier 1 |
| 4 | Region | Dim_Country | Region | Direct — marketing region label | Tier 1 |
| 5 | AccountType | Dim_AccountType | Name | Direct — account type name | Tier 1 |
| 6 | PlayerLevel | Dim_PlayerLevel | Name | Direct — eToro Club tier name | Tier 1 |
| 7 | PlayerStatus | Dim_PlayerStatus | Name | Direct — player/account status | Tier 1 |
| 8 | Total_RegChangeCount | Fact_SnapshotCustomer (computed) | RegulationID | MAX(RegChangeRowNum) per CID from LAG change detection. NULL = customer had zero regulation changes | Tier 2 |
| 9 | CIDsCount | SP-computed | CID | COUNT(CID) within each demographic + change count bucket | Tier 2 |
| 10 | UpdateDate | SP-computed | GETDATE() | ETL metadata: timestamp when this row was last updated by the ETL pipeline | Tier 2 |

## UC External Lineage

UC Target: Not Migrated
