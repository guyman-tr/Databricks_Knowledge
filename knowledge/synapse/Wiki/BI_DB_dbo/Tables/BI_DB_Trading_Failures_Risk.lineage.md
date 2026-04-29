# BI_DB_dbo.BI_DB_Trading_Failures_Risk — Column Lineage

## Source Objects

| Source | Schema | Role | Join Condition |
|--------|--------|------|----------------|
| Dealing_staging.PositionFailReal_History_PositionFail_DWH | Dealing_staging | Position failure events (FailTypeID 3=Open, 4=Close) | Main driver for Failures rows |
| CopyFromLake.DB_Logs_History_OpenExecutionPlan | CopyFromLake | MirrorID/Amount for open failures | oep.OrderID = pf.OrderID AND oep.CID = pf.CID |
| Dealing_staging.External_DB_Logs_History_CloseExecutionPlan | Dealing_staging | Close execution plan (Level filter) | cep.OrderID = pf.ExitOrderID AND cep.CID = pf.CID |
| DWH_dbo.Dim_Position | DWH_dbo | Position details for close failures + succeeded positions | pf.PositionID = hp.PositionID / OpenDateID/CloseDateID = @DateID |
| DWH_dbo.Dim_Customer | DWH_dbo | Customer regulation mapping | pf.CID = dc.RealCID / dp.CID = dc.RealCID |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name lookup | dr.ID = dc.RegulationID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | PositionFail / Dim_Position | FailOccurred / OpenOccurred / CloseOccurred | CAST AS DATE |
| ErrorCode | PositionFail / (literal) | ErrorCode / -1 | Failures: from source; Succeeds: -1 |
| InstrumentID | PositionFail / Dim_Position | InstrumentID | Passthrough |
| Leverage_Type | PositionFail / Dim_Position | Leverage | CASE: >1='Leveraged', else='Not Leveraged' |
| Copy_Manual | OpenExecutionPlan / Dim_Position | MirrorID | CASE: >0='Copy', else='Manual' |
| ind_open_close | (computed) | — | 'Open' or 'Close' based on FailTypeID/source |
| Type | (computed) | — | 'Failures' or 'Succeeds' based on source |
| Customers | (aggregation) | CID | COUNT(DISTINCT CID) |
| Orders_Positions | (aggregation) | OrderID / PositionID | COUNT(orders/positions) |
| Amount | PositionFail / Dim_Position | Amount / InitialAmountCents | SUM(Amount) |
| Volume | (computed) | Amount * Leverage | SUM(Amount * Leverage) |
| HedgeServerID | PositionFail / Dim_Position | HedgeServerID | Passthrough |
| UpdateDate | (ETL) | GETDATE() | ETL metadata |
| RegulationID | DWH_dbo.Dim_Customer | RegulationID | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough |
| AirDrop_Type | (unpopulated) | — | Column exists in DDL but not in SP INSERT |

## Production Source Chain

```
Dealing_staging.PositionFailReal_History_PositionFail_DWH (position failures)
  + CopyFromLake.DB_Logs_History_OpenExecutionPlan (open execution plans)
  + Dealing_staging.External_DB_Logs_History_CloseExecutionPlan (close execution plans)
  + DWH_dbo.Dim_Position (position details + succeeded positions)
  + DWH_dbo.Dim_Customer (CID→RegulationID)
  + DWH_dbo.Dim_Regulation (RegulationID→Name)
  |-- SP_Trading_Failures_Risk @Date --|
  |-- Failures: FailTypeID 3(open)/4(close), exclude hierarchical/noise --|
  |-- Succeeds: Dim_Position opened/closed on @Date --|
  |-- Aggregate: COUNT/SUM by Date+ErrorCode+Instrument+Leverage+Copy+Direction+HedgeServer+Regulation --|
  |-- DELETE+INSERT by @Date --|
  v
BI_DB_dbo.BI_DB_Trading_Failures_Risk (27.7M rows)
  |-- Generic Pipeline (Append, parquet, 1440 min) --|
  v
trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk
```
