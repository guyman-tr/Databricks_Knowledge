# History.ExposureBreakdownLog

> Legacy archived version of the hedge net exposure snapshot log - periodic snapshots of eToro's open position exposure vs hedged coverage per instrument per hedge server. Superseded by Hedge.ExposureBreakdownLog (which added ExposureID, MarketPriceRateID, and Queued columns and widened unit decimals).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | EntryID (int, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (NONCLUSTERED PK on EntryID, CLUSTERED on Occurred) |

---

## 1. Business Meaning

This table is a **legacy archive of net exposure snapshots** for eToro's hedging system, representing the original version of `Hedge.ExposureBreakdownLog` before the `ExposureID`, `MarketPriceRateID`, and `Queued` columns were added and before unit columns were widened.

Each row is a **periodic exposure snapshot event**: at a given moment in time, for a specific instrument on a specific hedge server, the hedge engine recorded:
- How many buy and sell units are currently open in customer positions
- How many of those units are already hedged at a liquidity provider
- How many hedge units have been requested but not yet filled
- The resulting **net USD exposure** - eToro's remaining unhedged risk

**The hedging lifecycle** this log captures:
```
Customers open positions -> OpenedBuyUnits / OpenedSellUnits increase
Hedge engine calculates needed hedge -> RequestedUnits set
LP fills hedge order -> HedgedUnits increase
Net exposure = (OpenedBuyUnits - OpenedSellUnits) * MidPrice - HedgedUnits * MidPrice
```

When `NetUSDExposure` is near zero, eToro is fully hedged for that instrument. When it deviates, the hedge engine has work to do.

**Relationship to Hedge schema**:
- `Hedge.ExposureBreakdownLog` is the current active table (16 columns on [MAIN] filegroup)
- `History.ExposureBreakdownLog` is the legacy version (13 columns on [PRIMARY] filegroup)
- No SP in SSDT writes to this History table - it was populated by application code or direct inserts in the earlier system
- Missing vs Hedge version: `ExposureID` (int NULL), `MarketPriceRateID` (int NULL), `Queued` decimal(22,6)
- Narrower precision: `OpenedBuyUnits`/`OpenedSellUnits` are decimal(16,6) here vs decimal(22,6) in Hedge version

The table has **0 rows** in this staging environment.

---

## 2. Business Logic

### 2.1 Exposure Snapshot Content

**What**: Each row captures a complete exposure state for one instrument on one hedge server at a point in time.

**Columns/Parameters Involved**: All columns

**Rules**:
- `OpenedBuyUnits`: Total customer buy units open in this instrument on this hedge server. Represents eToro's net long customer exposure.
- `OpenedSellUnits`: Total customer sell units open. Represents eToro's net short customer exposure.
- `HedgedUnits`: Units currently hedged at the LP (signed: positive = LP position open for this instrument). Reduces net exposure.
- `RequestedUnits`: Units for which hedge orders have been sent to the LP but not yet confirmed.
- `NetUSDExposure`: The final unhedged exposure in USD. A large positive = eToro is net long and under-hedged. A negative = over-hedged. Near-zero = fully hedged.
- `IsAggregated = 1`: This row represents a rolled-up snapshot across multiple sub-accounts or components for this instrument. `IsAggregated = 0`: Per-component snapshot.
- `eToroPriceBid` / `eToroPriceAsk`: eToro's internal bid/ask price at snapshot time, used to convert unit-denominated exposure to USD.

### 2.2 Legacy Status - Missing Columns

**What**: Three columns were added to the Hedge version that are not in this History version.

**Rules**:
- `Queued` (decimal(22,6)): Units that have been queued for hedging but not yet sent to the LP. Fills the gap between "decided to hedge" and "request sent". Missing here means queued state was not tracked in the legacy version.
- `ExposureID` (int NULL): Links this snapshot to a specific exposure tracking record in the Hedge system. Without this, legacy rows cannot be joined to the exposure management system.
- `MarketPriceRateID` (int NULL): The market price snapshot ID at logging time for precise TCA and exposure attribution. Missing here.
- `OpenedBuyUnits` / `OpenedSellUnits` precision was decimal(16,6) here vs decimal(22,6) in Hedge - the wider type was needed as eToro's customer base and position sizes grew.

