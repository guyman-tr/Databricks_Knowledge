# Column Lineage — BI_DB_dbo.BI_DB_Reg_UK_Compliance_VolumeByInstrument

**Writer SP**: `BI_DB_dbo.SP_Reg_UK_Compliance_VolumeByInstrument`
**UC Target**: `_Not_Migrated`
**Generated**: 2026-04-21
**Author**: Nir Weber (2022-03-27) | Migrated to Synapse: Slavane (2023-06-08) | DSR-1848

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Tier |
|------------|-------------|---------------|-----------|------|
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough via dp.InstrumentID JOIN | Tier 2 |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough | Tier 2 |
| ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Passthrough | Tier 2 |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Filtered: IN ('Stocks', 'ETF') only | Tier 2 |
| Regulation | DWH_dbo.Dim_Regulation | Name | dr.Name via c.DesignatedRegulationID = dr.ID | Tier 2 |
| IsReal | DWH_dbo.Dim_Position | IsSettled | dp.IsSettled AS IsReal — 1=real/settled asset, 0=CFD | Tier 2 |
| FullNotionalAmount | DWH_dbo.Dim_Position | Leverage, Amount | SUM(dp.Leverage * dp.Amount) — UNION ALL of opened + closed positions on last weekday | Tier 2 |
| UpdateDate | ETL metadata | — | GETDATE() at insert — weekday snapshot timestamp | Tier 3 |

## Source Objects

| Source | Role |
|--------|------|
| DWH_dbo.Dim_Position | Driving source — position leverage, amount, IsSettled, open/close dates |
| DWH_dbo.Dim_Instrument | Instrument metadata — display name, ISIN code, instrument type |
| DWH_dbo.Dim_Customer | Customer regulation assignment — DesignatedRegulationID |
| DWH_dbo.Dim_Regulation | Regulation name text — CySEC, FCA, FSA Seychelles, etc. |
| DWH_dbo.Dim_Country | JOINed but not used in output — present for historical filtering context |

## Date Logic

- `@startdate` = last weekday relative to run date (Mon→Fri, Sun→Fri, other→yesterday)
- Leg 1: `OpenDateID = @startdateid` — positions opened on last weekday
- Leg 2: `CloseDateID = @startdateid` — positions closed on last weekday
- UNION ALL then outer GROUP BY → final row = total notional per instrument/regulation/settlement combination

## ETL Pipeline

```
DWH_dbo.Dim_Position (OpenDateID = last weekday)
  + DWH_dbo.Dim_Instrument (filter: InstrumentType IN ('Stocks', 'ETF'))
  + DWH_dbo.Dim_Customer (DesignatedRegulationID)
  + DWH_dbo.Dim_Regulation (Regulation name)
  + DWH_dbo.Dim_Country (JOINed, not used)
    [Leg 1: opened on last weekday]
UNION ALL
DWH_dbo.Dim_Position (CloseDateID = last weekday)
  + same JOINs
    [Leg 2: closed on last weekday]
    → outer GROUP BY InstrumentID, DisplayName, ISINCode, InstrumentType, Regulation, IsReal
    |-- SP_Reg_UK_Compliance_VolumeByInstrument (Daily weekdays only, Priority 21, SB_Daily) ---|
    v                                                                           [TRUNCATE + INSERT]
BI_DB_dbo.BI_DB_Reg_UK_Compliance_VolumeByInstrument
  (20,932 rows | latest snapshot 2026-04-13 | ROUND_ROBIN HEAP)
    |-- UC: _Not_Migrated
```
