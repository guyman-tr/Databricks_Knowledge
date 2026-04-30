# Trade.AlertForExitOrders_which_should_have_clsoed1

> Legacy variant of orphaned exit orders alert using WITH RECOMPILE and the Trade.OrdersExit view instead of OrdersExitTbl. Misspelled name retained for compatibility.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Recipients, @Copy_Recipients |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is another variant of the orphaned exit orders alert family. It detects pending exit orders that should have been executed based on received market prices but remain open. The "1" suffix and procedure-level `WITH RECOMPILE` hint distinguish it from other variants.

The key difference from the other variants is that this version uses the `Trade.OrdersExit` view (not `Trade.OrdersExitTbl` directly) and the `Trade.Position` view for both the EXISTS check and the detail query. This means it operates through the view's abstraction layer, which may apply additional filtering or join logic. It also uses `WITH RECOMPILE` at the procedure level to force a fresh plan on every execution, and returns -1 when no orphans are found.

The email format and alerting behavior are identical to the other family members.

---

## 2. Business Logic

### 2.1 View-Based Orphan Detection

**What**: Uses Trade.OrdersExit view instead of the base OrdersExitTbl table.

**Rules**:
- EXISTS check uses Trade.OrdersExit (view) + Trade.Position (view) + Trade.CurrencyPrice
- No explicit StatusID filter - the OrdersExit view may already filter for active orders
- No instrument exclusion list
- No partition column alignment
- WITH RECOMPILE at procedure level ensures fresh plan every execution
- Returns -1 when no orphans found (unlike other variants that just RETURN)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Recipients | varchar(max) | YES | 'tradingbackend@etoro.com;pinikr@etoro.com;yitzchakwa@etoro.com;' | CODE-BACKED | Email recipients. |
| 2 | @Copy_Recipients | varchar(max) | YES | '' | CODE-BACKED | CC recipients. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Trade.OrdersExit (view) | READER | Exit orders via view abstraction |
| JOIN | Trade.Position (view) | READER | Position details via view |
| JOIN | Trade.CurrencyPrice | READER | Market price timestamps |
| JOIN | Trade.InstrumentMetaData | READER | Instrument display names |
| OUTER APPLY | History.PositionFail | READER | Recent failure reasons |
| EXEC | msdb.dbo.sp_send_dbmail | System call | HTML email alert |

### 5.2 Referenced By (other objects point to this)

No SQL-level dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AlertForExitOrders_which_should_have_clsoed1 (procedure)
+-- Trade.OrdersExit (view)
+-- Trade.Position (view)
+-- Trade.CurrencyPrice (table)
+-- Trade.InstrumentMetaData (table)
+-- History.PositionFail (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExit | View | READER - exit orders via view |
| Trade.Position | View | READER - position details |
| Trade.CurrencyPrice | Table | READER - market prices |
| Trade.InstrumentMetaData | Table | READER - instrument names |
| History.PositionFail | Table | READER - fail history |

### 6.2 Objects That Depend On This

No SQL-level dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Procedure hint | Forces fresh execution plan on every call |

---

## 8. Sample Queries

### 8.1 Run the view-based alert

```sql
EXEC Trade.AlertForExitOrders_which_should_have_clsoed1;
```

### 8.2 Preview using the same views

```sql
SELECT  O.OrderID, O.CID, O.PositionID, P.InstrumentID, O.OpenOccurred, C.ReceivedOnPriceServer
FROM    Trade.OrdersExit O WITH (NOLOCK)
JOIN    Trade.Position P WITH (NOLOCK) ON O.PositionID = P.PositionID
JOIN    Trade.CurrencyPrice C WITH (NOLOCK) ON P.InstrumentID = C.InstrumentID
WHERE   O.OpenOccurred < C.ReceivedOnPriceServer;
```

### 8.3 Compare view vs table results

```sql
SELECT  COUNT(*) AS ViewCount
FROM    Trade.OrdersExit WITH (NOLOCK)
UNION ALL
SELECT  COUNT(*) AS TableCount
FROM    Trade.OrdersExitTbl WITH (NOLOCK)
WHERE   StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AlertForExitOrders_which_should_have_clsoed1 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AlertForExitOrders_which_should_have_clsoed1.sql*
