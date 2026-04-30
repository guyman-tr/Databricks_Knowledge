# dbo.GetTransactionByGuid

> Simple lookup that retrieves a transaction record by its TransactionGuid, returning all key columns.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from FiatTransactions WHERE TransactionGuid = @TransactionGuid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetTransactionByGuid retrieves a transaction by its unique TransactionGuid. Returns all key transaction columns: Id, TransactionGuid, AccountId, CardId, CurrencyBalanceId, ExternalBankAccountId, TransactionTypeId, MerchantId, Created, Label, TransactionLocalTime, ReferenceNumber, TransactionCategory, PaymentSchemeId, PaymentReference. Uses the UIX_FiatTransactions_TransactionGuid unique index.

---

## 2. Business Logic

No complex logic. Simple GUID lookup.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionGuid | uniqueidentifier | NO | - | CODE-BACKED | The transaction GUID to look up. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatTransactions | Read | GUID lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetTransactionByGuid (procedure)
└── dbo.FiatTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatTransactions | Table | SELECT source |

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

### 8.1 Look up a transaction
```sql
EXEC dbo.GetTransactionByGuid @TransactionGuid = 'E4E24A57-08ED-4D4A-82E7-FFE22BBA586B';
```

### 8.2 Equivalent query
```sql
SELECT Id, TransactionGuid, AccountId, CardId, CurrencyBalanceId, ExternalBankAccountId,
       TransactionTypeId, MerchantId, Created, Label, TransactionLocalTime, ReferenceNumber,
       TransactionCategory, PaymentSchemeId, PaymentReference
FROM dbo.FiatTransactions WITH (NOLOCK)
WHERE TransactionGuid = 'E4E24A57-08ED-4D4A-82E7-FFE22BBA586B';
```

### 8.3 Chain with status lookup
```sql
DECLARE @r TABLE (Id bigint, TransactionGuid uniqueidentifier, AccountId bigint, CardId bigint, CurrencyBalanceId bigint, ExternalBankAccountId bigint, TransactionTypeId int, MerchantId bigint, Created datetime2, Label nvarchar(200), TransactionLocalTime datetime2, ReferenceNumber nvarchar(300), TransactionCategory int, PaymentSchemeId bigint, PaymentReference nvarchar(100));
INSERT INTO @r EXEC dbo.GetTransactionByGuid @TransactionGuid = 'E4E24A57-08ED-4D4A-82E7-FFE22BBA586B';
SELECT r.TransactionGuid, ts.TransactionStatusId, ts.HolderAmount, ts.TransactionOccured
FROM @r r CROSS APPLY (SELECT TOP 1 * FROM dbo.FiatTransactionsStatuses WITH (NOLOCK) WHERE TransactionId = r.Id ORDER BY Created DESC) ts;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetTransactionByGuid | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetTransactionByGuid.sql*
