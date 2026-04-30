# Tribe.AccountsActivities_AccountActivity-833937

> Child data table containing detailed account activity (transaction) records from Tribe, with 100+ columns covering all transaction fields including amounts, currencies, merchant info, risk data, and payment details.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

AccountsActivities_AccountActivity-833937 is the richest child table in the Tribe schema. Each row represents a single transaction/activity record from Tribe, containing all raw fields: holder/account/card identifiers, transaction amounts in holder/transaction/billing/settlement currencies, FX rates, fee details, merchant info, risk flags, external payment (EPM) details, dispute info, and external bank account details.

All data columns are nvarchar(max) - no data typing is applied at this layer. This is the raw data landing zone. The dbo schema tables (FiatTransactions, FiatTransactionsStatuses) contain the typed/normalized equivalent.

Parent: Tribe.AccountsActivities-862157 (linked via @AccountsActivities@Id-862157).

---

## 2. Business Logic

### 2.1 Multi-Currency Transaction Record

**What**: Each row captures a complete transaction with amounts in 4 currencies: holder, transaction, billing, and settlement.

**Key Column Groups**:
- Identity: HolderId, AccountId, CardNumber, CardNumberId
- Transaction: TransactionCode, TransactionAmount, TransactionCurrencyCode, TransactionDateTime
- Holder: HolderAmount, HolderCurrencyCode, FxRate
- Billing: BillingAmount, BillingCurrencyCode, BillRateAmount
- Settlement: SettlementAmount, SettlementCurrencyCode, SettlementConversionRate
- Fees: FxFeeName/Amount/Currency, F0FeeName/Amount/Currency
- Risk: Suspicious, RiskRuleCodes
- EPM: EpmMethodId, EpmTransactionId, EpmTransactionType, EpmTransactionStatusCode
- External: ExternalIban, ExternalBban, ExternalAccountName, ExternalSortCode, ExternalBIC

---

## 3. Data Overview

N/A - raw provider data with PII fields (masked).

---

## 4. Elements

Key elements (100+ columns total - showing most important):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Unique record identifier. PK. |
| 3 | @AccountsActivities@Id-862157 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent table Tribe.AccountsActivities-862157.@Id. |
| 4 | HolderId | nvarchar(max) | YES | - | CODE-BACKED | Tribe holder (customer) identifier. |
| 5 | AccountId | nvarchar(max) | YES | - | CODE-BACKED | Tribe account identifier. |
| 6 | TransactionCode | nvarchar(max) | YES | - | CODE-BACKED | Transaction type code from Tribe. |
| 7 | TransactionAmount | nvarchar(max) | YES | - | CODE-BACKED | Transaction amount (as string). |
| 8 | TransactionCurrencyAlpha | nvarchar(max) | YES | - | CODE-BACKED | Transaction currency ISO alpha code. |
| 9 | HolderAmount | nvarchar(max) | YES | - | CODE-BACKED | Amount in holder's currency (as string). |
| 10 | HolderCurrencyAlpha | nvarchar(max) | YES | - | CODE-BACKED | Holder currency ISO alpha code. |
| 11 | Suspicious | nvarchar(max) | YES | - | CODE-BACKED | Risk flag: whether transaction was flagged as suspicious. |
| 12 | RiskRuleCodes | nvarchar(max) | YES | - | CODE-BACKED | Comma-separated risk rule codes that fired. |
| 13 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source system timestamp. |

(Full column list: 100+ columns - see DDL for complete definition)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AccountsActivities@Id-862157 | Tribe.AccountsActivities-862157 | Implicit FK | Parent file container |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.AccountsActivities_AccountActivity-833937 (table)
└── Tribe.AccountsActivities-862157 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.AccountsActivities-862157 | Table | Parent (implicit FK) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AccountsActivities_AccountActivity-833937 | CLUSTERED | @Id ASC | - | - | Active |
| IX_AccountsActivities_AccountActivity-833937_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (defaults) | DEFAULT | @Created and Created default to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent activity records
```sql
SELECT TOP 5 [@Id], HolderId, AccountId, TransactionCode, TransactionAmount,
       TransactionCurrencyAlpha, HolderAmount, Created
FROM Tribe.[AccountsActivities_AccountActivity-833937] WITH (NOLOCK)
ORDER BY Created DESC;
```

### 8.2 Find transactions by holder
```sql
SELECT TransactionCode, TransactionAmount, TransactionCurrencyAlpha, TransactionDateTime
FROM Tribe.[AccountsActivities_AccountActivity-833937] WITH (NOLOCK)
WHERE HolderId = '12345' ORDER BY Created DESC;
```

### 8.3 Find suspicious transactions
```sql
SELECT [@Id], HolderId, AccountId, Suspicious, RiskRuleCodes, TransactionAmount, Created
FROM Tribe.[AccountsActivities_AccountActivity-833937] WITH (NOLOCK)
WHERE Suspicious = 'true' ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.AccountsActivities_AccountActivity-833937 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.AccountsActivities_AccountActivity-833937.sql*