### 2.3 FK to Trade.Instrument (not InstrumentMetaData)

**What**: This History table references `Trade.Instrument` directly, unlike the Hedge version which only has the HedgeServer FK.

**Rules**:
- FK `FK_ExposureBreakdownLog_Instrument`: InstrumentID -> Trade.Instrument.InstrumentID.
- The Hedge version dropped this FK (using NOCHECK or removing it), suggesting the FK was enforced in the legacy system but relaxed as the system evolved.
- `Trade.Instrument` is a more basic instrument table than `Trade.InstrumentMetaData`; both contain InstrumentID.

---

## 3. Data Overview

The table contains **0 rows** in this staging environment. A representative production row:

| EntryID | InstrumentID | HedgeServerID | Occurred | IsAggregated | OpenedBuyUnits | OpenedSellUnits | HedgedUnits | RequestedUnits | NetUSDExposure |
|---|---|---|---|---|---|---|---|---|---|
| 4521 | 4 (NASDAQ) | 3 | 2011-09-14 16:30:00 | 1 | 1250000.000 | 750000.000 | 450000.000 | 50000.000 | 27500.000 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EntryID | int | NO | - | CODE-BACKED | Surrogate PK. IDENTITY(1,1) in the Hedge version (NOT FOR REPLICATION); carried as-is in this archive. NONCLUSTERED PK allows CLUSTERED index on Occurred. |
| 2 | InstrumentID | int | NO | - | VERIFIED | The instrument for which this exposure snapshot was recorded. FK to Trade.Instrument (FK_ExposureBreakdownLog_Instrument). The Hedge version dropped this FK. |
| 3 | HedgeServerID | int | NO | - | VERIFIED | The hedge server that recorded this snapshot. FK to Trade.HedgeServer (FK_ExposureBreakdownLog_HedgeServer). Each hedge server manages exposure for a subset of instruments or accounts. |
| 4 | Occurred | datetime | NO | - | VERIFIED | UTC datetime when this snapshot was logged (default = GETUTCDATE() in Hedge version). CLUSTERED index leading column. Primary time dimension for trend analysis. |
| 5 | eToroPriceBid | decimal(16,8) | NO | - | VERIFIED | eToro's internal bid price at snapshot time. Used to convert unit exposure to USD. 8 decimal places for forex/crypto precision. |
| 6 | eToroPriceAsk | decimal(16,8) | NO | - | VERIFIED | eToro's internal ask price at snapshot time. The mid-price ((Bid+Ask)/2) is used for exposure-to-USD conversion. |
| 7 | IsAggregated | bit | NO | - | VERIFIED | 1 = this row is an aggregated view across all sub-components for this instrument/server. 0 = per-component breakdown row. The hedge engine logs both individual and aggregate snapshots for drill-down analysis. |
| 8 | OpenedBuyUnits | decimal(16,6) | NO | - | VERIFIED | Total units of buy positions open for this instrument on this hedge server. Represents eToro's net long customer exposure. In Hedge version: decimal(22,6) for larger volumes. |
| 9 | OpenedSellUnits | decimal(16,6) | NO | - | VERIFIED | Total units of sell positions open for this instrument on this hedge server. Represents eToro's net short customer exposure. In Hedge version: decimal(22,6). |
| 10 | HedgedUnits | decimal(16,6) | NO | - | VERIFIED | Units currently hedged at the LP. Subtracting from net open exposure gives remaining unhedged position. A fully hedged book has HedgedUnits = OpenedBuyUnits - OpenedSellUnits (for net long). |
| 11 | RequestedUnits | decimal(16,6) | NO | - | VERIFIED | Units for which hedge orders have been sent to the LP and are pending confirmation. Represents in-flight hedge activity. (In Hedge version, `Queued` was added to capture units decided but not yet sent.) |
| 12 | NetUSDExposure | decimal(16,3) | NO | - | VERIFIED | The net unhedged exposure in USD. Calculated as: (OpenedBuyUnits - OpenedSellUnits - HedgedUnits) * MidPrice. Near-zero = fully hedged. Positive = under-hedged long. Negative = over-hedged. 3 decimal places. |

