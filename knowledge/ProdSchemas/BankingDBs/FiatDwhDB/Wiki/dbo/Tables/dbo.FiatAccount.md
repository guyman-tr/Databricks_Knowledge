# dbo.FiatAccount

> Central entity table representing a customer's fiat money account on the platform, linking to cards, currency balances, transactions, and program transitions.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (+ PK + unique) |

---

## 1. Business Meaning

FiatAccount is the central entity table for the fiat platform's data warehouse. Each record represents a single customer's fiat money account, identified by a GCID (Global Customer ID) and an AccountGuid (external-facing unique identifier). The account is assigned to an Account Program (card or IBAN) and optionally a SubProgram (specific regional/tier variant). All other entities in the schema - cards, currency balances, transactions, statuses, provider mappings - link back to this table.

This table exists because every customer interaction with the fiat platform requires an account context. A customer must have a FiatAccount before they can receive cards, hold currency balances, or process transactions. The data warehouse copy mirrors the operational FiatWalletDB account data for reporting and historical analysis.

Data is created by the dbo.AddFiatAccount stored procedure when the operational system notifies the DWH of a new account. The account is looked up by GUID (GetAccountByAccountGuid), by ID (GetAccountByAccountId), in batch by GUIDs (GetFiatAccountsByAccountGuids), or paginated (GetAccountsByPage). The DailyBalanceCalculation/Sync procedures reference it to match customers to their balances.

---

## 2. Business Logic

### 2.1 Account-Customer Relationship

**What**: One-to-one mapping between a GCID (customer) and their fiat account.

**Columns/Parameters Involved**: `Id`, `Gcid`, `AccountGuid`

**Rules**:
- Each customer (GCID) has at most one fiat account (enforced by UIX_FiatAccount_Gcid_AccountGuid unique constraint)
- AccountGuid is the external-facing identifier used in APIs and provider integrations
- Id is the internal surrogate key used in FK relationships throughout the schema

### 2.2 Program Assignment

**What**: Each account is assigned to an account program type and optionally a specific sub-program variant.

**Columns/Parameters Involved**: `AccountProgramId`, `SubProgramId`

