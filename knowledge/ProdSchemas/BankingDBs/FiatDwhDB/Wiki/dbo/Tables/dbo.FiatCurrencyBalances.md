# dbo.FiatCurrencyBalances

> Entity table representing currency-specific balance containers within a fiat account, linking to bank accounts, transactions, payment specifications, and provider mappings.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 4 active (+ PK) |

---

## 1. Business Meaning

FiatCurrencyBalances represents a specific currency balance container within a customer's fiat account. A single account can hold multiple currency balances (e.g., one in EUR and one in GBP). Each currency balance is the anchor point for transactions, bank account linkage, payment specifications (direct debits), and balance status tracking.

This table exists because the fiat platform supports multi-currency accounts. A customer's account may have separate balance containers for different currencies, each with its own bank account (for IBAN programs), transactions, and lifecycle status. The currency balance is the fundamental unit at which money is held and moved.

Data is created by dbo.AddCurrencyBalances when a new currency balance is provisioned. Lookups use dbo.GetCurrencyBalancesByGuid and dbo.GetCurrencyBalancesById.

---

## 2. Business Logic

### 2.1 Multi-Currency Account Structure

**What**: A fiat account can hold multiple currency-specific balance containers.

**Columns/Parameters Involved**: `AccountId`, `CurrencyISON`, `BankAccountId`, `CurrencyBalanceGuid`

**Rules**:
- Each currency balance has a unique CurrencyBalanceGuid for external reference
- CurrencyISON stores the ISO numeric currency code (826=GBP, 978=EUR)
- BankAccountId links to the associated bank account (nullable - not all currency balances have a bank account)
- Transactions (FiatTransactions) reference CurrencyBalanceId to identify which balance was affected

**Diagram**:
```
FiatAccount
├── FiatCurrencyBalances (GBP, CurrencyISON=826)
│   ├── FiatBankAccount (IBAN for GBP)
│   ├── FiatTransactions (GBP transactions)
│   ├── PaymentSpecifications (GBP direct debits)
│   └── FiatCurrencyBalancesStatuses (balance lifecycle)
│
└── FiatCurrencyBalances (EUR, CurrencyISON=978)
    ├── FiatBankAccount (IBAN for EUR)
    ├── FiatTransactions (EUR transactions)
    └── FiatCurrencyBalancesStatuses
```

---

## 3. Data Overview

