# Lineage Map — Dealing_dbo.Dealing_ESMANetLoss

## Object
- **Table**: `Dealing_dbo.Dealing_ESMANetLoss`
- **Schema**: Dealing_dbo
- **Type**: Table

## Production Source
| Attribute | Value |
|-----------|-------|
| Writer SP | `Dealing_dbo.SP_ESMANetLoss` |
| Primary Source | `DWH_dbo.Dim_Position` |
| Dimension Sources | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_MifidCategorization` |
| Price Source | `CopyFromLake.PriceLog_History_CurrencyPrice` |
| Generic Pipeline | Not applicable |

## ETL Flow
```
DWH_dbo.Dim_Position
    ↓ FILTER: NetProfit<0
             AND ABS(NetProfit)/Amount >= 0.95
             AND ClosePositionReasonID = 1
             AND EndForexPriceRateID = 0
             AND IsComputeForHedge = 1
             AND CloseOccurred BETWEEN @Date AND @Date+1
    ↓ JOIN DWH_dbo.Dim_Instrument (InstrumentType, Name)
    ↓ JOIN DWH_dbo.Dim_Regulation (Regulation name by CID)
    ↓ JOIN DWH_dbo.Dim_MifidCategorization (MifID by CID)
    ↓ JOIN CopyFromLake.PriceLog_History_CurrencyPrice
         ON InstrumentID + CloseOccurred → NoProtectionRate
    ↓ COMPUTE NoRestrictionNetProfit = f(NoProtectionRate, AmountInUnitsDecimal, LastOpConversionRate, IsBuy, InitForexRate)
    ↓ COMPUTE DeltaLoss = NoRestrictionNetProfit - NetProfit
→ Dealing_dbo.Dealing_ESMANetLoss (DELETE + INSERT for @Date)
```

## Column Lineage
| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | Dim_Position.CloseOccurred | CONVERT(DATE, CloseOccurred) |
| Regulation | Dim_Regulation | Lookup by CID → regulation name |
| MifID | Dim_MifidCategorization | Lookup by CID → Retail/Professional |
| PositionID | Dim_Position.PositionID | Passthrough; filter per criteria above |
| InstrumentType | Dim_Instrument.InstrumentType | Passthrough |
| InstrumentID | Dim_Position.InstrumentID | Passthrough |
| InstrumentName | Dim_Instrument.Name | Passthrough |
| IsBuy | Dim_Position.IsBuy | Passthrough |
| AmountInUnitsDecimal | Dim_Position.AmountInUnitsDecimal | Passthrough |
| CloseOccurred | Dim_Position.CloseOccurred | Passthrough |
| Amount | Dim_Position.Amount | Passthrough |
| NetProfit | Dim_Position.NetProfit | Passthrough (actual realized P&L with stop protection) |
| NoRestrictionNetProfit | Derived | Computed from NoProtectionRate × units × conversion — hypothetical without stop |
| InitForexRate | Dim_Position.InitForexRate | Passthrough |
| EndForexRate | Dim_Position.EndForexRate | Passthrough |
| StopRate | Dim_Position.StopRate | Passthrough |
| NoProtectionRate | PriceLog_History_CurrencyPrice | Market price at CloseOccurred ignoring stop-out |
| LastOpConversionRate | Dim_Position.LastOpConversionRate | Passthrough |
| DeltaLoss | Derived | NoRestrictionNetProfit − NetProfit |
| UpdateDate | ETL | GETDATE() at INSERT time |

## Notes
- Author: Jenia Simonovitch
- Filter criteria tightly scoped: only natural closes (ReasonID=1), hedged positions (IsComputeForHedge=1), with near-total loss (≥95%)
- NoProtectionRate is the counterfactual price from PriceLog at the close moment, enabling DeltaLoss calculation
