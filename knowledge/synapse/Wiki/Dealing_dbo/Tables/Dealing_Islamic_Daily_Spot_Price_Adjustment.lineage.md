# Lineage Map — Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment

## Object
- **Table**: `Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment`
- **Schema**: Dealing_dbo
- **Type**: Table

## Production Source
| Attribute | Value |
|-----------|-------|
| Writer SP | `Dealing_dbo.SP_Islamic_Spot_Price_Adjustment` |
| Primary Source | `DWH_dbo.Dim_Position` |
| Customer Filter | `DWH_dbo.Dim_Customer` (WeekendFeePrecentage=0, IsValidCustomer=1) |
| Futures Prices | `Dealing_staging.External_Fivetran_dealing_overnight_fees` |
| Alert Output | `Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment_Email` (when Fivetran data missing) |
| Generic Pipeline | Not applicable |

## ETL Flow
```
DWH_dbo.Dim_Position (open at 22:00 UTC on @Date, InstrumentID IN (17,22,339,340,341,343,344))
    ↓ JOIN DWH_dbo.Dim_Customer (WeekendFeePrecentage=0, IsValidCustomer=1)
    ↓ JOIN DWH_dbo.Dim_Instrument (InstrumentTypeID, InstrumentType, InstrumentName, Exchange)
    ↓ JOIN DWH_dbo.Dim_Date (day-of-week, Count_Fri rule for Days_Open)
    ↓ JOIN Dealing_staging.External_Fivetran_dealing_overnight_fees
         (latest update per date, Rank=1; Front=Row1, Next=Row2 per future_short_cut)
    ↓ COMPUTE NewOpenOccurred = OpenOccurred + 1 day if time ≥ 22:00 UTC
    ↓ COMPUTE Days_Open = SUM(Count_Fri) from NewOpenOccurred to @Date
    ↓ COMPUTE Days_To_Charge = 3 (Friday), 1 (Mon–Thu)
    ↓ COMPUTE Final_Fee = (IsBuy=1 ? -1 : +1) × ((Next-Front)/Days_Between_Expiration) × Units × Days_To_Charge
    ↓ IF @Date is Sunday: use Friday's date instead; SP skips on Sat/Sun
    ↓ IF Fivetran data missing on non-weekend/non-Friday: INSERT alert into Email table, skip main insert
→ Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment (DELETE + INSERT for @Date)
```

## Column Lineage
| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | SP parameter | @Date (Sunday → Friday substitution) |
| DateID | SP parameter | CAST(@Date AS INT) |
| PositionID | Dim_Position.PositionID | Passthrough |
| RealCID | Dim_Customer.RealCID | Passthrough |
| GCID | Dim_Customer.GCID | Passthrough |
| UserName | Dim_Customer.UserName | Passthrough |
| OpenDateID | Dim_Position.OpenDateID | Passthrough |
| OpenOccurred | Dim_Position.OpenOccurred | Passthrough |
| NewOpenOccurred | Derived | OpenOccurred + 1 day if time ≥ 22:00 UTC |
| IsTheDayBefore | Derived | 1 if OpenOccurred time ≥ 22:00 UTC |
| CloseDateID | Dim_Position.CloseDateID | Passthrough |
| CloseOccurred | Dim_Position.CloseOccurred | Passthrough |
| InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Passthrough |
| InstrumentType | Dim_Instrument.InstrumentType | Passthrough |
| InstrumentID | Dim_Position.InstrumentID | Passthrough; one of 17,22,339,340,341,343,344 |
| InstrumentName | Dim_Instrument.Name | Passthrough |
| Exchange | Dim_Instrument.Exchange | Passthrough |
| ExchangeID | Hardcoded | Always 0 — Dim_ExchangeInfo not joined |
| IsBuy | Dim_Position.IsBuy | Passthrough |
| Leverage | Dim_Position.Leverage | Passthrough |
| IsSettled | Dim_Position.IsSettled | Passthrough |
| AmountInUnitsDecimal | Dim_Position.AmountInUnitsDecimal | Passthrough |
| Days_Open | Dim_Date | SUM(Count_Fri) from NewOpenOccurred to @Date |
| Days_To_Charge | Derived | Fri=3, Mon–Thu=1 |
| Front | External_Fivetran_dealing_overnight_fees.close | ROW_NUMBER()=1 per future_short_cut (front contract) |
| Next | External_Fivetran_dealing_overnight_fees.close | ROW_NUMBER()=2 per future_short_cut (next contract) |
| Days_Between_Expiration | External_Fivetran_dealing_overnight_fees.days | Front contract days to expiry |
| Final_Fee | Derived | (IsBuy=1 ? -1 : +1) × ((Next-Front)/Days_Between_Expiration) × AmountInUnitsDecimal × Days_To_Charge |
| Fee_Type_ID | Hardcoded | Always 2 |
| UpdateDate | ETL | GETDATE() at INSERT time |

## Notes
- Author: Gili Goldbaum (2024-03-07)
- Active since 2024-03-08 (no historical backfill)
- All 7 futures instruments use Count_Fri rule (ExchangeID irrelevant)
- SP also writes alert to `Dealing_Islamic_Daily_Spot_Price_Adjustment_Email` when Fivetran data is missing
- Companion to `Dealing_Islamic_Daily_Administrative_Fee` (Fee_Type_ID=1) — written by a separate SP
