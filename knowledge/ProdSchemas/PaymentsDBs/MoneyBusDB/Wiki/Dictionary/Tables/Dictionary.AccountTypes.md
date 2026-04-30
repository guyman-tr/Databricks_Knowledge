# Dictionary.AccountTypes

> Lookup table that classifies the types of financial accounts involved in money transfer transactions and withdrawals within the MoneyBus payment system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.AccountTypes defines the classification of financial accounts that participate in money transfer operations. Each account type represents a distinct product vertical within the platform - from standard trading accounts to managed portfolio accounts. This table is the canonical source for resolving AccountTypeID, CreditorTypeID, and DebitorTypeID columns across the MoneyBus schema.

This table is essential because every transaction in the MoneyBus system involves at least one account type reference. Transactions carry both a creditor and debitor account type (the two sides of a fund movement), withdrawals carry the source account type, and transfer limits are defined per account type pair. Without this lookup, the system cannot determine which product rules apply to a given fund movement.

Data flow: This is a static reference table - rows are managed by DBAs or schema migrations, not by application code. It is read by numerous stored procedures including the alert system (ALERT_ConsecutiveTransactionFailuresAlert), withdrawal procedures (WithdrawAdd, WithdrawGet), and transaction group procedures (TransactionsAndGroupAdd). The IDENTITY column indicates new types can be added without specifying IDs.

---

## 2. Business Logic

### 2.1 Account Type Classification for Fund Movements

**What**: Each money transfer involves a source (debitor) and destination (creditor) account type, enabling the system to apply product-specific rules and limits.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- Transactions reference AccountTypes twice: once for the creditor side (CreditorTypeID) and once for the debitor side (DebitorTypeID), allowing cross-product transfers (e.g., Trading-to-IBAN withdrawal)
- Transfer limits (MoneyBus.TransferLimits) are defined per DebitAccountTypeID/CreditAccountTypeID pair, controlling maximum amounts per product combination
- Withdrawals carry a single AccountTypeID representing the source account from which funds are withdrawn
- Transaction groups track the InitiatorAccountTypeId to record which product context initiated the grouped operation

**Diagram**:
```
MoneyBus.Transactions:
  CreditorTypeID ---> Dictionary.AccountTypes.ID (destination)
  DebitorTypeID  ---> Dictionary.AccountTypes.ID (source)

MoneyBus.TransferLimits:
  DebitAccountTypeID  ---> Dictionary.AccountTypes.ID
  CreditAccountTypeID ---> Dictionary.AccountTypes.ID

MoneyBus.Withdrawals:
  AccountTypeID ---> Dictionary.AccountTypes.ID (source account)
```

---

## 3. Data Overview

