# dbo.AddTransaction

> Upsert procedure that creates a financial transaction record, deduplicating on TransactionGuid with a UNION ALL check against both unique constraints.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into FiatTransactions, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddTransaction creates or retrieves a transaction record in the DWH. Uses a UNION ALL subquery to check both unique constraints (TransactionGuid alone, and TransactionGuid + AccountId) for deduplication. UPDLOCK/HOLDLOCK for concurrency safety. Optional parameters (@TransactionCountryIso, @MoneyCorrelationId, @SourceCugTransactionId) default to NULL for backward compatibility.

---

## 2. Business Logic

### 2.1 Dual-Constraint Deduplication

**What**: Checks both unique indexes via UNION ALL before inserting.

**Rules**:
- Checks UIX_FiatTransactions_TransactionGuid AND UIX_FiatTransactions_TransactionGuid_AccountId
- If TransactionGuid exists (either constraint), returns existing Id
- SET NOCOUNT ON + SET XACT_ABORT ON for clean transaction handling

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountId | bigint | NO | - | CODE-BACKED | FK to FiatAccount.Id. |
| 2 | @TransactionGuid | uniqueidentifier | NO | - | CODE-BACKED | Unique external transaction ID. |
| 3 | @CardId | bigint | YES | - | CODE-BACKED | FK to FiatCards.Id (NULL for non-card txns). |
| 4 | @CurrencyBalanceId | bigint | NO | - | CODE-BACKED | FK to FiatCurrencyBalances.Id. |
| 5 | @ExternalBankAccountId | bigint | YES | - | CODE-BACKED | FK to FiatBankAccount.Id (NULL for non-bank txns). |
| 6 | @TransactionTypeId | int | NO | - | CODE-BACKED | Type: 0-14. See [Transaction Type](../../_glossary.md#transaction-type). |
| 7 | @MerchantId | bigint | YES | - | CODE-BACKED | FK to FiatMerchants.Id. |
| 8 | @Created | datetime2 | NO | - | CODE-BACKED | DWH recording timestamp. |
| 9 | @Label | nvarchar(200) | NO | - | CODE-BACKED | Customer-facing transaction description. |
| 10 | @TransactionLocalTime | datetime2 | YES | - | CODE-BACKED | Merchant local time. |
| 11 | @ReferenceNumber | nvarchar(300) | YES | - | CODE-BACKED | External reference. |
| 12 | @TransactionCategory | int | YES | - | CODE-BACKED | Category: 0-4. See [Transaction Category](../../_glossary.md#transaction-category). |
| 13 | @PaymentSchemeId | bigint | YES | - | CODE-BACKED | Payment scheme: 0-7. See [Payment Schema Type](../../_glossary.md#payment-schema-type). |
| 14 | @PaymentReference | nvarchar(100) | YES | - | CODE-BACKED | Payment ref for bank transfers (PII). |
| 15 | @TransactionCountryIso | nvarchar(100) | YES | NULL | CODE-BACKED | Origin country ISO code. |
| 16 | @MoneyCorrelationId | uniqueidentifier | YES | NULL | CODE-BACKED | Money Transfer system correlation. |
| 17 | @SourceCugTransactionId | bigint | YES | NULL | CODE-BACKED | CUG operational system transaction ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.FiatTransactions | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddTransaction (procedure)
└── dbo.FiatTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatTransactions | Table | Upsert target |

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

### 8.1 Create a transfer transaction
```sql
EXEC dbo.AddTransaction @AccountId = 730099, @TransactionGuid = NEWID(),
    @CardId = NULL, @CurrencyBalanceId = 730092, @ExternalBankAccountId = NULL,
    @TransactionTypeId = 5, @MerchantId = 9, @Created = SYSUTCDATETIME(),
    @Label = 'Transfer Received', @TransactionLocalTime = NULL,
    @ReferenceNumber = NULL, @TransactionCategory = 3, @PaymentSchemeId = 0,
    @PaymentReference = NULL;
```

### 8.2 Verify
```sql
SELECT TOP 1 * FROM dbo.FiatTransactions WITH (NOLOCK) WHERE AccountId = 730099 ORDER BY Created DESC;
```

### 8.3 Test idempotency
```sql
DECLARE @guid UNIQUEIDENTIFIER = 'E4E24A57-08ED-4D4A-82E7-FFE22BBA586B';
EXEC dbo.AddTransaction @AccountId = 730099, @TransactionGuid = @guid,
    @CardId = NULL, @CurrencyBalanceId = 730092, @ExternalBankAccountId = NULL,
    @TransactionTypeId = 5, @MerchantId = 9, @Created = SYSUTCDATETIME(),
    @Label = 'Transfer Received', @TransactionLocalTime = NULL,
    @ReferenceNumber = NULL, @TransactionCategory = 3, @PaymentSchemeId = 0,
    @PaymentReference = NULL;
-- Returns existing Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddTransaction | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddTransaction.sql*