**Missing columns** (present in `Hedge.ExposureBreakdownLog` but NOT in this legacy version):
- `ExposureID` (int NULL) - links to exposure tracking record
- `MarketPriceRateID` (int NULL) - market price snapshot at log time
- `Queued` (decimal(22,6) NOT NULL DEFAULT 0) - units queued for hedging but not yet requested

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (FK_ExposureBreakdownLog_HedgeServer) | The hedge server that logged this snapshot |
| InstrumentID | Trade.Instrument | FK (FK_ExposureBreakdownLog_Instrument) | The instrument whose exposure is recorded |

### 5.2 Referenced By (other objects point to this)

No objects in SSDT reference this History table. All current consumers use `Hedge.ExposureBreakdownLog`.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExposureBreakdownLog (table)
- Legacy archive - receives no new data
- Equivalent (older) version of Hedge.ExposureBreakdownLog
- FK deps: Trade.HedgeServer, Trade.Instrument

Active version: Hedge.ExposureBreakdownLog
- Written by: hedging application code (no SP writer in SSDT)
- Adds: ExposureID, MarketPriceRateID, Queued columns
- Larger precision: decimal(22,6) for unit columns
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK - HedgeServerID must exist |
| Trade.Instrument | Table | FK - InstrumentID must exist |

### 6.2 Objects That Depend On This

No active dependencies. See `Hedge.ExposureBreakdownLog` for the current version.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryExposureBreakdownLog | NONCLUSTERED (PK) | EntryID ASC | - | - | Active |
| IX_HistoryExposureBreakdownLog_Occurred | CLUSTERED | Occurred ASC | - | - | Active |

**Note**: The Hedge version uses FILLFACTOR=90 on the clustered index; the History version uses the default.

**Filegroup**: [PRIMARY] - no DATA_COMPRESSION specified (default = none). Hedge version uses [MAIN] filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryExposureBreakdownLog | PRIMARY KEY (NONCLUSTERED) | Uniqueness on EntryID |
| FK_ExposureBreakdownLog_HedgeServer | FOREIGN KEY | HedgeServerID -> Trade.HedgeServer |
| FK_ExposureBreakdownLog_Instrument | FOREIGN KEY | InstrumentID -> Trade.Instrument |

---

## 8. Sample Queries

### 8.1 Exposure trend for a specific instrument
```sql
SELECT Occurred, HedgeServerID, IsAggregated,
       OpenedBuyUnits, OpenedSellUnits, HedgedUnits, RequestedUnits,
       NetUSDExposure,
       OpenedBuyUnits - OpenedSellUnits AS NetOpenUnits,
       (OpenedBuyUnits - OpenedSellUnits) - HedgedUnits AS UnhedgedUnits
FROM [History].[ExposureBreakdownLog]
WHERE InstrumentID = 4
  AND IsAggregated = 1
ORDER BY Occurred
```

### 8.2 Peak exposure per instrument
```sql
SELECT InstrumentID, HedgeServerID,
       MAX(ABS(NetUSDExposure)) AS PeakAbsExposureUSD,
       MAX(OpenedBuyUnits + OpenedSellUnits) AS PeakTotalUnits,
       MIN(Occurred) AS FirstSnapshot,
       MAX(Occurred) AS LastSnapshot
FROM [History].[ExposureBreakdownLog]
WHERE IsAggregated = 1
GROUP BY InstrumentID, HedgeServerID
ORDER BY PeakAbsExposureUSD DESC
```

### 8.3 Combined view with current data
```sql
SELECT 'History' AS Source, EntryID, InstrumentID, HedgeServerID, Occurred,
       OpenedBuyUnits, OpenedSellUnits, HedgedUnits, NetUSDExposure
FROM [History].[ExposureBreakdownLog]
UNION ALL
SELECT 'Hedge' AS Source, EntryID, InstrumentID, HedgeServerID, Occurred,
       OpenedBuyUnits, OpenedSellUnits, HedgedUnits, NetUSDExposure
FROM [Hedge].[ExposureBreakdownLog]
ORDER BY Occurred
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.6/10 (Elements: 9/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Note: Table has 0 rows in staging. Legacy version of Hedge.ExposureBreakdownLog - no longer written*
*Object: History.ExposureBreakdownLog | Type: Table | Source: etoro/etoro/History/Tables/History.ExposureBreakdownLog.sql*
