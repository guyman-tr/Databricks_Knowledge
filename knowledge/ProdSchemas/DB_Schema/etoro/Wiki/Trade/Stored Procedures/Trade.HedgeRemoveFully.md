# Trade.HedgeRemoveFully

> Cursor loop that calls Trade.HedgeRemove for hedges in Trade.Hedge that DO have linked Trade.Position records. Removes hedges WITH positions - used for forced cleanup when both hedge and position linkage must be severed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @FailTypeID, @FailReason; Iterates: Trade.Hedge WHERE linked Position EXISTS; Calls: Trade.HedgeRemove per hedge |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeRemoveFully removes hedges that are still **fully linked to positions**: live hedges in Trade.Hedge where at least one Trade.Position row references them via HedgeID. These are the "real" live hedges actively covering customer exposure.

This is the complement of Trade.HedgeRemoveDiff (which removes orphaned hedges with NO positions). Together:
- HedgeRemoveDiff: orphaned hedges (hedge exists, no position) -> cleanup
- HedgeRemoveFully: linked hedges (hedge exists WITH positions) -> forced teardown

Calling this procedure means forcibly unwinding hedges that are still active, which will cause Trade.HedgeRemove to SET HedgeID=NULL on those positions. Use with caution: this leaves positions unhedged.

**Important quirk**: Same @FailReasonID omission defect as HedgeRemoveAll and HedgeRemoveDiff.

---

## 2. Business Logic

### 2.1 Linked Hedge Enumeration

**What**: Find hedges with linked positions and remove them.

**Rules**:
- Cursor: `SELECT HedgeID FROM Trade.Hedge THDG WHERE EXISTS (SELECT * FROM Trade.Position TPOS WHERE TPOS.HedgeID = THDG.HedgeID)`
- For each HedgeID: `EXEC Trade.HedgeRemove @HedgeID, @FailTypeID, @FailReason`
- Failures silently ignored; loop continues.
- Returns 0 always.
- Trade.HedgeRemove will UPDATE Trade.Position SET HedgeID=NULL for each removed hedge.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FailTypeID | INTEGER | NO | - | CODE-BACKED | Failure type code for History.HedgeFail entries. |
| 2 | @FailReason | VARCHAR(MAX) | NO | - | CODE-BACKED | Reason text for History.HedgeFail entries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (cursor source) | Trade.Hedge | SELECT (cursor) | Enumerates all live hedges |
| (EXISTS filter) | Trade.Position | Subquery | Includes ONLY hedges that have linked positions |
| @HedgeID | Trade.HedgeRemove | EXEC per cursor row | Delegates removal (includes Position HedgeID=NULL update) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server (external) | - | Called by external system | Forced teardown of all active hedges |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeRemoveFully (procedure)
+-- Trade.Hedge (table) [cursor SELECT]
+-- Trade.Position (view) [EXISTS subquery filter]
+-- Trade.HedgeRemove (procedure) [EXEC per HedgeID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Hedge | Table | Cursor source - all live hedges |
| Trade.Position | View | EXISTS filter - hedges with linked positions |
| Trade.HedgeRemove | Procedure | Called for each linked HedgeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Server (external) | External caller | Forced hedge teardown |

---

## 7. Technical Details

N/A. CURSOR (READ_ONLY FORWARD_ONLY STATIC). Known defect: missing @FailReasonID argument in HedgeRemove call.

---

## 8. Sample Queries

### 8.1 Preview linked hedges before removal

```sql
SELECT THDG.HedgeID, THDG.InstrumentID, THDG.HedgeServerID, THDG.Amount,
       COUNT(TPOS.PositionID) AS LinkedPositions
FROM Trade.Hedge THDG WITH (NOLOCK)
JOIN Trade.Position TPOS WITH (NOLOCK) ON TPOS.HedgeID = THDG.HedgeID
GROUP BY THDG.HedgeID, THDG.InstrumentID, THDG.HedgeServerID, THDG.Amount;
```

### 8.2 Remove all linked hedges (CAUTION: leaves positions unhedged)

```sql
EXEC Trade.HedgeRemoveFully
    @FailTypeID = 6,
    @FailReason = 'Emergency hedge teardown - broker disconnect';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 7/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.HedgeRemove) | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeRemoveFully | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeRemoveFully.sql*
