# Trade.GetMSLMirrorData

> Returns active mirror financial data (amount and stop-loss threshold in both cents and dollars) for a specific shard partition (MirrorID % @ModDivder = @ModResult), used by the Mirror Stop-Loss calculation engine to check if mirrors have breached their stop-loss.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ModDivder + @ModResult - selects a specific shard of active mirrors |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMSLMirrorData` is the second of three MSL (Mirror Stop-Loss) data-feed procedures. It returns the financial parameters for all active mirrors in a specific shard: the mirror's allocated amount and its stop-loss threshold (`MirrorSL`), expressed in both cents and dollars. The shard is selected by `MirrorID % @ModDivder = @ModResult`.

The MSL calculation engine uses this data to compare each mirror's current equity against its stop-loss threshold. If `RealizedEquity < MirrorSL`, the mirror should be closed. The procedure returns both cent and dollar representations to support different calculation paths (the MSL engine works primarily in cents).

Data flows: Called per-shard by the MSL engine. Paired with `GetMSLPositionData` (same shard parameters) to get the matching position data for PnL calculation.

---

## 2. Business Logic

### 2.1 Mirror Shard Selection

**What**: Returns only the mirrors that belong to a specific shard.

**Columns/Parameters Involved**: `@ModDivder`, `@ModResult`, `MirrorID`

**Rules**:
- `MirrorID % @ModDivder = @ModResult`: Only mirrors whose MirrorID falls in this modulus bucket.
- `IsActive = 1`: Only active mirrors. Inactive/closed mirrors have no open positions to calculate MSL for.
- Example: @ModDivder=10, @ModResult=3 -> returns mirrors where MirrorID ends in 3 (modulo 10).

### 2.2 Dual-Unit Amount Output

**What**: Mirror amount and stop-loss are returned in both cents and dollars.

**Columns/Parameters Involved**: `MirrorAmount`, `MirrorSLAmount`, `MirrorAmountInDollars`, `MirrorSLAmountInDollars`

**Rules**:
- `mr.Amount * 100 AS MirrorAmount`: Amount in cents.
- `mr.MirrorSL * 100 AS MirrorSLAmount`: Stop-loss threshold in cents.
- `mr.Amount AS MirrorAmountInDollars`: Amount in dollars.
- `mr.MirrorSL AS MirrorSLAmountInDollars`: Stop-loss threshold in dollars.
- MSL trigger: when the copier's portfolio value drops below `MirrorSL`, the mirror auto-closes.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ModDivder | TINYINT | NO | - | CODE-BACKED | The total number of shards. Divisor in the modulus calculation (MirrorID % @ModDivder). |
| 2 | @ModResult | TINYINT | NO | - | CODE-BACKED | The shard number to return. Only mirrors where MirrorID % @ModDivder = @ModResult are returned. Range: 0 to @ModDivder-1. |

**Output columns** (result set):

| # | Column | Description |
|---|--------|-------------|
| 1 | MirrorID | The mirror identifier. |
| 2 | MirrorAmount | Current allocated amount in CENTS (Amount * 100). Primary unit for MSL calculation. |
| 3 | MirrorSLAmount | Mirror Stop-Loss threshold in CENTS (MirrorSL * 100). MSL triggers when equity < this value. |
| 4 | MirrorAmountInDollars | Current allocated amount in dollars (Trade.Mirror.Amount). |
| 5 | MirrorSLAmountInDollars | Mirror Stop-Loss threshold in dollars (Trade.Mirror.MirrorSL). NULL = no MSL set. |
| 6 | CID | The copier's customer ID. Used to identify whose mirror to close if MSL is triggered. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ModDivder + @ModResult | Trade.Mirror | Primary read | Reads active mirrors in the specified shard for MSL calculation. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMSLMirrorData (procedure)
└── Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | SELECT MirrorID, Amount, MirrorSL, CID WHERE IsActive=1 AND MirrorID % @ModDivder = @ModResult |

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

### 8.1 Get MSL mirror data for shard 3 of 10

```sql
EXEC Trade.GetMSLMirrorData @ModDivder = 10, @ModResult = 3;
```

### 8.2 Find mirrors close to hitting their stop-loss

```sql
SELECT m.MirrorID, m.CID, m.Amount, m.MirrorSL,
       m.RealizedEquity,
       (m.RealizedEquity - m.MirrorSL) AS MarginAboveMSL
FROM Trade.Mirror m WITH (NOLOCK)
WHERE m.IsActive = 1
  AND m.MirrorSL IS NOT NULL
  AND m.RealizedEquity < m.MirrorSL * 1.1  -- within 10% of MSL
ORDER BY MarginAboveMSL;
```

### 8.3 Get MSL data for a full processing cycle across all shards (pseudocode)

```sql
-- Process all 10 shards sequentially
-- EXEC Trade.GetMSLMirrorData @ModDivder = 10, @ModResult = 0  (shard 0)
-- EXEC Trade.GetMSLMirrorData @ModDivder = 10, @ModResult = 1  (shard 1)
-- ...
-- EXEC Trade.GetMSLMirrorData @ModDivder = 10, @ModResult = 9  (shard 9)
SELECT MirrorID, MirrorAmount, MirrorSLAmount, CID
FROM Trade.Mirror WITH (NOLOCK)
WHERE IsActive = 1
  AND MirrorID % 10 = 3;  -- Example: shard 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMSLMirrorData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMSLMirrorData.sql*
