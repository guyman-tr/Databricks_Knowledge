# Column Lineage: DWH_dbo.Dim_Position

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Position` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position` |
| **Primary Source** | `etoro_Trade_OpenPositionEndOfDay` (open positions) |
| **Secondary Source** | `etoro_History_ClosePositionEndOfDay` (closed positions) |
| **ETL SP** | `SP_Dim_Position_DL_To_Synapse` |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
[etoroDB-REAL]
  etoro.Trade.Position (open)          etoro.History.ClosePosition
          |                                        |
          v (Generic Pipeline, daily)              v (Generic Pipeline, daily)
  Bronze/etoro/Trade/OpenPositionEndOfDay   Bronze/etoro/History/ClosePositionEndOfDay
          |                                        |
          v                                        v
  DWH_staging.etoro_Trade_OpenPositionEndOfDay  DWH_staging.etoro_History_ClosePositionEndOfDay
          |                                        |
          +----------------+------------------------+
                           |
          Additional sources:
          - DWH_staging.etoro_History_BackOfficeCustomer (RegulationID)
          - DWH_staging.etoro_Trade_GetInstrument (IsSettled logic)
          - DWH_staging.etoro_History_PositionChangeLog (IsSettled/Amount corrections)
          - DWH_staging.etoro_Trade_PositionAirdropLog (IsAirDrop)
          - DWH_staging.PriceLog_History_CurrencyPrice_Active (price book data)
          - DWH_dbo.Ext_Dim_Position_FundCIDs (IsCopyFundPosition)
          |
          v (SP_Dim_Position_DL_To_Synapse -- DELETE + UPDATE + INSERT + multi-step ETL)
  DWH_dbo.Dim_Position  (134 cols, positions from 2007-08-27 to 2026-03-10)
          |
          v (Generic Pipeline -- Override, daily)
  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position
```

## Column Lineage (Key Columns)

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from staging. |
| **rename** | Same value, different column name. |
| **ETL-computed** | Derived by ETL SP logic. Not directly from a single source column. |

### Core Identity and Lifecycle

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| PositionID | etoro_Trade_OpenPositionEndOfDay / etoro_History_ClosePositionEndOfDay | PositionID | passthrough | Same in both sources |
| CID | etoro_Trade_OpenPositionEndOfDay / etoro_History_ClosePositionEndOfDay | CID | passthrough | |
| InstrumentID | etoro_Trade_OpenPositionEndOfDay / etoro_History_ClosePositionEndOfDay | InstrumentID | passthrough | |
| CurrencyID | etoro_Trade_OpenPositionEndOfDay / etoro_History_ClosePositionEndOfDay | CurrencyID | passthrough | |
| OpenOccurred | etoro_Trade_OpenPositionEndOfDay | Occurred | rename | Source col is `Occurred` for open positions |
| CloseOccurred | etoro_History_ClosePositionEndOfDay | CloseOccurred | passthrough | '1900-01-01' for open positions (ETL-set) |
| OpenDateID | -- | OpenOccurred | ETL-computed | CONVERT(int, CONVERT(varchar, DATEADD(DAY,DATEDIFF(DAY,0,OpenOccurred),0), 112)) |
| CloseDateID | -- | CloseOccurred | ETL-computed | Same YYYYMMDD conversion; 0 for open positions |
| IsBuy | etoro_Trade_OpenPositionEndOfDay / etoro_History_ClosePositionEndOfDay | IsBuy | passthrough | |
| Leverage | etoro_Trade_OpenPositionEndOfDay / etoro_History_ClosePositionEndOfDay | Leverage | passthrough | |
| Amount | etoro_Trade_OpenPositionEndOfDay / etoro_History_ClosePositionEndOfDay | Amount | passthrough | Can be corrected by PositionChangeLogAmount |
| AmountInUnitsDecimal | etoro_Trade_OpenPositionEndOfDay / etoro_History_ClosePositionEndOfDay | AmountInUnitsDecimal | passthrough | |
| NetProfit | etoro_Trade_OpenPositionEndOfDay / etoro_History_ClosePositionEndOfDay | NetProfit | passthrough | |
| InitForexRate | etoro_Trade_OpenPositionEndOfDay / etoro_History_ClosePositionEndOfDay | InitForexRate | passthrough | |
| EndForexRate | etoro_History_ClosePositionEndOfDay | EndForexRate | passthrough | NULL for open positions |
| Commission | etoro_Trade_OpenPositionEndOfDay / etoro_History_ClosePositionEndOfDay | Commission | passthrough | |
| CommissionOnClose | etoro_History_ClosePositionEndOfDay | CommissionOnClose | passthrough | 0 for open positions (ETL-set) |

### ETL-Computed Columns

| DWH Column | Transform | Derivation |
|-----------|-----------|------------|
| RegulationIDOnOpen | ETL-computed | ISNULL(c.RegulationID, 0) from JOIN etoro_History_BackOfficeCustomer ON CID + date range = @CurrentDate |
| Volume | ETL-computed | ROUND(AmountInUnitsDecimal * InitForexRate * USD_conversion, 0) -- approximates open USD value |
| VolumeOnClose | ETL-computed | ROUND(AmountInUnitsDecimal * EndForexRate * USD_conversion, 0) -- 0 for open positions |
| IsSettled | ETL-computed | CASE WHEN IsSettled IN (1,0) THEN IsSettled WHEN IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) THEN 1 ELSE 0 END |
| IsReOpen | ETL-computed | CASE WHEN ReopenForPositionID IS NOT NULL THEN 1 END (open) / CASE WHEN ReopenForPositionID IS NOT NULL THEN 1 ELSE 0 END (closed) |
| IsCopyFundPosition | ETL-computed | JOIN Dim_Position (TreeID=PositionID) -> Ext_Dim_Position_FundCIDs (CID has AccountTypeID=9) -- SET to 1 if match |
| IsAirDrop | ETL-computed | EXISTS JOIN etoro_Trade_PositionAirdropLog ON PositionID -- SET to 1 if found |
| InitHedgeType | ETL-computed | From SP_Dim_Position_HedgeType_Real based on InitExecutionID |
| EndHedgeType | ETL-computed | From SP_Dim_Position_HedgeType_History based on EndExecutionID |
| InitForex_Ask/Bid/AskSpreaded/BidSpreaded/USDConversionRate | ETL-computed | JOIN PriceLog_History_CurrencyPrice_Active ON PriceRateID = InitForexPriceRateID |
| EndForex_Ask/Bid/AskSpreaded/BidSpreaded/USDConversionRate | ETL-computed | JOIN PriceLog_History_CurrencyPrice_Active ON PriceRateID = EndForexPriceRateID |
| ClosePositionReasonID | rename | ActionType from etoro_History_ClosePositionEndOfDay |
| OpenPositionReasonID | rename | OpenActionType from etoro_Trade_OpenPositionEndOfDay |
| CommissionOnCloseOrig | ETL-computed | CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0 END |
| FullCommissionOnCloseOrig | ETL-computed | CASE WHEN ReopenForPositionID IS NOT NULL THEN FullCommissionOnClose ELSE 0 END |
| UpdateDate | ETL-computed | GETDATE() for INSERTs; GETUTCDATE() for UPDATEs of closing positions |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | ~90 |
| **Rename** | 2 (ClosePositionReasonID, OpenPositionReasonID) |
| **ETL-computed** | ~20 |
| **Corrections applied via staging** | ~6 (Amount, IsSettled, InitHedgeType, EndHedgeType, IsCopyFundPosition, IsAirDrop) |
| **Total DWH columns** | 134 |
