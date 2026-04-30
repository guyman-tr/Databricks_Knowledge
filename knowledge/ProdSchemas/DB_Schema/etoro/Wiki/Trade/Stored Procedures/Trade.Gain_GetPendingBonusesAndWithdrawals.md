# Trade.Gain_GetPendingBonusesAndWithdrawals

> Matches bonus credits to their subsequent withdrawals within a 24-hour window where the bonus amount exactly offsets the withdrawal, identifying bonus-funded withdrawal pairs for gain calculation adjustment.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @bonus (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies pairs of bonus credits and subsequent withdrawals where the bonus amount exactly matches the withdrawal amount (they cancel out to zero). The Gain system uses this to identify "bonus-funded withdrawals" - cases where a customer received a bonus and immediately withdrew the same amount, which should be treated differently in gain calculations than regular deposits/withdrawals.

The matching logic requires: same CID, withdrawal occurs within 0-24 hours after the bonus, and the bonus amount plus the withdrawal's TotalCashChange sums to exactly zero (a.Amount + SUM(b.TotalCashChange) = 0).

---

## 2. Business Logic

### 2.1 Bonus-Withdrawal Time-Amount Matching

**What**: Pairs bonus credits with withdrawals that exactly offset them within 24 hours.

**Columns/Parameters Involved**: `@bonus.Amount`, `@bonus.Occurred`, `History.Credit.TotalCashChange`, `WithdrawID`

**Rules**:
- Bonus records provided via TVP with CID, CreditID, Occurred, and Amount
- Matches against History.Credit records where WithdrawID IS NOT NULL (actual withdrawals)
- Time window: withdrawal must occur within 0-24 hours AFTER the bonus (DATEDIFF(HOUR) >= 0 AND <= 24)
- Amount match: bonus Amount + SUM(withdrawal TotalCashChange) must equal exactly 0
- If @CID = -1: process all CIDs in the bonus TVP (batch mode)
- If @CID != -1: filter to single CID (individual mode)
- Output includes the withdrawal's earliest Occurred date and the offset amount

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer filter. Pass -1 to process all CIDs in the bonus TVP. Pass a specific CID to filter to that customer only. |
| 2 | @bonus | Trade.Gain_WithdrawalMatcherBonus (TVP) | NO | - | CODE-BACKED | Table-Valued Parameter containing bonus credit records to match against withdrawals. READONLY. Contains CID, CreditID, Occurred, Amount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | History.Credit | READER | Matches bonus records to subsequent withdrawal records within 24-hour window |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Gain calculation service | EXEC | Caller | Identifies bonus-withdrawal pairs for gain adjustment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Gain_GetPendingBonusesAndWithdrawals (procedure)
+-- History.Credit (table)
+-- Trade.Gain_WithdrawalMatcherBonus (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | JOIN on CID + time window + amount matching |
| Trade.Gain_WithdrawalMatcherBonus | User Defined Type | TVP type for @bonus parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called by external Gain service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Temp table: NC INDEX IX_CID_Occurred on #Bonus(CID, Occurred).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Match Bonuses to Withdrawals for All CIDs

```sql
DECLARE @bonus Trade.Gain_WithdrawalMatcherBonus
INSERT INTO @bonus VALUES (12345, 999, '2026-03-15 10:00:00', 100.00)
EXEC Trade.Gain_GetPendingBonusesAndWithdrawals @CID = -1, @bonus = @bonus
```

### 8.2 Match for a Specific Customer

```sql
DECLARE @bonus Trade.Gain_WithdrawalMatcherBonus
INSERT INTO @bonus VALUES (12345, 999, '2026-03-15 10:00:00', 100.00)
EXEC Trade.Gain_GetPendingBonusesAndWithdrawals @CID = 12345, @bonus = @bonus
```

### 8.3 View Recent Bonus Credits

```sql
SELECT TOP 20 CID, CreditID, Occurred, TotalCashChange, WithdrawID
  FROM History.Credit WITH (NOLOCK)
 WHERE CreditTypeID IN (3, 4)
   AND Occurred > DATEADD(DAY, -7, GETUTCDATE())
 ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_GetPendingBonusesAndWithdrawals | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Gain_GetPendingBonusesAndWithdrawals.sql*
