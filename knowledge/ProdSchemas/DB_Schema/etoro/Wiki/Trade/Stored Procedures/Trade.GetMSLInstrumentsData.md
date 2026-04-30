# Trade.GetMSLInstrumentsData

> Returns distinct (InstrumentID, MirrorIDModDivder) combinations for active copy-trade positions, partitioned by a modulus divisor, used by the Mirror Stop-Loss calculation engine to enumerate instrument exposure per mirror shard.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ModDivder - defines the partition shard count for MSL processing |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMSLInstrumentsData` is one of three MSL (Mirror Stop-Loss) data-feed procedures (with `GetMSLMirrorData` and `GetMSLPositionData`). It returns the distinct set of `(InstrumentID, MirrorIDModDivder)` combinations across all active copy positions in active mirrors. The `MirrorIDModDivder` column is `MirrorID % @ModDivder`, which bins mirrors into shards for parallel processing.

The MSL engine calculates each mirror's current loss and checks if it exceeds the `MirrorSLPercentage` threshold. To process millions of positions across thousands of mirrors efficiently, the engine divides work into shards using modular arithmetic. This procedure provides the instrument inventory needed to fetch current prices for PnL calculation.

Data flows: Called by the MSL calculation service. The result is used to determine which instruments need current price data for the PnL calculation pass across each mirror shard.

---

## 2. Business Logic

### 2.1 Mirror Shard Partitioning

**What**: Mirrors are partitioned into N shards using MirrorID modulo arithmetic for parallel MSL processing.

**Columns/Parameters Involved**: `@ModDivder`, `MirrorIDModDivder`

**Rules**:
- `@ModDivder`: Total number of shards (e.g., 10 = split into 10 buckets: 0 through 9).
- `MirrorID % @ModDivder` = the shard bucket for each mirror.
- This result (`MirrorIDModDivder`) is returned so the caller can correlate the instrument data to the mirror shard when calling `GetMSLMirrorData` and `GetMSLPositionData` with the same divisor and specific `@ModResult`.
- Grouping: `GROUP BY InstrumentID, MirrorID % @ModDivder` - one row per instrument per shard.

### 2.2 MSL Data Feed Set

**What**: GetMSLInstrumentsData is part of a 3-procedure set for Mirror Stop-Loss calculation.

**Rules**:
- `GetMSLInstrumentsData(@ModDivder)`: Instrument inventory per shard (this procedure).
- `GetMSLMirrorData(@ModDivder, @ModResult)`: Mirror amounts + SL thresholds for shard = @ModResult.
- `GetMSLPositionData(@ModDivder, @ModResult)`: Position data (amounts, rates) for shard = @ModResult.
- All three use the same @ModDivder to ensure consistent partitioning.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ModDivder | INT | NO | - | CODE-BACKED | The modulus divisor defining how many shards to split mirrors into. MirrorID % @ModDivder determines which shard each mirror belongs to. |

**Output columns** (result set):

| # | Column | Description |
|---|--------|-------------|
| 1 | InstrumentID | The instrument identifier. Each distinct instrument present in active copy positions in this shard. |
| 2 | MirrorIDModDivder | MirrorID % @ModDivder - the shard number this instrument-mirror combination belongs to. Used to correlate with GetMSLMirrorData/GetMSLPositionData results for the same shard. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| pos.MirrorID | Trade.PositionTbl | Primary read | Source of copy positions (ParentPositionID>0, StatusID=1). |
| pos.MirrorID | Trade.Mirror | JOIN | Filters to active mirrors (IsActive=1). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMSLInstrumentsData (procedure)
├── Trade.PositionTbl (table)
└── Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Source of open copy positions - JOIN with Mirror for active filter |
| Trade.Mirror | Table | INNER JOIN on MirrorID WHERE IsActive=1 - restricts to active mirrors |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get instrument shard data for 10 shards

```sql
EXEC Trade.GetMSLInstrumentsData @ModDivder = 10;
```

### 8.2 Get instruments for a specific shard directly

```sql
SELECT DISTINCT pos.InstrumentID
FROM Trade.PositionTbl pos WITH (NOLOCK)
INNER JOIN Trade.Mirror tm WITH (NOLOCK) ON pos.MirrorID = tm.MirrorID
WHERE pos.ParentPositionID > 0
  AND pos.MirrorID > 0
  AND pos.StatusID = 1
  AND tm.IsActive = 1
  AND pos.MirrorID % 10 = 3; -- Shard 3 of 10
```

### 8.3 Count instruments per shard

```sql
SELECT
    pos.MirrorID % 10 AS Shard,
    COUNT(DISTINCT pos.InstrumentID) AS InstrumentCount
FROM Trade.PositionTbl pos WITH (NOLOCK)
INNER JOIN Trade.Mirror tm WITH (NOLOCK) ON pos.MirrorID = tm.MirrorID
WHERE pos.ParentPositionID > 0
  AND pos.MirrorID > 0
  AND pos.StatusID = 1
  AND tm.IsActive = 1
GROUP BY pos.MirrorID % 10
ORDER BY Shard;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMSLInstrumentsData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMSLInstrumentsData.sql*