**Rules**:
- AccountProgramId: 0=Unknown, 1=card, 2=iban. See [Account Program](../../_glossary.md#account-program). Default is 1 (card).
- SubProgramId: Optional sub-program assignment (1-16). See [Sub-Program](../../_glossary.md#sub-program). NULL if not yet assigned to a specific variant.
- Program transitions (upgrades/downgrades) are tracked in dbo.ProgramTransitionsEligibility and dbo.FiatAccountsProperties

**Diagram**:
```
FiatAccount (central entity)
├── FiatAccountStatuses (lifecycle: Active/Suspended/Deleted)
├── FiatAccountsProperties (program assignment history)
├── FiatCards (debit cards)
│   ├── FiatCardInstances (physical/virtual instances)
│   ├── FiatCardStatuses (card lifecycle)
│   └── CardsProvidersMapping (Tribe card IDs)
├── FiatCurrencyBalances (currency balances)
│   ├── FiatBankAccount (bank account details)
│   ├── FiatCurrencyBalancesStatuses (balance lifecycle)
│   ├── CurrencyBalancesProvidersMapping (Tribe balance IDs)
│   └── PaymentSpecifications (direct debits)
├── FiatTransactions (all financial transactions)
│   ├── FiatTransactionsStatuses (transaction lifecycle)
│   └── TransactionsProvidersMapping (Tribe txn IDs)
├── AccountsProviderHoldersMapping (Tribe holder IDs)
├── BalanceReports (reconciliation snapshots)
└── ProgramTransitionsEligibility (upgrade/downgrade eligibility)
```

---

## 3. Data Overview

| Id | Gcid | AccountGuid | Created | AccountProgramId | SubProgramId | Meaning |
|---|---|---|---|---|---|---|
| 2135556 | 17689308 | 8C3984A1-... | 2026-04-14 | 2 | 13 | Customer 17689308 with an IBAN account in IBAN Green AUS sub-program |
| 2135555 | 47414124 | 12AAA44B-... | 2026-04-14 | 2 | 6 | Customer 47414124 with an IBAN account in IBAN EU Green sub-program |
| 2135554 | 18479782 | 312F23BD-... | 2026-04-14 | 2 | 4 | Customer 18479782 with an IBAN account in IBAN Standard UK sub-program |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. |
| 2 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. |
| 3 | AccountGuid | uniqueidentifier | NO | - | CODE-BACKED | External-facing unique identifier for this fiat account. Used in application APIs, provider integrations, and cross-system references. Indexed for efficient GUID-based lookups. |
| 4 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this account record was created in the data warehouse. Indexed for time-range queries. |
| 5 | AccountProgramId | tinyint | NO | 1 | CODE-BACKED | Account program type: 0=Unknown, 1=card (default), 2=iban. See [Account Program](../../_glossary.md#account-program). (Dictionary.AccountPrograms). Determines the fundamental product type (card-based vs IBAN-based banking). |
| 6 | SubProgramId | tinyint | YES | - | CODE-BACKED | Specific sub-program variant: 1-16 (e.g., Card Premium UK, IBAN EU Green). See [Sub-Program](../../_glossary.md#sub-program). FK to dbo.SubPrograms. NULL if not yet assigned to a specific variant. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountProgramId | Dictionary.AccountPrograms | Implicit | Account program type (card/iban) |
| SubProgramId | dbo.SubPrograms | Implicit | Specific sub-program variant (nullable) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.FiatAccountStatuses | AccountId | FK | Account status history |
| dbo.FiatAccountsProperties | AccountId | FK | Account property snapshots |
| dbo.FiatCards | AccountId | FK | Cards issued to this account |
| dbo.FiatCurrencyBalances | AccountId | FK | Currency balances held by this account |
| dbo.FiatTransactions | AccountId | FK | Transactions on this account |
| dbo.AccountsProviderHoldersMapping | AccountId | FK | Provider-side holder IDs |
| dbo.BalanceReports | AccountId | FK | Balance reconciliation snapshots |
| dbo.ProgramTransitionsEligibility | AccountId | FK | Program transition eligibility |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (table is a leaf node).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccountStatuses | Table | FK from AccountId |
| dbo.FiatAccountsProperties | Table | FK from AccountId |
| dbo.FiatCards | Table | FK from AccountId |
| dbo.FiatCurrencyBalances | Table | FK from AccountId |
| dbo.FiatTransactions | Table | FK from AccountId |
| dbo.AccountsProviderHoldersMapping | Table | FK from AccountId |
| dbo.BalanceReports | Table | FK from AccountId |
| dbo.ProgramTransitionsEligibility | Table | FK from AccountId |
| dbo.AddFiatAccount | Stored Procedure | Inserts new accounts |
| dbo.GetAccountByAccountGuid | Stored Procedure | Reads account by GUID |
| dbo.GetAccountByAccountId | Stored Procedure | Reads account by Id |
| dbo.GetAccountsByPage | Stored Procedure | Paginated account listing |
| dbo.GetFiatAccountsByAccountGuids | Stored Procedure | Batch GUID lookup |
| dbo.DailyBalanceCalculation | Stored Procedure | Joins for balance calculation |
| dbo.DailyBalanceSync | Stored Procedure | Joins for balance sync |
| dbo.CalcAccountSettled | Stored Procedure | Calculates settled amounts |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatAccount | CLUSTERED | Id ASC | - | - | Active |
| UIX_FiatAccount_Gcid_AccountGuid | NC UNIQUE | Gcid ASC, AccountGuid ASC | - | - | Active |
| IX_FiatAccount_AccountGuid | NONCLUSTERED | AccountGuid ASC | Gcid, Created | - | Active |
| IX_FiatAccount_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UIX_FiatAccount_Gcid_AccountGuid | UNIQUE | Ensures one account per customer-GUID combination |
| (default) | DEFAULT | AccountProgramId defaults to 1 (card) |

---

## 8. Sample Queries

### 8.1 Find an account by GCID
```sql
SELECT a.Id, a.Gcid, a.AccountGuid, a.AccountProgramId, a.SubProgramId, sp.Name AS SubProgram
FROM dbo.FiatAccount a WITH (NOLOCK)
LEFT JOIN dbo.SubPrograms sp WITH (NOLOCK) ON sp.Id = a.SubProgramId
WHERE a.Gcid = 17689308;
```

### 8.2 Find an account by GUID
```sql
SELECT * FROM dbo.FiatAccount WITH (NOLOCK)
WHERE AccountGuid = '8C3984A1-CF81-4534-A907-5D81F2362D90';
```

### 8.3 Count accounts by sub-program
```sql
SELECT sp.Name, sp.Region, COUNT(*) AS AccountCount
FROM dbo.FiatAccount a WITH (NOLOCK)
JOIN dbo.SubPrograms sp WITH (NOLOCK) ON sp.Id = a.SubProgramId
GROUP BY sp.Name, sp.Region
ORDER BY AccountCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Banking Database](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290242096) | Confluence | FiatDwhDB stores "information about fiat account/currency balance account/bank account" |
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | `SELECT * FROM dbo.FiatAccount WHERE Gcid=XXXXXXX` is a primary lookup pattern; AccountsProviderHoldersMapping provides Tribe holder mapping |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatAccount | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatAccount.sql*
