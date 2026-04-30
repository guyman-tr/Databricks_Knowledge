# Trade.DetachPositionsFromMirrorTree

> Memory-optimized TVP carrying tree-level risk parameters during mirror position detach operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | TreeID |
| **Partition** | N/A |
| **Indexes** | 1 (NONCLUSTERED HASH on TreeID) |

---

## 1. Business Meaning

This User Defined Type is a memory-optimized table-valued parameter (TVP) that carries tree-level risk and fee metadata when copy-trade relationships are being detached. It operates in the context of mirror (copy-trade) detachment alongside position-level (Trade.DetachPositionsFromMirrorPosition) and mirror-level data.

During detachment, the tree's risk parameters must be preserved or transferred. StopLoss and TakeProfit are rate-based price thresholds. IsTslEnabled indicates whether trailing stop loss is active. IsDiscounted flags positions with discounted fee arrangements. IsNoStopLoss and IsNoTakeProfit are override flags that disable risk limits when set.

---

## 2. Business Logic

### 2.1 Tree-level risk parameter transfer

**What**: When a copy-trade relationship is detached, the position tree retains its risk settings (SL, TP, TSL). This TVP passes tree-scoped values to the detach procedure.

**Columns/Parameters Involved**: TreeID, StopLoss, TakeProfit, TrailingStopLossThreshold, IsTslEnabled, IsNoStopLoss, IsNoTakeProfit

**Rules**: StopLoss and TakeProfit are rate-based. IsTslEnabled=1 means trailing stop is active. IsNoStopLoss/IsNoTakeProfit bypass standard risk enforcement.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TreeID | bigint | Yes | - | 10 | Position tree identifier |
| 2 | StopLoss | decimal(16,8) | Yes | - | 10 | Rate-based stop loss threshold |
| 3 | StopLossVersion | smallint | Yes | - | 10 | Version of stop loss logic |
| 4 | StopLossVersionTimestamp | datetime | Yes | - | 10 | Timestamp of SL version change |
| 5 | TakeProfit | decimal(16,8) | Yes | - | 10 | Rate-based take profit threshold |
| 6 | TrailingStopLossThreshold | decimal(16,8) | Yes | - | 10 | TSL activation threshold |
| 7 | IsTslEnabled | tinyint | Yes | - | 10 | 1=trailing stop loss enabled |
| 8 | IsDiscounted | bit | Yes | - | 10 | Discounted fee arrangement |
| 9 | IsNoStopLoss | bit | Yes | - | 10 | Override to disable stop loss |
| 10 | IsNoTakeProfit | bit | Yes | - | 10 | Override to disable take profit |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Trade.PositionTreeInfo (TreeID) | Implicit reference to tree |
| Trade.PositionTbl | Tree positions |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.DetachPositionsFromMirror | Local variable @DetachPositionsFromMirrorTree |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Trade.DetachPositionsFromMirror

---

## 7. Technical Details

### 7.1 Indexes

| Name | Type | Columns |
|------|------|---------|
| IDX | NONCLUSTERED HASH | TreeID (BUCKET_COUNT = 1) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for detach

```sql
DECLARE @DetachPositionsFromMirrorTree Trade.DetachPositionsFromMirrorTree;
INSERT INTO @DetachPositionsFromMirrorTree (TreeID, StopLoss, TakeProfit, IsTslEnabled, IsDiscounted, IsNoStopLoss, IsNoTakeProfit)
VALUES (12345, 100.5, 105.2, 1, 0, 0, 0);
EXEC Trade.DetachPositionsFromMirror @DetachPositionsFromMirrorTree = @DetachPositionsFromMirrorTree, ...;
```

### 8.2 Multi-tree batch insert

```sql
DECLARE @Trees Trade.DetachPositionsFromMirrorTree;
INSERT INTO @Trees (TreeID, StopLoss, TakeProfit, TrailingStopLossThreshold, IsTslEnabled)
SELECT TreeID, StopLoss, TakeProfit, TrailingStopLossThreshold, IsTslEnabled
FROM Trade.PositionTreeInfo
WHERE TreeID IN (1, 2, 3);
```

### 8.3 Check TVP structure

```sql
SELECT c.name, t.name AS data_type, c.max_length
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'DetachPositionsFromMirrorTree';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure reference)*
*Sources: DDL, Trade.DetachPositionsFromMirror procedure*
*Object: Trade.DetachPositionsFromMirrorTree | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.DetachPositionsFromMirrorTree.sql*
