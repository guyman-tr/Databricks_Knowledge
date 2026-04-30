# Trade.OrdersExitChangeLogAdd

> Inserts an audit record into History.OrdersExitChangeLog capturing an exit order modification event, including units-to-deduct tracking for partial close operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID (the exit order being logged) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OrdersExitChangeLogAdd records an audit trail entry whenever an exit order (close position order) is modified. Exit orders trigger position closes, and this log captures the operation type, client request, and unit deduction details. The @UnitsToDeduct and @PreviousUnitsToDeduct parameters are unique to exit orders, tracking how many units were requested for close and what the previous deduction amount was - essential for partial close reconciliation.

Created by Alex on 2018-06-28 (FB 51445), as part of the same change log infrastructure as Trade.OrdersChangeLogAdd and Trade.OrdersEntryChangeLogAdd.

---

## 2. Business Logic

### 2.1 Exit Change Log Insertion

**What**: Inserts a single audit record into History.OrdersExitChangeLog.

**Columns/Parameters Involved**: @OrderID, @OperationTypeID, @ClientRequestGuid, @UnitsToDeduct, @PreviousUnitsToDeduct

**Rules**:
- Direct INSERT with no transformation
- @OrderID is OUTPUT (allows chaining)
- @OperationTypeID defaults to 1
- @UnitsToDeduct and @PreviousUnitsToDeduct are DECIMAL(16,6) to support fractional unit amounts

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | Exit OrderID being logged. Declared OUTPUT for chaining. |
| 2 | @OperationTypeID | INT | YES | 1 | CODE-BACKED | Type of operation performed on the exit order (default 1 = standard). |
| 3 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation ID linking this change to the originating client request. |
| 4 | @UnitsToDeduct | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Number of units being deducted (closed) in this operation. Used for partial close tracking. |
| 5 | @PreviousUnitsToDeduct | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Previous value of units to deduct before this change. Enables before/after comparison for audit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | History.OrdersExitChangeLog | INSERT | Target audit table for exit order changes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Exit order / position close procedures | Various | EXEC | Called when exit orders are created/modified |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrdersExitChangeLogAdd (procedure)
+-- History.OrdersExitChangeLog (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.OrdersExitChangeLog | Table | INSERT - audit destination |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Exit order / close procedures | Procedures | EXEC - audit trail |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| TRY/CATCH with THROW | Error handling | Re-throws errors to caller |

---

## 8. Sample Queries

### 8.1 View recent exit order change log entries

```sql
SELECT TOP 20 OrderID, OperationTypeID, UnitsToDeduct, PreviousUnitsToDeduct, ClientRequestGuid, *
FROM   History.OrdersExitChangeLog WITH (NOLOCK)
ORDER BY 1 DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrdersExitChangeLogAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrdersExitChangeLogAdd.sql*
