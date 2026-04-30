# History.MirrorDividend

> Idempotency guard and audit log for "Copy Dividend" deductions from CopyTrader mirror balances, recording each proportional withdrawal event triggered when a copier performs a financial operation (cashout, deposit, compensation, or bonus) so the mirror's stop-loss ratio remains valid after the balance change.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, CLUSTERED PK); UNIQUE on (MirrorID, ParentOperationID) |
| **Partition** | No |
| **Indexes** | 2 (1 CLUSTERED PK + 1 UNIQUE NC on MirrorID, ParentOperationID) |

---

## 1. Business Meaning

This table records the "Copy Dividend" deduction events for CopyTrader mirror portfolios. In eToro's CopyTrading system, a customer (the copier) allocates funds to mirror a popular investor's portfolio. When the copier performs a financial operation - a cashout, deposit, compensation, or bonus - a proportional amount is deducted from their mirror balance to maintain the mirror's stop-loss percentage validity. This deduction is called a "Mirror Dividend Withdrawal."

Without this table, two problems would occur: (1) the same dividend withdrawal could be processed twice for the same (mirror, parent operation) pair, causing double-deductions; and (2) there would be no audit trail showing when and why mirror balances were reduced by the Copy Dividend mechanism. The UNIQUE constraint on (MirrorID, ParentOperationID) and the explicit deduplication check in `Trade.MirrorDividendWithdrawal` together enforce exactly-once processing.

Data flows via `Trade.MirrorDividendWithdrawal`: the SP verifies the parent operation exists, checks the UNIQUE constraint has not been satisfied (no duplicate), validates the mirror is active with `UseCopyDividend=1`, then INSERTs into this table and calls `Trade.ChangeMirrorAmount` to apply the deduction. If MirrorDividendAmount is negative (withdrawal from mirror), `Trade.ChangeMirrorAmount` is called; positive amounts (additions to mirror) do not trigger the ChangeMirrorAmount call.

**Note**: Live data shows only 15 rows across 3 mirrors (2016-2023), indicating this is a rarely-triggered feature used in specific CopyTrading scenarios.

---

## 2. Business Logic

### 2.1 Copy Dividend Proportional Deduction

**What**: When a copier performs a qualifying financial operation, a proportional share of that operation's amount is deducted from their mirror balance, computed as a percentage of the mirror's realized equity.

**Columns/Parameters Involved**: `ParentOperationID`, `ParentOperationPercentage`, `MirrorDividendAmount`, `MirrorRealizedEquity`, `CreditTypeID`

**Rules**:
- `ParentOperationPercentage` = (parent operation amount / realized equity at operation time). Observed value: 0.0001 = 0.01%
- `MirrorDividendAmount` = the final deduction amount after applying restrictions and boundaries (minimum amount, operation buffer). Negative = deduction from mirror. Observed values: -$1.55 to -$1.56
- Example: MirrorRealizedEquity=$15,500, ParentOperationPercentage=0.01% -> raw deduction=$1.55
- `MinimumDividendAmount` = floor threshold; deductions smaller than this minimum are not processed. Observed: $1.00
- `OperationBuffer` = safety multiplier applied when computing the expected mirror amount in `Trade.MirrorDividendWithdrawal`. Observed: 1.1 (10% buffer)
- Qualifying CreditTypeIDs: 1=Deposit, 2=Cashout, 6=Compensation, 7=Bonus. Other credit types raise error 60093
- The mirror must be active, have `UseCopyDividend=1`, and have been opened before the parent operation's timestamp

**Diagram**:
```
Copier performs cashout of $155 (CreditTypeID=2)
MirrorRealizedEquity = $15,500
ParentOperationPercentage = $155 / $15,500 = 0.0100 = 1.0%

Wait, observed 0.0001... let me recalculate:
Observed: MirrorRealizedEquity=$15,597, Amount=-$1.56
0.0001 * 15,597 = $1.5597 ≈ $1.56 ✓

ParentOperationPercentage = ParentOperation amount / MirrorRealizedEquity
MirrorDividendAmount = -(ParentOperationPercentage * MirrorRealizedEquity)

Trade.MirrorDividendWithdrawal(@CID, @MirrorID, @ParentOperationID, ...)
  |
  +-- Verify parent op exists in Billing.Deposit / Billing.Withdraw / History.ActiveCredit
  +-- Check History.MirrorDividend: no existing row for (MirrorID, ParentOperationID)?
  +-- Verify Trade.Mirror is active, UseCopyDividend=1, opened before parent op
  |
  +-- INSERT INTO History.MirrorDividend (audit record)
  +-- IF MirrorDividendAmount < 0: EXEC Trade.ChangeMirrorAmount (apply deduction)
  +-- COMMIT
```

