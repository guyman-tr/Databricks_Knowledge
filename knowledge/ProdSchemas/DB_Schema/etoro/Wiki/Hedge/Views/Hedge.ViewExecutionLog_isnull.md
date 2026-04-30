# Hedge.ViewExecutionLog_isnull

> Filter view over Hedge.ExecutionLog returning only rows where ExecutionTime IS NULL - i.e., execution requests that have not yet been completed. Used for monitoring/alerting on stuck or pending hedge executions.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | View |
| **Row Count** | Not queryable in current environment (object not found) |

---

## 1. Business Meaning

Hedge.ViewExecutionLog_isnull surfaces execution log entries from Hedge.ExecutionLog where ExecutionTime has not been populated. Since ExecutionTime is set when a hedge order is executed at the LP, a NULL value indicates the order was submitted but no execution response has been received yet.

This view is an operational monitoring tool: during normal operation, rows here represent in-flight hedge orders. If rows persist without an ExecutionTime for an extended period, it may indicate:
- LP connectivity issues (no FIX execution report returned)
- Processing delays in the hedge server
- Failed orders where the rejection was not properly recorded
- Stuck processing queues

The view uses `SELECT *` over Hedge.ExecutionLog, returning all columns of the execution log for the matching rows. This makes it easy to examine the full context of pending executions.

The view could not be queried in the current environment (object not found error) - it may be deployed only to certain environments, or may have been dropped without removing the SSDT definition.

For full column descriptions, see [Hedge.ExecutionLog](Hedge.ExecutionLog.md).

---

## 2. Business Logic

### 2.1 NULL ExecutionTime as Pending Indicator

**Filter**: `WHERE ExecutionTime IS NULL`

**Rules**:
- ExecutionTime in Hedge.ExecutionLog is set when the FIX execution report is received from the LP
- NULL = the execution report has NOT been received
- Rows here represent in-flight or stuck orders
- In normal operation, rows appear briefly while the order is in transit; persistent rows indicate a problem

---

## 3. Output Columns

All columns from Hedge.ExecutionLog where ExecutionTime IS NULL. See [Hedge.ExecutionLog](Hedge.ExecutionLog.md) for the full column list.

---

## 4. Relationships

### 4.1 Source Tables

| Table | Join Type | Condition |
|-------|-----------|-----------|
| Hedge.ExecutionLog | Base table (filtered) | WHERE ExecutionTime IS NULL |

### 4.2 Consumed By

No stored procedures found referencing this view.

---

## 5. Dependencies

```
Hedge.ViewExecutionLog_isnull (view)
+-- Hedge.ExecutionLog (table) [see Hedge.ExecutionLog.md]
```

---

## 6. Sample Queries

### 6.1 Monitor for stuck pending executions
```sql
SELECT  OrderID, RequestTime, ExecutionTime, InstrumentID, LiquidityAccountID, Units
FROM    [Hedge].[ViewExecutionLog_isnull] WITH (NOLOCK)
ORDER BY RequestTime;
-- Rows here = hedge orders awaiting LP execution confirmation
```

### 6.2 Fallback: query the table directly with same filter
```sql
SELECT *
FROM   [Hedge].[ExecutionLog] WITH (NOLOCK)
WHERE  ExecutionTime IS NULL
ORDER BY RequestTime;
```

---

## 7. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11 (View phases)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | Corrections: 0 applied*
*Object: Hedge.ViewExecutionLog_isnull | Type: View | Source: etoro/etoro/Hedge/Views/Hedge.ViewExecutionLog_isnull.sql*
