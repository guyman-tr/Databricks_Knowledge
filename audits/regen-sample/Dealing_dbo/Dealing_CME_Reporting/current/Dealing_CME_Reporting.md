---
object: Dealing_CME_Reporting
schema: Dealing_dbo
type: Table
description: Monthly CME regulatory reporting aggregate — counts distinct clients and total volume per instrument for a fixed set of CME-regulated instruments (futures, indices, commodities). Written at end-of-month for each prior calendar month.
etl_sp: Dealing_dbo.SP_M_CME_Reporting
frequency: Monthly (end-of-month, last calendar day)
status: Active (last row 2026-02-28 based on row count)
row_count: 690
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_CME_Reporting

Monthly regulatory report table for CME instrument obligations. Each row represents one **instrument × month** reporting unit — the distinct client count and aggregate traded volume for that instrument over the calendar month. Used to fulfill eToro's CME reporting obligations.

Service request SR-225467 defined the initial instrument set. SR-303463 (2025-03-05) added 3 additional instruments to the hardcoded list.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Position` | CID, Volume (open), VolumeOnClose (close) for positions touching the month |
| Dimension | `DWH_dbo.Dim_Instrument` | InstrumentDisplayName + crude oil name-pattern filter |
| Dimension | `DWH_dbo.Dim_Customer` | IsValidCustomer=1 filter |
| Writer | `Dealing_dbo.SP_M_CME_Reporting` | Monthly (last calendar day), OpsDB Priority 0 |

**ETL logic**: `@Date` is passed as the last day of the previous month (derived via DATEADD in the calling script). The SP computes `@EndOfMonth` from `@Date`. Positions with `OpenDateID` OR `CloseDateID` falling within the reference calendar month are included. Volume contributions are unioned — a position contributes Volume (via OpenDateID) and VolumeOnClose (via CloseDateID) separately.

**Instrument scope** — hardcoded InstrumentIDs:
`21, 22, 27, 28, 29, 36, 91, 97, 312, 313, 314, 317, 318, 324, 325, 331, 332, 335, 336, 337, 338, 380, 381, 382`
Plus any instrument whose display name matches the crude oil futures name pattern (normalized to `'Crude Oil Future'`).

## 1. Business Purpose

- Fulfills eToro's monthly CME (Chicago Mercantile Exchange) regulatory reporting obligation for derivatives/futures instruments
- Provides CME with aggregate client participation counts and traded volumes — not individual client data
- Crude oil futures from multiple exchanges are normalized into a single `'Crude Oil Future'` category per CME reporting requirements

## 2. Key Concepts

| Concept | Explanation |
|---------|-------------|
| Volume vs VolumeOnClose | Volume = position size at open; VolumeOnClose = size at close. Both are USD-approximated from AmountInUnitsDecimal × InitForexRate in Dim_Position. |
| Monthly_Volume | SUM of all Volume contributions (open-side + close-side) for the month per instrument |
| CID_Count | COUNT(DISTINCT CID) — unique clients who had an open or close event during the month |
| Crude oil normalization | Multiple crude oil future instruments (e.g., WTI, Brent variants) are reported under a single 'Crude Oil Future' label |

## 3. Grain

One row per **InstrumentDisplayName × calendar month end date**. ~690 rows = ~30 months × ~23 instruments.

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| `Date` | date | Last calendar day of the reference reporting month (e.g., 2026-02-28). | Tier 2 | SP-computed via DATEADD from input @Date parameter. Clustered index key. |
| `InstrumentDisplayName` | varchar(100) | Instrument display name for this row. Crude oil futures all map to 'Crude Oil Future'. | Tier 1 | From DWH_dbo.Dim_Instrument.InstrumentDisplayName; CASE normalizes crude oil variants. |
| `CID_Count` | int | Count of distinct client IDs who had a position open or close event for this instrument during the month. | Tier 2 | COUNT(DISTINCT CID) from DWH_dbo.Dim_Position; valid customers only. |
| `Monthly_Volume` | decimal(38,6) | Total USD-equivalent volume (open + close sides) for this instrument during the month. | Tier 2 | SUM(Volume) + SUM(VolumeOnClose) from DWH_dbo.Dim_Position. |
| `UpdateDate` | datetime | ETL metadata: timestamp when row was last written. | Tier 1 | ETL metadata (blacklist canonical). |

## 5. Common Query Patterns

```sql
-- Latest month's report
SELECT InstrumentDisplayName, CID_Count, Monthly_Volume
FROM Dealing_dbo.Dealing_CME_Reporting
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_CME_Reporting)
ORDER BY Monthly_Volume DESC;

-- Monthly trend for a specific instrument
SELECT Date, CID_Count, Monthly_Volume
FROM Dealing_dbo.Dealing_CME_Reporting
WHERE InstrumentDisplayName = 'Crude Oil Future'
ORDER BY Date DESC;
```

## 6. Data Quality & Caveats

- Instrument list is hardcoded in SP — new CME-regulated instruments require an SP update (SR process)
- Crude oil normalization collapses multiple instruments; cannot distinguish sub-types in this table
- Monthly_Volume is USD-approximated via DWH Dim_Position.Volume (Tier 2 — ETL-computed, not exchange-confirmed)
- Row count is small (690 rows) — full scans are cheap

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `DWH_dbo.Dim_Position` | Primary source for Volume, VolumeOnClose, CID |
| `DWH_dbo.Dim_Instrument` | Instrument name and scope filter |

## 8. Operational Notes

- **ETL**: `SP_M_CME_Reporting` runs on the last calendar day of each month (OpsDB ProcessType 1, ProcessName SB_Monthly)
- **@Date** passed in as last-day-of-previous-month; must be end-of-month for correct DATEADD logic
- **DELETE+INSERT** pattern: prior month's rows are deleted and reinserted on each run
- SR-303463 (2025-03-05): added 3 instruments to the hardcoded list (InstrumentIDs 380, 381, 382)

---
*Quality score: 8.0/10 — Good SP traceability, regulatory context clear. Minor deduction: instrument IDs not named (only IDs listed), crude oil pattern not enumerated.*
