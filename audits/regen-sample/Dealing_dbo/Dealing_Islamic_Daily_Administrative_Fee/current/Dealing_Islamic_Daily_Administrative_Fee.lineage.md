# Lineage Map — Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee

## Object
- **Table**: `Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee`
- **Schema**: Dealing_dbo
- **Type**: Table

## Production Source
| Attribute | Value |
|-----------|-------|
| Writer SP | `Dealing_dbo.SP_Islamic_Administrative_Fee` |
| Primary Source | `DWH_dbo.Dim_Position` |
| Customer Filter | `DWH_dbo.Dim_Customer` (WeekendFeePrecentage=0, IsValidCustomer=1) |
| Price Source | `DWH_dbo.Fact_CurrencyPriceWithSplit` |
| Fee Config | `Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group` |
| Instrument Groups | `Dealing_dbo.Dealing_Islamic_Instruments_Groups` |
| Contract Sizes | `Dealing_dbo.Dealing_Islamic_Units_Per_Contract` |
| Generic Pipeline | Not applicable |

## ETL Flow
```
DWH_dbo.Dim_Position (positions open at 22:00 UTC on @Date)
    ↓ JOIN DWH_dbo.Dim_Customer (WeekendFeePrecentage=0, IsValidCustomer=1)
    ↓ JOIN DWH_dbo.Dim_Instrument (InstrumentTypeID, Exchange)
    ↓ JOIN DWH_dbo.Dim_ExchangeInfo (ExchangeID on Exchange name)
    ↓ JOIN Dealing_dbo.Dealing_Islamic_Instruments_Groups (manual groupings)
    ↓ JOIN Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group (Admin_Fee_USD, GracePeriod)
    ↓ JOIN Dealing_dbo.Dealing_Islamic_Units_Per_Contract (Commodities only)
    ↓ JOIN DWH_dbo.Fact_CurrencyPriceWithSplit (EOD Bid/Ask + ConvertRate)
    ↓ JOIN DWH_dbo.Dim_Date (day-of-week counts: Count_Wed, Count_Thu, Count_Fri, Count_i, Count_All)
    ↓ COMPUTE NewOpenOccurred = OpenOccurred + 1 day if opened after 22:00 UTC
    ↓ COMPUTE IsTheDayBefore = 1 if OpenOccurred time ≥ 22:00 UTC
    ↓ COMPUTE Days_Open = SUM(day counts from NewOpenOccurred to Date by exchange rule)
    ↓ COMPUTE Days_Admin_Fee = Days_Open - GracePeriod
    ↓ COMPUTE Days_To_Charge = 0/1/2/3 based on day-of-week and instrument rule
    ↓ COMPUTE USD_Price = Bid×ConvertRateIsBuy_1 (IsBuy=1) or Ask×ConvertRateIsBuy_0 (IsBuy=0)
    ↓ COMPUTE Final_Fee = instrument-type-specific formula × Days_To_Charge × -1
    ↓ FILTER: ClosedOnWeekend = 0, exclude 25 suspended InstrumentIDs
→ Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee (DELETE + INSERT for @Date)
```

## Column Lineage
| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | SP parameter | @Date passthrough |
| DateID | SP parameter | CAST(@Date AS INT) |
| PositionID | Dim_Position.PositionID | Passthrough |
| RealCID | Dim_Customer.RealCID | Passthrough |
| GCID | Dim_Customer.GCID | Passthrough |
| UserName | Dim_Customer.UserName | Passthrough |
| CountryID | Dim_Customer.CountryID | Passthrough; used for German Crypto exclusion |
| OpenDateID | Dim_Position.OpenDateID | Passthrough |
| OpenOccurred | Dim_Position.OpenOccurred | Passthrough |
| NewOpenOccurred | Derived | OpenOccurred + 1 day if time ≥ 22:00 UTC |
| IsTheDayBefore | Derived | 1 if OpenOccurred time ≥ 22:00 UTC, else 0 |
| CloseDateID | Dim_Position.CloseDateID | Passthrough; 0 if open |
| CloseOccurred | Dim_Position.CloseOccurred | Passthrough |
| InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Passthrough |
| InstrumentID | Dim_Position.InstrumentID | Passthrough |
| InstrumentGroup | Dealing_Islamic_Instruments_Groups.instrument_group | Manual config lookup |
| Units_per_Contract | Dealing_Islamic_Units_Per_Contract.units_per_contract | Manual config lookup; Commodities only |
| ExchangeID | Dim_ExchangeInfo.ExchangeID | JOIN on Dim_Instrument.Exchange name |
| IsBuy | Dim_Position.IsBuy | Passthrough |
| Leverage | Dim_Position.Leverage | Passthrough |
| USD_Price | Fact_CurrencyPriceWithSplit | Bid×ConvertRateIsBuy_1 (IsBuy=1) or Ask×ConvertRateIsBuy_0 |
| AmountInUnitsDecimal | Dim_Position.AmountInUnitsDecimal | Passthrough |
| Admin_Fee_USD | Dealing_Islamic_Admin_Fee_Per_Group.admin_fee_usd | Manual config lookup |
| Days_Open | Dim_Date | SUM of day-type flags (Count_Wed/Thu/Fri/i/All) from NewOpenOccurred to Date |
| GracePeriod | Dealing_Islamic_Admin_Fee_Per_Group.grace_period | Manual config lookup |
| Days_Admin_Fee | Derived | Days_Open − GracePeriod |
| Days_To_Charge | Derived | 0/1/2/3 based on day-of-week + instrument triple-day rule |
| Final_Fee | Derived | Instrument-type-specific formula × Days_To_Charge × -1 |
| Fee_Type_ID | Hardcoded | Always 1 |
| UpdateDate | ETL | GETDATE() at INSERT time |

## Notes
- Author: Gili Goldbaum (2024-02-21). Last SR: SR-343388 (2025-11-17)
- Companion table `Dealing_Islamic_Daily_Spot_Price_Adjustment` (Fee_Type_ID=2) written by a separate SP
- 25 suspended instruments excluded via hardcoded blacklist in SP (SR-258928, 2024-06-26)
- German Crypto exclusion: CountryID=79, Leverage=1, IsBuy=1 positions excluded
