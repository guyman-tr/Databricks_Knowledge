# Trade.Gain_WithdrawalMatcherBonus

> TVP for the Gain withdrawal matching process. Carries bonus credit records - each row represents a bonus given to a customer at a specific time for a specific amount. Matched against pending withdrawals.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CreditID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.Gain_WithdrawalMatcherBonus is a table-valued parameter used in the Gain withdrawal matching workflow. It carries bonus credit records that represent bonuses awarded to customers. Each row contains CreditID (references the credit system), CID (customer), Occurred (timestamp when the bonus was given), and Amount (bonus value in money).

Trade.Gain_GetPendingBonusesAndWithdrawals accepts this TVP via the @bonus parameter. The procedure matches these bonuses against pending withdrawals to determine net withdrawal amounts - i.e. what portion of a withdrawal can be offset by prior bonuses. The Gain_ prefix identifies this as part of the external cashflow/payment provider integration.

---

## 2. Business Logic

### 2.1 Bonus-to-Withdrawal Matching

**What**: Bonuses are matched against pending withdrawals to compute net amounts. The procedure determines how much of each withdrawal is covered by prior bonus credits.

**Columns/Parameters Involved**: CreditID, CID, Occurred, Amount.

**Rules**: All columns NOT NULL. CreditID references the credit system. CID identifies the customer. Occurred is when the bonus was granted. Amount is the bonus value. Matching logic typically pairs bonuses with withdrawals by CID and chronology to compute net withdrawal liabilities.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NOT NULL | - | High | Credit system ID. References the source bonus record in the credit tables. |
| 2 | CID | int | NOT NULL | - | High | Customer ID. Identifies the recipient of the bonus. |
| 3 | Occurred | datetime | NOT NULL | - | High | Timestamp when the bonus was granted. Used for chronological matching. |
| 4 | Amount | money | NOT NULL | - | High | Bonus amount in money. Value to be matched against withdrawals. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditID | Credit system tables | Implicit | Links to bonus credit record |
| CID | Customer tables | Implicit | Customer who received the bonus |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Gain_GetPendingBonusesAndWithdrawals | @bonus | Parameter (TVP) | Passes bonus records for withdrawal matching |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Trade.Gain_GetPendingBonusesAndWithdrawals

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Pass Single Bonus for Withdrawal Matching

```sql
DECLARE @bonus Trade.Gain_WithdrawalMatcherBonus;
INSERT INTO @bonus (CreditID, CID, Occurred, Amount)
VALUES (1001, 12345, '2025-03-01 10:00:00', 50.00);
EXEC Trade.Gain_GetPendingBonusesAndWithdrawals @bonus = @bonus;
```

### 8.2 Pass Multiple Bonuses for Batch Matching

```sql
DECLARE @bonus Trade.Gain_WithdrawalMatcherBonus;
INSERT INTO @bonus (CreditID, CID, Occurred, Amount)
VALUES (1001, 12345, '2025-03-01', 50.00),
       (1002, 12345, '2025-03-05', 25.00),
       (1003, 67890, '2025-03-10', 100.00);
EXEC Trade.Gain_GetPendingBonusesAndWithdrawals @bonus = @bonus;
```

### 8.3 Populate from Credit System

```sql
DECLARE @bonus Trade.Gain_WithdrawalMatcherBonus;
INSERT INTO @bonus (CreditID, CID, Occurred, Amount)
SELECT CreditID, CID, Occurred, Amount
FROM Credit.BonusCredits WITH (NOLOCK)
WHERE Occurred >= @Since AND StatusID = 1;
EXEC Trade.Gain_GetPendingBonusesAndWithdrawals @bonus = @bonus;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7/10 (Elements: 10/10, Logic: 6/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_WithdrawalMatcherBonus | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.Gain_WithdrawalMatcherBonus.sql*
