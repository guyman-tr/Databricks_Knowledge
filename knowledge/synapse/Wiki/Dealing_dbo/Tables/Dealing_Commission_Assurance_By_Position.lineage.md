# Lineage Map — Dealing_dbo.Dealing_Commission_Assurance_By_Position

## Object
- **Table**: `Dealing_dbo.Dealing_Commission_Assurance_By_Position`
- **Schema**: Dealing_dbo
- **Type**: Table

## Production Source
| Attribute | Value |
|-----------|-------|
| Writer SP | `Dealing_dbo.SP_Rev_Assurance` |
| Primary Source | `DWH_dbo.Dim_Position` |
| Staging Sources | `DWH_staging.etoro_Trade_ProviderToInstrument`, `Dealing_staging.External_Etoro_Trade_InstrumentSpread` |
| Dimension Sources | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Customer` |
| Generic Pipeline | Not applicable |

## ETL Flow
```
DWH_dbo.Dim_Position (OpenDateID = @DateID)
    ↓ JOIN DWH_staging.etoro_Trade_ProviderToInstrument (Precision per instrument)
    ↓ JOIN Dealing_staging.External_Etoro_Trade_InstrumentSpread (live bid/ask, SpreadTypeID=1)
    ↓ JOIN DWH_dbo.Dim_Instrument (InstrumentType, Name; SellCurrencyID=1 filter)
    ↓ JOIN DWH_dbo.Dim_Customer (PlayerLevelID <> 4 filter)
    ↓ COMPUTE RealComm = AmountInUnitsDecimal × (Ask-Bid) / 10^Precision
    ↓ FILTER: |Commission - RealComm| > 0.0051
→ Dealing_dbo.Dealing_Commission_Assurance_By_Position (DELETE + INSERT for @Date)
```

## Column Lineage
| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | SP parameter | @date | CAST to date |
| PositionID | DWH_dbo.Dim_Position | PositionID | Passthrough |
| MirrorID | DWH_dbo.Dim_Position | MirrorID | Passthrough |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | Passthrough |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Passthrough |
| AmountInUnitsDecimal | DWH_dbo.Dim_Position | AmountInUnitsDecimal | Passthrough |
| Spread | Dealing_staging.External_Etoro_Trade_InstrumentSpread | (Ask-Bid)/10^Precision | Computed from live spread |
| Commission | DWH_dbo.Dim_Position | Commission | Passthrough (actual charged) |
| RealComm | Computed | AmountInUnitsDecimal × Spread | Calculated expected commission |
| diff | Computed | Commission - RealComm | Commission discrepancy |
| UpdateDate | ETL | GETDATE() | ETL metadata |

## Notes
- Only USD-denominated instruments (SellCurrencyID=1 in Dim_Instrument join)
- Spread from real-time External_Etoro_Trade_InstrumentSpread, not historical at open time
- Threshold filter |diff| > 0.0051 removes micro-rounding noise
