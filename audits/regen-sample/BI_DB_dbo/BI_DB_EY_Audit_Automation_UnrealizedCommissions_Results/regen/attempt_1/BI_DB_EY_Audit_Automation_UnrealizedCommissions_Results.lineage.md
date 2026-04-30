# Lineage: BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results

## Source Objects

| Source Object | Type | Relationship | Schema |
|--------------|------|-------------|--------|
| BI_DB_dbo.SP_EY_Audit_Auditor_Unrealized_Calculations | Stored Procedure | Writer (DELETE+INSERT per Date) | BI_DB_dbo |
| BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Table | Read (Metric_b comparison source) | BI_DB_dbo |
| BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions | Table | Read (position-level audit snapshots) | BI_DB_dbo |
| BI_DB_dbo.EY_Audit_Automation_LastOpRate | Table | Read (last operation price rates) | BI_DB_dbo |
| BI_DB_dbo.EY_Audit_Automation_Opened_Positions_End_2022_Baseline | Table | Read (pre-2023 baseline prices) | BI_DB_dbo |
| BI_DB_dbo.EY_Audit_Automation_Position_Open_Configs | Table | Read (spread configs per position) | BI_DB_dbo |
| DWH_dbo.Dim_Position | Table | Read (closed commissions for timing adjustment) | DWH_dbo |

## Column Lineage

| Target Column | Source Object | Source Column | Transform |
|--------------|--------------|---------------|-----------|
| Date | SP parameter @date | @edate | `CONVERT(DATE, CONVERT(VARCHAR(8), ma.DateID), 112)` |
| Stored_Proc | ETL-computed | N/A | Hardcoded string: `'SP_EY_Audit_Auditor_Unrealized_Calculations_On_Synapse'` |
| Metric_a | #testresults aggregation | N/A | Hardcoded label from UNION: `'EY_UnrealizedCommissionChange_Calc'`, `'EY_UnrealizedFullCommissionChange_Calc'`, or `'EY_UnrealizedPnLChange_Calc'` |
| Metric_a_Value | #testresults | UnrealizedCommissionChange / UnrealizedFullCommissionChange / UnrealizedPnLChange | `ABS(SUM(...))` of per-position daily change computed by EY audit logic |
| Metric_b | BI_DB_Client_Balance_Aggregate_Level_New | N/A | Hardcoded label from UNION: `'CB_UnrealizedCommissionChange'`, `'CB_UnrealizedFullCommissionChange'`, or `'CB_UnrealizedPnLChange'` |
| Metric_b_Value | BI_DB_Client_Balance_Aggregate_Level_New | UnrealizedCommissionChange / UnrealizedFullCommissionChange / UnrealizedPnLChange | `ABS(SUM(...))` from client balance aggregate for the same DateID |
| Diff | ETL-computed | Metric_a_Value, Metric_b_Value | `Metric_a_Value - Metric_b_Value` |
| Diff_Percentage | ETL-computed | Metric_a_Value, Metric_b_Value | `ABS((Metric_a_Value - Metric_b_Value) / Metric_b_Value * 100)` |
| IsPriceFound | ETL-computed | N/A | Hardcoded `NULL` |
| UpdateDate | ETL-computed | N/A | `GETDATE()` at insert time |
