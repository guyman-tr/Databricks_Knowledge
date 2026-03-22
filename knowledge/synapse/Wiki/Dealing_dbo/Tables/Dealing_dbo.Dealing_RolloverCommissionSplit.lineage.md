# Lineage: Dealing_dbo.Dealing_RolloverCommissionSplit

## Source Tables
| Source | Role |
|--------|------|
| CopyFromLake.etoro_History_Credit | Rollover transactions (CreditTypeID=14, TotalCashChange) |
| DWH_dbo.Dim_Position | Position metadata (InstrumentID, IsBuy, CID, HedgeServerID) |
| DWH_dbo.Dim_Customer | IsValidCustomer=1, WeekendFeePrecentage (Islamic flag) |
| CopyFromLake.etoro_Trade_InstrumentToFeeConfig | NonLeveragedBuy/SellOverNightFee rates |
| CopyFromLake.etoro_History_InstrumentToFeeConfig | Historical fee config (UNION with current) |
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | Hourly candle prices (AskLast, BidLast) |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Amount | History_Credit.TotalCashChange | `ISNULL(TotalCashChange, 0)` |
| Units | Derived | `Amount / NonLeveraged{Buy\|Sell}OverNightFee` |
| eToroCommissionAsk | Candle.AskLast | `AskLast * 0.05 / 365` |
| PureROSellRate | Derived | `NonLeveragedSellOverNightFee - eToroCommissionAsk` |
| PureROBuy | Derived | `PureROBuyRate * Units` (IsBuy=1 only) |
| PureEtoroFeeBuy | Derived | `eToroCommissionAsk * Units` (IsBuy=1 only) |
| IsIslamic | Dim_Customer.WeekendFeePrecentage | `CASE WHEN =0 THEN 'Islamic' ELSE 'Not Islamic' END` |

## No Generic Pipeline Mapping
This table is not in the generic pipeline mapping.
