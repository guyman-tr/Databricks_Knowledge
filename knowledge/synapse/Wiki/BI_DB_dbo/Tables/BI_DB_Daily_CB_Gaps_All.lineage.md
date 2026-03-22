# Column Lineage -- BI_DB_dbo.BI_DB_Daily_CB_Gaps_All

**Writer SP**: `BI_DB_dbo.SP_Daily_CB_Gaps_All` (Priority 99 -- FinanceReportSPS)
**Author**: Guy Manova (2021-03-25)
**ETL Pattern**: DELETE-INSERT by DateID
**Population Filter**: HAVING ABS(Gap) > 0.01

---

## Source Tables

| Source | Alias | Role |
|--------|-------|------|
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | bdcbcln | Primary -- all balance components |
| DWH_dbo.Fact_SnapshotCustomer | fsc | Customer classification |
| DWH_dbo.Dim_Range | dr | Date range resolution |
| DWH_dbo.Dim_Regulation | dr1 | Regulation name |
| BI_DB_dbo.V_GermanBaFin (via #germanbafin) | vgbf | German BaFin indicator |
| DWH_dbo.Dim_PlayerStatus | dps | Player status name |

---

## Column-Level Lineage

**Alias-level source attribution applied** -- single SELECT/INSERT with #germanbafin temp.

| BI_DB Column | Source Table (alias) | Source Column | Transform |
|-------------|---------------------|---------------|-----------|
| CID | BI_DB_Client_Balance_CID_Level_New (bdcbcln) | CID | Direct |
| DateID | BI_DB_Client_Balance_CID_Level_New (bdcbcln) | DateID | Direct. Filtered: WHERE DateID = @dateID |
| Date | computed | DateID | CONVERT(date, CONVERT(varchar(10), bdcbcln.DateID)) |
| Regulation | Dim_Regulation (dr1) | Name | Direct via fsc.RegulationID = dr1.DWHRegulationID |
| IsCreditReportValidCB | Fact_SnapshotCustomer (fsc) | IsCreditReportValidCB | Direct |
| IsGermanBaFin | #germanbafin (vgbf) | CID existence | CASE WHEN vgbf.CID IS NOT NULL THEN 1 ELSE 0 END |
| PlayerStatus | Dim_PlayerStatus (dps) | Name | Direct via fsc.PlayerStatusID |
| ClosingBalance | BI_DB_Client_Balance_CID_Level_New (bdcbcln) | ClosingBalance | SUM(ISNULL(,0)) |
| CycleCalculation | BI_DB_Client_Balance_CID_Level_New (bdcbcln) | 27 component columns | SUM of OpeningBalance + Deposits + CompensationDeposit + UsedBonus + ... - Cashouts |
| Gap | computed | ClosingBalance, CycleCalculation | ClosingBalance - CycleCalculation. HAVING ABS() > 0.01 |
| UpdateDate | computed | GETDATE() | SP execution timestamp |
