# Trade.HedgeRemoveDiff

> Cursor loop that calls Trade.HedgeRemove for hedges in Trade.Hedge that have NO linked Trade.Position records. Removes "orphaned" hedges (hedges without positions) during reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @FailTypeID, @FailReason; Iterates: Trade.Hedge WHERE no linked Position; Calls: Trade.HedgeRemove per hedge |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeRemoveDiff removes **orphaned hedges**: live hedges in Trade.Hedge that no longer have any associated customer position (no Trade.Position row with HedgeID = that hedge's ID). These orphaned hedges can arise when positions are closed or cleaned up separately from their hedge linkages, leaving dangling hedge rows.

The "Diff" name refers to the difference between hedges and positions: hedges that exist but have no matching position represent a discrepancy. This procedure resolves that discrepancy by removing the orphaned hedge side.

**Important quirk**: Calls Trade.HedgeRemove with only 3 arguments but current Trade.HedgeRemove requires 4 (@FailReasonID has no default). Same defect as HedgeRemoveAll and HedgeRemoveFully.

---

## 2. Business Logic

### 2.1 Orphaned Hedge Enumeration

**What**: Find hedges with no linked positions and remove them.

**Rules**:
- Cursor: `SELECT HedgeID FROM Trade.Hedge THDG WHERE NOT EXISTS (SELECT * FROM Trade.Position TPOS WHERE TPOS.HedgeID = THDG.HedgeID)`
- For each HedgeID: `EXEC Trade.HedgeRemove @HedgeID, @FailTypeID, @FailReason`
- Failures silently ignored; loop continues.
- Returns 0 always.

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
| (NOT EXISTS filter) | Trade.Position | Subquery | Excludes hedges that have linked positions |
| @HedgeID | Trade.HedgeRemove | EXEC per cursor row | Delegates removal to core procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server (external) | - | Called by external system | Reconciliation cleanup of orphaned hedges |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeRemoveDiff (procedure)
+-- Trade.Hedge (table) [cursor SELECT]
+-- Trade.Position (view) [NOT EXISTS subquery filter]
+-- Trade.HedgeRemove (procedure) [EXEC per HedgeID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Hedge | Table | Cursor source - all live hedges |
| Trade.Position | View | NOT EXISTS filter - hedges without linked positions |
| Trade.HedgeRemove | Procedure | Called for each orphaned HedgeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Server (external) | External caller | Reconciliation to clean orphaned hedges |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses CURSOR (READ_ONLY FORWARD_ONLY STATIC). Known defect: missing @FailReasonID argument in HedgeRemove call.

---

## 8. Sample Queries

### 8.1 Preview orphaned hedges before removal

```sql
SELECT THDG.HedgeID, THDG.InstrumentID, THDG.HedgeServerID, THDG.Amount, THDG.IsBuy
FROM Trade.Hedge THDG WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Trade.Position TPOS WITH (NOLOCK) WHERE TPOS.HedgeID = THDG.HedgeID
);
```

### 8.2 Remove orphaned hedges

```sql
EXEC Trade.HedgeRemoveDiff
    @FailTypeID = 5,
    @FailReason = 'Reconciliation: hedge has no associated positions';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 7/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.HedgeRemove) | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeRemoveDiff | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeRemoveDiff.sql*
