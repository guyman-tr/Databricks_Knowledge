# BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data — Column Lineage

## Writer SP
`BI_DB_dbo.SP_BI_DB_ReturnCalculation` — daily incremental DELETE+INSERT (Phase 1: new DateIDs only)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| DWH_dbo.Dim_Position | DWH_dbo | Closed position NetProfit (by CloseDateID) |
| DWH_dbo.V_Liabilities | DWH_dbo | RealizedEquity (by DateID) |
| BI_DB_dbo.BI_DB_DailyCommisionReport | BI_DB_dbo | FullCommissions + RollOverFee (Revenue) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| DateID | DWH_dbo.Dim_Position | CloseDateID | passthrough (NetProfit rows) |
| DateID | DWH_dbo.V_Liabilities | DateID | passthrough (RealizedEquity rows) |
| DateID | BI_DB_dbo.BI_DB_DailyCommisionReport | DateID | passthrough (Revenue rows) |
| Date | (computed) | — | derived from DateID (calendar date; 1900-01-01 for DateID=0) |
| RealCID | DWH_dbo.Dim_Position / V_Liabilities / DailyCommisionReport | RealCID | passthrough |
| NetProfit | DWH_dbo.Dim_Position | NetProfit | SUM by CloseDateID + RealCID |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | passthrough |
| IsZeroRealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | CASE WHEN RealizedEquity = 0 THEN 1 ELSE 0 END |
| IsNegativeRealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | CASE WHEN RealizedEquity < 0 THEN 1 ELSE 0 END |
| Revenue | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions, RollOverFee | SUM(FullCommissions + RollOverFee) by DateID + RealCID |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
