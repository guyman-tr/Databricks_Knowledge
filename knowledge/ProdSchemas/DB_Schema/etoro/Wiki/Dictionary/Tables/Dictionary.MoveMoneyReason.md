# Dictionary.MoveMoneyReason

> Classifies the business reasons for internal money movements (balance adjustments, transfers, staking, bonuses) recorded in the ActiveCredit ledger system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MoveMoneyReasonID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.MoveMoneyReason enumerates the valid business justifications for internal money movements — balance credits, debits, and transfers that are not standard deposits or withdrawals. These operations are recorded in the ActiveCredit system (History.ActiveCredit) and tracked for audit, compliance, and financial reporting.

Without this table, the system could not classify internal money movements, making it impossible to distinguish between manual adjustments, bonus abuse corrections, staking rewards, internal account transfers, and recurring investments. Compliance and finance teams rely on these reason codes for reconciliation and regulatory reporting.

Referenced by 50+ procedures across Customer, Billing, and Trade schemas including Customer.SetBalance, Customer.SetBalanceCompensation, Billing.AmountAdd, Billing.DepositProcess, Trade.InsertActiveCredit, and numerous credit history retrieval procedures (Trade.TAPI_GetFlatCreditHistoryByCID variants).

---

## 2. Business Logic

### 2.1 Money Movement Categories

**What**: Eight reason codes categorizing non-standard financial operations.

**Columns/Parameters Involved**: `MoveMoneyReasonID`, `MoveMoneyReason`

**Rules**:
- Adjustment (1): Manual balance correction by operations staff
- Bonus Abuser (2): Reversal of bonus funds from customers flagged for bonus abuse
- Staking (3): Crypto staking reward credits
- ID 4 is missing — possibly deprecated
- InternalTransfer Trade (5): Inter-account transfer related to trading operations
- InternalTransfer (6): General inter-account transfer (not trade-specific)
- Not In Use (7): Reserved/deprecated placeholder
- Recurring Deposit (8): Automated periodic deposit from linked payment method
- Recurring Investment (9): Automated periodic investment allocation

**Diagram**:
```
Money Movement Reasons:
  Manual ──────────> Adjustment (1), Bonus Abuser (2)
  Crypto ──────────> Staking (3)
  Transfers ───────> InternalTransfer Trade (5), InternalTransfer (6)
  Reserved ────────> Not In Use (7)
  Automated ───────> Recurring Deposit (8), Recurring Investment (9)
```

---

## 3. Data Overview

| MoveMoneyReasonID | MoveMoneyReason | Meaning |
|---|---|---|
| 1 | Adjustment | Manual balance correction by operations/compliance staff — used for error fixes, compensations, and regulatory adjustments |
| 2 | Bonus Abuser | Clawback of bonus funds from customers identified as abusing promotional offers — compliance-driven reversal |
| 3 | Staking | Crypto staking reward credits — periodic yield earned on eligible crypto positions held on the platform |
| 5 | InternalTransfer Trade | Money movement between accounts triggered by a trading operation (e.g., transferring funds to cover a trade in a different entity) |
| 9 | Recurring Investment | Automated periodic investment — customer has configured regular allocations to specific instruments or CopyTrading leaders |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MoveMoneyReasonID | int | NO | - | CODE-BACKED | Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures. |
| 2 | MoveMoneyReason | varchar(30) | NO | - | VERIFIED | Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.ActiveCredit | MoveMoneyReasonID | Implicit | Credit history records classify the reason for each money movement |
| Customer.SetBalance | @MoveMoneyReasonID | Implicit | Balance adjustment procedure records the reason |
| Customer.SetBalanceCompensation | @MoveMoneyReasonID | Implicit | Compensation procedure records the reason |
| Billing.AmountAdd | @MoveMoneyReasonID | Implicit | Amount addition records movement reason |
| Billing.DepositProcess | MoveMoneyReasonID | Implicit | Deposit processing classifies internal movements |
| Trade.InsertActiveCredit | MoveMoneyReasonID | Implicit | Credit insertion records reason |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table | MoveMoneyReasonID column |
| Customer.SetBalance | Stored Procedure | Records movement reason |
| Customer.SetBalanceCompensation | Stored Procedure | Records compensation reason |
| Customer.SetBalanceDeposit | Stored Procedure | Records deposit reason |
| Customer.SetBalanceCashOut | Stored Procedure | Records cashout reason |
| Customer.SetBalanceBonus | Stored Procedure | Records bonus reason |
| Billing.AmountAdd | Stored Procedure | Records amount addition reason |
| Billing.DepositProcess | Stored Procedure | Classifies deposit movements |
| Trade.InsertActiveCredit | Stored Procedure | Records credit reason |
| Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit | Stored Procedure | Reads for credit history API |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryMoneyReason | CLUSTERED PK | MoveMoneyReasonID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all money movement reasons
```sql
SELECT  MoveMoneyReasonID,
        MoveMoneyReason
FROM    [Dictionary].[MoveMoneyReason] WITH (NOLOCK)
ORDER BY MoveMoneyReasonID;
```

### 8.2 Find active credit entries by reason
```sql
SELECT  mmr.MoveMoneyReason,
        COUNT(*) AS CreditCount
FROM    [History].[ActiveCredit] ac WITH (NOLOCK)
JOIN    [Dictionary].[MoveMoneyReason] mmr WITH (NOLOCK)
        ON ac.MoveMoneyReasonID = mmr.MoveMoneyReasonID
GROUP BY mmr.MoveMoneyReason
ORDER BY CreditCount DESC;
```

### 8.3 Find all staking credits for a customer
```sql
SELECT  ac.*,
        mmr.MoveMoneyReason
FROM    [History].[ActiveCredit] ac WITH (NOLOCK)
JOIN    [Dictionary].[MoveMoneyReason] mmr WITH (NOLOCK)
        ON ac.MoveMoneyReasonID = mmr.MoveMoneyReasonID
WHERE   mmr.MoveMoneyReasonID = 3
        AND ac.CustomerID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MoveMoneyReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MoveMoneyReason.sql*
