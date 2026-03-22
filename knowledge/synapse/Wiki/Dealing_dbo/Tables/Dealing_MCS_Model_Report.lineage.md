# Lineage Map — Dealing_dbo.Dealing_MCS_Model_Report

**Generated**: 2026-03-21
**Writer SP**: `Dealing_dbo.SP_MCS_Model_Report(@dd)`
**Pattern**: DELETE WHERE Date=@Date + INSERT (daily append/replace)

## ETL Chain

```
DWH_dbo.Dim_Position (Stocks/ETFs InstrumentTypeID IN 5,6; IsValidCustomer=1)
  + DWH_dbo.Dim_Instrument — instrument metadata
  + DWH_dbo.Dim_Customer — CID, CountryID (IsValidCustomer=1 filter)
  + DWH_dbo.Dim_Country — country name
        ├── #openapositions (opened today, not closed today)
        └── #closeapositions (closed today, may have opened today)
              UNION → #allpositions
                    └── Dealing_dbo.Dealing_MCS_Model_Report
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | @dd parameter | — | Report date |
| PositionID | DWH_dbo.Dim_Position | PositionID | Direct |
| CID | DWH_dbo.Dim_Position | CID | Direct |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | Direct |
| InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | Direct |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Direct |
| Name | DWH_dbo.Dim_Instrument | Name | Direct |
| Symbol | DWH_dbo.Dim_Instrument | Symbol | Direct |
| CountryID | DWH_dbo.Dim_Customer | CountryID | Direct |
| Country_Name | DWH_dbo.Dim_Country | Name | Direct |
| OpenDateID | DWH_dbo.Dim_Position | OpenDateID | Direct |
| CloseDateID | DWH_dbo.Dim_Position | CloseDateID | Direct (0 if open) |
| OpenOccurred | DWH_dbo.Dim_Position | OpenOccurred | Direct |
| CloseOccurred | DWH_dbo.Dim_Position | CloseOccurred | Direct |
| Leverage | DWH_dbo.Dim_Position | Leverage | Direct |
| IsSettled | DWH_dbo.Dim_Position | IsSettled | Direct |
| IsBuy | DWH_dbo.Dim_Position | IsBuy | Direct |
| Units | DWH_dbo.Dim_Position | AmountInUnitsDecimal | Direct |
| Commission | DWH_dbo.Dim_Position | FullCommission | Direct |
| Volume | DWH_dbo.Dim_Position | Volume | Direct |
| VolumeOnClose | DWH_dbo.Dim_Position | VolumeOnClose | Direct |
| Volume_Open_Position | Computed | — | Volume if OpenDateID=@Date, else 0 |
| Volume_Close_Position | Computed | — | VolumeOnClose if CloseDateID=@Date, else 0 |
| Total_daily_Volume | Computed | — | Open+Close volumes for the day |
| Click_Open_Position | Computed | — | 1 if opened today, else 0 |
| Click_Close_Position | Computed | — | 1 if closed today, else 0 |
| Total_daily_clicks | Computed | — | Sum of open/close click counts |
| UpdateDate | GETDATE() | — | ETL timestamp |

## Governance

- **Generic Pipeline mapping**: Not applicable — reads DWH_dbo dimension tables directly
- **Scope**: InstrumentTypeID IN (5,6) — Real Stocks and ETFs only; IsValidCustomer=1

## Lost / Added Columns

**Added by ETL**:
- `Volume_Open_Position`, `Volume_Close_Position`, `Total_daily_Volume` — derived volume decompositions
- `Click_Open_Position`, `Click_Close_Position`, `Total_daily_clicks` — click-event counters (1 per position event)
- `Country_Name` — denormalized from Dim_Country
- `InstrumentType`, `Name`, `Symbol` — denormalized from Dim_Instrument
