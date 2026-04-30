# MoneyBus.TransactionsGetByParams

> Retrieves transactions matching a specific customer, creditor/debitor type combination, with optional status filter - used to find existing transactions for a given money flow direction.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns filtered result set from Transactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionsGetByParams retrieves transactions for a specific customer and transfer direction. The caller provides the GCID, CreditorTypeID, and DebitorTypeID to identify the flow direction (e.g., "all IBAN->Trading deposits for customer 12345"), with an optional StatusID filter to narrow to a specific state.

This is used by the application to check for existing transactions in a given direction before creating new ones (idempotency check), or to retrieve all transactions for a specific flow type for a customer.

The @StatusID uses `ISNULL(@StatusID, StatusID)` pattern, meaning NULL matches all statuses.

---

## 2. Business Logic

No complex business logic. This is a parameterized read with optional filtering.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | NO | - | CODE-BACKED | Customer to search. Uses IX_Transactions_GCID index. |
| 2 | @CreditorTypeID | int | NO | - | CODE-BACKED | Creditor account type filter: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. |
| 3 | @DebitorTypeID | int | NO | - | CODE-BACKED | Debitor account type filter: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. |
| 4 | @StatusID | int | YES | NULL | CODE-BACKED | Optional status filter. NULL returns all statuses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | MoneyBus.Transactions | Reader | Reads transactions matching customer and direction |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransactionsGetByParams (procedure)
└── MoneyBus.Transactions (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Transactions | Table | SELECT FROM with GCID + type filters |

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

### 8.1 Find all IBAN->Trading deposits for a customer
```sql
EXEC MoneyBus.TransactionsGetByParams @GCID = 12345, @CreditorTypeID = 1, @DebitorTypeID = 3;
```

### 8.2 Find only successful Trading->IBAN withdrawals
```sql
EXEC MoneyBus.TransactionsGetByParams @GCID = 12345, @CreditorTypeID = 3, @DebitorTypeID = 1, @StatusID = 2;
```

### 8.3 Find in-process Options<->Trading transfers
```sql
EXEC MoneyBus.TransactionsGetByParams @GCID = 12345, @CreditorTypeID = 2, @DebitorTypeID = 1, @StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionsGetByParams | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransactionsGetByParams.sql*
