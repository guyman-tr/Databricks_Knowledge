# Dealing_dbo.Dealing_Market_Manipulation_OutstandingsharesHigherthan005

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_Market_Manipulation_OutstandingsharesHigherthan005 |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_Market_Manipulation_OutstandingsharesHigherthan005(@Date)` |
| **Refresh** | Daily (Priority 0, SB_Daily) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~2.2K |
| **Date Range** | 2024-03-31 → 2026-03-10 (active ✅) |
| **PII** | CID (client identifier) |

---

## 1. Business Meaning

Daily surveillance table for detecting potential market manipulation in Real Stocks and ETFs. Flags CIDs (clients) who, on a given day, personally account for more than **0.25%** of an instrument's outstanding shares via realized (same-day open+close) activity — on days when eToro's aggregate hedge volume itself exceeds **0.5%** of outstanding shares.

The dual-threshold design filters at two levels: first identifying instruments where eToro's total externalized volume is large relative to the market float, then drilling down to find which specific clients drove outsized individual contributions. Results are also written to a sibling `_Email` table (TRUNCATE+INSERT) for automated alert distribution.

Migrated from Databricks to Synapse SQL (SR-244356, Mar 2024); updated to source from CopyFromLake (SR-286859, Dec 2024).

---

## 2. Grain

One row = one CID × one InstrumentID on one Date where both thresholds are breached. Days with no breaches still produce a NULL row for date continuity (via LEFT JOIN pattern).

---

## 3. Key Columns & Elements

| Column | Type | Description |
|--------|------|-------------|
| `Date` | date | Report date |
| `CID` | int | Client identifier — the flagged account |
| `InstrumentID` | int | Instrument that breached both thresholds |
| `InstrumentName` | nvarchar | Instrument name from Dim_Instrument |
| `ADV_Last3Months` | float | Average daily volume over the last 3 months (from Dim_Instrument) |
| `SharesOutStanding` | float | Instrument's total outstanding shares (from Dim_Instrument) |
| `VolumeInUnitsDailyRealized` | float | CID's realized units on this date (same-day open+close, ×2 for round-trip) |
| `RealizedZero` | money | Net P&L for these positions including commission (FullCommissionOnClose + NetProfit) |
| `EtoroVolumeExternalized` | float | Total eToro hedge volume externalized for this instrument on Date (SUM of LP-hedged units) |
| `CustomersTotalUnits` | float | All customers' combined open+close units for this instrument on Date |
| `VolumeExternalised_CID` | float | CID's proportional share of externalized volume: `(VolumeInUnitsDailyRealized × EtoroVolumeExternalized) / CustomersTotalUnits` |
| `UpdateDate` | datetime | ETL metadata timestamp |

---

## 4. Common Query Patterns

```sql
-- Flagged clients on a specific date
SELECT Date, CID, InstrumentName, VolumeInUnitsDailyRealized,
       SharesOutStanding, VolumeInUnitsDailyRealized/SharesOutStanding AS PctOutstanding,
       RealizedZero, VolumeExternalised_CID
FROM Dealing_dbo.Dealing_Market_Manipulation_OutstandingsharesHigherthan005
WHERE Date = '2026-03-10'
  AND CID IS NOT NULL
ORDER BY VolumeInUnitsDailyRealized/SharesOutStanding DESC;

-- Trend: flagged events per day
SELECT Date, COUNT(CID) AS FlaggedClients, COUNT(DISTINCT InstrumentID) AS FlaggedInstruments
FROM Dealing_dbo.Dealing_Market_Manipulation_OutstandingsharesHigherthan005
WHERE CID IS NOT NULL
GROUP BY Date
ORDER BY Date DESC;
```

> ⚠️ **NULL rows**: Days with no breaches contain a single NULL CID row — always filter `WHERE CID IS NOT NULL` for meaningful analysis.

---

## 5. Known Issues & Quirks

- **NULL sentinel row**: LEFT JOIN pattern inserts a NULL row on breach-free days — necessary to prevent date gaps in downstream consumers
- **HedgeServerID exclusion list**: Servers 2,7,101 (CFD), 121–124 (internal), 225–226 (EtoroX), 3,9,112,125,126,128 (real LP) are excluded — only unhedged/non-LP flow is measured
- **InstrumentID ≠ 2731**: Hardcoded exclusion in Dim_Instrument join (specific instrument excluded from monitoring)
- **PlayerLevelID ≠ 4**: Excludes eToro employee accounts from CID detection
- **IsSettled = 1**: Only settled (completed) positions count — no pending trades
- **Sibling table**: Results also written to `Dealing_Market_Manipulation_OutstandingsharesHigherthan005_Email` via TRUNCATE+INSERT (email alert table)
- **Sparse table**: ~2.2K rows across 2 years = relatively rare flags; typically a handful of events per trading day

---

## 6. Lineage Summary

Sources: CopyFromLake.etoro_Hedge_ExecutionLog (hedge volumes) + DWH_dbo.Dim_Instrument (outstanding shares thresholds) + DWH_dbo.Dim_Position (client realized volumes) + DWH_dbo.Dim_Customer (employee exclusion). See `.lineage.md` for full column-level map.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_Market_Manipulation_OutstandingsharesHigherthan005_Email` | Sibling email-alert table (TRUNCATE+INSERT from same SP) |
| `CopyFromLake.etoro_Hedge_ExecutionLog` | Primary source — hedge execution data |
| `DWH_dbo.Dim_Instrument` | Outstanding shares and ADV thresholds |
| `DWH_dbo.Dim_Position` | Client-level realized position volumes |

---

*Quality score: 7.5/10 — active surveillance table, clear dual-threshold logic, sparse by design*
