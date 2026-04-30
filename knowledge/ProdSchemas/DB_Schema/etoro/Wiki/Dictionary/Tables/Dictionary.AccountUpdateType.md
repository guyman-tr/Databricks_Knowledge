# Dictionary.AccountUpdateType

> Lookup table defining the 14 types of account balance updates — deposits, cashouts, bonuses, trade operations, fees, and cancellations — that modify a customer's financial account.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AccountUpdateTypeID (INT, PK NONCLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK NC + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.AccountUpdateType classifies every type of financial operation that changes a customer's account balance. Every credit or debit posted to a customer's account through the billing system is tagged with an AccountUpdateTypeID to identify what caused the balance change.

Without this table, the billing system would have no structured way to distinguish a deposit from a cashout from a trade fee in the account transaction ledger. Reports, reconciliation, and auditing all depend on these classifications to categorize financial movements.

The table is heavily used by the billing engine. Billing.AmountAdd and Billing.AmountSubstract (the core credit/debit procedures) reference it to validate and categorize transactions. Billing.LoadAccountUpdateTypes loads all types into memory for the billing service. History.Account stores the AccountUpdateTypeID on every historical transaction record, making this table essential for financial reporting and audit trails.

---

## 2. Business Logic

### 2.1 Balance Update Categories

**What**: Classification of all financial operations that modify customer account balances.

**Columns/Parameters Involved**: `AccountUpdateTypeID`, `Name`

**Rules**:
- **Money-In operations**: Deposit (1), Bonus (3), GamePrize (5), Compensation (6), Champ Win (12) — these increase the customer's available balance
- **Money-Out operations**: Cashout (2), GameFee (4), End Of Week Fee (14) — these decrease the customer's available balance
- **Cancellation/Reversal operations**: GameCancellation (7), BonusCancellation (8), CashoutCancellation (9) — these reverse a previous operation
- **Trade operations**: Open Trade (10), Close Trade (11), Edit Stop Loss (13) — these represent margin holds and P&L settlements

**Diagram**:
```
Account Balance Updates:

  Money In                    Money Out                 Reversals
  ────────                    ─────────                 ─────────
  1 = Deposit                 2 = Cashout               7 = GameCancellation
  3 = Bonus                   4 = GameFee               8 = BonusCancellation
  5 = GamePrize              14 = End Of Week Fee       9 = CashoutCancellation
  6 = Compensation
 12 = Champ Win

  Trade Operations
  ────────────────
  10 = Open Trade  (margin hold)
  11 = Close Trade (P&L settlement)
  13 = Edit Stop Loss (margin adjustment)
```

---

## 3. Data Overview

