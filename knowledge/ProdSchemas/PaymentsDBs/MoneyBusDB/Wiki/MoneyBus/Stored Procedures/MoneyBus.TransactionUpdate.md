# MoneyBus.TransactionUpdate

> Updates a transaction's status, references, exchange rates, and hold details as it progresses through the hold-debit-credit pipeline, using ISNULL to selectively modify only provided fields. Uses partition elimination for efficient access.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Transactions row by ID with partition elimination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionUpdate advances a transaction through the hold-debit-credit pipeline. Called at each step transition to update the status, provider references, and exchange rates. Uses the same ISNULL pattern as WithdrawUpdate: only non-NULL parameters modify their columns, enabling selective updates at each pipeline step.

The WHERE clause uses `ID = @ID AND PartitionCol = @ID % 100` for partition elimination on the 7.7M+ row partitioned table.

---

## 2. Business Logic

### 2.1 Selective Update with Partition Optimization

**What**: Combines ISNULL-based selective updates with partition-aware access.

**Columns/Parameters Involved**: All optional parameters + `@ID`

**Rules**:
- Modified always set to GETUTCDATE() (or @Modified if provided)
- StatusID, StatusReasonID: updated at each pipeline step transition
- CreditorReferenceID, DebitorReferenceID: set when provider returns references
- Exchange rate fields: set when cross-currency conversion is processed
- HoldReferenceID: set during hold initiation for later release/settlement
- FlowID, ExtraData: can be updated mid-flight if needed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | bigint | NO | - | CODE-BACKED | Transaction ID. Also used to calculate partition key (@ID % 100). |
| 2 | @Modified | datetime | YES | NULL | CODE-BACKED | Override for Modified timestamp. If NULL, defaults to GETUTCDATE(). |
| 3 | @StatusID | int | YES | NULL | CODE-BACKED | New status. NULL preserves current. See [Transaction Status](../../_glossary.md#transaction-status). |
| 4 | @StatusReasonID | int | YES | NULL | CODE-BACKED | New status reason. NULL preserves current. See [Transaction Status Reason](../../_glossary.md#transaction-status-reason). |
| 5 | @CreditorReferenceID | varchar(100) | YES | NULL | CODE-BACKED | Provider reference for credit leg. NULL preserves current. |
| 6 | @DebitorReferenceID | varchar(100) | YES | NULL | CODE-BACKED | Provider reference for debit leg. NULL preserves current. |
| 7 | @FlowID | int | YES | NULL | CODE-BACKED | Business flow ID. NULL preserves current. |
| 8 | @ExtraData | nvarchar(4000) | YES | NULL | CODE-BACKED | JSON metadata. NULL preserves current. |
| 9 | @CreditorBaseExchangeRate | decimal(16,8) | YES | NULL | CODE-BACKED | Creditor market rate. NULL preserves current. |
| 10 | @CreditorExchangeFee | decimal(16,8) | YES | NULL | CODE-BACKED | Creditor fee rate. NULL preserves current. |
| 11 | @CreditorExchangeRate | decimal(16,8) | YES | NULL | CODE-BACKED | Creditor effective rate. NULL preserves current. |
| 12 | @DebitorBaseExchangeRate | decimal(16,8) | YES | NULL | CODE-BACKED | Debitor market rate. NULL preserves current. |
| 13 | @DebitorExchangeFee | decimal(16,8) | YES | NULL | CODE-BACKED | Debitor fee rate. NULL preserves current. |
| 14 | @DebitorExchangeRate | decimal(16,8) | YES | NULL | CODE-BACKED | Debitor effective rate. NULL preserves current. |
| 15 | @HoldReferenceID | varchar(100) | YES | NULL | CODE-BACKED | Hold/reserve reference from provider. NULL preserves current. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UPDATE target) | MoneyBus.Transactions | Modifier | Updates transaction state with partition elimination |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransactionUpdate (procedure)
└── MoneyBus.Transactions (table) [UPDATE with partition elimination]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Transactions | Table | UPDATE with PartitionCol optimization |

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

### 8.1 Advance to Success
```sql
EXEC MoneyBus.TransactionUpdate @ID = 7747200, @StatusID = 2, @StatusReasonID = 2;
```

### 8.2 Update with exchange rates
```sql
EXEC MoneyBus.TransactionUpdate @ID = 7747200,
    @StatusID = 1, @StatusReasonID = 5,
    @CreditorBaseExchangeRate = 0.84790313, @CreditorExchangeRate = 0.84162332,
    @DebitorBaseExchangeRate = 1.17906, @DebitorExchangeRate = 1.17906;
```

### 8.3 Set hold reference
```sql
EXEC MoneyBus.TransactionUpdate @ID = 7747200,
    @StatusReasonID = 3, @HoldReferenceID = 'HOLD-REF-12345';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionUpdate | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransactionUpdate.sql*
