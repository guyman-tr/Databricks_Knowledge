# Trade.CloseManualPositionByInitRate

> Closes a position and all its copy-trade children at their respective init rates (zero PnL), used for recovery scenarios. Validates the position is not a mirror/copy-trade, then recursively traverses the position tree closing each child individually via Trade.ManualPositionClose.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (root position to close) |
| **Partition** | PositionPartitionCol = @PositionID % 50 |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CloseManualPositionByInitRate is a recovery procedure that closes a position at its original opening rate (InitForexRate), producing zero profit or loss. After closing the root position, it recursively finds all child positions in the copy-trade tree and closes each of them at their own InitForexRate. This is used when a position needs to be unwound without financial impact — typically in error recovery or regulatory reversal scenarios.

The procedure uses ActionType=10 (Hierarchical close by recovery) and sets price rate IDs to -1 (indicating these are synthetic closures, not real market closures). It validates that the target position is not part of a mirror/copy relationship (MirrorID must be 0) — if it is a mirror position, error 60122 is raised.

Any child positions that fail to close are tracked in a temp table with their error codes and messages, returned as the result set so operators can investigate failures.

---

## 2. Business Logic

### 2.1 Zero-PnL Close at Init Rate

**What**: Closes each position at its InitForexRate, guaranteeing zero profit/loss.

**Rules**:
- EndForexRate = InitForexRate (from Trade.Position for each position)
- ActionType = 10 (Hierarchical close by recovery)
- All rate IDs set to -1 (synthetic, no real price snapshot)
- UseLastOpConversionRate = 0

### 2.2 Mirror Position Validation

**What**: Blocks closure of mirror/copy-trade positions.

**Rules**:
- If position not found (IsBuy IS NULL): RAISERROR 60121
- If MirrorID ≠ 0: RAISERROR 60122 (cannot close mirror positions this way)

### 2.3 Recursive Tree Traversal

**What**: Finds all child positions in the copy-trade tree using a recursive CTE.

**Rules**:
- Anchor: positions where ParentPositionID = @PositionID AND StatusID = 1 (open)
- Recurse: join PositionTbl.ParentPositionID to PositionID of already-found children
- Each child closed individually in a WHILE loop
- Errors per child are captured (ErrorCode, FailReason) and reported at the end

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | VERIFIED | Root position to close at init rate. Must not be a mirror position. All children in the tree will also be closed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Position | SELECT | Reads root position data (IsBuy, InitForexRate, etc.) |
| FROM | Trade.CurrencyPrice | SELECT | Gets skew value for the instrument |
| FROM | Trade.PositionTbl | SELECT (recursive CTE) | Traverses copy-trade tree to find all children |
| EXEC | Trade.ManualPositionClose | EXEC | Closes each position at its init rate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found in SSDT) | - | - | Called from admin/DBA tools for recovery |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CloseManualPositionByInitRate (procedure)
+-- Trade.Position (view)
+-- Trade.CurrencyPrice (table)
+-- Trade.PositionTbl (table) [recursive CTE]
+-- Trade.ManualPositionClose (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT - root position data |
| Trade.CurrencyPrice | Table | SELECT - skew values |
| Trade.PositionTbl | Table | SELECT - recursive tree traversal |
| Trade.ManualPositionClose | Procedure | EXEC - closes each position |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT) | - | Called from admin layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Not a mirror position | Validation | MirrorID ≠ 0 → RAISERROR 60122 |
| Position exists | Validation | IsBuy IS NULL → RAISERROR 60121 |
| Error tracking | Resilience | Child close failures captured, not re-thrown |

---

## 8. Sample Queries

### 8.1 Preview the copy-trade tree to be closed

```sql
WITH Tree AS (
    SELECT PositionID, ParentPositionID, InitForexRate
    FROM   Trade.PositionTbl WITH (NOLOCK)
    WHERE  ParentPositionID = 12345 AND StatusID = 1
    UNION ALL
    SELECT t.PositionID, t.ParentPositionID, t.InitForexRate
    FROM   Trade.PositionTbl t WITH (NOLOCK)
    JOIN   Tree ON t.ParentPositionID = Tree.PositionID AND t.StatusID = 1
)
SELECT * FROM Tree;
```

### 8.2 Execute recovery close

```sql
EXEC Trade.CloseManualPositionByInitRate @PositionID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CloseManualPositionByInitRate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CloseManualPositionByInitRate.sql*
