# Trade.GetOpenPositions

> Returns all open positions eligible for hedge computation, with precision-adjusted spread values - used by the hedge engine to load its working set of positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns all eligible positions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOpenPositions` returns the full set of open positions that are actively tracked by the hedge engine (`IsComputeForHedge = 1`), joined with the corresponding provider-instrument configuration to apply the correct price precision. The spread values (`SpreadedPipBid`, `SpreadedPipAsk`) are divided by `POWER(10, Precision)` to convert from raw integer storage to decimal pip values.

**WHY:** The hedge engine needs to know every live position it is responsible for hedging: which server, which instrument, direction, stop/limit levels, lot count, and current spread. This SP is the single point that loads that working set. The `IsComputeForHedge = 1` flag means the position's risk exposure must be offset by a hedge. The `Enabled = 1` filter on ProviderToInstrument ensures the instrument is still active in the current provider routing.

**HOW:** Called at startup or on refresh by the hedge computation service to reload its in-memory position state. Returns all rows - no pagination, no partitioning. Uses `NOLOCK` on both tables for maximum read throughput in a high-frequency context.

---

## 2. Business Logic

### 2.1 Hedge-Eligible Position Filter

**What:** Only positions with `IsComputeForHedge = 1` are returned. This flag is set on positions whose exposure must be managed by the hedge engine (typically retail CFD positions, as opposed to paper/demo positions).

**Columns/Parameters Involved:** `IsComputeForHedge`, `Trade.ProviderToInstrument.Enabled`

**Rules:**
- `IsComputeForHedge = 1` -> position is in scope for hedging (set on PositionTbl at open time)
- `ProviderToInstrument.Enabled = 1` -> the instrument is currently active for the provider
- No status filter is applied here - the Position view (not PositionTbl) already filters to open positions (StatusID=1)
- A commented-out filter `-- and a.InstrumentID < 1000` suggests historical debugging; ignored now

### 2.2 Spread Precision Normalization

**What:** Raw spread values stored in `Trade.Position` are integers scaled by precision. Dividing by `POWER(10, Precision)` converts to the human-readable pip/tick decimal value.

**Columns/Parameters Involved:** `SpreadedPipBid`, `SpreadedPipAsk`, `Trade.ProviderToInstrument.Precision`

**Rules:**
- `SpreadedPipBid / POWER(10, Precision)` -> normalized bid spread in pips
- `SpreadedPipAsk / POWER(10, Precision)` -> normalized ask spread in pips
- `Precision` comes from `Trade.ProviderToInstrument` which holds the instrument's decimal places

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns (from Trade.Position JOIN Trade.ProviderToInstrument):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | HedgeServerID | int | YES | - | CODE-BACKED | The hedge server responsible for offsetting this position's exposure. Used by hedge engine to route hedging instructions. |
| R2 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument being traded. Used to group exposures by instrument for aggregated hedging. |
| R3 | IsBuy | bit | NO | - | CODE-BACKED | Direction flag: 1=long (buy), 0=short (sell). Hedge engine aggregates buy and sell separately to compute net exposure. |
| R4 | LimitRate | money | YES | - | CODE-BACKED | Take-profit rate. Hedge engine uses this to monitor open order conditions. |
| R5 | StopRate | money | YES | - | CODE-BACKED | Stop-loss rate. Hedge engine uses this to monitor open order conditions. |
| R6 | LotCountDecimal | decimal | YES | - | CODE-BACKED | Position size in lots (decimal precision). Core metric for computing hedge lot quantities. |
| R7 | SpreadedPipBid | decimal | YES | - | CODE-BACKED | Precision-normalized bid spread (SpreadedPipBid / POWER(10, Precision)). Used by hedge engine for spread accounting. |
| R8 | SpreadedPipAsk | decimal | YES | - | CODE-BACKED | Precision-normalized ask spread (SpreadedPipAsk / POWER(10, Precision)). Used by hedge engine for spread accounting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IsComputeForHedge filter | Trade.Position | Direct query | SELECT with IsComputeForHedge=1 filter - only hedge-eligible positions |
| InstrumentID JOIN | Trade.ProviderToInstrument | INNER JOIN | Gets Precision and Enabled flag for each position's instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge computation service | N/A | CALLER | Loads full hedge-eligible position set at startup or refresh |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenPositions (procedure)
├── Trade.Position (view)
└── Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT position data WHERE IsComputeForHedge=1 AND ProviderToInstrument.Enabled=1 |
| Trade.ProviderToInstrument | Table | INNER JOIN on InstrumentID to get Precision and Enabled flag |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge computation service | External | Loads hedge position working set |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Hint:** Both tables use `WITH (NOLOCK)` for high-throughput read performance. This is appropriate for a read-only snapshot used by the hedge engine.

---

## 8. Sample Queries

### 8.1 Load all hedge-eligible positions
```sql
EXEC Trade.GetOpenPositions
```

### 8.2 Manual equivalent - check hedge positions by instrument
```sql
SELECT a.HedgeServerID, a.InstrumentID, a.IsBuy, a.LimitRate, a.StopRate,
       a.LotCountDecimal,
       a.SpreadedPipBid / POWER(10, b.[Precision]) AS SpreadedPipBid,
       a.SpreadedPipAsk / POWER(10, b.[Precision]) AS SpreadedPipAsk
FROM   Trade.Position a WITH (NOLOCK)
       INNER JOIN Trade.ProviderToInstrument b WITH (NOLOCK) ON a.InstrumentID = b.InstrumentID
WHERE  a.IsComputeForHedge = 1
AND    b.Enabled = 1
```

### 8.3 Count hedge-eligible positions by instrument
```sql
SELECT a.InstrumentID, COUNT(*) AS PositionCount,
       SUM(CASE WHEN a.IsBuy = 1 THEN a.LotCountDecimal ELSE 0 END) AS BuyLots,
       SUM(CASE WHEN a.IsBuy = 0 THEN a.LotCountDecimal ELSE 0 END) AS SellLots
FROM   Trade.Position a WITH (NOLOCK)
       INNER JOIN Trade.ProviderToInstrument b WITH (NOLOCK) ON a.InstrumentID = b.InstrumentID
WHERE  a.IsComputeForHedge = 1 AND b.Enabled = 1
GROUP  BY a.InstrumentID
ORDER  BY PositionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenPositions.sql*