### 2.2 Idempotency Guard via UNIQUE Constraint

**What**: The combination of a UNIQUE database constraint and an explicit deduplication check prevents the same dividend withdrawal from being processed more than once for a given mirror and parent operation.

**Columns/Parameters Involved**: `MirrorID`, `ParentOperationID`, `CreditTypeID`

**Rules**:
- UNIQUE NONCLUSTERED constraint on (MirrorID ASC, ParentOperationID ASC) with FILLFACTOR=95 provides DB-level enforcement
- `Trade.MirrorDividendWithdrawal` also explicitly checks: `IF EXISTS (SELECT MirrorID FROM History.MirrorDividend WHERE MirrorID = @MirrorID AND ParentOperationID = @ParentOperationID AND CreditTypeID = @CreditTypeID)` -> RAISERROR 60094 ("withdrawal already performed")
- The CreditTypeID is included in the SP's dedup check but NOT in the UNIQUE constraint - so the DB constraint catches any (MirrorID, ParentOperationID) collision regardless of CreditTypeID
- The INSERT happens BEFORE `Trade.ChangeMirrorAmount` is called, ensuring the audit record exists even if the mirror amount update fails

### 2.3 Mirror Equity State Snapshot

**What**: At the moment of each dividend withdrawal, the current equity state of the mirror is captured for audit purposes.

**Columns/Parameters Involved**: `MirrorRealizedEquity`, `MirrorUnrealizedEquity`, `MirrorSLPercentage`

**Rules**:
- `MirrorRealizedEquity` = total realized (closed position) equity in the mirror at the moment of the withdrawal
- `MirrorUnrealizedEquity` = total unrealized (open position) equity at the same moment
- `MirrorSLPercentage` = the stop-loss percentage threshold for this mirror (observed: 5 = 5% stop-loss). This is the level at which the mirror would automatically close if equity drops this far below the high watermark
- These snapshot values cannot be recovered after the fact, making this table the only source for "what was the mirror's equity state when this dividend was taken?"

---

## 3. Data Overview

