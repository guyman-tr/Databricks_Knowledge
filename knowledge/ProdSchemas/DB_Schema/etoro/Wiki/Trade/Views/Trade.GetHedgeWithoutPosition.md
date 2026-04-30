# Trade.GetHedgeWithoutPosition

> Returns orphaned hedge records that have no matching open position, indicating potential hedge mismatches or positions that were closed without closing the corresponding hedge.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | HedgeID (from Trade.Hedge) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetHedgeWithoutPosition identifies **orphaned hedges** - hedge records in Trade.Hedge that have no corresponding open position in Trade.Position. In normal operation, every hedge should be linked to one or more open positions via HedgeID. When a position is closed, its hedge should also be closed. If the hedge remains after all linked positions are closed, it represents an exposure leak.

This view is critical for **hedge reconciliation and risk management**. Orphaned hedges mean the system is paying for hedging exposure that no longer exists on the position side, causing unnecessary costs and potentially masking the true exposure picture. Operations teams use this view to identify and manually close orphaned hedges.

The implementation is straightforward: LEFT JOIN Trade.Hedge to Trade.Position ON HedgeID, WHERE Position.HedgeID IS NULL (no matching position).

---

## 2. Business Logic

### 2.1 Orphaned Hedge Detection

**What**: Finds hedges with no matching open position.

**Columns/Parameters Involved**: `HedgeID`, `Trade.Position.HedgeID`

**Rules**:
- LEFT JOIN Trade.Hedge to Trade.Position on HedgeID
- WHERE Trade.Position.HedgeID IS NULL (no open position references this hedge)
- Returns the full hedge record for investigation and cleanup

---

## 3. Data Overview

N/A - diagnostic/operational view. Each row represents an orphaned hedge requiring investigation.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeID | bigint | NO | - | CODE-BACKED | Unique hedge record identifier. No matching open position exists for this hedge. |
| 2 | CurrencyID | int | YES | - | CODE-BACKED | Currency of the hedge. FK to Dictionary.Currency. |
| 3 | ProviderID | int | YES | - | CODE-BACKED | Execution provider for the hedge. FK to Trade.Provider. |
| 4 | InstrumentID | int | YES | - | CODE-BACKED | Financial instrument hedged. FK to Trade.Instrument. |
| 5 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server that executed this hedge. FK to Trade.HedgeServer. |
| 6 | Leverage | int | YES | - | CODE-BACKED | Leverage used in the hedge. |
| 7 | Amount | money | YES | - | CODE-BACKED | Hedge amount in denomination currency. |
| 8 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Hedge amount in units. |
| 9 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count for the hedge. Key metric for exposure impact. |
| 10 | NetProfit | money | YES | - | CODE-BACKED | Current PnL of the orphaned hedge. |
| 11 | InitForexRate | float | YES | - | CODE-BACKED | Forex rate when hedge was opened. |
| 12 | InitDateTime | datetime | YES | - | CODE-BACKED | When the hedge was opened. Useful for determining how long it has been orphaned. |
| 13 | LimitRate | float | YES | - | CODE-BACKED | Take-profit rate on the hedge. |
| 14 | StopRate | float | YES | - | CODE-BACKED | Stop-loss rate on the hedge. |
| 15 | IsBuy | bit | YES | - | CODE-BACKED | Hedge direction: 1=buy, 0=sell. |
| 16 | TradeID | varchar | YES | - | CODE-BACKED | External trade ID from the provider. |
| 17 | AccountID | varchar | YES | - | CODE-BACKED | External account ID on the provider. |
| 18 | RequestOccurred | datetime | YES | - | CODE-BACKED | When the hedge request was made. |
| 19 | Occurred | datetime | YES | - | CODE-BACKED | When the hedge was executed. |
| 20 | ParentTradeID | varchar | YES | - | CODE-BACKED | Parent trade ID for linked hedges. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Trade.Hedge | FROM | Source of orphaned hedge records |
| HedgeID | Trade.Position | LEFT JOIN (NULL) | Anti-join: position does NOT exist |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetHedgeWithoutPosition (view)
+-- Trade.Hedge (table)
+-- Trade.Position (view)
      +-- Trade.PositionTbl (table)
      +-- Trade.PositionTreeInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Hedge | Table | Source of all hedge records |
| Trade.Position | View | Anti-join to find hedges without open positions |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All orphaned hedges

```sql
SELECT HedgeID, InstrumentID, HedgeServerID, IsBuy, LotCountDecimal, InitDateTime
FROM   Trade.GetHedgeWithoutPosition WITH (NOLOCK)
ORDER BY InitDateTime;
```

### 8.2 Total orphaned exposure by instrument

```sql
SELECT InstrumentID, HedgeServerID,
       SUM(CASE WHEN IsBuy = 1 THEN LotCountDecimal ELSE -LotCountDecimal END) AS OrphanedLots,
       COUNT(*) AS OrphanedCount
FROM   Trade.GetHedgeWithoutPosition WITH (NOLOCK)
GROUP BY InstrumentID, HedgeServerID;
```

### 8.3 Long-standing orphaned hedges

```sql
SELECT HedgeID, InstrumentID, LotCountDecimal, NetProfit,
       InitDateTime, DATEDIFF(DAY, InitDateTime, GETDATE()) AS DaysOrphaned
FROM   Trade.GetHedgeWithoutPosition WITH (NOLOCK)
WHERE  DATEDIFF(DAY, InitDateTime, GETDATE()) > 7
ORDER BY DaysOrphaned DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.8/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetHedgeWithoutPosition | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetHedgeWithoutPosition.sql*
