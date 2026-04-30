# MoneyBus.TransactionsGroupGet

> Retrieves a single transaction group record by ID, returning the group's metadata including customer, reference, and initiator account type.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row from TransactionsGroup by PK |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionsGroupGet retrieves the details of a single transaction group by its ID. This is used by the application after creating transactions to verify the group exists, or when processing individual transactions that reference a GroupID to understand the group context (customer, reference, initiator).

This is a straightforward PK lookup procedure. It returns all columns from TransactionsGroup for the specified ID: the creation timestamp, external reference, customer GCID, and initiator account type.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple SELECT by PK.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | bigint | NO | - | CODE-BACKED | The TransactionsGroup.ID to look up. This is the PK of the TransactionsGroup table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | MoneyBus.TransactionsGroup | Reader | Reads a single group record by PK |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransactionsGroupGet (procedure)
└── MoneyBus.TransactionsGroup (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.TransactionsGroup | Table | SELECT FROM - reads group by PK |

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

### 8.1 Get a transaction group by ID
```sql
EXEC MoneyBus.TransactionsGroupGet @ID = 7746360;
```

### 8.2 Get group and its transactions together
```sql
-- First get the group
EXEC MoneyBus.TransactionsGroupGet @ID = 7746360;

-- Then get its transactions
SELECT * FROM MoneyBus.Transactions WITH (NOLOCK) WHERE GroupID = 7746360;
```

### 8.3 Verify group exists before adding transactions
```sql
DECLARE @GroupID BIGINT = 7746360;
IF EXISTS (SELECT 1 FROM MoneyBus.TransactionsGroup WITH (NOLOCK) WHERE ID = @GroupID)
    EXEC MoneyBus.TransactionsGroupGet @ID = @GroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionsGroupGet | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransactionsGroupGet.sql*