| ID | MirrorID | CID | CreditTypeID | MirrorDividendAmount | MirrorRealizedEquity | ParentOperationID | Meaning |
|---|---|---|---|---|---|---|---|
| 14 | 1829944 | 3739182 | 2 (Cashout) | -1.56 | 15,596.12 | 546157 | 13th deduction from mirror 1829944 - a $1.56 copy dividend taken when the copier's cashout (WithdrawID 546157) was processed. Mirror equity was ~$15,596. |
| 13 | 1829944 | 3739182 | 2 (Cashout) | -1.56 | 15,597.68 | 545942 | Same mirror, earlier cashout (WithdrawID 545942) processed 4.7 hours earlier the same day. Equity decreased by $1.56 between the two events. |
| 11 | 1829944 | 3739182 | 2 (Cashout) | -1.55 | 15,454.55 | 464788 | A $1.55 deduction vs the usual $1.56, because MirrorRealizedEquity was ~$15,454 (slightly lower). Confirms the amount is proportional to realized equity. |
| (ID 1) | 1820543 | 3678866 | - | -562.50 | - | - | Single large deduction of $562.50 from 2017 - a much larger mirror with a larger cashout, showing the proportional scaling of the Copy Dividend amount. |
| (ID 0) | 0 | 0 | - | 0 | - | - | Test/seed row from 2016 with zeroed-out values, likely created during feature initialization or testing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(0,1) | CODE-BACKED | Primary key. Auto-incrementing unique identifier starting at 0 (not 1). NOT FOR REPLICATION prevents identity gaps during replication. IDENTITY(0,1) seed=0 explains the test row with ID=0. |
| 2 | MirrorID | int | NO | - | CODE-BACKED | The CopyTrader mirror portfolio being charged. References `Trade.Mirror.MirrorID` (no FK constraint, implicit reference). Part of the UNIQUE constraint with ParentOperationID to prevent duplicate processing. Multiple rows may share the same MirrorID (one per qualifying financial operation). |
| 3 | CID | int | NO | - | CODE-BACKED | Customer account ID of the copier who owns this mirror. Passed from `Trade.MirrorDividendWithdrawal` @CID parameter. Consistent with MirrorID (a mirror belongs to exactly one customer). |
| 4 | ParentOperationID | bigint | YES | - | CODE-BACKED | ID of the triggering financial operation. Interpreted based on CreditTypeID: if Deposit -> Billing.Deposit.DepositID; if Cashout -> Billing.Withdraw.WithdrawID; if Compensation or Bonus -> History.ActiveCredit.CreditID. Part of the UNIQUE constraint. NULL is allowed but in practice always populated. |
| 5 | ParentOperationPercentage | decimal(5,4) | YES | - | CODE-BACKED | Ratio of the parent operation amount to the mirror's realized equity at operation time: `ParentOperation amount / MirrorRealizedEquity`. For example, 0.0001 = 0.01%. Used to compute the proportional mirror deduction. The MirrorDividendAmount equals approximately this ratio times the realized equity. |
| 6 | MirrorDividendAmount | money | NO | - | CODE-BACKED | The final deduction amount applied to the mirror balance. Always negative for a withdrawal (deduction from the mirror). Computed as `ParentOperationPercentage * MirrorRealizedEquity`, subject to the MinimumDividendAmount floor and OperationBuffer. Passed to `Trade.ChangeMirrorAmount` (multiplied by 100 to convert to cents) when negative. |
| 7 | MirrorRealizedEquity | money | NO | - | CODE-BACKED | Snapshot of the mirror's total realized (closed position) equity at the moment the dividend withdrawal is processed. Used as the denominator for percentage calculations and as context for this audit record. |
| 8 | MirrorUnrealizedEquity | money | NO | - | CODE-BACKED | Snapshot of the mirror's total unrealized (open position) equity at the time of the withdrawal. Passed to `Trade.ChangeMirrorAmount` (multiplied by 100) to account for open positions when adjusting the mirror balance. |
| 9 | MirrorSLPercentage | money | NO | - | CODE-BACKED | The mirror's stop-loss percentage threshold at the time of this event. Observed value: 5 (5% stop-loss). If the mirror equity drops this percentage below the high watermark, the mirror auto-closes. Stored for audit - shows what risk parameters were active during this deduction. |
| 10 | MinimumDividendAmount | money | NO | - | CODE-BACKED | Minimum deduction threshold - deductions smaller than this amount are not processed. Observed: $1.00. Prevents micro-deductions that would create excessive operational overhead for tiny cashouts. |
| 11 | Occurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the dividend withdrawal record was created (GETUTCDATE() at INSERT time in Trade.MirrorDividendWithdrawal). The INSERT happens before Trade.ChangeMirrorAmount is called, so this timestamp predates the actual balance change by milliseconds. |
| 12 | OperationBuffer | decimal(18,2) | YES | - | CODE-BACKED | Safety buffer multiplier used in Trade.MirrorDividendWithdrawal when computing the expected mirror amount: `Amount*100 + @MirrorDividendAmount` compared against the mirror's current balance including a 10% buffer. Observed value: 1.1 (10% buffer). NULL if not applicable. |
| 13 | CreditTypeID | tinyint | NO | - | CODE-BACKED | Type of the triggering financial operation. FK to `Dictionary.CreditType.CreditTypeID` (WITH CHECK). Supported values in Trade.MirrorDividendWithdrawal: 1=Deposit, 2=Cashout, 6=Compensation, 7=Bonus. All 15 live rows use CreditTypeID=2 (Cashout). Other credit types would raise error 60093 in real environments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditTypeID | Dictionary.CreditType | FK (WITH CHECK) | Type of the parent financial operation that triggered the dividend deduction. |
| MirrorID | Trade.Mirror | Implicit | The mirror portfolio being charged (no FK constraint; enforced in SP logic). |
| ParentOperationID (CreditTypeID=1) | Billing.Deposit | Implicit | When CreditTypeID=1, ParentOperationID is a Billing.Deposit.DepositID. |
| ParentOperationID (CreditTypeID=2) | Billing.Withdraw | Implicit | When CreditTypeID=2, ParentOperationID is a Billing.Withdraw.WithdrawID. |
| ParentOperationID (CreditTypeID=6,7) | History.ActiveCredit | Implicit | When CreditTypeID=6 or 7, ParentOperationID is a History.ActiveCredit.CreditID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.MirrorDividendWithdrawal | INSERT + SELECT | WRITER + READER | Sole writer; also reads for deduplication check before inserting |
| History.Mirror | JOIN (via MirrorID) | RELATED | History.Mirror documents the parent mirror record that these dividend events belong to |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MirrorDividend (table)
- no code-level dependencies (leaf table)
```

This object has no code-level dependencies (it is a target table, not a view or procedure with FROM/JOIN logic).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CreditType | Table | FK target - CreditTypeID references Dictionary.CreditType.CreditTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.MirrorDividendWithdrawal | Stored Procedure | WRITER + READER - sole writer; reads for idempotency check before inserting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryMirrorDvividend | CLUSTERED PK | ID ASC | - | - | Active (note: typo "Dvividend" in constraint name matches DDL) |
| UNQ | UNIQUE NONCLUSTERED | MirrorID ASC, ParentOperationID ASC | - | - | Active (FILLFACTOR=95) |

Note: The PK constraint name contains a typo ("Dvividend" not "Dividend") - this matches the DDL exactly.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryMirrorDvividend | PRIMARY KEY | CLUSTERED on ID - IDENTITY(0,1) sequence guarantees uniqueness |
| UNQ | UNIQUE | (MirrorID, ParentOperationID) - prevents duplicate dividend processing for the same mirror + operation pair |
| FK_HistoryMirrorDividend_DictionaryCreditTypeID | FOREIGN KEY (WITH CHECK) | CreditTypeID -> Dictionary.CreditType(CreditTypeID) |

---

## 8. Sample Queries

### 8.1 Get all dividend deductions for a specific mirror

```sql
SELECT
    hmd.ID,
    hmd.Occurred,
    hmd.CreditTypeID,
    ct.Name AS CreditType,
    hmd.ParentOperationID,
    hmd.ParentOperationPercentage,
    hmd.MirrorDividendAmount,
    hmd.MirrorRealizedEquity,
    hmd.MirrorSLPercentage
