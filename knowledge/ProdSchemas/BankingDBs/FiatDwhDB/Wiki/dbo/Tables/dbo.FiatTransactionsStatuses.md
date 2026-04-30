# dbo.FiatTransactionsStatuses

> Event-sourced transaction status table tracking the complete lifecycle of each financial transaction, including amounts, currencies, risk actions, and authorization details.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (+ PK + unique) |

---

## 1. Business Meaning

FiatTransactionsStatuses records every status event for a financial transaction, including the authorization type, amounts in both holder and transaction currencies, accumulated balance impact, and risk action flags. This is the richest status table in the schema - each row captures the complete financial snapshot at the moment of a status change.

This table exists because transactions go through multiple states (Authorized -> Settled, or Failed/Rejected), and each state carries different financial amounts and risk assessments. The unique constraint on (TransactionId, TransactionStatusId, AuthorizationType, TransactionOccured) prevents duplicate status events.

Data is created by dbo.AddTransacitonStatuses (note: typo preserved from source).

---

## 2. Business Logic

### 2.1 Transaction Status Lifecycle with Amounts

**What**: Each status event captures the financial state of the transaction at that point.

**Columns/Parameters Involved**: `TransactionStatusId`, `AuthorizationType`, `HolderAmount`, `HolderCurrency`, `TransactionAmount`, `TransactionCurrency`, `AccumulatedAmount`

