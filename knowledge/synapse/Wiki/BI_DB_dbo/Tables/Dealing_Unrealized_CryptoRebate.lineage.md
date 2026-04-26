# Lineage: BI_DB_dbo.Dealing_Unrealized_CryptoRebate

**Writer SP**: `BI_DB_dbo.SP_M_CryptoRebateDiamond`
**Refresh**: Monthly (OpsDB Priority 20). Same SP that writes `Dealing_CryptoRebate` (realized) — unrealized section runs second in same execution.
**Load Pattern**: DELETE WHERE MonthEndDate = @MonthEndDate + INSERT (monthly full-refresh per month)
**UC Target**: _Not_Migrated

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | MonthEndDate | ETL parameter | @Date | `EOMONTH(DATEADD(month, DATEDIFF(month,0,@Date),0))` — last day of the parameter month | Tier 2 |
| 2 | Club | DWH_dbo.Fact_SnapshotCustomer + Dim_PlayerLevel | PlayerLevelID | `CASE 7→'1 Diamond', 6→'1 Platinum Plus'` at @MonthEndDate via Dim_Range SCD2 | Tier 2 |
| 3 | CID | Customer.CustomerStatic (via Fact_SnapshotCustomer.RealCID) | CID | Passthrough; RealCID in FSC maps to CID in source | Tier 1 |
| 4 | IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough; customer credit report validity flag | Tier 2 |
| 5 | IsGermanBaFin | BI_DB_dbo.V_GermanBaFin | CID | `CASE WHEN vbf.CID IS NOT NULL THEN 1 ELSE 0` — 1 if customer has German BaFin-regulated status at @MonthEndDateID | Tier 2 |
| 6 | GuruStatus_ID | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | Passthrough. Only customers with GuruStatusID NOT IN (2,3,4,5,6) included — active PIs excluded. In practice always 0 in stored data (non-PI club members). FK to Dim_GuruStatus. | Tier 2 |
| 7 | Country | DWH_dbo.Dim_Country | Name | Via Fact_SnapshotCustomer.CountryID → Dim_Country.CountryID; country name string | Tier 2 |
| 8 | Region | DWH_dbo.Fact_SnapshotCustomer | Region | Passthrough; geographic region grouping | Tier 2 |
| 9 | Regulation | DWH_dbo.Dim_Regulation | Name | Via Fact_SnapshotCustomer.RegulationID → Dim_Regulation.DWHRegulationID; regulation name string | Tier 2 |
| 10 | OpenedVolume | BI_DB_PositionPnL + DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate, InitForex_USDConversionRate | `SUM(AmountInUnitsDecimal × ISNULL(InitForexRate,1) × ISNULL(InitForex_USDConversionRate,1))` — open positions (IsSettled=1, IsBuy=1, Leverage=1, MirrorID=0, InstrumentTypeID=10) still active at @MonthEndDateID, valued at open-side rate | Tier 2 |
| 11 | ClosedVolume | DWH_dbo.Fact_CurrencyPriceWithSplit | BidSpreaded, ConvertRateIsBuy_1 | `SUM(AmountInUnitsDecimal × ISNULL(BidSpreaded,1) × ISNULL(ConvertRateIsBuy_1,1))` at OccurredDateID=@MonthEndDateID — mark-to-market close-side valuation using EOM prices | Tier 2 |
| 12 | TotalVolume | ETL-computed | OpenedVolume + ClosedVolume | Arithmetic sum. Represents total turnover exposure (double-counts each position: open + EOM close sides). Input to bracket calculation. | Tier 2 |
| 13 | Markup | ETL-computed | TotalVolume | `TotalVolume × 0.01` — 1% spread proxy; informational only, not used in rebate math | Tier 2 |
| 14 | Bracket1_Volume | ETL-computed | TotalVolume | `CASE WHEN TotalVolume BETWEEN 50K AND 1M THEN TotalVolume-50K; WHEN >1M THEN 950,000; ELSE 0` | Tier 2 |
| 15 | Bracket2_Volume | ETL-computed | TotalVolume | `CASE WHEN TotalVolume BETWEEN 1M AND 5M THEN TotalVolume-1M; WHEN >5M THEN 4,000,000; ELSE 0` | Tier 2 |
| 16 | Bracket3_Volume | ETL-computed | TotalVolume | `CASE WHEN TotalVolume > 5M THEN TotalVolume-5M; ELSE 0` — uncapped top tier | Tier 2 |
| 17 | Bracket1_Rebate | ETL-computed | Bracket1_Volume | `Bracket1_Volume × 0.15 / 100` — 0.15% rate | Tier 2 |
| 18 | Bracket2_Rebate | ETL-computed | Bracket2_Volume | `Bracket2_Volume × 0.25 / 100` — 0.25% rate | Tier 2 |
| 19 | Bracket3_Rebate | ETL-computed | Bracket3_Volume | `Bracket3_Volume × 0.50 / 100` — 0.50% rate (highest) | Tier 2 |
| 20 | TotalRebate | ETL-computed | Bracket1_Rebate + Bracket2_Rebate + Bracket3_Rebate | `CASE WHEN sum < 5 THEN 0 ELSE sum` — $5 minimum threshold applied | Tier 2 |
| 21 | UPdatedate | ETL-computed | — | `GETDATE()` on insert | Propagation |

