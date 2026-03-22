# Lineage: Dealing_dbo.Dealing_CryptoVolume_ByDirection

## Source Tables
| Source | Role |
|--------|------|
| DWH_dbo.Dim_Position | Crypto positions (InstrumentID, IsBuy, Volume, AmountInUnitsDecimal, OpenDateID, CloseDateID, Leverage, IsSettled) |
| DWH_dbo.Dim_Customer | IsValidCustomer=1 filter |
| DWH_dbo.Dim_Instrument | InstrumentTypeID=10 (crypto) filter, instrument name |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| DateID | Generated | @DateID parameter |
| FullDate | Derived | `CONVERT(DATETIME, @Date)` |
| Leverage | Dim_Position.Leverage | Direct |
| IsSettled | Dim_Position.IsSettled | Direct |
| InstrumentID | Dim_Instrument.InstrumentID | InstrumentTypeID=10 filter |
| Instrument | Dim_Instrument.InstrumentName | Crypto instrument display name |
| IsBuy | Derived | Opens: IsBuy direct; Closes: `CASE WHEN IsBuy=1 THEN 0 ELSE 1 END` (inverted — close of a buy is a sell) |
| Volume | Dim_Position.Volume / VolumeOnClose | `SUM(Volume)` for opens, `SUM(VolumeOnClose)` for closes on @Date |
| Units | Dim_Position.AmountInUnitsDecimal | `SUM(AmountInUnitsDecimal)` in decimal(17,6) |
| UpDate_Date | Generated | `GETDATE()` |

## Generic Pipeline
| Property | Value |
|----------|-------|
| Datalake Path | Gold/sql_dp_prod_we/Dealing_dbo/Dealing_CryptoVolume_ByDirection/ |
