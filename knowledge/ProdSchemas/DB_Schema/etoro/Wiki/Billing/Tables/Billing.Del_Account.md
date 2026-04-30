# Billing.Del_Account

> Core customer billing account table storing each customer's current USD account balance in integer cents; the "Del_" prefix is a legacy naming artifact, not a deletion marker - this is the live account balance store referenced by History.Account.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | AccountID - IDENTITY PK NONCLUSTERED |
| **Partition** | MAIN filegroup |
| **Indexes** | 3 (PK nonclustered + unique on CID/CurrencyID + nonclustered on CurrencyID) |

---

## 1. Business Meaning

`Billing.Del_Account` is the core account balance table for the Billing domain. Despite the "Del_" prefix (a legacy naming artifact, not a deletion indicator), this is the LIVE current account balance table. It stores one row per customer per currency, holding the customer's current account balance as an integer (cents).

The table holds 2,218,203 rows. All rows use CurrencyID=1 (USD) - the platform operates in a single currency at the account level. 77,586 rows (3.5%) have a non-zero AccountBalance; the rest are zero (closed, dormant, or unfunded accounts).

AccountID=1 / CID=-1 is the system account (AccountBalance=0) - a standard sentinel row used for system-level accounting operations.

`History.Account` is the audit trail companion table: every change to AccountBalance (deposits, cashouts, bonuses, fees, trade opens/closes, etc.) is recorded in History.Account referencing AccountID from this table. The 14 update types include Deposit, Cashout, Bonus, GameFee, GamePrize, Compensation, BonusCancellation, Open Trade, Close Trade, and others.

---

## 2. Business Logic

### 2.1 Integer Balance Storage (Cents)

**What**: AccountBalance is stored as INT, not decimal. It represents the balance in minor currency units (cents for USD).

**Columns/Parameters Involved**: `AccountBalance`, `CurrencyID`

**Rules**:
```
AccountBalance = 207658 with CurrencyID=1 (USD)
  -> $2,076.58 (divide by 100 to get USD amount)

AccountBalance = 0
  -> Zero balance / unfunded account

Integer storage avoids floating-point precision issues on cumulative balance updates.
```

### 2.2 One Account Per Customer Per Currency

**What**: The unique index BACC_ACCOUNT on (CID, CurrencyID) enforces one billing account per customer per currency.

**Columns/Parameters Involved**: `CID`, `CurrencyID`

**Rules**:
- A customer can have at most one account per currency.
- In practice, ALL 2.2M rows use CurrencyID=1 (USD), meaning each customer has exactly one USD billing account.
- To add a currency, a new row would be inserted (one per currency).

### 2.3 History.Account as the Audit Trail

**What**: History.Account has an FK to Billing.Del_Account(AccountID). Every mutation to AccountBalance must result in a History.Account insert logging the previous/new balance and the update type.

**Update Types (Dictionary.AccountUpdateType)**:
```
1  = Deposit            (customer deposits funds)
2  = Cashout            (customer withdraws)
3  = Bonus              (promotional credit)
4  = GameFee            (fee for trading game/feature)
5  = GamePrize          (prize from trading game)
6  = Compensation       (manual adjustment/compensation)
7  = GameCancellation   (reverse game fee)
8  = BonusCancellation  (reverse bonus)
9  = CashoutCancellation (reverse cashout)
10 = Open Trade         (funds locked for open trade)
11 = Close Trade        (funds released/settled from trade)
12 = Champ Win          (championship prize)
13 = Edit Stop Loss     (margin adjustment on stop loss edit)
14 = End Of Week Fee    (periodic maintenance fee)
```

---

## 3. Data Overview

