# Hedge.PositionsNetOpenDollarPersistTable

> Table-valued parameter type carrying net open dollar exposure data per instrument and direction for bulk persistence of the hedge server's dollar-denominated exposure state.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type) |
| **Key Identifier** | No primary key (heap TVP) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

`Hedge.PositionsNetOpenDollarPersistTable` is a Table-Valued Parameter type whose structure mirrors `Hedge.PositionsNetOpenDollarTbl`. It enables the hedge server to persist its net open exposure in dollar terms via `Hedge.SetNetOpenDollarPersistData`.

Unlike `Hedge.PositionsHedgePersistTable` (which captures unit-based position state), this TVP captures the dollar-denominated net open exposure: how many units are open, what they are worth in USD, and what the normalized (cross-currency adjusted) exposure is. This "dollar view" is used by the INSight exposure monitoring system to display aggregate risk in a common currency.

Each row represents the net exposure for one InstrumentID/IsBuy combination - the total open units, their USD equivalent, and a normalization factor for cross-currency comparison. The HedgeServerID is absent here - this type aggregates exposure across all servers per instrument/direction.

---

## 2. Business Logic

### 2.1 Dollar-Denominated Exposure Persistence

**What**: Each TVP row captures the net open exposure for one instrument/direction in USD terms.

**Columns/Parameters Involved**: `InstrumentID`, `IsBuy`, `NetOpenUnits`, `NetOpenDollars`, `NetOpenNormalize`

**Rules**:
- `NetOpenUnits`: the count of units in this direction (long or short) across all positions.
- `NetOpenDollars`: USD equivalent of the net open units at the current rate.
- `NetOpenNormalize`: a normalized exposure value adjusted for currency conversion, used for cross-instrument comparison in INSight dashboards.
- `LastDataID` / `LastUpdated`: same watermark semantics as `PositionsHedgePersistTable` - used for recovery/replay sequencing.

**Diagram**:
```
Hedge Server (exposure calculation)
  |
  | computes dollar-denominated net open per (InstrumentID, IsBuy)
  |
  | populates PositionsNetOpenDollarPersistTable TVP
  v
Hedge.SetNetOpenDollarPersistData (SP)
  |
  v
Hedge.PositionsNetOpenDollarTbl (persistence table)
  |
  +-> INSight exposure display (reads via Hedge.GetCurrentOpenExposure or similar)
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | CODE-BACKED | Trading instrument whose dollar exposure is being persisted. Implicit FK to Trade.Instrument. Part of composite key (InstrumentID, IsBuy). |
| 2 | IsBuy | bit | YES | - | CODE-BACKED | Exposure direction: 1 = net long (buy-side) positions, 0 = net short (sell-side) positions. Dollar exposure is tracked separately by direction. |
| 3 | NetOpenUnits | decimal(16,6) | YES | - | CODE-BACKED | Total open units in this instrument/direction across all positions. Decimal precision supports fractional shares/lots. |
| 4 | NetOpenDollars | decimal(16,6) | YES | - | CODE-BACKED | USD equivalent of NetOpenUnits at the current market rate. This is the dollar-denominated risk exposure for this instrument/direction, shown in INSight exposure monitors. |
| 5 | NetOpenNormalize | decimal(16,6) | YES | - | CODE-BACKED | Normalized exposure value adjusted for cross-currency effects (e.g., converting EUR/USD exposure to USD basis). Used for aggregating multi-currency exposures on a comparable basis in reporting. |
| 6 | LastDataID | int | YES | - | CODE-BACKED | Watermark: the last event/data ID processed when this snapshot was taken. On recovery, the hedge server replays only events after this ID to avoid double-processing. |
| 7 | LastUpdated | datetime | NO | - | CODE-BACKED | Timestamp of this persistence snapshot (NOT NULL). Used for ordering and staleness detection. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Identifies the trading instrument whose dollar exposure is persisted |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.SetNetOpenDollarPersistData | @PositionsNetOpenDollar parameter | TVP parameter | Receives dollar exposure batch for upsert into Hedge.PositionsNetOpenDollarTbl |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.SetNetOpenDollarPersistData | Stored Procedure | Bulk-upserts dollar exposure state to Hedge.PositionsNetOpenDollarTbl |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (none) | - | - | - | - | - |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View current net open dollar exposure
```sql
SELECT InstrumentID, IsBuy, NetOpenUnits, NetOpenDollars, NetOpenNormalize, LastUpdated
FROM [Hedge].[PositionsNetOpenDollarTbl] WITH (NOLOCK)
ORDER BY ABS(NetOpenDollars) DESC
```

### 8.2 Calculate net dollar exposure (long minus short) per instrument
```sql
SELECT InstrumentID,
       SUM(CASE WHEN IsBuy = 1 THEN NetOpenDollars ELSE -NetOpenDollars END) AS NetDollarExposure
FROM [Hedge].[PositionsNetOpenDollarTbl] WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY ABS(SUM(CASE WHEN IsBuy = 1 THEN NetOpenDollars ELSE -NetOpenDollars END)) DESC
```

### 8.3 Detect stale exposure data
```sql
SELECT COUNT(*) AS StaleRows, MIN(LastUpdated) AS OldestUpdate
FROM [Hedge].[PositionsNetOpenDollarTbl] WITH (NOLOCK)
WHERE LastUpdated < DATEADD(minute, -2, GETUTCDATE())
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | Exposure data: typed instrument exposure joined with instrument metadata; InstrumentPerHSSystemExposure drives the INSight exposure display |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.PositionsNetOpenDollarPersistTable | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.PositionsNetOpenDollarPersistTable.sql*