## Tier Summary

| Tier | Count | Description |
|------|-------|-------------|
| Tier 1 | 1 | CID from Customer.CustomerStatic |
| Tier 2 | 19 | ETL-computed or SP-join-derived (Fact_SnapshotCustomer, Dim_Position, Fact_CurrencyPriceWithSplit, V_GermanBaFin, bracket math) |
| Propagation | 1 | UPdatedate (ETL timestamp) |

## Source Objects

- `DWH_dbo.Fact_SnapshotCustomer` — club membership, IsCreditReportValidCB, GuruStatusID, CountryID, RegulationID, Region
- `DWH_dbo.Dim_Range` — SCD2 time-bounded snapshot lookup
- `DWH_dbo.Dim_PlayerLevel` — PlayerLevelID → Club tier name
- `DWH_dbo.Dim_Country` — CountryID → Country name
- `DWH_dbo.Dim_Regulation` — RegulationID → Regulation name
- `BI_DB_dbo.V_GermanBaFin` — German BaFin status flag by CID/DateID
- `BI_DB_dbo.BI_DB_PositionPnL` — open positions snapshot at @MonthEndDateID (IsSettled=1, crypto only)
- `DWH_dbo.Dim_Position` — position filters (IsDiscounted, IsBuy, MirrorID, Leverage, OpenDateID inception gate)
- `DWH_dbo.Dim_Instrument` — InstrumentTypeID=10 (crypto) filter
- `DWH_dbo.Fact_CurrencyPriceWithSplit` — EOM crypto prices for unrealized valuation (BidSpreaded, ConvertRateIsBuy_1)
- `Customer.CustomerStatic` (etoro production, via Fact_SnapshotCustomer.RealCID) — CID Tier 1 source

## ETL Pipeline

```
Customer.CustomerStatic (etoro production)
  |-- Generic Pipeline (Bronze export) --|
  v
DWH_dbo.Fact_SnapshotCustomer + Dim_PlayerLevel/Country/Regulation/Range
  |-- Filter: PlayerLevelID IN(6,7), IsValidCustomer=1, GuruStatusID NOT IN(2-6) --|
  v
#club_members (Diamond + Platinum Plus at @MonthEndDate)

BI_DB_PositionPnL (at @MonthEndDateID, IsSettled=1, crypto/long/non-mirror/non-leveraged)
  +
Dim_Position (filters: IsDiscounted=0, IsBuy=1, MirrorID=0, Leverage=1, OpenDateID>=20220308)
  +
Dim_Instrument (InstrumentTypeID=10)
  |-- Unrealized open positions --|
  v
#UnrealizedOpen → #UnrealizedVolumeOpen (InitForexRate valuation)

Fact_CurrencyPriceWithSplit (OccurredDateID=@MonthEndDateID)
  v
#UnrealizedVolumeClose (BidSpreaded EOM mark-to-market)

SP_M_CryptoRebateDiamond(@Date) — second INSERT in SP (after Dealing_CryptoRebate)
  → bracket volume splits → rebate calc → $5 threshold
  → DELETE FROM Dealing_Unrealized_CryptoRebate WHERE MonthEndDate = @MonthEndDate
  → INSERT INTO BI_DB_dbo.Dealing_Unrealized_CryptoRebate
      (786K rows, 44 months: 2022-03-31 to 2026-03-31)
  → UC: _Not_Migrated
```
