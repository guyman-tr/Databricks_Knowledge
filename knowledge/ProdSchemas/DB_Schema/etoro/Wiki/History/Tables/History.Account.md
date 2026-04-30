# History.Account

> Audit trail of account balance changes in the Billing subsystem, recording every credit and debit event with before/after balance snapshots.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | AccountUpdateID (INT IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.Account is the financial audit log for account balance changes within eToro's Billing subsystem. Every time an account balance is modified — by a deposit, cashout, bonus award, trade open/close, game entry fee, or any of 14 defined event types — a row is inserted here recording the event type, the balance before and after, and the magnitude of the change.

Without this table, there would be no immutable record of why an account balance changed over time. It supports customer support inquiries ("why did my balance change?"), regulatory audit requirements, reconciliation processes, and the Billing.GetAccountHistory procedure which exposes account history to back-office and API consumers.

Data flows into this table exclusively from Billing-layer stored procedures (Billing.CashoutRequestAdd, Billing.CashoutReverse, Billing.CustomerRemove, and others). Rows are never updated — it is an append-only ledger. Reads are served by Billing.GetAccountHistory which queries by AccountID.

---

## 2. Business Logic

### 2.1 Account Balance Change Event

**What**: Each row is one atomic event that changed an account's balance. The row captures the full financial state transition: prior balance, new balance, and the delta.

**Columns/Parameters Involved**: `AccountUpdateTypeID`, `PreviousAccountBalance`, `NewAccountBalance`, `Amount`

**Rules**:
- Amount = NewAccountBalance - PreviousAccountBalance (the signed delta of the balance change)
- AccountUpdateTypeID classifies what business event caused the change (deposit, cashout, trade, bonus, etc.)
- The table is append-only: no UPDATE or DELETE operations exist in the schema

**Diagram**:
```
Account Balance Timeline:
  [Event 1] Deposit        PrevBal=0      NewBal=1000    Amount=+1000
  [Event 2] Open Trade     PrevBal=1000   NewBal=950     Amount=-50
  [Event 3] Close Trade    PrevBal=950    NewBal=1020    Amount=+70
  [Event 4] Cashout        PrevBal=1020   NewBal=520     Amount=-500
```

### 2.2 Event Type Classification

**What**: The 14-value AccountUpdateTypeID lookup classifies the business event that triggered the balance change.

**Columns/Parameters Involved**: `AccountUpdateTypeID`

**Rules**:
- Types 1-3 (Deposit, Cashout, Bonus) are core funding events
- Types 4-5, 7 (GameFee, GamePrize, GameCancellation) relate to the eToro forex game feature
- Types 10-11 (Open Trade, Close Trade) are position lifecycle events affecting balance
- Types 8-9 (BonusCancellation, CashoutCancellation) are reversal events
- Type 14 (End Of Week Fee) is a periodic fee charge

**Diagram**:
```
AccountUpdateTypeID Values:
  1  = Deposit
  2  = Cashout
  3  = Bonus
  4  = GameFee
  5  = GamePrize
  6  = Compensation
  7  = GameCancellation
  8  = BonusCancellation
  9  = CashoutCancellation
  10 = Open Trade
  11 = Close Trade
  12 = Champ Win
  13 = Edit Stop Loss
  14 = End Of Week Fee
```

---

## 3. Data Overview

The table is currently empty in the query environment (0 rows). This suggests History.Account may be a legacy or archive table no longer actively written to in the current environment, or the data has been purged. The Billing.GetAccountHistory procedure still reads from it, indicating it remains operationally relevant.

| AccountUpdateID | AccountID | AccountUpdateTypeID | PreviousAccountBalance | NewAccountBalance | Amount | UpdateDate |
|---|---|---|---|---|---|---|
| (no data) | - | - | - | - | - | - |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountUpdateID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-incrementing surrogate PK. Unique identifier for each balance change event. NOT FOR REPLICATION ensures identity values are generated locally and not replicated from a publisher. |
| 2 | AccountID | int | NO | - | CODE-BACKED | Foreign key to Billing.Del_Account(AccountID). Identifies which billing account experienced the balance change. Used by Billing.GetAccountHistory as the primary lookup key (SELECT * WHERE AccountID = @AccountID). |
| 3 | AccountUpdateTypeID | int | NO | - | VERIFIED | Type of event that caused this balance change. FK to Dictionary.AccountUpdateType: 1=Deposit, 2=Cashout, 3=Bonus, 4=GameFee, 5=GamePrize, 6=Compensation, 7=GameCancellation, 8=BonusCancellation, 9=CashoutCancellation, 10=Open Trade, 11=Close Trade, 12=Champ Win, 13=Edit Stop Loss, 14=End Of Week Fee. Billing.CashoutRequestAdd hard-codes type 2 on INSERT. |
| 4 | PreviousAccountBalance | int | NO | - | CODE-BACKED | Account balance immediately before this event, in integer monetary units. Captured from Billing.Del_Account.Balance at the moment of the update (sourced via @PreviousAccountBalance in Billing.CashoutRequestAdd). |
| 5 | NewAccountBalance | int | NO | - | CODE-BACKED | Account balance immediately after this event, in integer monetary units. Together with PreviousAccountBalance, forms an immutable snapshot of the balance transition. |
| 6 | Amount | int | NO | - | CODE-BACKED | Signed magnitude of the balance change in integer monetary units. For credits (deposits, bonuses, trade profits): positive. For debits (cashouts, fees, trade losses): negative. Amount = NewAccountBalance - PreviousAccountBalance. |
| 7 | UpdateDate | datetime | NO | - | CODE-BACKED | Timestamp when this balance change was recorded. Set to GETDATE() at INSERT time by Billing procedures. Provides chronological ordering for account history queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountID | Billing.Del_Account | FK (FK_BACC_HACC) | Each balance change event belongs to one billing account. Del_Account is the master account record in the Billing schema. |
| AccountUpdateTypeID | Dictionary.AccountUpdateType | FK (FK_DAUT_HACC) | Classifies the business event type that caused the balance change. Lookup has 14 event types. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetAccountHistory | AccountID | Reader | Returns full account history for a given AccountID. Primary read path for account balance audit queries. |
| Billing.CashoutRequestAdd | AccountID | Writer | Inserts a row with AccountUpdateTypeID=2 (Cashout) when a cashout request is created. |
| Billing.CashoutReverse | AccountID | Writer | Inserts a reversal record (type=9, CashoutCancellation) when a cashout is reversed. |
| Billing.CustomerRemove | AccountID | Writer | Records balance changes when a customer account is removed/closed. |
| Billing.GetCustomerBonuses | AccountID | Reader | Reads bonus events (type=3) from account history. |
| BackOffice.SanityCheck | AccountID | Reader | Back-office consistency check that validates account balance history integrity. |
| Maintenance.PositionFix | AccountID | Writer/Reader | Maintenance procedure that may reconcile account history during position fix operations. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Account (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Del_Account | Table | FK target - AccountID must exist in Billing.Del_Account |
| Dictionary.AccountUpdateType | Table | FK target - AccountUpdateTypeID must exist in Dictionary.AccountUpdateType |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetAccountHistory | Stored Procedure | Reader - SELECT * WHERE AccountID = @AccountID |
| Billing.CashoutRequestAdd | Stored Procedure | Writer - INSERT on cashout creation (type=2) |
| Billing.CashoutReverse | Stored Procedure | Writer - INSERT on cashout reversal |
| Billing.CustomerRemove | Stored Procedure | Writer - INSERT on account removal |
| Billing.GetCustomerBonuses | Stored Procedure | Reader - reads bonus history entries |
| BackOffice.SanityCheck | Stored Procedure | Reader - sanity/integrity validation |
| Maintenance.PositionFix | Stored Procedure | Writer/Reader - maintenance reconciliation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HACC | CLUSTERED PK | AccountUpdateID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HACC | PRIMARY KEY CLUSTERED | Unique identity per balance change event |
| FK_BACC_HACC | FOREIGN KEY | AccountID REFERENCES Billing.Del_Account(AccountID) - ensures account exists |
| FK_DAUT_HACC | FOREIGN KEY | AccountUpdateTypeID REFERENCES Dictionary.AccountUpdateType(AccountUpdateTypeID) - ensures valid event type |

---

## 8. Sample Queries

### 8.1 Retrieve full balance change history for an account
```sql
SELECT
    ha.AccountUpdateID,
    ha.AccountID,
    aut.[Name]                 AS UpdateType,
    ha.PreviousAccountBalance,
    ha.NewAccountBalance,
    ha.Amount,
    ha.UpdateDate
FROM History.Account ha WITH (NOLOCK)
INNER JOIN Dictionary.AccountUpdateType aut WITH (NOLOCK)
    ON ha.AccountUpdateTypeID = aut.AccountUpdateTypeID
WHERE ha.AccountID = 12345
ORDER BY ha.UpdateDate ASC;
```

### 8.2 Summarise balance changes by event type for an account
```sql
SELECT
    aut.[Name]           AS UpdateType,
    COUNT(*)             AS EventCount,
    SUM(ha.Amount)       AS TotalAmount
FROM History.Account ha WITH (NOLOCK)
INNER JOIN Dictionary.AccountUpdateType aut WITH (NOLOCK)
    ON ha.AccountUpdateTypeID = aut.AccountUpdateTypeID
WHERE ha.AccountID = 12345
GROUP BY aut.[Name]
ORDER BY TotalAmount DESC;
```

### 8.3 Find all cashout events across accounts in a date range
```sql
SELECT
    ha.AccountUpdateID,
    ha.AccountID,
    ha.PreviousAccountBalance,
    ha.NewAccountBalance,
    ha.Amount,
    ha.UpdateDate
FROM History.Account ha WITH (NOLOCK)
WHERE ha.AccountUpdateTypeID = 2  -- Cashout
  AND ha.UpdateDate >= '2025-01-01'
  AND ha.UpdateDate <  '2026-01-01'
ORDER BY ha.UpdateDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Account | Type: Table | Source: etoro/etoro/History/Tables/History.Account.sql*