| ID | Name | Meaning |
|----|------|---------|
| 1 | Trading | Standard trading account for equity/CFD positions - the primary account type for most platform fund movements including deposits, withdrawals, and internal transfers |
| 2 | Options | Options trading account for options-specific fund flows - separated from Trading to apply distinct margin and settlement rules |
| 3 | IBAN | IBAN-based bank account representing external banking endpoints used for deposit/withdrawal operations via SEPA or wire transfer channels |
| 4 | MoneyFarm | Managed portfolio (robo-advisor) account for automated investment fund flows - distinct from self-directed Trading accounts |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | Auto-increment | CODE-BACKED | Primary key and unique identifier for each account type. Referenced as CreditorTypeID, DebitorTypeID (MoneyBus.Transactions), AccountTypeID (MoneyBus.Withdrawals), DebitAccountTypeID/CreditAccountTypeID (MoneyBus.TransferLimits), and InitiatorAccountTypeId (MoneyBus.TransactionsGroup). Values: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See [Account Type](../../_glossary.md#account-type) for full business definitions. |
| 2 | Name | nvarchar(50) | NO | - | CODE-BACKED | Human-readable label for the account type. Used in alert reporting (ALERT_ConsecutiveTransactionFailuresAlert JOINs this column to display creditor/debitor type names). Unique business names that map to platform product verticals. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.Transactions | CreditorTypeID | Implicit Lookup | Account type of the creditor (destination) side of a transaction |
| MoneyBus.Transactions | DebitorTypeID | Implicit Lookup | Account type of the debitor (source) side of a transaction |
| MoneyBus.TransferLimits | DebitAccountTypeID | Implicit Lookup | Account type constraint for the debit side of transfer limit rules |
| MoneyBus.TransferLimits | CreditAccountTypeID | Implicit Lookup | Account type constraint for the credit side of transfer limit rules |
| MoneyBus.TransactionsGroup | InitiatorAccountTypeId | Implicit Lookup | Account type of the product context that initiated the transaction group |
| MoneyBus.Withdrawals | AccountTypeID | Implicit Lookup | Source account type from which the withdrawal is being made |
| History.MoneyBusWithdrawals | AccountTypeID | Implicit Lookup | Historical record of the source account type for archived withdrawals |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Transactions | Table | CreditorTypeID and DebitorTypeID reference AccountTypes.ID |
| MoneyBus.TransferLimits | Table | DebitAccountTypeID and CreditAccountTypeID reference AccountTypes.ID |
| MoneyBus.TransactionsGroup | Table | InitiatorAccountTypeId references AccountTypes.ID |
| MoneyBus.Withdrawals | Table | AccountTypeID references AccountTypes.ID |
| History.MoneyBusWithdrawals | Table | AccountTypeID references AccountTypes.ID |
| MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert | Stored Procedure | JOINs to resolve CreditorTypeID and DebitorTypeID to names for alert output |
| MoneyBus.TransactionsAndGroupAdd | Stored Procedure | Passes InitiatorAccountTypeId when creating transaction groups |
| MoneyBus.TransactionsGroupAdd | Stored Procedure | Inserts InitiatorAccountTypeId into TransactionsGroup |
| MoneyBus.TransactionsGroupGet | Stored Procedure | Reads InitiatorAccountTypeId from TransactionsGroup |
| MoneyBus.TransferLimitsGet | Stored Procedure | Reads DebitAccountTypeID and CreditAccountTypeID from TransferLimits |
| MoneyBus.WithdrawAdd | Stored Procedure | Inserts AccountTypeID into Withdrawals |
| MoneyBus.WithdrawGet | Stored Procedure | Reads AccountTypeID from Withdrawals |
| MoneyBus.WithdrawGetList | Stored Procedure | Reads AccountTypeID from Withdrawals |
| MoneyBus.WithdrawGetListV2 | Stored Procedure | Reads AccountTypeID from Withdrawals |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all account types
```sql
SELECT ID, Name
FROM Dictionary.AccountTypes WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find transactions between two specific account types
```sql
SELECT t.TransactionID, t.Amount,
       cred.Name AS CreditorType,
       deb.Name AS DebitorType
FROM MoneyBus.Transactions t WITH (NOLOCK)
INNER JOIN Dictionary.AccountTypes cred WITH (NOLOCK) ON cred.ID = t.CreditorTypeID
INNER JOIN Dictionary.AccountTypes deb WITH (NOLOCK) ON deb.ID = t.DebitorTypeID
WHERE t.CreditorTypeID = 1 -- Trading
  AND t.DebitorTypeID = 3  -- IBAN
```

### 8.3 View transfer limits by account type pair
```sql
SELECT da.Name AS DebitAccountType,
       ca.Name AS CreditAccountType,
       tl.*
FROM MoneyBus.TransferLimits tl WITH (NOLOCK)
LEFT JOIN Dictionary.AccountTypes da WITH (NOLOCK) ON da.ID = tl.DebitAccountTypeID
LEFT JOIN Dictionary.AccountTypes ca WITH (NOLOCK) ON ca.ID = tl.CreditAccountTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this object. General MoneyBus pages exist in Confluence but do not contain AccountTypes-specific documentation.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AccountTypes | Type: Table | Source: MoneyBusDB/Dictionary/Tables/Dictionary.AccountTypes.sql*
