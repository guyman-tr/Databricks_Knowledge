# Trade.HedgeEditStopLost

> Updates the stop-loss rate on a live hedge position in Trade.Hedge, used by the hedge server to adjust the stop-loss level of an open broker-side hedge.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeID, @StopRate; Updates: Trade.Hedge.StopRate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeEditStopLost updates the StopRate column on a specific hedge in Trade.Hedge. When the hedge server needs to adjust the stop-loss level for a broker-side hedge position (e.g., when the corresponding customer position's stop-loss is moved), it calls this procedure to keep the hedge's stop rate in sync.

This procedure exists because hedge positions at liquidity providers can have their stop-loss levels modified after initial placement. The name "StopLost" is a legacy typo (should be "StopLoss") that has been preserved for backward compatibility with hedge server integrations.

---

## 2. Business Logic

### 2.1 Stop-Loss Rate Update

**What**: Simple single-column update on Trade.Hedge.

**Rules**:
- UPDATE Trade.Hedge SET StopRate = @StopRate WHERE HedgeID = @HedgeID
- No validation, no transaction, no error handling
- If HedgeID does not exist: UPDATE affects 0 rows silently (no error raised)
- Returns 0 always

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INTEGER | NO | - | CODE-BACKED | ID of the hedge to update. Must exist in Trade.Hedge; if not found, the UPDATE silently affects 0 rows. |
| 2 | @StopRate | dtPrice | NO | - | CODE-BACKED | New stop-loss rate for the hedge position. Stored in Trade.Hedge.StopRate. dtPrice is a user-defined decimal type for price values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeID, @StopRate | Trade.Hedge | UPDATE | Updates StopRate for the specified hedge |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server (external) | - | Called by external system | Hedge server calls this when adjusting stop-loss on an open hedge |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeEditStopLost (procedure)
+-- Trade.Hedge (table) [leaf - UPDATE StopRate]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Hedge | Table | UPDATE StopRate WHERE HedgeID=@HedgeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Server (external) | External caller | Adjusts stop-loss on broker-side hedge positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Note: procedure name "StopLost" is a legacy typo for "StopLoss" - preserved for backward compatibility.

---

## 8. Sample Queries

### 8.1 Update stop-loss on a hedge

```sql
EXEC Trade.HedgeEditStopLost @HedgeID = 12345, @StopRate = 1.07500;
```

### 8.2 Verify the update

```sql
SELECT HedgeID, StopRate, LimitRate, InstrumentID, IsBuy, Amount
FROM Trade.Hedge WITH (NOLOCK)
WHERE HedgeID = 12345;
```

### 8.3 Compare stop rates between positions and their hedges

```sql
SELECT
    p.PositionID, p.StopRate AS PositionStopRate,
    h.HedgeID, h.StopRate AS HedgeStopRate
FROM Trade.Position p WITH (NOLOCK)
INNER JOIN Trade.Hedge h WITH (NOLOCK) ON p.HedgeID = h.HedgeID
WHERE p.CID = 99999;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeEditStopLost | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeEditStopLost.sql*
