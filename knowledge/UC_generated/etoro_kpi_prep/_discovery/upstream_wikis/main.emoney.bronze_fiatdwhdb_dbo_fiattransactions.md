# dbo.FiatTransactions

> Central transaction table recording all financial movements (card payments, bank transfers, refunds, fees, crypto conversions) across customer fiat accounts.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 4 active (+ PK + 2 unique) |

---

## 1. Business Meaning

FiatTransactions is the central transaction ledger for the fiat platform's data warehouse. Each row represents a single financial transaction - card payments, bank transfers, refunds, fees, balance adjustments, direct debits, and crypto-to-fiat conversions. It links to the account, card (if card-based), currency balance, external bank account (if bank transfer), and merchant (if card payment).

This table exists because FiatDwhDB is a reporting database. While the operational database (FiatCustodianDB) processes transactions in real-time, this table provides a consolidated view for historical reporting, reconciliation, and analytics. Confluence documents it as the primary source for "All the successful transactions and its statuses."

Data is created by dbo.AddTransaction. Each transaction has a unique TransactionGuid and can have multiple status events tracked in dbo.FiatTransactionsStatuses.

---

## 2. Business Logic

### 2.1 Transaction Classification

**What**: Multi-dimensional transaction classification by type, category, and payment scheme.

**Columns/Parameters Involved**: `TransactionTypeId`, `TransactionCategory`, `PaymentSchemeId`

