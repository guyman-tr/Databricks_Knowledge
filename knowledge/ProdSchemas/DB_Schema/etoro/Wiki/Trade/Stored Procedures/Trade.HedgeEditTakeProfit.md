# Trade.HedgeEditTakeProfit

> Updates the take-profit rate on a live hedge position in Trade.Hedge, used by the hedge server to adjust the take-profit level of an open broker-side hedge.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeID, @LimitRate; Updates: Trade.Hedge.LimitRate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeEditTakeProfit updates the LimitRate column on a specific hedge in Trade.Hedge. When the hedge server needs to adjust the take-profit level for a broker-side hedge position, it calls this procedure to keep the hedge's limit rate in sync with any customer-side take-profit changes.

This procedure is the counterpart of Trade.HedgeEditStopLost (stop-loss adjustment). Together they allow the hedge server to maintain stop/limit rates on open hedges without needing to close and reopen the hedge. The naming convention in Trade.Hedge uses "LimitRate" for take-profit (consistent with customer positions where LimitRate = take-profit rate).

---

## 2. Business Logic

### 2.1 Take-Profit Rate Update

**What**: Simple single-column update on Trade.Hedge.LimitRate.

**Rules**:
- UPDATE Trade.Hedge SET LimitRate = @LimitRate WHERE HedgeID = @HedgeID
- No validation, no transaction, no error handling
- If HedgeID does not exist: UPDATE affects 0 rows silently
- Returns 0 always

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INTEGER | NO | - | CODE-BACKED | ID of the hedge to update. Must exist in Trade.Hedge; if not found, the UPDATE silently affects 0 rows. |
| 2 | @LimitRate | dtPrice | NO | - | CODE-BACKED | New take-profit rate for the hedge position. Stored in Trade.Hedge.LimitRate. LimitRate = take-profit rate (consistent naming with Trade.Position.LimitRate). dtPrice is a user-defined decimal type for price values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeID, @LimitRate | Trade.Hedge | UPDATE | Updates LimitRate (take-profit) for the specified hedge |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server (external) | - | Called by external system | Hedge server calls this when adjusting take-profit on an open hedge |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeEditTakeProfit (procedure)
+-- Trade.Hedge (table) [leaf - UPDATE LimitRate]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Hedge | Table | UPDATE LimitRate WHERE HedgeID=@HedgeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Server (external) | External caller | Adjusts take-profit on broker-side hedge positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Symmetric counterpart to Trade.HedgeEditStopLost (which updates StopRate).

---

## 8. Sample Queries

### 8.1 Update take-profit on a hedge

```sql
EXEC Trade.HedgeEditTakeProfit @HedgeID = 12345, @LimitRate = 1.10000;
```

### 8.2 Verify the update

```sql
SELECT HedgeID, LimitRate, StopRate, InstrumentID, IsBuy, Amount
FROM Trade.Hedge WITH (NOLOCK)
WHERE HedgeID = 12345;
```

### 8.3 Compare take-profit rates between positions and their hedges

```sql
SELECT
    p.PositionID, p.LimitRate AS PositionLimitRate,
    h.HedgeID, h.LimitRate AS HedgeLimitRate
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
*Object: Trade.HedgeEditTakeProfit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeEditTakeProfit.sql*
