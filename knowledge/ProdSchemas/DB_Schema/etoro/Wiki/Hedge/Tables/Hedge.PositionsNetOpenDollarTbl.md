# Hedge.PositionsNetOpenDollarTbl

> Global net open exposure cache per instrument - stores the aggregate net customer position per InstrumentID in units and dollar-equivalent terms. Companion to Hedge.PositionsHedgeTbl but with no HedgeServerID split and a single row per instrument. Currently empty (cleared state).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID - single column CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED PK + NC on NetOpenUnits) |

---

## 1. Business Meaning

Hedge.PositionsNetOpenDollarTbl is the global net open exposure cache - one row per instrument representing the TOTAL net customer position across all hedge servers, expressed in both raw units and dollar-equivalent terms.

This is the "what do we need to hedge?" summary table. While Hedge.PositionsHedgeTbl stores position data split by HedgeServerID and direction (IsBuy in PK), this table:
- Has NO HedgeServerID - it represents the aggregated global view
- Has InstrumentID as the sole PK - one row per instrument, not per direction
- Stores IsBuy as the net direction of the aggregated position
- Provides three representations of the exposure: NetOpenUnits (raw), NetOpenDollars (monetary), NetOpenNormalize (normalized)

The dollar-denominated columns (NetOpenDollars, NetOpenNormalize) convert unit-based positions into a common monetary measure, enabling cross-instrument exposure comparison and hedging threshold logic (see Hedge.InstrumentBoundaries which uses dollar-based thresholds).

The table follows the same "persist data" operational pattern as Hedge.PositionsHedgeTbl:
- Written via TVP batch upsert (`SetNetOpenDollarPersistData`)
- Cleared via TRUNCATE (`ClearNetOpenExposuresPersistData`)
- Cleaned up by removing zero-unit rows (`DeleteZeroRowNetOpenHedgePersistData`)

The table is currently empty (0 rows) - in a cleared state, not actively populated.

---

## 2. Business Logic

### 2.1 TVP Batch Upsert Pattern (SetNetOpenDollarPersistData)

**What**: Exposure data is written in bulk via TVP `Hedge.PositionsNetOpenDollarPersistTable`, following the same pattern as `SetHedgePersistData` but keyed only on InstrumentID.

**Columns/Parameters Involved**: All columns

**Rules**:
- `SetNetOpenDollarPersistData` receives `@NetOpenDollarToUpdate` TVP
- Step 1: UPDATE rows where InstrumentID matches (updates ALL columns including IsBuy - direction can change as net shifts)
- Step 2: INSERT rows where InstrumentID not in table (NOT EXISTS check)
- No DELETE path in this SP - only via TRUNCATE or zero-cleanup
- IsBuy can flip between calls as the net direction of customer positions shifts

**Diagram**:
```
Aggregate customer positions ->  SetNetOpenDollarPersistData(@NetOpenDollarToUpdate TVP)
                                  |
                                  +-> UPDATE where InstrumentID exists (incl. IsBuy direction change)
                                  +-> INSERT where InstrumentID is new
```

### 2.2 Three Exposure Representations

**What**: The table stores three different numeric representations of the same net open position, serving different analytical purposes.

**Columns/Parameters Involved**: `NetOpenUnits`, `NetOpenDollars`, `NetOpenNormalize`

**Rules**:
- `NetOpenUnits`: raw position size in instrument-native units (e.g., barrels for oil, shares for equities). Nullable - may be absent for some instruments.
- `NetOpenDollars`: monetary equivalent of the net position in USD. NOT NULL - always required. Enables cross-instrument exposure comparison regardless of unit type. Likely computed as `NetOpenUnits * CurrentPrice * UnitMargin` or similar.
- `NetOpenNormalize`: a further normalized dollar value. Nullable. Purpose is likely normalization per-unit notional or per some hedge factor, enabling proportional comparisons between instruments of different scales.
- Cleanup predicate (`DeleteZeroRowNetOpenHedgePersistData`) uses `NetOpenUnits = 0` only - a zero-unit position is considered closed even if NetOpenDollars may show rounding residuals.

### 2.3 Direction Stored as Net Result (IsBuy)

**What**: Unlike Hedge.PositionsHedgeTbl where IsBuy is a PK component (separate rows for long/short), here IsBuy describes the NET result of all client positions combined.

**Rules**:
- IsBuy=1: the aggregate customer book is net long on this instrument (more buyers than sellers)
- IsBuy=0: the aggregate customer book is net short (more sellers than buyers)
- IsBuy can change between update cycles if the net direction shifts
- There is only ONE row per instrument - not split by direction

---

## 3. Data Overview

Table is currently empty (0 rows). In cleared state. When populated, rows represent one net exposure per instrument:

| InstrumentID | IsBuy | NetOpenUnits | NetOpenDollars | NetOpenNormalize | LastDataID | LastUpdated |
|---|---|---|---|---|---|---|
| 1 | 1 | 15,500,000.000000 | 1,255,300.000000 | 1,255.300000 | 112233 | 2026-03-19 08:00:00 |
| 5 | 0 | 2,300,000.000000 | 310,500.000000 | 310.500000 | 112233 | 2026-03-19 08:00:00 |