**Rules**:
- TransactionStatusId: 0=Failed, 1=Authorized, 2=Settled, 3=Rejected, 4=Returned, 5=Expired, 6=Reserved, 7=Cancelled. See [Transaction Status](../../_glossary.md#transaction-status).
- AuthorizationType: 0-14. See [Authorization Type](../../_glossary.md#authorization-type).
- HolderAmount/HolderCurrency: Amount in the cardholder's account currency
- TransactionAmount/TransactionCurrency: Amount in the merchant's currency (may differ for cross-border)
- AccumulatedAmount: Running accumulated impact on the balance

### 2.2 Risk Action Flags

**What**: Boolean flags indicating risk-triggered actions taken during transaction processing.

**Columns/Parameters Involved**: `MarkTransactionAsSuspiciousRiskAction`, `ChangeCardStatusToRiskRiskAction`, `ChangeAccountStatusToSuspendedRiskAction`, `RejectTransactionRiskAction`

**Rules**:
- These flags record risk engine decisions made during transaction processing
- Multiple flags can be true simultaneously (e.g., mark suspicious AND change card status)
- All default to 0 (no action) - only set to 1 when risk engine triggers
- RejectTransactionRiskAction=1 means the risk engine blocked the transaction

---

## 3. Data Overview

N/A - querying live transaction status data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | TransactionId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatTransactions.Id. The transaction this status belongs to. |
| 3 | TransactionStatusId | int | NO | - | CODE-BACKED | Status: 0-7. See [Transaction Status](../../_glossary.md#transaction-status). (Dictionary.TransactionStatuses) |
| 4 | AuthorizationType | int | NO | - | CODE-BACKED | Authorization type: 0-14. See [Authorization Type](../../_glossary.md#authorization-type). (Dictionary.AuthorizationTypes) |
| 5 | HolderAmount | decimal(36,18) | NO | - | CODE-BACKED | Transaction amount in the cardholder's account currency. |
| 6 | HolderCurrency | varchar(3) | NO | - | CODE-BACKED | ISO 4217 alphabetical currency code of the holder's balance (e.g., "GBP", "EUR"). |
| 7 | TransactionAmount | decimal(36,18) | NO | - | CODE-BACKED | Transaction amount in the merchant/originator currency. May differ from HolderAmount for cross-border transactions. |
| 8 | TransactionCurrency | varchar(3) | NO | - | CODE-BACKED | ISO 4217 alphabetical currency code of the transaction (e.g., "USD" for a US merchant). |
| 9 | AccumulatedAmount | decimal(36,18) | NO | - | CODE-BACKED | Cumulative balance impact from this transaction across all its status events. Used for reconciliation. |
| 10 | TransactionOccured | datetime2(7) | NO | - | CODE-BACKED | When the transaction event occurred (source system timestamp). Part of unique constraint. |
| 11 | Created | datetime2(7) | NO | - | CODE-BACKED | When this record was written to the DWH. |
| 12 | RiskRuleCodes | nvarchar(max) | YES | - | CODE-BACKED | Comma-separated risk rule codes that were triggered during this transaction. NULL if no risk rules fired. |
| 13 | MarkTransactionAsSuspiciousRiskAction | bit | NO | 0 | CODE-BACKED | Risk action: 1=transaction flagged as suspicious for review. Default 0. |
| 14 | ChangeCardStatusToRiskRiskAction | bit | NO | 0 | CODE-BACKED | Risk action: 1=card status changed to Risk(4) due to this transaction. Default 0. |
| 15 | ChangeAccountStatusToSuspendedRiskAction | bit | NO | 0 | CODE-BACKED | Risk action: 1=account suspended due to this transaction's risk assessment. Default 0. |
| 16 | RejectTransactionRiskAction | bit | NO | 0 | CODE-BACKED | Risk action: 1=transaction rejected by the risk engine. Default 0. |
| 17 | CorrelationId | uniqueidentifier | YES | NULL | CODE-BACKED | Links this status event to the business operation for distributed tracing. Nullable for legacy records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransactionId | dbo.FiatTransactions | FK | The transaction this status belongs to |
| TransactionStatusId | Dictionary.TransactionStatuses | Implicit | Status value |
| AuthorizationType | Dictionary.AuthorizationTypes | Implicit | Authorization type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddTransacitonStatuses | INSERT | Writer | Records transaction status events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.FiatTransactionsStatuses (table)
└── dbo.FiatTransactions (table)
    ├── dbo.FiatAccount (table)
    ├── dbo.FiatCards (table)
    ├── dbo.FiatCurrencyBalances (table)
    ├── dbo.FiatBankAccount (table)
    └── dbo.FiatMerchants (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatTransactions | Table | FK from TransactionId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddTransacitonStatuses | Stored Procedure | Writes status records |
| dbo.DailyBalanceCalculation | Stored Procedure | Reads settled transactions for balance calc |
| dbo.CalcAccountSettled | Stored Procedure | Calculates settled amounts |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatTransactionsStatuses | CLUSTERED | Id ASC | - | - | Active |
| UIX_FiatTransactionsStatuses_... | NC UNIQUE | TransactionId, TransactionStatusId, AuthorizationType, TransactionOccured | - | - | Active |
| IX_FiatTransactionsStatuses_Created | NONCLUSTERED | Created ASC | - | - | Active |
| ix_FiatTransactionsStatuses_TransactionStatusId_... | NONCLUSTERED | TransactionStatusId ASC | AccumulatedAmount, TransactionId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_FiatTransactionsStatuses_TransactionId_FiatTransactions_Id | FK | TransactionId -> dbo.FiatTransactions.Id |
| (defaults) | DEFAULT | All risk action flags default to 0; CorrelationId defaults to NULL |

---

## 8. Sample Queries

### 8.1 Get full status history for a transaction
```sql
SELECT ts.TransactionStatusId, dst.Name AS Status, at.Name AS AuthType,
       ts.HolderAmount, ts.HolderCurrency, ts.TransactionAmount, ts.TransactionCurrency,
       ts.AccumulatedAmount, ts.TransactionOccured
FROM dbo.FiatTransactionsStatuses ts WITH (NOLOCK)
JOIN Dictionary.TransactionStatuses dst WITH (NOLOCK) ON dst.Id = ts.TransactionStatusId
JOIN Dictionary.AuthorizationTypes at WITH (NOLOCK) ON at.Id = ts.AuthorizationType
WHERE ts.TransactionId = 28513721 ORDER BY ts.TransactionOccured;
```

### 8.2 Find transactions with risk actions
```sql
SELECT ts.TransactionId, ts.RiskRuleCodes,
       ts.MarkTransactionAsSuspiciousRiskAction AS Suspicious,
       ts.ChangeCardStatusToRiskRiskAction AS CardRisk,
       ts.ChangeAccountStatusToSuspendedRiskAction AS AcctSuspended,
       ts.RejectTransactionRiskAction AS Rejected
FROM dbo.FiatTransactionsStatuses ts WITH (NOLOCK)
WHERE (ts.MarkTransactionAsSuspiciousRiskAction = 1 OR ts.ChangeCardStatusToRiskRiskAction = 1
       OR ts.ChangeAccountStatusToSuspendedRiskAction = 1 OR ts.RejectTransactionRiskAction = 1)
AND ts.Created >= DATEADD(DAY, -1, GETUTCDATE())
ORDER BY ts.Created DESC;
```

### 8.3 Settled transactions with amounts (from Confluence pattern)
```sql
SELECT t.TransactionGuid, tt.Name AS Type, dst.Name AS Status,
       ts.HolderAmount, ts.HolderCurrency, ts.AccumulatedAmount, ts.TransactionOccured
FROM dbo.FiatTransactions t WITH (NOLOCK)
JOIN dbo.FiatTransactionsStatuses ts WITH (NOLOCK) ON ts.TransactionId = t.Id
JOIN Dictionary.TransactionTypes tt WITH (NOLOCK) ON tt.Id = t.TransactionTypeId
JOIN Dictionary.TransactionStatuses dst WITH (NOLOCK) ON dst.Id = ts.TransactionStatusId
WHERE t.CurrencyBalanceId = 730092 AND ts.TransactionStatusId = 2
ORDER BY ts.TransactionOccured DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | "All the successful transactions and its statuses" query pattern with Dictionary joins documented for FiatCustodianDB |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatTransactionsStatuses | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatTransactionsStatuses.sql*
