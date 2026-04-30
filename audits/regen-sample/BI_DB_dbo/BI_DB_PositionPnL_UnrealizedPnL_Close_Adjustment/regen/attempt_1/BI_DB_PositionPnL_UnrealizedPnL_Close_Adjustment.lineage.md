# Lineage: BI_DB_dbo.BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment

## Source Objects

| # | Source Object | Schema | Role | Relationship |
|---|---------------|--------|------|--------------|
| 1 | BI_DB_PositionPnL | BI_DB_dbo | Prior-day unrealized P&L snapshot (open positions) | JOIN on PositionID; provides UnrealizedPnLStart via PositionPnL column for positions that were open the prior day |
| 2 | Dim_Position | DWH_dbo | Closed-position attributes and realized P&L | JOIN on PositionID WHERE CloseDateID = @dateID; provides NetProfit and position dimension columns |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|---------------|---------------|-----------|------|
| 1 | DateID | (parameter) | @date | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | Tier 3 |
| 2 | CID | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | CID | COALESCE(upl.CID, dp.CID) | Tier 1 |
| 3 | PositionID | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | PositionID | COALESCE(upl.PositionID, dp.PositionID) | Tier 1 |
| 4 | UnrealizedPnLStart | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | Prior-day PositionPnL value; SUM(ISNULL(…, 0)) | Tier 2 |
| 5 | UnrealizedPnLEnd | (literal) | 0 | Hardcoded 0 — position closed, unrealized PnL ceases | Tier 2 |
| 6 | UnrealizedPnLChange | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | CASE: if Start IS NULL then End; if End IS NULL then -1*Start; else End - Start. Then SUM. | Tier 2 |
| 7 | NetProfit | DWH_dbo.Dim_Position | NetProfit | SUM(ISNULL(dp.NetProfit, 0)) — passthrough (one row per PositionID) | Tier 1 |
| 8 | InstrumentID | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | InstrumentID | COALESCE(dp.InstrumentID, upl.InstrumentID) | Tier 1 |
| 9 | MirrorID | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | MirrorID | COALESCE(dp.MirrorID, upl.MirrorID) | Tier 1 |
| 10 | Leverage | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | Leverage | COALESCE(dp.Leverage, upl.Leverage) | Tier 1 |
| 11 | IsBuy | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | IsBuy | COALESCE(dp.IsBuy, upl.IsBuy) | Tier 1 |
| 12 | IsSettled | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | IsSettled | COALESCE(dp.IsSettled, upl.IsSettled) | Tier 5 |
| 13 | HedgeServerID | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | HedgeServerID | COALESCE(dp.HedgeServerID, upl.HedgeServerID) | Tier 1 |
| 14 | SettlementTypeID | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | SettlementTypeID | COALESCE(dp.SettlementTypeID, upl.SettlementTypeID) | Tier 1 |
| 15 | UpdateDate | (runtime) | GETDATE() | Row load timestamp | Tier 3 |
