# Trade.OrdersEntryChangeLogAdd

> Inserts an audit record into History.OrdersEntryChangeLog capturing an entry order modification event with operation type and client request correlation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID (the entry order being logged) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OrdersEntryChangeLogAdd records an audit trail entry whenever an entry order (pending buy/sell order) is modified. Entry orders are orders placed to open positions at a specific price (limit/stop orders). This procedure captures the OrderID, operation type, and client request GUID for traceability.

Created by Alex on 2018-06-28 (FB 51445), as part of the same change log infrastructure as Trade.OrdersChangeLogAdd and Trade.OrdersExitChangeLogAdd.

---

## 2. Business Logic

### 2.1 Entry Change Log Insertion

**What**: Inserts a single audit record into History.OrdersEntryChangeLog.

**Columns/Parameters Involved**: @OrderID, @OperationTypeID, @ClientRequestGuid

**Rules**:
- Direct INSERT with no transformation
- @OrderID is OUTPUT (allows chaining with order creation)
- @OperationTypeID defaults to 1
- Minimal parameters compared to OrdersChangeLogAdd (no settlement/SL/TP flags)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | Entry OrderID being logged. Declared OUTPUT for chaining. |
| 2 | @OperationTypeID | INT | YES | 1 | CODE-BACKED | Type of operation performed on the entry order (default 1 = standard). |
| 3 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Correlation ID linking this change to the originating client request. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | History.OrdersEntryChangeLog | INSERT | Target audit table for entry order changes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Entry order management procedures | Various | EXEC | Called when entry orders are created/modified |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrdersEntryChangeLogAdd (procedure)
+-- History.OrdersEntryChangeLog (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.OrdersEntryChangeLog | Table | INSERT - audit destination |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Entry order management procedures | Procedures | EXEC - audit trail |

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

### 8.1 View recent entry order change log entries

```sql
SELECT TOP 20 OrderID, OperationTypeID, ClientRequestGuid, *
FROM   History.OrdersEntryChangeLog WITH (NOLOCK)
ORDER BY 1 DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrdersEntryChangeLogAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrdersEntryChangeLogAdd.sql*
