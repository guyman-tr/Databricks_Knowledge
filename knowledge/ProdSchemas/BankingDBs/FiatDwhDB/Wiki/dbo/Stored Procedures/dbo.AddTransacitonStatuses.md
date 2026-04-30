# dbo.AddTransacitonStatuses

> Upsert procedure that records a transaction status event with amounts, currencies, and risk action flags. Deduplicates on TransactionId + TransactionStatusId + TransactionOccured. Note: procedure name contains a typo ("Transaciton" instead of "Transaction").

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into FiatTransactionsStatuses, returns Results (ID or 0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddTransacitonStatuses (typo preserved) records a transaction status event with full financial details and risk action flags. Uses timestamp-based deduplication: if a record with same TransactionId, TransactionStatusId, and TransactionOccured >= incoming exists, returns 0. Otherwise inserts all financial fields and risk flags.

This is the richest upsert procedure in the schema - it captures amounts in both holder and transaction currencies, accumulated balance impact, risk rule codes, and four boolean risk action flags.

---

## 2. Business Logic

### 2.1 Timestamp-Based Deduplication with Risk Actions

**What**: Prevents duplicate/outdated transaction status events while recording risk engine decisions.

**Rules**:
- Dedup on (TransactionId + TransactionStatusId + TransactionOccured)
- UPDLOCK/HOLDLOCK, SET NOCOUNT ON, SET XACT_ABORT ON
- Risk flags default to 0 (no action); set to 1 when risk engine triggers
- @CorrelationId defaults to NULL for legacy compatibility

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionId | bigint | NO | - | CODE-BACKED | FK to FiatTransactions.Id. |
| 2 | @TransactionStatusId | int | NO | - | CODE-BACKED | Status: 0-7. See [Transaction Status](../../_glossary.md#transaction-status). |
| 3 | @AuthorizationType | int | NO | - | CODE-BACKED | Auth type: 0-14. See [Authorization Type](../../_glossary.md#authorization-type). |
| 4 | @HolderAmount | decimal(36,18) | NO | - | CODE-BACKED | Amount in holder's currency. |
| 5 | @HolderCurrency | varchar(3) | NO | - | CODE-BACKED | Holder's currency code (e.g., "GBP"). |
| 6 | @TransactionAmount | decimal(36,18) | NO | - | CODE-BACKED | Amount in transaction currency. |
| 7 | @AccumulatedAmount | decimal(36,18) | NO | - | CODE-BACKED | Cumulative balance impact. |
| 8 | @TransactionCurrency | varchar(3) | NO | - | CODE-BACKED | Transaction currency code. |
| 9 | @TransactionOccured | datetime2 | NO | - | CODE-BACKED | Event time (dedup key). |
| 10 | @Created | datetime2 | NO | - | CODE-BACKED | DWH recording time. |
| 11 | @RiskRuleCodes | nvarchar(max) | YES | NULL | CODE-BACKED | Triggered risk rule codes. |
| 12 | @MarkTransactionAsSuspicious | bit | YES | 0 | CODE-BACKED | Risk: flag as suspicious. |
| 13 | @ChangeCardStatusToRisk | bit | YES | 0 | CODE-BACKED | Risk: change card to Risk status. |
| 14 | @ChangeAccountStatusToSuspended | bit | YES | 0 | CODE-BACKED | Risk: suspend account. |
| 15 | @RejectTransaction | bit | YES | 0 | CODE-BACKED | Risk: reject transaction. |
| 16 | @CorrelationId | uniqueidentifier | YES | NULL | CODE-BACKED | Distributed tracing ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.FiatTransactionsStatuses | Read/Write | Dedup + insert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddTransacitonStatuses (procedure)
└── dbo.FiatTransactionsStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatTransactionsStatuses | Table | Dedup + insert target |

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

### 8.1 Record a settled transaction status
```sql
EXEC dbo.AddTransacitonStatuses @TransactionId = 28513721, @TransactionStatusId = 2,
    @AuthorizationType = 1, @HolderAmount = 100.00, @HolderCurrency = 'GBP',
    @TransactionAmount = 100.00, @AccumulatedAmount = 100.00, @TransactionCurrency = 'GBP',
    @TransactionOccured = SYSUTCDATETIME(), @Created = SYSUTCDATETIME();
```

### 8.2 Record with risk actions
```sql
EXEC dbo.AddTransacitonStatuses @TransactionId = 28513721, @TransactionStatusId = 1,
    @AuthorizationType = 1, @HolderAmount = 5000.00, @HolderCurrency = 'GBP',
    @TransactionAmount = 5000.00, @AccumulatedAmount = 5000.00, @TransactionCurrency = 'GBP',
    @TransactionOccured = SYSUTCDATETIME(), @Created = SYSUTCDATETIME(),
    @RiskRuleCodes = 'LARGE_AMOUNT,NEW_MERCHANT', @MarkTransactionAsSuspicious = 1;
```

### 8.3 Verify
```sql
SELECT TransactionStatusId, AuthorizationType, HolderAmount, RiskRuleCodes
FROM dbo.FiatTransactionsStatuses WITH (NOLOCK) WHERE TransactionId = 28513721 ORDER BY TransactionOccured DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddTransacitonStatuses | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddTransacitonStatuses.sql*