| AccountID | CID | CurrencyID | AccountBalance | Meaning |
|-----------|-----|-----------|----------------|---------|
| 1 | -1 | 1 (USD) | 0 | System account - sentinel row for system-level accounting operations |
| 259 | 5 | 1 (USD) | 0 | Real customer (CID=5), zero balance |
| 261 | 15 | 1 (USD) | 207658 | Customer CID=15 holds $2,076.58 USD |
| 262 | 17 | 1 (USD) | 0 | Real customer, zero balance |
| (2.2M rows) | (various) | 1 (USD only) | (0 for 96.5%, >0 for 3.5%) | One USD account per customer |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | auto | VERIFIED | Surrogate PK. Auto-incremented account identifier. Referenced by History.Account(AccountID) as the FK target. NOT FOR REPLICATION suppresses identity increment on replication subscribers to prevent divergence. |
| 2 | CID | int | NO | - | VERIFIED | Customer who owns this account. FK to Customer.CustomerStatic(CID) via FK_CCST_BACC. CID=-1 is the system sentinel account (AccountID=1). Combined with CurrencyID, unique per customer per currency (enforced by BACC_ACCOUNT index). |
| 3 | CurrencyID | int | NO | - | VERIFIED | Currency denomination of this account. FK to Dictionary.Currency(CurrencyID) via FK_DCUR_BACC. Currently ALL 2,218,203 rows use CurrencyID=1 (USD). The schema supports multi-currency accounts but the current data is single-currency (USD). |
| 4 | AccountBalance | int | NO | - | VERIFIED | Current account balance in minor currency units (cents for USD). Stored as INT to avoid floating-point precision issues. Divide by 100 for USD value. 77,586 rows (3.5%) have non-zero balance. Updated by application logic; every change is recorded in History.Account with PreviousAccountBalance/NewAccountBalance/Amount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (explicit: FK_CCST_BACC) | Owner of the billing account |
| CurrencyID | Dictionary.Currency | FK (explicit: FK_DCUR_BACC) | Currency denomination of the account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Account | AccountID | FK (FK_BACC_HACC) | Audit trail - every balance change is logged in History.Account with PreviousAccountBalance, NewAccountBalance, Amount, UpdateDate, and update type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Del_Account (table)
|- Customer.CustomerStatic (table)      [FK: CID via FK_CCST_BACC]
|- Dictionary.Currency (table)          [FK: CurrencyID via FK_DCUR_BACC]

Referenced by:
History.Account (table)                 [FK: AccountID via FK_BACC_HACC]
|- Dictionary.AccountUpdateType (table) [FK: AccountUpdateTypeID via FK_DAUT_HACC]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK target - account owner |
| Dictionary.Currency | Table | FK target - currency denomination |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Account | Table | FK (AccountID) - records every AccountBalance change with before/after values |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BACC | NONCLUSTERED PK | AccountID ASC | - | - | Active (FILLFACTOR 90) on MAIN |
| BACC_ACCOUNT | UNIQUE NONCLUSTERED | CID ASC, CurrencyID ASC | - | - | Active (FILLFACTOR 90) - enforces one account per customer per currency |
| i_CureenyID | NONCLUSTERED | CurrencyID ASC | - | - | Active - note: column name has typo ("Cureeny" not "Currency"), same typo is in the index name |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BACC | PRIMARY KEY NONCLUSTERED | AccountID - unique account identifier |
| BACC_ACCOUNT | UNIQUE INDEX | (CID, CurrencyID) - one account per customer per currency |
| FK_CCST_BACC | FOREIGN KEY | CID must exist in Customer.CustomerStatic |
| FK_DCUR_BACC | FOREIGN KEY | CurrencyID must exist in Dictionary.Currency |

### 7.3 Notable Design Decisions

- **NONCLUSTERED PK**: Unusual - the PK (AccountID) is NONCLUSTERED. The table has no explicit clustered index, meaning the data pages are stored as a heap. The unique index BACC_ACCOUNT on (CID, CurrencyID) effectively serves as the natural lookup key.
- **Integer balance**: AccountBalance as INT (cents) avoids decimal floating-point rounding issues on high-frequency balance updates.
- **Typo in index name**: `i_CureenyID` has a typo ("Cureeny" instead of "Currency"). This is a legacy artifact.

---

## 8. Sample Queries

### 8.1 Get current account balance for a customer
```sql
SELECT  DA.AccountID,
        DA.CID,
        DA.CurrencyID,
        DA.AccountBalance,
        DA.AccountBalance / 100.0   AS BalanceInDollars
FROM    Billing.Del_Account DA WITH (NOLOCK)
WHERE   DA.CID = 12345;
```

### 8.2 Get recent balance history for an account
```sql
SELECT  HA.AccountUpdateID,
        DA.CID,
        HA.AccountUpdateTypeID,
        AUT.Name                            AS UpdateType,
        HA.PreviousAccountBalance / 100.0   AS PrevBalanceDollars,
        HA.NewAccountBalance / 100.0        AS NewBalanceDollars,
        HA.Amount / 100.0                   AS AmountDollars,
        HA.UpdateDate
FROM    History.Account HA WITH (NOLOCK)
INNER JOIN Billing.Del_Account DA WITH (NOLOCK)
        ON HA.AccountID = DA.AccountID
INNER JOIN Dictionary.AccountUpdateType AUT WITH (NOLOCK)
        ON HA.AccountUpdateTypeID = AUT.AccountUpdateTypeID
WHERE   DA.CID = 12345
ORDER BY HA.UpdateDate DESC;
```

### 8.3 Find accounts with positive balance
```sql
SELECT  DA.CID,
        DA.AccountBalance / 100.0   AS BalanceDollars
FROM    Billing.Del_Account DA WITH (NOLOCK)
WHERE   DA.AccountBalance > 0
ORDER BY DA.AccountBalance DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific table.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Del_Account | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Del_Account.sql*