| AccountUpdateTypeID | Name | Meaning |
|---|---|---|
| 1 | Deposit | Customer adds funds to their account via any payment method. Triggers balance increase and updates funding records. |
| 2 | Cashout | Customer withdraws funds from their account. Triggers balance decrease and withdrawal processing workflow. |
| 10 | Open Trade | Margin is reserved when a customer opens a trading position. Reduces available balance by the required margin amount. |
| 11 | Close Trade | Position P&L is settled when a trade is closed. Credits profit or debits loss from the customer's balance. |
| 14 | End Of Week Fee | Weekend overnight fee (swap) charged on open leveraged positions held over the weekend. Debited automatically. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountUpdateTypeID | int | NO | - | VERIFIED | Primary key identifying the update type. Used as NONCLUSTERED PK (unusual — suggests the table was originally heap-organized). Values 1-14 covering deposits, cashouts, bonuses, trades, fees, and cancellations. Stored in History.Account and referenced by Billing.AmountAdd, Billing.AmountSubstract, Billing.CashoutRequestAdd, Customer.SetBalance. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable name of the balance update type. Unique index enforced (DPMS_NAME). Used in reports and audit trails to describe what financial operation occurred. Loaded into billing service memory by Billing.LoadAccountUpdateTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Account | AccountUpdateTypeID | Implicit | Every historical account transaction is tagged with its update type |
| Billing.AmountAdd | @AccountUpdateTypeID | Parameter | Core credit procedure — validates update type before posting |
| Billing.AmountSubstract | @AccountUpdateTypeID | Parameter | Core debit procedure — validates update type before posting |
| Billing.CashoutRequestAdd | AccountUpdateTypeID | WHERE | Cashout processing references Cashout type (2) |
| Billing.WithdrawRequestReverse | AccountUpdateTypeID | WHERE | Withdrawal reversal references CashoutCancellation type (9) |
| Billing.CashoutReverse | AccountUpdateTypeID | WHERE | Cashout reversal processing |
| Billing.LoadAccountUpdateTypes | - | SELECT ALL | Loads all types into billing service memory |
| Customer.SetBalance | AccountUpdateTypeID | Parameter | Balance update during customer operations |
| Customer.BonusRequest | AccountUpdateTypeID | WHERE | Bonus posting references Bonus type (3) |
| Customer.BonusConfirm | AccountUpdateTypeID | WHERE | Bonus confirmation |
| Billing.AmountAddBonus | AccountUpdateTypeID | WHERE | Bonus credit posting |
| BackOffice.SanityCheck | AccountUpdateTypeID | WHERE | Data integrity validation |
| Maintenance.PositionFix | AccountUpdateTypeID | Parameter | Position correction operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Account | Table | Stores AccountUpdateTypeID on every transaction |
| Billing.AmountAdd | Stored Procedure | Writer — core credit posting |
| Billing.AmountSubstract | Stored Procedure | Writer — core debit posting |
| Billing.CashoutRequestAdd | Stored Procedure | Reader — cashout processing |
| Billing.LoadAccountUpdateTypes | Stored Procedure | Reader — loads all types into memory |
| Customer.SetBalance | Stored Procedure | Writer — balance adjustments |
| Customer.BonusRequest | Stored Procedure | Reader — bonus operations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DAUT | NC PK | AccountUpdateTypeID ASC | - | - | Active (FILLFACTOR 90) |
| DPMS_NAME | NC UNIQUE | Name ASC | - | - | Active (FILLFACTOR 90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DAUT | PRIMARY KEY (NC) | Unique update type identifier. Nonclustered — table is a heap with no clustered index. |
| DPMS_NAME | UNIQUE INDEX | Prevents duplicate update type names |

---

## 8. Sample Queries

### 8.1 List all account update types
```sql
SELECT  AccountUpdateTypeID,
        Name
FROM    Dictionary.AccountUpdateType WITH (NOLOCK)
ORDER BY AccountUpdateTypeID;
```

### 8.2 Count transactions by update type
```sql
SELECT  daut.Name           AS UpdateType,
        COUNT(*)            AS TransactionCount
FROM    History.Account ha WITH (NOLOCK)
JOIN    Dictionary.AccountUpdateType daut WITH (NOLOCK)
        ON ha.AccountUpdateTypeID = daut.AccountUpdateTypeID
GROUP BY daut.Name
ORDER BY TransactionCount DESC;
```

### 8.3 Find all money-in vs money-out types
```sql
SELECT  AccountUpdateTypeID,
        Name,
        CASE
            WHEN AccountUpdateTypeID IN (1, 3, 5, 6, 12) THEN 'Money-In'
            WHEN AccountUpdateTypeID IN (2, 4, 14)        THEN 'Money-Out'
            WHEN AccountUpdateTypeID IN (7, 8, 9)         THEN 'Reversal'
            WHEN AccountUpdateTypeID IN (10, 11, 13)      THEN 'Trade'
        END AS Category
FROM    Dictionary.AccountUpdateType WITH (NOLOCK)
ORDER BY AccountUpdateTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AccountUpdateType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AccountUpdateType.sql*
