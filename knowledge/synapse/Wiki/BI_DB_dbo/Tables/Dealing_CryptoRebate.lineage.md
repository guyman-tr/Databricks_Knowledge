# Lineage: BI_DB_dbo.Dealing_CryptoRebate

**Writer SP**: `BI_DB_dbo.SP_M_CryptoRebateDiamond`
**OpsDB Priority**: P20
**Refresh**: Monthly (runs per @Date parameter)
**UC Target**: _Not_Migrated

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|---------------|---------------|-----------|
| 1 | MonthEndDate | ETL parameter | @Date | `EOMONTH(DATEADD(month, DATEDIFF(month, 0, @Date), 0))` — last day of the input month |
| 2 | Club | DWH_dbo.Fact_SnapshotCustomer / Dim_PlayerLevel | PlayerLevelID | `CASE WHEN PlayerLevelID=7 THEN '1 Diamond' WHEN PlayerLevelID=6 THEN '1 Platinum Plus' ELSE 'Error'` |
| 3 | CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | passthrough |
| 4 | GuruStatus_ID | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | passthrough |
| 5 | Country | DWH_dbo.Dim_Country | Name | via `Fact_SnapshotCustomer.CountryID → Dim_Country.CountryID → Dim_Country.Name` |
| 6 | Region | DWH_dbo.Fact_SnapshotCustomer | Region | passthrough |
| 7 | Regulation | DWH_dbo.Dim_Regulation | Name | via `Fact_SnapshotCustomer.RegulationID → Dim_Regulation.DWHRegulationID → Dim_Regulation.Name` |
| 8 | OpenedVolume | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate, InitForex_USDConversionRate | `SUM(AmountInUnitsDecimal × ISNULL(InitForexRate,1) × ISNULL(InitForex_USDConversionRate,1))` — crypto positions closed this month, valued at open rate |
| 9 | ClosedVolume | DWH_dbo.Dim_Position | AmountInUnitsDecimal, EndForexRate, LastOpConversionRate | `SUM(AmountInUnitsDecimal × ISNULL(EndForexRate,1) × ISNULL(LastOpConversionRate,1))` — same positions, valued at close rate |
| 10 | TotalVolume | ETL-computed | OpenedVolume, ClosedVolume | `ISNULL(OpenedVolumeSum, 0) + ISNULL(ClosedVolumeSum, 0)` |
| 11 | Markup | ETL-computed | TotalVolume | `TotalVolume × 0.01` — 1% spread proxy |
| 12 | Bracket1_Volume | ETL-computed | TotalVolume | `CASE WHEN TotalVolume>50000 AND ≤1M THEN TotalVolume−50000; WHEN >1M THEN 950000; ELSE 0` |
| 13 | Bracket2_Volume | ETL-computed | TotalVolume | `CASE WHEN TotalVolume>1M AND ≤5M THEN TotalVolume−1M; WHEN >5M THEN 4000000; ELSE 0` |
| 14 | Bracket3_Volume | ETL-computed | TotalVolume | `CASE WHEN TotalVolume>5M THEN TotalVolume−5M; ELSE 0` |
| 15 | Bracket1_Rebate | ETL-computed | Bracket1_Volume | `Bracket1_Volume × 0.15 / 100` |
| 16 | Bracket2_Rebate | ETL-computed | Bracket2_Volume | `Bracket2_Volume × 0.25 / 100` |
| 17 | Bracket3_Rebate | ETL-computed | Bracket3_Volume | `Bracket3_Volume × 0.50 / 100` |
| 18 | TotalRebate | ETL-computed | Bracket1_Rebate + Bracket2_Rebate + Bracket3_Rebate | `CASE WHEN sum < 5 THEN 0 ELSE sum` — $5 minimum threshold |
| 19 | UPdatedate | ETL-computed | — | `GETDATE()` on insert |

---

## Upstream Sources

| Source Object | Schema | Role |
|---------------|--------|------|
| Fact_SnapshotCustomer | DWH_dbo | Club membership identification (SCD2, time-bounded via Dim_Range) |
| Dim_Range | DWH_dbo | Time-bounded snapshot lookup (FromDateID / ToDateID) |
| Dim_PlayerLevel | DWH_dbo | PlayerLevelID → Club name (6=Platinum Plus, 7=Diamond) |
| Dim_Country | DWH_dbo | CountryID → Country name |
| Dim_Regulation | DWH_dbo | DWHRegulationID → Regulation name |
| Dim_Position | DWH_dbo | Crypto position volumes (settled, closed in month) |
| Dim_Instrument | DWH_dbo | InstrumentTypeID=10 filter (crypto instruments) |
| V_GermanBaFin | BI_DB_dbo | German BaFin customer flag (used in companion unrealized table) |

## Downstream Consumers

| Object | Schema | Relationship |
|--------|--------|-------------|
| Dealing_Unrealized_CryptoRebate | BI_DB_dbo | Companion table — same SP, unrealized positions |
