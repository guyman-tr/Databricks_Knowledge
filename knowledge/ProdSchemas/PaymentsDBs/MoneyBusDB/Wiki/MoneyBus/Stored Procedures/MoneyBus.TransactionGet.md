# MoneyBus.TransactionGet

> Retrieves a single transaction by ID with partition-optimized lookup (WHERE ID = @ID AND PartitionCol = @ID % 100), returning all columns including exchange rates and hold reference.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row from Transactions by PK with partition elimination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionGet retrieves a single transaction by its ID using a partition-optimized query. The WHERE clause includes `PartitionCol = @ID % 100` to enable partition elimination on the PS_Transactions scheme, ensuring the query only scans 1 of 100 partitions instead of all of them.

Returns all transaction columns including the exchange rate fields (CreditorBaseExchangeRate through DebitorExchangeRate), FlowID, ExtraData, and HoldReferenceID.

---

## 2. Business Logic

### 2.1 Partition Elimination Pattern

**What**: The query calculates the partition key from the ID to enable single-partition access.

**Columns/Parameters Involved**: `@ID`, `PartitionCol`

**Rules**:
- PartitionCol = ID % 100 (persisted computed column)
- The procedure adds `AND PartitionCol = @ID % 100` to the WHERE clause
- This enables SQL Server to skip 99 of 100 partitions, dramatically improving lookup performance on the 7.7M+ row table

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | bigint | NO | - | CODE-BACKED | The Transactions.ID to look up. Used both for the PK filter and to calculate the partition key (@ID % 100). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | MoneyBus.Transactions | Reader | Reads single transaction with partition elimination |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransactionGet (procedure)
└── MoneyBus.Transactions (table) [SELECT FROM with partition elimination]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Transactions | Table | SELECT FROM with PartitionCol optimization |

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

### 8.1 Get transaction by ID
```sql
EXEC MoneyBus.TransactionGet @ID = 7747200;
```

### 8.2 Equivalent direct query
```sql
SELECT * FROM MoneyBus.Transactions WITH (NOLOCK)
WHERE ID = 7747200 AND PartitionCol = 7747200 % 100;
```

### 8.3 Get with resolved lookups
```sql
SELECT t.*, ct.Name AS CreditorType, dt.Name AS DebitorType, ts.Name AS Status
FROM MoneyBus.Transactions t WITH (NOLOCK)
JOIN Dictionary.AccountTypes ct WITH (NOLOCK) ON ct.ID = t.CreditorTypeID
JOIN Dictionary.AccountTypes dt WITH (NOLOCK) ON dt.ID = t.DebitorTypeID
JOIN Dictionary.TransactionStatuses ts WITH (NOLOCK) ON ts.ID = t.StatusID
WHERE t.ID = 7747200 AND t.PartitionCol = 7747200 % 100;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionGet | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransactionGet.sql*
