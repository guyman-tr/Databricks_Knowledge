# Trade.DeleteOldOrderOnlyDemo

> Removes stale demo-only orders older than 120 days from Trade.Orders by iterating through each and calling Trade.OrdersClientRemove, with email notification on failures.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @recipients (email target) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs **bulk cleanup of old orders on the demo (practice) environment**. Demo accounts accumulate orders over time and, unlike real accounts, have no natural lifecycle that guarantees timely closure. This procedure identifies all orders in Trade.Orders with OccurredTime older than 120 days (~4 months) and removes them one by one using Trade.OrdersClientRemove.

The procedure exists to prevent unbounded growth of Trade.Orders in demo environments. Since demo orders carry no financial significance, they can be safely purged once stale. Without this cleanup, demo order tables would grow indefinitely, degrading query performance for active demo users and consuming unnecessary storage.

The procedure first checks Maintenance.Feature (FeatureID=22) to determine if the current environment is "real" (production with live money). If FeatureID=22 has Value=1 (real), the procedure exits immediately without doing anything - this is a critical safety guard preventing accidental deletion of real customer orders. On demo environments (FeatureID=22 Value=0), it builds a list of stale orders, iterates through each calling `Trade.OrdersClientRemove`, and sends an email alert if any deletions fail.

---

## 2. Business Logic

### 2.1 Real Environment Safety Guard

**What**: Prevents execution on real/production environments by checking a feature flag.

**Columns/Parameters Involved**: `Maintenance.Feature.FeatureID`, `Maintenance.Feature.Value`

**Rules**:
- Reads Maintenance.Feature WHERE FeatureID = 22 (the "IsReal" feature flag - if 1 then real, else demo)
- If Value = 1 (real environment): RETURN immediately - no orders are touched
- This is a hard safety guard - the procedure should never be scheduled on real environments, but if it is, it self-aborts

### 2.2 Order Selection and Iterative Deletion

**What**: Identifies stale demo orders and removes them one at a time via Trade.OrdersClientRemove.

**Columns/Parameters Involved**: `Trade.Orders.OrderID`, `Trade.Orders.CID`, `Trade.Orders.OccurredTime`

**Rules**:
- Selects all orders from Trade.Orders where OccurredTime < GETUTCDATE() - 120 (older than ~4 months)
- For each order, dynamically builds and executes: `EXEC Trade.OrdersClientRemove @OrderID={OrderID}, @CID={CID}`
- Uses a WHILE loop with ROW_NUMBER()-based ID for iteration
- Each deletion is wrapped in TRY/CATCH - failures are silently skipped (the order remains in #Order2Delete for the email check)
- Successfully deleted orders are removed from the temp table

**Diagram**:
```
Maintenance.Feature (FeatureID=22)
  |
  +-- Value=1 (Real) --> RETURN (abort)
  |
  +-- Value=0 (Demo) --> Continue
         |
         v
  Trade.Orders WHERE OccurredTime < GETUTCDATE()-120
         |
         v
  #Order2Delete (OrderID, CID per row)
         |
         v
  WHILE loop: EXEC Trade.OrdersClientRemove per order
         |
         +-- Success --> DELETE from #Order2Delete
         +-- Failure --> CATCH, skip, continue
         |
         v
  Any remaining in #Order2Delete? --> sp_send_dbmail alert
```

### 2.3 Failure Notification

**What**: Sends email alert when any orders fail to delete.

**Columns/Parameters Involved**: `@recipients`

**Rules**:
- After the loop completes, checks if any rows remain in #Order2Delete (indicating failures)
- If failures exist, sends an email via msdb.dbo.sp_send_dbmail to @recipients
- Subject: "Demo prod - Some Old order fail to Delete from Trade.Orders"
- Body references this procedure for investigation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @recipients | VARCHAR(500) | NO | - | CODE-BACKED | Email address(es) for failure notification via sp_send_dbmail. Comma-separated list of recipients who should be alerted when demo order deletions fail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | Maintenance.Feature | Lookup | Reads FeatureID=22 to determine if environment is real (1) or demo (0) |
| (SELECT) | Trade.Orders | READ + DELETE target (via OrdersClientRemove) | Identifies orders older than 120 days for cleanup |
| (EXEC) | Trade.OrdersClientRemove | Procedure call (dynamic) | Delegates per-order removal - handles the actual order deletion logic |
| (EXEC) | msdb.dbo.sp_send_dbmail | Procedure call | Sends failure notification email |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (SQL Agent Job) | N/A | Scheduled caller | Expected to be called by a scheduled job on demo environments only |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteOldOrderOnlyDemo (procedure)
+-- Maintenance.Feature (table)
+-- Trade.Orders (table)
+-- Trade.OrdersClientRemove (procedure)
+-- msdb.dbo.sp_send_dbmail (system procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | Read FeatureID=22 to check real vs demo environment |
| Trade.Orders | Table | SELECT orders older than 120 days (OccurredTime, OrderID, CID) |
| Trade.OrdersClientRemove | Stored Procedure | Called per order via dynamic EXEC to remove each stale order |
| msdb.dbo.sp_send_dbmail | System Procedure | Sends failure notification email |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found) | - | This is a terminal cleanup procedure not called by other procedures |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

**Relevant indexes on Trade.Orders used by this procedure**: The WHERE clause on OccurredTime benefits from any index covering that column.

### 7.2 Constraints

None.

**Note**: The procedure uses dynamic SQL (`EXEC (@CMD)`) to call Trade.OrdersClientRemove. The dynamic SQL is constructed from integer OrderID and CID values sourced from Trade.Orders, not from user input, so injection risk is minimal.

---

## 8. Sample Queries

### 8.1 Preview demo orders eligible for cleanup

```sql
SELECT  OrderID, CID, OccurredTime,
        DATEDIFF(DAY, OccurredTime, GETUTCDATE()) AS AgeDays
FROM    Trade.Orders WITH (NOLOCK)
WHERE   OccurredTime < GETUTCDATE() - 120
ORDER BY OccurredTime ASC;
```

### 8.2 Check current environment type (real vs demo)

```sql
SELECT  FeatureID, Value,
        CASE WHEN CAST(Value AS INT) = 1 THEN 'REAL' ELSE 'DEMO' END AS Environment
FROM    Maintenance.Feature WITH (NOLOCK)
WHERE   FeatureID = 22;
```

### 8.3 Count stale orders by age bracket

```sql
SELECT  CASE
            WHEN DATEDIFF(DAY, OccurredTime, GETUTCDATE()) BETWEEN 120 AND 180 THEN '120-180 days'
            WHEN DATEDIFF(DAY, OccurredTime, GETUTCDATE()) BETWEEN 181 AND 365 THEN '181-365 days'
            ELSE '365+ days'
        END AS AgeBracket,
        COUNT(*) AS OrderCount
FROM    Trade.Orders WITH (NOLOCK)
WHERE   OccurredTime < GETUTCDATE() - 120
GROUP BY CASE
            WHEN DATEDIFF(DAY, OccurredTime, GETUTCDATE()) BETWEEN 120 AND 180 THEN '120-180 days'
            WHEN DATEDIFF(DAY, OccurredTime, GETUTCDATE()) BETWEEN 181 AND 365 THEN '181-365 days'
            ELSE '365+ days'
         END;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteOldOrderOnlyDemo | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteOldOrderOnlyDemo.sql*
