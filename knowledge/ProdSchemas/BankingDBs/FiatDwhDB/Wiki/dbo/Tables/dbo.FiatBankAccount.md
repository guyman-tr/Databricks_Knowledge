# dbo.FiatBankAccount

> Stores bank account details (IBAN, sort code, BIC) linked to customer fiat accounts, representing both internal platform bank accounts and external third-party bank accounts used for payments and transfers.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (+ PK + unique) |

---

## 1. Business Meaning

FiatBankAccount represents bank accounts in the fiat platform. Each record stores the details of a bank account that is either internal (belonging to the platform for holding customer funds) or external (a customer's personal bank account used as a destination for withdrawals or source for deposits). Key details include IBAN, sort code, BIC/SWIFT, and BSB code - supporting multiple banking regions (UK, EU, Australia).

This table exists because the fiat platform needs to track bank account details for payment processing. Internal bank accounts are created by the provider (Tribe) when a customer gets an IBAN sub-program. External bank accounts are registered when customers add a payee for outgoing bank transfers. Without this table, the platform would not know where to send or receive banking payments.

Data is created by the dbo.AddBankAccount stored procedure when the application service registers a new bank account (either internal or external). Bank accounts are looked up by GUID (GetBankAccountByGuid) or by ID (GetBankAccountById) for payment processing and display.

---

## 2. Business Logic

### 2.1 Internal vs External Bank Accounts

**What**: Classification of bank accounts as platform-owned (internal) or customer-owned (external).

**Columns/Parameters Involved**: `IsExternal`, `CurrencyBalanceId`, `BankAccountGuid`

**Rules**:
- IsExternal = 0 (false): Internal platform bank account. CurrencyBalanceId is populated, linking to the customer's currency balance. These are created when a customer gets an IBAN sub-program.
- IsExternal = 1 (true): External customer bank account (payee). CurrencyBalanceId is typically NULL. These are registered when customers add external bank accounts for withdrawals.
- BankAccountGuid is a unique external-facing identifier used by the application and provider APIs.

**Diagram**:
```
Internal Bank Account (IsExternal=0):
  Customer -> FiatAccount -> FiatCurrencyBalances -> FiatBankAccount
                                                     (CurrencyBalanceId set)

External Bank Account (IsExternal=1):
  Customer adds payee -> FiatBankAccount (standalone, CurrencyBalanceId NULL)
  Used as destination for outgoing bank transfers
```

### 2.2 Multi-Region Banking Details

**What**: Bank account identification fields supporting UK, EU, and Australian banking systems.

**Columns/Parameters Involved**: `Iban`, `SortCode`, `Bic`, `BankAccountNumber`, `BsbCode`, `Ncc`

**Rules**:
- UK accounts: SortCode + BankAccountNumber (Faster Payments, Bacs)
- EU/SEPA accounts: Iban + Bic (SEPA transfers)
- Australian accounts: BsbCode + BankAccountNumber (NPP/direct entry)
- Ncc: National Clearing Code for other regions
- Not all fields populated for every account - depends on the banking region

---

## 3. Data Overview

| Id | IsExternal | BankAccountGuid | Nickname | Created | CurrencyBalanceId | Meaning |
|---|---|---|---|---|---|---|
| 4405561 | false | 0573B98D-... | NULL | 2026-04-14 | 2135646 | Internal platform bank account linked to currency balance 2135646 - likely a new IBAN account |
| 4405560 | true | 5EAFDE3C-... | NULL | 2026-04-14 | NULL | External payee bank account registered by a customer for outgoing transfers |
| 4405559 | false | 33A23D7F-... | NULL | 2026-04-14 | 2135645 | Internal platform bank account linked to currency balance 2135645 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | IsExternal | bit | NO | - | CODE-BACKED | Classifies the bank account: 0=internal platform bank account (linked to currency balance), 1=external customer payee bank account (standalone). Determines how the account is used in payment flows. |
| 3 | BankAccountGuid | uniqueidentifier | NO | - | CODE-BACKED | Unique external-facing identifier for this bank account. Used by application APIs and provider integrations. Has a unique constraint. |
| 4 | FullName | nvarchar(128) MASKED | NO | - | CODE-BACKED | Full name of the bank account holder. Masked with dynamic data masking (DDM) for PII protection - only privileged users see the actual value. |
| 5 | Nickname | nvarchar(128) | YES | - | NAME-INFERRED | Optional user-assigned friendly name for the bank account (e.g., "My savings"). Used for display in the customer's account list. |
| 6 | BankAccountNumber | nvarchar(128) MASKED | YES | - | CODE-BACKED | Bank account number. Masked for PII protection. Format varies by region (UK: 8 digits, other regions vary). |
| 7 | SortCode | nvarchar(128) | YES | - | CODE-BACKED | UK bank sort code (6 digits, e.g., "040004"). Used together with BankAccountNumber for UK Faster Payments and Bacs transfers. NULL for non-UK accounts. |
| 8 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this bank account record was created in the data warehouse. |
| 9 | Iban | nvarchar(128) MASKED | YES | - | CODE-BACKED | International Bank Account Number. Masked for PII protection. Used for SEPA transfers in EU/EEA. NULL for non-IBAN accounts (e.g., UK-only sort code accounts). |
| 10 | Bic | nvarchar(128) | YES | - | CODE-BACKED | Bank Identifier Code (SWIFT/BIC). Identifies the bank for international transfers. Used alongside IBAN for SEPA payments. |
| 11 | EventTimestamp | datetime2(7) | YES | - | CODE-BACKED | Timestamp of the original event in the source system that created or modified this bank account. May differ from Created (DWH insertion time). |
| 12 | CurrencyBalanceId | bigint | YES | - | CODE-BACKED | FK to dbo.FiatCurrencyBalances.Id. Links internal bank accounts to their associated currency balance. NULL for external payee accounts. |
| 13 | BsbCode | nvarchar(128) | YES | - | CODE-BACKED | Australian Bank-State-Branch code (6 digits). Used together with BankAccountNumber for Australian NPP and direct entry payments. NULL for non-Australian accounts. |
| 14 | Ncc | nvarchar(128) | YES | - | NAME-INFERRED | National Clearing Code. Used for bank identification in regions that don't use IBAN or sort code systems. NULL when other identifiers are sufficient. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyBalanceId | dbo.FiatCurrencyBalances | Implicit | Links internal bank accounts to their currency balance (nullable - NULL for external accounts) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.FiatCurrencyBalances | BankAccountId | FK | Currency balances reference their associated bank account |
| dbo.FiatTransactions | ExternalBankAccountId | FK | Transactions reference the external bank account involved |
| dbo.AddBankAccount | INSERT | Writer | Creates new bank account records |
| dbo.GetBankAccountByGuid | SELECT | Reader | Looks up bank account by GUID |
| dbo.GetBankAccountById | SELECT | Reader | Looks up bank account by ID |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCurrencyBalances | Table | FK from BankAccountId |
| dbo.FiatTransactions | Table | FK from ExternalBankAccountId |
| dbo.AddBankAccount | Stored Procedure | Inserts new bank account records |
| dbo.GetBankAccountByGuid | Stored Procedure | Reads bank account by GUID |
| dbo.GetBankAccountById | Stored Procedure | Reads bank account by ID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatBankAccount | CLUSTERED | Id ASC | - | - | Active |
| UIX_FiatBankAccount_BankAccountGuid | NC UNIQUE | BankAccountGuid ASC | - | - | Active |
| IX_FiatBankAccount_BankAccountGuid | NONCLUSTERED | Id ASC, BankAccountGuid ASC | FullName, Nickname, BankAccountNumber, SortCode, Created | - | Active |
| IX_FiatBankAccount_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UIX_FiatBankAccount_BankAccountGuid | UNIQUE | Ensures each bank account has a globally unique GUID |

---

## 8. Sample Queries

### 8.1 Find a bank account by GUID
```sql
SELECT Id, IsExternal, FullName, BankAccountNumber, SortCode, Iban, Bic, CurrencyBalanceId
FROM dbo.FiatBankAccount WITH (NOLOCK)
WHERE BankAccountGuid = '0573B98D-EA13-4487-8E4F-6B1D9E533D85';
```

### 8.2 List all internal bank accounts with their currency balance link
```sql
SELECT ba.Id, ba.BankAccountGuid, ba.CurrencyBalanceId, ba.Created
FROM dbo.FiatBankAccount ba WITH (NOLOCK)
WHERE ba.IsExternal = 0 AND ba.CurrencyBalanceId IS NOT NULL
ORDER BY ba.Created DESC;
```

### 8.3 Find external payee bank accounts created recently
```sql
SELECT TOP 20 Id, BankAccountGuid, FullName, Iban, SortCode, BsbCode, Created
FROM dbo.FiatBankAccount WITH (NOLOCK)
WHERE IsExternal = 1
ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Banking Database](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290242096) | Confluence | FiatDwhDB stores "information about fiat account/currency balance account/bank account" |
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | Bank account overview queries show relationship between bank accounts and currency balances |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 9.3/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatBankAccount | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatBankAccount.sql*