FROM History.MirrorDividend hmd WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON hmd.CreditTypeID = ct.CreditTypeID
WHERE hmd.MirrorID = @MirrorID
ORDER BY hmd.Occurred ASC;
```

### 8.2 Check if a dividend has already been processed for a given mirror + operation

```sql
-- Replicates the deduplication check in Trade.MirrorDividendWithdrawal
SELECT
    hmd.ID,
    hmd.Occurred,
    hmd.MirrorDividendAmount
FROM History.MirrorDividend hmd WITH (NOLOCK)
WHERE hmd.MirrorID = @MirrorID
  AND hmd.ParentOperationID = @ParentOperationID
  AND hmd.CreditTypeID = @CreditTypeID;
```

### 8.3 Summary of dividend deductions by credit type

```sql
SELECT
    ct.Name AS CreditType,
    COUNT(*) AS EventCount,
    SUM(hmd.MirrorDividendAmount) AS TotalDeducted,
    AVG(hmd.MirrorDividendAmount) AS AvgDeduction,
    COUNT(DISTINCT hmd.MirrorID) AS UniqueMirrors,
    MIN(hmd.Occurred) AS FirstEvent,
    MAX(hmd.Occurred) AS LastEvent
FROM History.MirrorDividend hmd WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON hmd.CreditTypeID = ct.CreditTypeID
GROUP BY hmd.CreditTypeID, ct.Name
ORDER BY EventCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.MirrorDividend | Type: Table | Source: etoro/etoro/History/Tables/History.MirrorDividend.sql*
