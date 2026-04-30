# Dictionary.CreditType

> Lookup table defining the 33 types of balance-affecting operations that create credit/debit entries in a customer's financial history.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CreditTypeID (TINYINT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK clustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.CreditType classifies every type of balance-changing operation on a customer account. Whenever money moves in or out of a customer's balance — through deposits, withdrawals, position P&L realization, fees, bonuses, mirror trading allocations, or administrative corrections — the operation is tagged with a CreditTypeID that explains *why* the balance changed.

This is the most granular classification of financial movements in the system. While TransactionType provides the top-level direction (deposit/refund/payout), CreditType provides the specific reason. The credit history is the complete audit trail of every balance change, essential for financial reconciliation, regulatory reporting, and customer dispute resolution.

CreditTypeID is stored in credit/history records and referenced by numerous billing, trading, and copy-trading procedures. The table covers the full spectrum from basic operations (Deposit, Cashout) through trading P&L (Open Position, Close Position) to complex copy-trading operations (Mirror allocations, detachments, hierarchical operations).

---

## 2. Business Logic

### 2.1 Financial Operation Categories

**What**: Credit types group into functional categories that represent different areas of the platform's financial engine.

**Columns/Parameters Involved**: `CreditTypeID`, `Name`

**Rules**:
- **Deposit/Cashout Lifecycle (1,2,8,9,32,33)**: Standard money in/out operations including reversals and rollbacks
- **Trading P&L (3,4,13,14,29,30)**: Position open/close operations, stop loss edits, stock orders, end-of-week fees
- **Administrative (5,6,7,31)**: Compensation, bonuses, championship winnings, data fixes
- **Chargeback/Refund (11,12,15,16,17)**: Payment disputes, refunds, chargeback processing, cashout fees
- **Copy Trading / Mirror (18-28)**: Mirror allocations, de-allocations, hierarchical operations, detachment from mirrors
- **IB Sync (10)**: Interactive Brokers synchronization for real stock positions

### 2.2 Balance Direction

**What**: Each credit type has an implied direction — positive (increases balance) or negative (decreases balance).

**Rules**:
- Balance-increasing: Deposit (1), Close Position (4) [profit], Bonus (7), Reverse Cashout (8), Mirror balance to account (19), Recovery open (25), Cashout Rollback (33)
- Balance-decreasing: Cashout (2), Open Position (3) [margin], Cashout Request (9), Chargeback (11), End of Week Fee (14), Cashout Fee (15), Account balance to mirror (18)
- Direction-variable: Close Position (4) [can be profit or loss], Data Fix (31) [administrative]

---

## 3. Data Overview

| CreditTypeID | Name | Meaning |
|---|---|---|
| 1 | Deposit | Customer deposited funds — credit card, wire, PayPal, etc. Increases available balance for trading. |
| 2 | Cashout | Customer withdrawal processed — funds sent to customer via their chosen method. Decreases balance. |
| 4 | Close Position | P&L realized when a trading position is closed. Positive = profit added to balance; negative = loss deducted. |
| 11 | Chargeback | Payment provider reversed a previous deposit (card dispute). Decreases balance. Triggers compliance review. |
| 20 | Register new mirror | Funds allocated when a customer starts copying a leader in CopyTrader. Moves balance from available to mirror allocation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditTypeID | tinyint | NO | - | VERIFIED | Financial operation type identifier (1-33). Classifies every balance change: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse Cashout, 9=Cashout Request, 10=IB Sync, 11=Chargeback, 12=Refund, 13=Edit Stop Loss, 14=End of Week Fee, 15=Cashout Fee, 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks, 18-28=Mirror/CopyTrading operations, 29-30=Stock Orders, 31=Data Fix, 32=Reverse Deposit, 33=Cashout Rollback. |
| 2 | Name | char(50) | NO | - | VERIFIED | Human-readable operation name. Unique constraint ensures no duplicate names. Used in financial reports, transaction history, and reconciliation tools. Note: char(50) with trailing spaces — always RTRIM when displaying. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Credit/History tables | CreditTypeID | Implicit | Every balance-change record is tagged with a CreditTypeID |
| Billing procedures | @CreditTypeID | Parameter | Billing operations specify the credit type for each financial movement |
| Dictionary.HistoryCreditActionsToHide | CreditTypeID | Implicit | Configures which credit types are hidden from customer-facing history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CreditType (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Credit/History subsystem | Various | Tags every balance change with a credit type |
| Billing procedures | Stored Procedures | Reference CreditTypeID for financial operations |
| Dictionary.HistoryCreditActionsToHide | Table | Configures which types to hide from customer view |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCRT | CLUSTERED PK | CreditTypeID | - | - | Active |
| DCRT_NAME | NONCLUSTERED UNIQUE | Name | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCRT | PRIMARY KEY | Unique credit type, FILLFACTOR 90, DICTIONARY filegroup |
| DCRT_NAME | UNIQUE INDEX | Ensures no duplicate credit type names |

---

## 8. Sample Queries

### 8.1 List all credit types
```sql
SELECT  CreditTypeID,
        RTRIM(Name) AS Name
FROM    Dictionary.CreditType WITH (NOLOCK)
ORDER BY CreditTypeID;
```

### 8.2 Categorize credit types by function
```sql
SELECT  CreditTypeID,
        RTRIM(Name) AS Name,
        CASE
            WHEN CreditTypeID IN (1, 2, 8, 9, 32, 33) THEN 'Deposit/Cashout'
            WHEN CreditTypeID IN (3, 4, 13, 14, 29, 30) THEN 'Trading P&L'
            WHEN CreditTypeID IN (18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28) THEN 'Mirror/CopyTrading'
            WHEN CreditTypeID IN (11, 12, 15, 16, 17) THEN 'Chargeback/Refund'
            ELSE 'Administrative'
        END AS Category
FROM    Dictionary.CreditType WITH (NOLOCK)
ORDER BY CreditTypeID;
```

### 8.3 Find credit types visible to customers
```sql
SELECT  ct.CreditTypeID,
        RTRIM(ct.Name) AS Name
FROM    Dictionary.CreditType ct WITH (NOLOCK)
WHERE   NOT EXISTS (
            SELECT 1
            FROM   Dictionary.HistoryCreditActionsToHide h WITH (NOLOCK)
            WHERE  h.CreditTypeID = ct.CreditTypeID
        )
ORDER BY ct.CreditTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CreditType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CreditType.sql*
