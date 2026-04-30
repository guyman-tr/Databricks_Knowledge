# MoneyBus.TransactionStatusReasonsGet

> Retrieves all transaction status reason lookup values from the Dictionary schema for application-side caching of the status reason enum.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns full result set from Dictionary.TransactionStatusReasons |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionStatusReasonsGet provides a clean API for the application to load the complete set of transaction status reasons from the Dictionary.TransactionStatusReasons table. This is a cache-loading procedure - the application calls it at startup to populate its in-memory enum/lookup of all valid status reason values (Created, Success, Held, Credited, Debited, etc.).

The procedure uses `SELECT *` with no parameters, returning all 15 status reason records with their IDs, names, and parent TransactionStatusID mappings. See [Transaction Status Reason](../../_glossary.md#transaction-status-reason) for the complete value map.

---

## 2. Business Logic

No complex business logic. This is a dictionary table read.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. It returns all columns from Dictionary.TransactionStatusReasons: ID, Name, TransactionStatusID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | Dictionary.TransactionStatusReasons | Reader | Reads all 15 status reason lookup values |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransactionStatusReasonsGet (procedure)
└── Dictionary.TransactionStatusReasons (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TransactionStatusReasons | Table | SELECT * - reads all status reason values |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all status reasons
```sql
EXEC MoneyBus.TransactionStatusReasonsGet;
```

### 8.2 Equivalent direct query with parent status resolved
```sql
SELECT tsr.ID, tsr.Name, ts.Name AS ParentStatus
FROM Dictionary.TransactionStatusReasons tsr WITH (NOLOCK)
JOIN Dictionary.TransactionStatuses ts WITH (NOLOCK) ON ts.ID = tsr.TransactionStatusID
ORDER BY tsr.ID;
```

### 8.3 Find terminal status reasons
```sql
SELECT tsr.ID, tsr.Name, ts.Name AS ParentStatus
FROM Dictionary.TransactionStatusReasons tsr WITH (NOLOCK)
JOIN Dictionary.TransactionStatuses ts WITH (NOLOCK) ON ts.ID = tsr.TransactionStatusID
WHERE tsr.TransactionStatusID IN (2, 3, 4, 5);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionStatusReasonsGet | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransactionStatusReasonsGet.sql*
