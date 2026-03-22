# Lineage Map — Dealing_dbo.Dealing_Unrealized_Open_CryptoRebate

**Generated**: 2026-03-21
**Writer SP**: `Dealing_dbo.SP_M_CryptoRebateOpenUnrealized(@Date)` (migrated from Databricks Mar 2024 SR-242245)
**Pattern**: DELETE WHERE MonthEndDate=EOMONTH(@Date) + INSERT (monthly, run on last day)

## ETL Chain

```
DWH_dbo.Fact_SnapshotCustomer (PlayerLevelID=7=Diamond, IsValidCustomer=1)
  + DWH_dbo.Dim_Range — temporal range join for snapshot validity
  + DWH_dbo.Dim_Country — country name
  + DWH_dbo.Dim_Regulation — regulation name (excludes FCA)
  + BI_DB_dbo.V_GermanBaFin — IsGermanBaFin flag
  → #club_members (Diamond, not FCA, not excluded countries)

BI_DB_dbo.BI_DB_PositionPnL (crypto InstrumentTypeID=10, open positions Leverage=1, IsBuy=1)
  JOIN #club_members + DWH_dbo.Dim_Instrument + Dim_Position
  WHERE dp.CloseDateID=0 (still open) AND OpenDateID>=20220308 (rebate program start)
  → #UnrealizedOpen

DWH_dbo.Fact_CurrencyPriceWithSplit (month-end prices)
  → #UnrealizedVolumeOpen (open at InitForexRate)
  → #UnrealizedVolumeClose (mark-to-market at month-end BidSpreaded)

→ Bracket tiering (0→skip, $100K-$1M=0.15%, $1M-$5M=0.25%, >$5M=0.5%)
→ TotalRebate < $5 → set to 0
        └── Dealing_dbo.Dealing_Unrealized_Open_CryptoRebate
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| MonthEndDate | EOMONTH(@MonthStartDate) | — | Last day of month |
| Club | DWH_dbo.Dim_PlayerLevel | Name | PlayerLevelID=7 → '1 Diamond' |
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Direct |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Direct |
| IsGermanBaFin | BI_DB_dbo.V_GermanBaFin | CID (presence) | 1 if present, else 0 |
| GuruStatus_ID | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | Direct |
| Country | DWH_dbo.Dim_Country | Name | Direct |
| Region | DWH_dbo.Fact_SnapshotCustomer | Region | Direct |
| Regulation | DWH_dbo.Dim_Regulation | Name | Direct |
| OpenedVolume | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal × InitForexRate × InitForex_USDConversionRate | SUM |
| ClosedVolume | DWH_dbo.Fact_CurrencyPriceWithSplit | BidSpreaded × ConvertRateIsBuy_1 | Mark-to-market value |
| TotalVolume | Computed | OpenedVolume + ClosedVolume | Sum |
| Markup | Computed | TotalVolume × 0.01 | 1% of total volume |
| Bracket1_Volume | Computed | — | Volume tier $100K–$1M cap |
| Bracket2_Volume | Computed | — | Volume tier $1M–$5M cap |
| Bracket3_Volume | Computed | — | Volume above $5M |
| Bracket1_Rebate | Computed | Bracket1_Volume × 0.0015 | 0.15% |
| Bracket2_Rebate | Computed | Bracket2_Volume × 0.0025 | 0.25% |
| Bracket3_Rebate | Computed | Bracket3_Volume × 0.005 | 0.50% |
| TotalRebate | Computed | SUM(Bracket1+2+3) if ≥$5 else 0 | Minimum $5 threshold |
| UPdatedate | GETDATE() | — | ETL timestamp (note: column name typo — capital P) |

## Governance

- **Scope**: Diamond (PlayerLevelID=7), crypto InstrumentTypeID=10, Leverage=1 (spot), IsBuy=1, MirrorID=0 (no copy)
- **Rebate start date**: OpenDateID >= 20220308 hardcoded — positions opened before March 8, 2022 excluded
- **Country exclusions**: Austria, France, Finland, Greece, Luxembourg, Malta, Portugal, Sweden, United Kingdom
- **OpsDB**: Priority 0, Monthly, SB_Daily (monthly execution tracked)