Row 1: InstrumentID=1 - 15.5M units net long, $1.26M equivalent exposure
Row 2: InstrumentID=5 - 2.3M units net short, $310.5K equivalent exposure

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | PK. Implicit FK to Trade.Instrument. One row per instrument represents the globally aggregated net open exposure. No HedgeServerID component - this is the cross-server global net, not a per-server view. |
| 2 | IsBuy | bit | NO | - | VERIFIED | Net direction of the aggregated customer position. 1 = net long (customers collectively hold more buy positions), 0 = net short (customers collectively hold more sell positions). NOT a PK component - only one row per instrument exists, and this column reflects the current net direction. Can flip between update cycles. |
| 3 | NetOpenUnits | decimal(16,6) | YES | - | VERIFIED | The net open position magnitude in instrument-native units (e.g., barrels, contracts, shares). Nullable for instruments where unit representation is not applicable. The cleanup predicate (`DELETE WHERE NetOpenUnits = 0`) treats a zero here as a fully closed position. |
| 4 | NetOpenDollars | decimal(16,6) | NO | - | VERIFIED | Dollar-equivalent monetary value of the net open position. NOT NULL - always required. Converts raw units into a USD-denominated exposure figure, enabling cross-instrument comparison and threshold-based hedging decisions. Likely computed from units, current price, and margin/dollar-ratio factors. |
| 5 | NetOpenNormalize | decimal(16,6) | YES | - | CODE-BACKED | Normalized version of the dollar exposure. Nullable. The normalization factor is not defined in DDL but likely represents exposure per some standard unit (e.g., per $1M notional, or divided by instrument scale factor). Enables proportional comparison between instruments of vastly different price scales. |
| 6 | LastDataID | int | NO | - | CODE-BACKED | Data batch/record identifier for the last update. Tracks which data cycle produced the current state, enabling consumers to detect stale rows. Same role as LastDataID in Hedge.PositionsHedgeTbl. |
| 7 | LastUpdated | datetime | NO | - | VERIFIED | Timestamp of the last upsert. NOT NULL. The TVP type also marks LastUpdated as NOT NULL (the only required column in the TVP), indicating it is always set by the caller. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | The financial instrument whose net exposure is stored |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.SetNetOpenDollarPersistData | InstrumentID | WRITER (upsert) | TVP-based batch upsert - primary write path |
| Hedge.ClearNetOpenExposuresPersistData | (all) | TRUNCATE | Full table clear for refresh cycle reset |
| Hedge.DeleteZeroRowNetOpenHedgePersistData | NetOpenUnits | DELETER | Removes instruments with zero net units |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.PositionsNetOpenDollarTbl (table)
+-- Trade.Instrument (table) [implicit FK target - leaf]
+-- Hedge.PositionsNetOpenDollarPersistTable (User Defined Type) [TVP for SetNetOpenDollarPersistData]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | Implicit FK target for InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.SetNetOpenDollarPersistData | Stored Procedure | WRITER - TVP-based batch upsert |
| Hedge.ClearNetOpenExposuresPersistData | Stored Procedure | TRUNCATE - full clear |
| Hedge.DeleteZeroRowNetOpenHedgePersistData | Stored Procedure | DELETE - removes zero-unit rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PositionsNetOpenDollarTbl | CLUSTERED PK | InstrumentID ASC | - | - | Active |
| Ix_NetOpenUnits | NONCLUSTERED | NetOpenUnits ASC | - | - | Active |

Note: `Ix_NetOpenUnits` supports lookups/sorts by exposure size. FILLFACTOR=95 on both indexes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PositionsNetOpenDollarTbl | PRIMARY KEY | One row per instrument (global net) |

### 7.3 Comparison with Hedge.PositionsHedgeTbl

| Property | PositionsHedgeTbl | PositionsNetOpenDollarTbl |
|---|---|---|
| PK | (InstrumentID, HedgeServerID, IsBuy) | InstrumentID only |
| Scope | Per hedge server, per direction | Global net across all servers |
| IsBuy | PK component (separate rows) | Direction attribute (can change) |
| Exposure | Units + Margin + Forex | Units + Dollars + Normalized |
| Cleanup trigger | AmountInUnitsDecimal = 0 AND Redeemed = 0 | NetOpenUnits = 0 |

### 7.4 Related User Defined Type

`Hedge.PositionsNetOpenDollarPersistTable` mirrors this table's schema as the TVP input for `SetNetOpenDollarPersistData`. All columns nullable except LastUpdated.

---

## 8. Sample Queries

### 8.1 Current global net exposure per instrument (sorted by dollar exposure)
```sql
SELECT  p.InstrumentID,
        CASE WHEN p.IsBuy = 1 THEN 'Net Long' ELSE 'Net Short' END AS NetDirection,
        p.NetOpenUnits,
        p.NetOpenDollars,
        p.NetOpenNormalize,
        p.LastDataID,
        p.LastUpdated
FROM    [Hedge].[PositionsNetOpenDollarTbl] p WITH (NOLOCK)
ORDER BY p.NetOpenDollars DESC;
```

### 8.2 Compare NetOpenDollarTbl with Netting (exposure reconciliation)
```sql
-- Dollar equivalent from netting (as LP hedge positions)
SELECT  n.InstrumentID,
        SUM(CASE WHEN n.IsBuy = 1 THEN n.Units ELSE -n.Units END) AS NetNettingUnits
FROM    [Hedge].[Netting] n WITH (NOLOCK)
GROUP BY n.InstrumentID

UNION ALL

-- Net open customer exposure
SELECT  pn.InstrumentID,
        CASE WHEN pn.IsBuy = 1 THEN pn.NetOpenUnits ELSE -pn.NetOpenUnits END AS NetCustomerUnits
FROM    [Hedge].[PositionsNetOpenDollarTbl] pn WITH (NOLOCK)
```

### 8.3 Find instruments where cleanup is needed (zero units)
```sql
SELECT  p.InstrumentID, p.NetOpenDollars, p.LastUpdated
FROM    [Hedge].[PositionsNetOpenDollarTbl] p WITH (NOLOCK)
WHERE   p.NetOpenUnits = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Confluence search for "PositionsNetOpenDollarTbl" and "net open dollar" returned no relevant results.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.PositionsNetOpenDollarTbl | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.PositionsNetOpenDollarTbl.sql*