| Id | CurrencyBalanceGuid | AccountId | BankAccountId | CurrencyISON | Created | Meaning |
|---|---|---|---|---|---|---|
| 2135699 | 26C43A5A-... | 2135580 | NULL | 826 | 2026-04-14 | New GBP balance for account 2135580, no bank account linked yet |
| 2135698 | E39E48B7-... | 2135579 | NULL | 978 | 2026-04-14 | New EUR balance for account 2135579 |
| 2135697 | D7EA5EBE-... | 2135578 | NULL | 978 | 2026-04-14 | New EUR balance for account 2135578 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. Referenced by FiatTransactions, FiatCurrencyBalancesStatuses, CurrencyBalancesProvidersMapping, PaymentSpecifications, FiatBankAccount, and BalanceReports. |
| 2 | CurrencyBalanceGuid | uniqueidentifier | NO | - | CODE-BACKED | External-facing unique identifier. Used in APIs and provider integrations. Indexed with AccountId for lookup. |
| 3 | AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. The account this balance belongs to. |
| 4 | BankAccountId | bigint | YES | - | CODE-BACKED | FK to dbo.FiatBankAccount.Id. The internal bank account associated with this balance (for IBAN programs). NULL for card-only balances or newly created balances before bank account assignment. |
| 5 | CurrencyISON | nvarchar(128) | NO | - | CODE-BACKED | ISO 4217 numeric currency code. E.g., "826"=GBP, "978"=EUR, "036"=AUD. See [ISO Currency Info](../../_glossary.md#iso-currency-info). Indexed for currency-based queries. |
| 6 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this currency balance was created in the data warehouse. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountId | dbo.FiatAccount | FK | The account this balance belongs to |
| BankAccountId | dbo.FiatBankAccount | FK | Associated bank account (nullable) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.FiatCurrencyBalancesStatuses | CurrencyBalancesId | FK | Balance lifecycle events |
| dbo.CurrencyBalancesProvidersMapping | CurrencyBalanceId | FK | Provider-side balance ID mapping |
| dbo.FiatTransactions | CurrencyBalanceId | FK | Transactions on this balance |
| dbo.PaymentSpecifications | CurrencyBalanceId | FK | Direct debit specifications |
| dbo.FiatBankAccount | CurrencyBalanceId | Implicit | Back-reference from bank account |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.FiatCurrencyBalances (table)
├── dbo.FiatAccount (table)
└── dbo.FiatBankAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | FK from AccountId |
| dbo.FiatBankAccount | Table | FK from BankAccountId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCurrencyBalancesStatuses | Table | FK from CurrencyBalancesId |
| dbo.CurrencyBalancesProvidersMapping | Table | FK from CurrencyBalanceId |
| dbo.FiatTransactions | Table | FK from CurrencyBalanceId |
| dbo.PaymentSpecifications | Table | FK from CurrencyBalanceId |
| dbo.AddCurrencyBalances | Stored Procedure | Inserts currency balances |
| dbo.GetCurrencyBalancesByGuid | Stored Procedure | Reads by GUID |
| dbo.GetCurrencyBalancesById | Stored Procedure | Reads by ID |
| dbo.DailyBalanceCalculation | Stored Procedure | Joins for balance calc |
| dbo.CalcAccountSettled | Stored Procedure | Calculates settled amounts |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatCurrencyBalances | CLUSTERED | Id ASC | - | - | Active |
| IX_FiatCurrencyBalances_AccountId | NONCLUSTERED | AccountId ASC | - | - | Active |
| IX_FiatCurrencyBalances_Created | NONCLUSTERED | Created ASC | - | - | Active |
| IX_FiatCurrencyBalances_CurrencyBalanceGuid_AccountId | NONCLUSTERED | CurrencyBalanceGuid ASC, AccountId ASC | - | - | Active |
| nci_wi_FiatCurrencyBalances_... | NONCLUSTERED | CurrencyISON ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_FiatCurrencyBalances_AccountId_FiatAccount_Id | FK | AccountId -> dbo.FiatAccount.Id |
| FK_FiatCurrencyBalances_BankAccountId_FiatBankAccount_Id | FK | BankAccountId -> dbo.FiatBankAccount.Id |

---

## 8. Sample Queries

### 8.1 Find all currency balances for an account
```sql
SELECT cb.Id, cb.CurrencyBalanceGuid, cb.CurrencyISON, cb.BankAccountId, cb.Created
FROM dbo.FiatCurrencyBalances cb WITH (NOLOCK)
WHERE cb.AccountId = 2135580 ORDER BY cb.CurrencyISON;
```

### 8.2 Find currency balance by GUID
```sql
SELECT cb.*, a.Gcid
FROM dbo.FiatCurrencyBalances cb WITH (NOLOCK)
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = cb.AccountId
WHERE cb.CurrencyBalanceGuid = '26C43A5A-E8D5-4452-957B-015DF55A7453';
```

### 8.3 Count balances by currency
```sql
SELECT CurrencyISON, COUNT(*) AS BalanceCount
FROM dbo.FiatCurrencyBalances WITH (NOLOCK)
GROUP BY CurrencyISON ORDER BY BalanceCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Banking Database](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290242096) | Confluence | FiatDwhDB stores "information about fiat account/currency balance account/bank account" |
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | Currency balance is the key entity for transaction lookups and balance reconciliation |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatCurrencyBalances | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatCurrencyBalances.sql*
