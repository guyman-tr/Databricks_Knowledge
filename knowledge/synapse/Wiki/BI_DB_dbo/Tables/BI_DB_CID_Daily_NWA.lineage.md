# Column Lineage — BI_DB_dbo.BI_DB_CID_Daily_NWA

**Writer SP**: `BI_DB_dbo.SP_CID_Daily_NWA` (Priority 99 — FinanceReportSPS)
**ETL Pattern**: DELETE-INSERT by Date (daily incremental)
**Population Filter**: ActualNWA <> 0 AND IsValidCustomer (PlayerLevelID <> 4 OR AccountTypeID = 2, LabelID NOT IN 26,30)

---

## Source Tables

| Source | Alias | Role |
|--------|-------|------|
| DWH_dbo.V_Liabilities | vl | Primary — RealizedEquity, PositionPnL, TotalPositionsAmount, ActualNWA, BonusCredit |
| DWH_dbo.Fact_SnapshotCustomer | dc | Customer dimension snapshot (CountryID, LabelID, RegulationID, AccountTypeID, etc.) |
| DWH_dbo.Dim_Country | dcn | Country name + Region |
| DWH_dbo.Dim_Regulation | dr | Regulation name |
| DWH_dbo.Dim_Label | dl | Label name |
| DWH_dbo.Dim_AccountType | dat | Account type name |
| DWH_dbo.Dim_MifidCategorization | dmc | MiFID categorization name |
| DWH_dbo.Dim_PlayerLevel | dpl | Player level name |
| DWH_dbo.Dim_PlayerStatus | dps | Player status name |
| DWH_dbo.Dim_Range | drr | Date range resolution |
| BI_DB_dbo.BI_DB_Daily_CreditLine | cl | Credit line amount (LEFT JOIN) |
| BI_DB_dbo.V_GermanBaFin | vbf | German BaFin indicator (LEFT JOIN) |

---

## Column-Level Lineage

**⛔ Alias-level source attribution applied** — single SELECT statement, all aliases traceable.

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| Date | computed | @Date | SP parameter, direct |
| CID | V_Liabilities (vl) | CID | Direct. Primary key from liabilities view |
| Label | Dim_Label (dl) | Name | Direct via dc.LabelID |
| Country | Dim_Country (dcn) | Name | Direct via dc.CountryID |
| Region | Dim_Country (dcn) | Region | Direct |
| AccountType | Dim_AccountType (dat) | Name | Direct via dc.AccountTypeID |
| Regulation | Dim_Regulation (dr) | Name | Direct via dc.RegulationID |
| RealizedEquity | V_Liabilities (vl) | RealizedEquity | ISNULL(,0). Cash balance after realized gains/losses |
| PositionPnL | V_Liabilities (vl) | PositionPnL | ISNULL(,0). Unrealized profit/loss on open positions |
| TotalPositionsAmount | V_Liabilities (vl) | TotalPositionsAmount | ISNULL(,0). Total margin allocated to open positions |
| ActualNWA | V_Liabilities (vl) | ActualNWA | ISNULL(,0). Non-Withdrawable Amount (trading bonuses, principal not cashable). Filtered: <> 0 |
| BonusCredit | V_Liabilities (vl) | BonusCredit | ISNULL(,0). Bonus/credit balance |
| CreditLine | BI_DB_Daily_CreditLine (cl) | TotalCLAmount | ISNULL(,0). LEFT JOIN — NULL if no credit line |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
| IsGermanResident | Fact_SnapshotCustomer (dc) | CountryID | CASE WHEN CountryID = 79 THEN 1 ELSE 0 END. CountryID 79 = Germany |
| IsGermanBaFin | V_GermanBaFin (vbf) | CID existence | CASE WHEN CID IS NOT NULL THEN 1 ELSE 0 END |
| IsCreditReportValidCB | Fact_SnapshotCustomer (dc) | IsCreditReportValidCB | Direct |
| MifidCategorization | Dim_MifidCategorization (dmc) | Name | Direct via dc.MifidCategorizationID |
| PlayerLevel | Dim_PlayerLevel (dpl) | Name | Direct via dc.PlayerLevelID |
| PlayerStatus | Dim_PlayerStatus (dps) | Name | Direct via dc.PlayerStatusID |
