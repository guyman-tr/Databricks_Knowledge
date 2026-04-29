# Lineage: Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee

## Source Objects

| # | Source Object | Type | Relationship | Join/Filter |
|---|--------------|------|-------------|-------------|
| 1 | DWH_dbo.Dim_Position | Table | Position data for Islamic accounts | JOIN ON dp.CID = dc.RealCID; filtered by CloseDateID=0 or CloseOccurred >= EndTrade, OpenOccurred < EndTrade |
| 2 | DWH_dbo.Dim_Customer | Table | Customer attributes, Islamic account filter | JOIN ON dp.CID = dc.RealCID; WHERE IsValidCustomer=1 AND WeekendFeePrecentage=0 |
| 3 | DWH_dbo.Dim_Instrument | Table | Instrument metadata (type, exchange, name) | JOIN ON p.InstrumentID = i.InstrumentID |
| 4 | Dealing_dbo.Dealing_Islamic_Instruments_Groups | Table | Instrument-to-fee-group mapping | LEFT JOIN ON p.InstrumentID = g.instrument_id |
| 5 | Dealing_dbo.Dealing_Islamic_Units_Per_Contract | Table | Commodity contract size reference | LEFT JOIN ON p.InstrumentID = u.instrument_id |
| 6 | DWH_dbo.Dim_ExchangeInfo | Table | Exchange ID lookup | LEFT JOIN ON LOWER(i.Exchange) = LOWER(e.ExchangeDescription) |
| 7 | DWH_dbo.Fact_CurrencyPriceWithSplit | Table | EOD bid/ask prices and USD conversion rates | LEFT JOIN ON t.DateID = f.OccurredDateID AND t.InstrumentID = f.InstrumentID |
| 8 | Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group | Table | Fee rate schedule per group/asset class | LEFT JOIN ON (InstrumentGroup, InstrumentTypeID) = (instrument_group, instrument_type_id) |
| 9 | DWH_dbo.Dim_Date | Table | Calendar dimension for day-counting logic | Used via #Dates temp table for Count_Wed/Count_Thu/Count_Fri/Count_i/Count_All |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform |
|---|--------------|--------------|---------------|-----------|
| 1 | Date | SP_Islamic_Administrative_Fee | @Date parameter | Passthrough — the @Date input parameter |
| 2 | DateID | SP_Islamic_Administrative_Fee | @ReportDateID | ETL-computed: CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT) |
| 3 | PositionID | DWH_dbo.Dim_Position | PositionID | Passthrough |
| 4 | RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough |
| 5 | GCID | DWH_dbo.Dim_Customer | GCID | Passthrough |
| 6 | UserName | DWH_dbo.Dim_Customer | UserName | Passthrough |
| 7 | OpenDateID | DWH_dbo.Dim_Position | OpenDateID | Passthrough |
| 8 | CloseDateID | DWH_dbo.Dim_Position | CloseDateID | Passthrough |
| 9 | OpenOccurred | DWH_dbo.Dim_Position | OpenOccurred | Passthrough |
| 10 | NewOpenOccurred | SP_Islamic_Administrative_Fee | OpenOccurred | ETL-computed: if CONVERT(time, OpenOccurred) >= 22:00 then next day, else same date |
| 11 | CloseOccurred | DWH_dbo.Dim_Position | CloseOccurred | Passthrough |
| 12 | NewCloseOccurred | DWH_dbo.Dim_Position | CloseOccurred | Passthrough (aliased as NewCloseOccurred) |
| 13 | IsTheDayBefore | SP_Islamic_Administrative_Fee | OpenOccurred | ETL-computed: CASE WHEN CONVERT(time, OpenOccurred) >= 22:00 THEN 1 ELSE 0 END |
| 14 | InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | Passthrough |
| 15 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough |
| 16 | InstrumentID | DWH_dbo.Dim_Position | InstrumentID | Passthrough |
| 17 | InstrumentName | DWH_dbo.Dim_Instrument | Name | Passthrough (aliased from Name) |
| 18 | InstrumentType_ID_InstrumentGroup | Dealing_dbo.Dealing_Islamic_Instruments_Groups | instrument_type_id | Passthrough |
| 19 | InstrumentName_InstrumentGroup | Dealing_dbo.Dealing_Islamic_Instruments_Groups | name | Passthrough |
| 20 | InstrumentGroup | Dealing_dbo.Dealing_Islamic_Instruments_Groups | instrument_group | Passthrough |
| 21 | Units_per_Contract | Dealing_dbo.Dealing_Islamic_Units_Per_Contract | units_per_contract | Passthrough |
| 22 | Exchange | DWH_dbo.Dim_Instrument | Exchange | Passthrough |
| 23 | ExchangeID | DWH_dbo.Dim_ExchangeInfo | ExchangeID | Passthrough |
| 24 | IsBuy | DWH_dbo.Dim_Position | IsBuy | Passthrough |
| 25 | Leverage | DWH_dbo.Dim_Position | Leverage | Passthrough |
| 26 | IsSettled | DWH_dbo.Dim_Position | IsSettled | Passthrough |
| 27 | ClosedOnWeekend | SP_Islamic_Administrative_Fee | — | Hardcoded 0 (weekend rows excluded in current logic) |
| 28 | Bid | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | Passthrough |
| 29 | Ask | DWH_dbo.Fact_CurrencyPriceWithSplit | Ask | Passthrough |
| 30 | ConvertRateIsBuy_1 | DWH_dbo.Fact_CurrencyPriceWithSplit | ConvertRateIsBuy_1 | Passthrough |
| 31 | ConvertRateIsBuy_0 | DWH_dbo.Fact_CurrencyPriceWithSplit | ConvertRateIsBuy_0 | Passthrough |
| 32 | USD_Price | SP_Islamic_Administrative_Fee | Bid, Ask, ConvertRateIsBuy_1/0 | ETL-computed: CASE WHEN IsBuy=1 THEN Bid*ConvertRateIsBuy_1 ELSE Ask*ConvertRateIsBuy_0 END |
| 33 | AmountInUnitsDecimal | DWH_dbo.Dim_Position | AmountInUnitsDecimal | Passthrough |
| 34 | Admin_Fee_USD | Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group | admin_fee_usd | Passthrough |
| 35 | Days_Open | SP_Islamic_Administrative_Fee | Dim_Date + exchange logic | ETL-computed: SUM of weighted day counts between NewOpenOccurred and Date, varies by exchange type |
| 36 | GracePeriod | Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group | grace_period | Passthrough |
| 37 | Days_Admin_Fee | SP_Islamic_Administrative_Fee | Days_Open, grace_period | ETL-computed: Days_Open - grace_period |
| 38 | Days_To_Charge | SP_Islamic_Administrative_Fee | Days_Admin_Fee, exchange rules | ETL-computed: CASE logic based on day of week, exchange type, and days past grace period (0-3) |
| 39 | Final_Fee | SP_Islamic_Administrative_Fee | AmountInUnitsDecimal, USD_Price, Admin_Fee_USD, Days_To_Charge, InstrumentTypeID, Units_per_Contract | ETL-computed: asset-class-specific formula × Days_To_Charge × (-1). See Section 2.1. |
| 40 | Fee_Type_ID | SP_Islamic_Administrative_Fee | — | Hardcoded 1 |
| 41 | UpdateDate | SP_Islamic_Administrative_Fee | — | ETL-computed: GETDATE() |
| 42 | CountryID | DWH_dbo.Dim_Customer | CountryID | Passthrough |
