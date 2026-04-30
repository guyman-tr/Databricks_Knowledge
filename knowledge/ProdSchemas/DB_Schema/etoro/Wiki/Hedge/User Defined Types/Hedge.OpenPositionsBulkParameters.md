# Hedge.OpenPositionsBulkParameters

> Memory-optimized table-valued parameter type for passing bulk open position snapshot data - unrealized P&L, unit counts, and price rate per hedge server and instrument.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type - MEMORY_OPTIMIZED) |
| **Key Identifier** | No primary key; NONCLUSTERED index on (HedgeServerID, InstrumentID) |
| **Partition** | N/A |
| **Indexes** | 1 (NONCLUSTERED on HedgeServerID, InstrumentID) |

---

## 1. Business Meaning

`Hedge.OpenPositionsBulkParameters` is a memory-optimized Table-Valued Parameter (TVP) type used to pass real-time open position snapshots - one row per HedgeServer/Instrument combination - into the bulk insert procedure `Hedge.InsertOpenPositionBulk`.

Each row represents the aggregate state of all open customer positions for a given instrument on a given hedge server at a specific moment: how many units are long vs. short, the unrealized P&L, the current price rate, and the timestamp. The hedge server application computes these aggregates and persists them via this TVP at regular intervals (typically every few seconds).

The `MEMORY_OPTIMIZED = ON` flag ensures that parameter marshalling is entirely in-memory - critical since this TVP is called at high frequency to maintain real-time position snapshots. The NONCLUSTERED index on (HedgeServerID, InstrumentID) provides fast lookup within the TVP for any join operations the consuming SP performs.

---

## 2. Business Logic

### 2.1 Real-Time Open Position Snapshot

**What**: Each row is a moment-in-time aggregate of customer open positions for one HedgeServer/Instrument pair.

**Columns/Parameters Involved**: `HedgeServerID`, `InstrumentID`, `OccurredAt`, `OpenBuyUnits`, `OpenSellUnits`, `UnrealizedPL`, `PriceRateID`

**Rules**:
- `OpenBuyUnits`: total units held long by customers hedged through this server/instrument.
- `OpenSellUnits`: total units held short by customers hedged through this server/instrument.
- Net exposure = `OpenBuyUnits - OpenSellUnits` (positive = net long, negative = net short).
- `UnrealizedPL`: unrealized profit/loss for all open positions at the time of this snapshot, in USD.
- `PriceRateID`: links to the market rate snapshot used to compute UnrealizedPL - enables retrospective rate lookup.
- `OccurredAt`: the snapshot timestamp. This is NOT NULL (mandatory) - without a timestamp, the data cannot be time-ordered.

**Diagram**:
```
Hedge Server application
  |
  | computes aggregate open positions per (HedgeServerID, InstrumentID)
  |
  | populates OpenPositionsBulkParameters TVP
  v
Hedge.InsertOpenPositionBulk (SP)
  |
  v
Hedge.CustomerOpenPositions (table) -> periodic snapshots
     |
     v
Hedge.ArchiveCustomerOpenPositions -> History.CustomerOpenPositions
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server instance that computed this open position snapshot. Groups exposure by server for per-server hedge cost tracking. Implicit FK to Trade.HedgeServer. |
| 2 | InstrumentID | int | YES | - | CODE-BACKED | Trading instrument for this snapshot row. Combined with HedgeServerID, uniquely identifies the exposure position at the given moment. Implicit FK to Trade.Instrument. NONCLUSTERED index key. |
| 3 | OccurredAt | datetime | NO | - | CODE-BACKED | Timestamp of this open position snapshot (NOT NULL - mandatory). Used for time-series ordering in Hedge.CustomerOpenPositions and for interval-based archival to History. |
| 4 | UnrealizedPL | decimal(14,4) | YES | - | CODE-BACKED | Unrealized profit/loss for all open customer positions on this instrument via this server, in USD. Positive = customers in profit (hedge mark-to-market loss), negative = customers at a loss (hedge mark-to-market gain). |
| 5 | OpenBuyUnits | int | YES | - | CODE-BACKED | Total units of long (buy) customer positions open on this instrument via this server. Used to calculate net exposure direction. |
| 6 | OpenSellUnits | int | YES | - | CODE-BACKED | Total units of short (sell) customer positions open on this instrument via this server. Net exposure = OpenBuyUnits - OpenSellUnits. |
| 7 | PriceRateID | bigint | YES | - | CODE-BACKED | Market price rate snapshot ID used to compute UnrealizedPL in this row. Links to the rate table for retrospective price verification and slippage analysis. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | Implicit | Identifies the hedge server that generated this open position snapshot |
| InstrumentID | Trade.Instrument | Implicit | Identifies the trading instrument the positions are on |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InsertOpenPositionBulk | @OpenPositions parameter | TVP parameter | Receives bulk open position snapshots for insert into Hedge.CustomerOpenPositions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf TVP type).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InsertOpenPositionBulk | Stored Procedure | Receives memory-optimized TVP with open position snapshots for bulk insert |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IDX_OpenPositions | NONCLUSTERED | HedgeServerID ASC, InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MEMORY_OPTIMIZED | Storage | TVP lives entirely in DRAM - eliminates disk I/O for high-frequency parameter passing |

---

## 8. Sample Queries

### 8.1 View latest open position snapshots
```sql
SELECT TOP 20 HedgeServerID, InstrumentID, OccurredAt,
       OpenBuyUnits, OpenSellUnits, UnrealizedPL
FROM [Hedge].[CustomerOpenPositions] WITH (NOLOCK)
ORDER BY OccurredAt DESC
```

### 8.2 Calculate net exposure by server and instrument
```sql
SELECT HedgeServerID, InstrumentID,
       MAX(OccurredAt) AS LatestSnapshot,
       OpenBuyUnits - OpenSellUnits AS NetExposureUnits,
       UnrealizedPL
FROM [Hedge].[CustomerOpenPositions] WITH (NOLOCK)
WHERE OccurredAt = (SELECT MAX(OccurredAt)
                    FROM [Hedge].[CustomerOpenPositions] WITH (NOLOCK))
ORDER BY ABS(OpenBuyUnits - OpenSellUnits) DESC
```

### 8.3 Declare and use the TVP for bulk insert
```sql
DECLARE @Positions [Hedge].[OpenPositionsBulkParameters]
INSERT INTO @Positions VALUES (1, 100, GETUTCDATE(), -500.25, 10000, 8000, 987654321)

EXEC [Hedge].[InsertOpenPositionBulk] @OpenPositions = @Positions
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | Hedge Cost system: CustomerPL computed from Rate + Exposure data; CustomerOpenPositions snapshots feed the UnrealizedPL calculation in the INSight HedgeCost flow |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.OpenPositionsBulkParameters | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.OpenPositionsBulkParameters.sql*
