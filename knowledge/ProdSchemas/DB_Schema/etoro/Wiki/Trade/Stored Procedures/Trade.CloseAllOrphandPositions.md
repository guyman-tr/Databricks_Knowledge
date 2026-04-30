# Trade.CloseAllOrphandPositions

> Identifies and closes orphaned demo-environment positions whose parent positions no longer exist in the Real environment, using the parent's historical closing rate to match the original close conditions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters - processes all orphaned positions) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CloseAllOrphandPositions is a Demo-environment cleanup procedure that identifies and closes "orphaned" positions — demo positions whose parent (Real environment) position has been closed. In the copy-trade architecture, demo positions mirror real positions. When a real position is closed, the corresponding demo position should also be closed, but occasionally this synchronization fails, leaving orphans.

The procedure:
1. Validates it's running in Demo (FeatureID 22 ≠ 1), blocking Real environment execution
2. Finds all open demo positions with a ParentPositionID ≠ 0 (copied positions)
3. Gets the list of currently open real positions via `GetRealPositionsWithNoLock`
4. Removes from the list any demo positions whose parent still exists in Real
5. For remaining orphans, reconstructs the parent's closing Bid/Ask from RealHistoryPosition
6. Closes each orphan via Trade.ManualPositionClose_Crisis at the parent's closing rate
7. Logs each close to History.OrphanPositionsCloseByJob

Error 60004 is silently caught per position (position already closed by another process).

---

## 2. Business Logic

### 2.1 Orphan Detection

**What**: Finds demo positions whose real parent is no longer open.

**Rules**:
- All open demo positions with ParentPositionID ≠ 0 and StatusID = 1
- LEFT JOIN to real positions (GetRealPositionsWithNoLock)
- Orphans = where real parent NOT found
- If no orphans exist → RETURN immediately

### 2.2 Rate Reconstruction from History

**What**: Reconstructs bid/ask from the parent's historical close data.

**Rules**:
- For buy positions: Bid = EndForexRate, Ask = EndForexRate + FullCommission/(Units × ConversionRate)
- For sell positions: Ask = EndForexRate, Bid = EndForexRate - FullCommission/(Units × ConversionRate)
- Source: RealHistoryPosition (linked server view/synonym to Real environment history)
- Optimizes by caching rates per ParentPositionID (skip recalculation for same parent)

### 2.3 Demo-Only Guard

**What**: Prevents accidental execution in Real environment.

**Rules**:
- Maintenance.Feature FeatureID=22 value=1 → RAISERROR (Real environment)
- Only runs in Demo environment

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.PositionTbl | SELECT | Finds open demo positions with parents |
| FROM | Maintenance.Feature | SELECT | Validates Demo environment |
| EXEC | GetRealPositionsWithNoLock | EXEC | Gets real-environment open position IDs |
| FROM | RealHistoryPosition | SELECT | Reconstructs parent's closing rates |
| EXEC | Trade.ManualPositionClose_Crisis | EXEC | Closes each orphan position |
| INSERT | History.OrphanPositionsCloseByJob | INSERT | Audit log for orphan closes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found in SSDT) | - | - | Called by scheduled cleanup job in Demo |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CloseAllOrphandPositions (procedure)
+-- Trade.PositionTbl (table)
+-- Maintenance.Feature (table)
+-- GetRealPositionsWithNoLock (procedure/linked)
+-- RealHistoryPosition (view/synonym to Real)
+-- Trade.ManualPositionClose_Crisis (procedure)
+-- History.OrphanPositionsCloseByJob (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT - find demo positions |
| Maintenance.Feature | Table | SELECT - environment check |
| GetRealPositionsWithNoLock | Procedure | EXEC - get real positions |
| RealHistoryPosition | View/Synonym | SELECT - parent close history |
| Trade.ManualPositionClose_Crisis | Procedure | EXEC - close orphans |
| History.OrphanPositionsCloseByJob | Table | INSERT - audit log |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT) | - | Scheduled job |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Demo-only | Safety | FeatureID 22 = 1 → RAISERROR |
| Error 60004 | Skip | Position already closed — silently caught |
| NULL rate check | Safety | Only closes if @Bid and @Ask are both NOT NULL |

---

## 8. Sample Queries

### 8.1 Preview orphaned positions (Demo only)

```sql
SELECT  p.PositionID, p.ParentPositionID
FROM    Trade.PositionTbl p WITH (NOLOCK)
WHERE   p.ParentPositionID <> 0
        AND p.StatusID = 1
        AND NOT EXISTS (
            SELECT 1 FROM Trade.PositionTbl r WITH (NOLOCK)
            WHERE r.PositionID = p.ParentPositionID AND r.StatusID = 1
        );
```

### 8.2 Execute orphan cleanup

```sql
EXEC Trade.CloseAllOrphandPositions;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CloseAllOrphandPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CloseAllOrphandPositions.sql*