**Rules**:
- TransactionTypeId: 0-14. See [Transaction Type](../../_glossary.md#transaction-type). E.g., 5=TransferReceived, 6=Transfer.
- TransactionCategory: 0-4. See [Transaction Category](../../_glossary.md#transaction-category). E.g., 1=CardTransaction, 2=BankingTransaction, 3=TransferTransaction.
- PaymentSchemeId: 0-7. See [Payment Schema Type](../../_glossary.md#payment-schema-type). E.g., 0=Unknown/Transfer, 2=FasterPayments, 5=SEPA.
- Card transactions (Category=1) have CardId populated; bank transfers (Category=2,3) have CardId NULL.
- Live data shows Category=3 (TransferTransaction) with Type=5/6 (TransferReceived/Transfer) and PaymentScheme=0 (internal transfer).

### 2.2 Transaction Entity Relationships

**What**: Each transaction links to the account, currency balance, and optionally to card, bank account, and merchant.

**Columns/Parameters Involved**: `AccountId`, `CurrencyBalanceId`, `CardId`, `ExternalBankAccountId`, `MerchantId`

**Rules**:
- AccountId + CurrencyBalanceId: Always populated - identifies whose balance is affected
- CardId: Populated for card-based transactions (Category=1), NULL otherwise
- ExternalBankAccountId: Populated for external bank transfers
- MerchantId: Populated for card payments at merchants

---

## 3. Data Overview

| Id | AccountId | TransactionTypeId | TransactionCategory | CardId | CurrencyBalanceId | Meaning |
|---|---|---|---|---|---|---|
| 28513721 | 730099 | 5 (TransferReceived) | 3 (Transfer) | NULL | 730092 | Internal transfer received into account 730099 |
| 28513720 | 234753 | 6 (Transfer) | 3 (Transfer) | NULL | 234752 | Internal transfer sent from account 234753 |
| 28513719 | 1808990 | 5 (TransferReceived) | 3 (Transfer) | NULL | 1808980 | Internal transfer received into account 1808990 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | TransactionGuid | uniqueidentifier | NO | - | CODE-BACKED | External-facing unique transaction identifier. Has two unique constraints. |
| 3 | AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. The account involved. |
| 4 | CardId | bigint | YES | - | CODE-BACKED | FK to dbo.FiatCards.Id. The card used (NULL for non-card transactions). |
| 5 | CurrencyBalanceId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCurrencyBalances.Id. The currency balance affected. |
| 6 | ExternalBankAccountId | bigint | YES | - | CODE-BACKED | FK to dbo.FiatBankAccount.Id. External bank account for bank transfers (NULL for card/internal). |
| 7 | TransactionTypeId | int | NO | - | CODE-BACKED | Transaction type: 0-14. See [Transaction Type](../../_glossary.md#transaction-type). (Dictionary.TransactionTypes) |
| 8 | MerchantId | bigint | YES | - | CODE-BACKED | FK to dbo.FiatMerchants.Id. Merchant for card payments (NULL for transfers/fees). |
| 9 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this transaction was recorded in DWH. |
| 10 | Label | nvarchar(200) | NO | - | CODE-BACKED | Human-readable transaction description/label displayed to the customer. |
| 11 | TransactionLocalTime | datetime2(7) | YES | - | CODE-BACKED | Transaction time in the merchant's local timezone (for card transactions). |
| 12 | ReferenceNumber | nvarchar(300) | YES | - | CODE-BACKED | External reference number from the payment network or provider. |
| 13 | TransactionCategory | int | YES | - | CODE-BACKED | High-level category: 0-4. See [Transaction Category](../../_glossary.md#transaction-category). (Dictionary.TransactionCategories) |
| 14 | PaymentSchemeId | bigint | YES | - | CODE-BACKED | Payment scheme used: 0-7. See [Payment Schema Type](../../_glossary.md#payment-schema-type). (Dictionary.PaymentSchemaType) |
| 15 | PaymentReference | nvarchar(100) MASKED | YES | - | CODE-BACKED | Payment reference for bank transfers (masked for PII). Used for SEPA/FPS reference matching. |
| 16 | MoneyCorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Correlation ID linking this transaction to related operations in the Money Transfer system. |
| 17 | TransactionCountryIso | nvarchar(100) | YES | - | CODE-BACKED | ISO country code where the transaction originated (for card transactions). |
| 18 | SourceCugTransactionId | bigint | YES | - | CODE-BACKED | Source CUG (operational system) transaction ID. Links DWH record back to the operational record for cross-referencing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountId | dbo.FiatAccount | FK | Account involved in transaction |
| CardId | dbo.FiatCards | FK | Card used (nullable) |
| CurrencyBalanceId | dbo.FiatCurrencyBalances | FK | Balance affected |
| ExternalBankAccountId | dbo.FiatBankAccount | FK | External bank account (nullable) |
| MerchantId | dbo.FiatMerchants | FK | Merchant (nullable) |
| TransactionTypeId | Dictionary.TransactionTypes | Implicit | Transaction type |
| TransactionCategory | Dictionary.TransactionCategories | Implicit | Transaction category |
| PaymentSchemeId | Dictionary.PaymentSchemaType | Implicit | Payment scheme |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.FiatTransactionsStatuses | TransactionId | FK | Transaction status history |
| dbo.TransactionsProvidersMapping | TransactionId | FK | Provider-side transaction ID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.FiatTransactions (table)
├── dbo.FiatAccount (table)
├── dbo.FiatCards (table)
│   └── dbo.FiatAccount (table)
├── dbo.FiatCurrencyBalances (table)
│   ├── dbo.FiatAccount (table)
│   └── dbo.FiatBankAccount (table)
├── dbo.FiatBankAccount (table)
└── dbo.FiatMerchants (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | FK from AccountId |
| dbo.FiatCards | Table | FK from CardId |
| dbo.FiatCurrencyBalances | Table | FK from CurrencyBalanceId |
| dbo.FiatBankAccount | Table | FK from ExternalBankAccountId |
| dbo.FiatMerchants | Table | FK from MerchantId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatTransactionsStatuses | Table | FK from TransactionId |
| dbo.TransactionsProvidersMapping | Table | FK from TransactionId |
| dbo.AddTransaction | Stored Procedure | Inserts transactions |
| dbo.GetTransactionByGuid | Stored Procedure | Reads by GUID |
| dbo.DailyBalanceCalculation | Stored Procedure | Joins for balance calc |
| dbo.CalcAccountSettled | Stored Procedure | Calculates settled |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatTransactions | CLUSTERED | Id ASC | - | - | Active |
| UIX_FiatTransactions_TransactionGuid | NC UNIQUE | TransactionGuid ASC | - | - | Active |
| UIX_FiatTransactions_TransactionGuid_AccountId | NC UNIQUE | TransactionGuid ASC, AccountId ASC | - | - | Active |
| IX_FiatTransactions_AccountId | NONCLUSTERED | TransactionTypeId ASC | AccountId | - | Active |
| ix_FiatTransactions_AccountId_inc_... | NONCLUSTERED | AccountId ASC | CurrencyBalanceId, TransactionCategory | - | Active |
| IX_FiatTransactions_Created | NONCLUSTERED | Created ASC | - | - | Active |
| IX_FiatTransactions_TransactionCategory_TransactionTypeId | NONCLUSTERED | TransactionCategory ASC, TransactionTypeId ASC | AccountId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_FiatTransactions_AccountId_FiatAccount_Id | FK | AccountId -> dbo.FiatAccount.Id |
| FK_FiatTransactions_CardId_FiatCards_Id | FK | CardId -> dbo.FiatCards.Id |
| FK_FiatTransactions_CurrencyBalanceId_FiatCurrencyBalances_Id | FK | CurrencyBalanceId -> dbo.FiatCurrencyBalances.Id |
| FK_FiatTransactions_ExternalBankAccountId_FiatBankAccount_Id | FK | ExternalBankAccountId -> dbo.FiatBankAccount.Id |
| FK_FiatTransactions_MerchantId_FiatMerchants_Id | FK | MerchantId -> dbo.FiatMerchants.Id |

---

## 8. Sample Queries

### 8.1 Get recent transactions for an account with types resolved
```sql
SELECT t.Id, t.TransactionGuid, tt.Name AS TxnType, tc.Name AS Category, t.Label, t.Created
FROM dbo.FiatTransactions t WITH (NOLOCK)
JOIN Dictionary.TransactionTypes tt WITH (NOLOCK) ON tt.Id = t.TransactionTypeId
LEFT JOIN Dictionary.TransactionCategories tc WITH (NOLOCK) ON tc.Id = t.TransactionCategory
WHERE t.AccountId = 730099 ORDER BY t.Created DESC;
```

### 8.2 Get transaction with latest status
```sql
SELECT t.TransactionGuid, tt.Name AS Type, ts.TransactionStatusId, dst.Name AS Status,
       ts.HolderAmount, ts.HolderCurrency, ts.TransactionAmount, ts.TransactionCurrency
FROM dbo.FiatTransactions t WITH (NOLOCK)
JOIN Dictionary.TransactionTypes tt WITH (NOLOCK) ON tt.Id = t.TransactionTypeId
CROSS APPLY (SELECT TOP 1 * FROM dbo.FiatTransactionsStatuses WITH (NOLOCK)
             WHERE TransactionId = t.Id ORDER BY Created DESC) ts
JOIN Dictionary.TransactionStatuses dst WITH (NOLOCK) ON dst.Id = ts.TransactionStatusId
WHERE t.TransactionGuid = 'E4E24A57-08ED-4D4A-82E7-FFE22BBA586B';
```

### 8.3 Count transactions by type for last 24 hours
```sql
SELECT tt.Name AS Type, tc.Name AS Category, COUNT(*) AS Cnt
FROM dbo.FiatTransactions t WITH (NOLOCK)
JOIN Dictionary.TransactionTypes tt WITH (NOLOCK) ON tt.Id = t.TransactionTypeId
LEFT JOIN Dictionary.TransactionCategories tc WITH (NOLOCK) ON tc.Id = t.TransactionCategory
WHERE t.Created >= DATEADD(DAY, -1, GETUTCDATE())
GROUP BY tt.Name, tc.Name ORDER BY Cnt DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Banking Database](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290242096) | Confluence | FiatDwhDB stores "report of client's balance, transactions, provider mapping" |
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | Transaction query patterns with status joins, Dictionary lookups documented for FiatCustodianDB |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatTransactions | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatTransactions.sql*
