---
object: Dealing_dbo.Dealing_DailySpread_ModeFrequency
lineage_type: dwh_computed_analytics
documented: 2026-03-21
---

# Lineage: Dealing_DailySpread_ModeFrequency

## ETL Chain

```
DWH_dbo.Dim_Position (InitForex, EndForex — open/close prices)
DWH_dbo.Dim_Instrument (InstrumentName, InstrumentType)
  → SP_DailySpread_ModeFrequency (@Date)
    Compute PP spread: |InitForex − EndForex| per position
    Compute eToro spread: eToro bid-ask markup
    Compute mode and mode frequency for each spread type
    GROUP BY Instrument × SpreadType (Open/Close)
    → Dealing_dbo.Dealing_DailySpread_ModeFrequency
```

## Generic Pipeline Mapping

No entry — DWH-computed analytics.

## Column Lineage

| Column | Source |
|--------|--------|
| Date | SP parameter @Date |
| InstrumentID | DWH_dbo.Dim_Position |
| InstrumentName | DWH_dbo.Dim_Instrument |
| InstrumentType | DWH_dbo.Dim_Instrument |
| DailyAvg_PPSpread | AVG(|InitForex − EndForex|) across positions |
| DailyAvg_EtoroSpread | AVG(eToro bid-ask spread) from DWH_dbo.Dim_Position |
| NumberofTradesDaily | COUNT(*) positions on this date |
| Daily_EtoroSpread_Mode | MODE(eToro spread values) |
| Daily_EtoroSpread_ModeFrequency | Frequency count of the modal eToro spread |
| DailyPPSpread_DividedByEtoroSpread | DailyAvg_PPSpread / DailyAvg_EtoroSpread |
| UpdateDate | GETDATE() at SP execution time |
| SpreadType | 'Open' or 'Close' — SP logic |
| ModePPSpread | MODE(PP spread values) |

## Refresh

- **OpsDB tracked**: ✅ Yes — Priority 0, SB_Daily
- **Pipeline status**: ✅ ACTIVE (2026-03-10)
