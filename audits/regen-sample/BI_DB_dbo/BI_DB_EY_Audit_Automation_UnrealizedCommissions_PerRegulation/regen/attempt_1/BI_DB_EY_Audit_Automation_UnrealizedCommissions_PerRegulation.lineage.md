# Lineage: BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation

## Source Objects

| # | Source Object | Type | Schema | Role | Wiki Available |
|---|--------------|------|--------|------|----------------|
| 1 | SP_EY_Audit_Auditor_Unrealized_Calculations | Stored Procedure | BI_DB_dbo | Writer SP (DELETE+INSERT per DateID) | SP code in bundle |
| 2 | BI_DB_EY_Audit_Opened_Positions | Table | BI_DB_dbo | Intermediate — daily open position snapshots used to compute unrealized metrics | No |
| 3 | EY_Audit_Automation_LastOpRate | Table | BI_DB_dbo | Last operation price rates per position | No |
| 4 | EY_Audit_Automation_Opened_Positions_End_2022_Baseline | Table | BI_DB_dbo | Baseline open position prices for positions opened before 2023 | No |
| 5 | EY_Audit_Automation_Position_Open_Configs | Table | BI_DB_dbo | Spread/precision config per position at open | No |
| 6 | Dim_Position | Table | DWH_dbo | Closed position commissions (CommissionOnClose, FullCommissionOnClose) | Yes |
| 7 | Fact_SnapshotCustomer | Table | DWH_dbo | Customer-to-regulation mapping via DateRangeID | Yes |
| 8 | Dim_Range | Table | DWH_dbo | DateRangeID decode for Fact_SnapshotCustomer join | Yes |
| 9 | Dim_Regulation | Table | DWH_dbo | Regulation name lookup (DWHRegulationID → Name) | Yes |
| 10 | BI_DB_Client_Balance_Aggregate_Level_New | Table | BI_DB_dbo | Comparison source for validation INSERT (not a direct upstream for this table) | Yes |

## Column Lineage

| # | Target Column | Source Object(s) | Source Column(s) | Transform | Tier |
|---|--------------|-----------------|-----------------|-----------|------|
| 1 | DateID | SP_EY_Audit_Auditor_Unrealized_Calculations | @edateID (computed from @date param) | `CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)` — YYYYMMDD integer from SP @date parameter | Tier 2 |
| 2 | Date | SP_EY_Audit_Auditor_Unrealized_Calculations | @edate (SP @date parameter) | Direct assignment from SP parameter | Tier 2 |
| 3 | Regulation | Dim_Regulation | Name | Passthrough via JOIN `Dim_Regulation dr1 ON fsc.RegulationID = dr1.DWHRegulationID`; SELECT `dr1.Name AS Regulation` | Tier 1 |
| 4 | InstrumentID | #testresults → BI_DB_EY_Audit_Opened_Positions → Dim_Position | InstrumentID | Passthrough through temp tables from Dim_Position.InstrumentID | Tier 1 |
| 5 | InstrumentType | #testresults → BI_DB_EY_Audit_Opened_Positions | InstrumentType | Passthrough through temp tables; originates from BI_DB_EY_Audit_Opened_Positions (SP_EY_Audit_Opened_Positions) | Tier 2 |
| 6 | UnrealizedCommissionChange | #byRegulation → #regPrep → #testresults | ISNULL(ed.EY_UnrealizedCommission,0) - ISNULL(sd.EY_UnrealizedCommission,0) | `SUM` of per-position daily unrealized commission change (end date minus start date), aggregated by regulation via Fact_SnapshotCustomer + Dim_Regulation join | Tier 2 |
| 7 | UnrealizedFullCommissionChange | #byRegulation → #regPrep → #testresults | ISNULL(ed.EY_UnrealizedFullCommission,0) - ISNULL(sd.EY_UnrealizedFullCommission,0) | `SUM` of per-position daily unrealized full commission change (end date minus start date), aggregated by regulation | Tier 2 |
| 8 | UnrealizedPnLChange | #byRegulation → #regPrep → #testresults | ISNULL(ed.EY_PnL_Calculation,0) - ISNULL(sd.EY_PnL_Calculation,0) | `SUM` of per-position daily unrealized PnL change (end date minus start date), aggregated by regulation | Tier 2 |
| 9 | UpdateDate | SP_EY_Audit_Auditor_Unrealized_Calculations | GETDATE() | ETL timestamp at insert time | Tier 2 |
