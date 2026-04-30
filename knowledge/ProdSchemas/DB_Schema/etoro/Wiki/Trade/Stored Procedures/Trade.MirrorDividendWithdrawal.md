# Trade.MirrorDividendWithdrawal

> Processes a proportional copy-dividend for a single mirror: validates the triggering financial event (deposit, cashout, compensation, or bonus), logs to History.MirrorDividend, and if the dividend is negative (withdrawal from mirror), calls Trade.ChangeMirrorAmount to deduct from the mirror allocation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID + @ParentOperationID + @CreditTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.MirrorDividendWithdrawal implements the "copy dividend" feature in eToro's CopyTrader: when a leader (the person being copied) receives a deposit, cashout, compensation, or bonus, the copier's mirror allocation is proportionally adjusted by the same percentage. For example, if a leader withdraws 10% of their equity, each mirror copying them should have 10% deducted from its allocation - this keeps the copy ratio in sync with the leader's actual trading capital.

The procedure validates the triggering operation exists in its source table (Billing.Deposit, Billing.Withdraw, or History.ActiveCredit), checks that the mirror qualifies (active, UseCopyDividend=1, opened before the triggering event), prevents duplicate processing, logs the dividend event to History.MirrorDividend, and - only if the dividend is negative (a withdrawal) - calls Trade.ChangeMirrorAmount to actually deduct the amount from the mirror balance.

A positive @MirrorDividendAmount (deposit/bonus case) only logs to History.MirrorDividend without changing Trade.Mirror.Amount - the business logic for deposits does not increase the mirror proportionally (only withdrawals are enforced as reductions).

Data flows: called by the application (DividendsApp or copy-dividend service) after calculating the proportional impact per mirror. No SP callers found in the Trade schema - this is called externally.

---

## 2. Business Logic

### 2.1 Parent Operation Validation (Real Environment Only)

**What**: In Real environment (FeatureID=22=1), validates that @ParentOperationID exists in the appropriate table based on CreditTypeID.

**Columns/Parameters Involved**: `@CreditTypeID`, `@ParentOperationID`, `@IsReal`

**Rules**:
- CreditTypeID=1 (Deposit): validates against Billing.Deposit.DepositID.
- CreditTypeID=2 (Cashout/Withdraw): validates against Billing.Withdraw.WithdrawID.
- CreditTypeID=6 (Compensation): validates against History.ActiveCredit WHERE CreditTypeID=6.
- CreditTypeID=7 (Bonus): validates against History.ActiveCredit WHERE CreditTypeID=7.
- If @OperationID remains 0 after the lookup (not found): RAISERROR(60093).
- Demo environment (FeatureID=22 != 1): validation is skipped entirely.

**Diagram**:
```
CreditTypeID:
  1 = Deposit    -> Billing.Deposit
  2 = Cashout    -> Billing.Withdraw
  6 = Compensation -> History.ActiveCredit (CreditTypeID=6)
  7 = Bonus      -> History.ActiveCredit (CreditTypeID=7)
  Not found -> Error 60093
```

### 2.2 Mirror Eligibility Check and Optimistic Concurrency

**What**: Verifies the mirror is active, has copy dividend enabled, was open before the triggering event, and has not already received this dividend.

**Columns/Parameters Involved**: `Trade.Mirror.IsActive`, `Trade.Mirror.UseCopyDividend`, `Trade.Mirror.Occurred`, `@ParentOperationOccurred`

**Rules**:
- Duplicate check: History.MirrorDividend WHERE MirrorID=@MirrorID AND ParentOperationID=@ParentOperationID AND CreditTypeID=@CreditTypeID -> if exists: RAISERROR(60094).
- Mirror qualification: IsActive=1 AND ISNULL(UseCopyDividend,1)=1 AND Occurred < @ParentOperationOccurred.
  - UseCopyDividend NULL treated as 1 (opt-in by default).
  - Mirror must have been opened BEFORE the triggering event (no dividend for mirrors opened after the event).
- @ExpectedMirrorAmountInCents = Amount*100 + @MirrorDividendAmount: used as an optimistic concurrency guard when calling Trade.ChangeMirrorAmount.
- If @ExpectedMirrorAmountInCents is NULL (mirror not found/not eligible): RAISERROR(60095).

### 2.3 Conditional Balance Deduction

**What**: Only deducts from the mirror balance when @MirrorDividendAmount is negative (withdrawal scenario).

**Columns/Parameters Involved**: `@MirrorDividendAmount`, `@NewSLAmount`, `Trade.Mirror.Amount`

**Rules**:
- IF @MirrorDividendAmount < 0: converts all amounts to cents (*100) and calls Trade.ChangeMirrorAmount to deduct the amount from Trade.Mirror and Customer account balance.
  - MIMOOperationTypeIID=1 (CopyDividend).
  - @DividnedID (the History.MirrorDividend identity just inserted) is passed as @MirrorDividendID to Trade.ChangeMirrorAmount for audit linkage.
  - @ExpectedMirrorAmountInCents passed for optimistic concurrency.
- IF @MirrorDividendAmount >= 0: only the History.MirrorDividend INSERT occurs - no balance change. Positive dividends are logged only (business decision: proportional gains are not automatically added to mirror).
- RETURN(0) on success; CATCH block ROLLBACK and THROW on failure.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the copier whose mirror is being adjusted. Written to History.MirrorDividend.CID. Passed to Trade.ChangeMirrorAmount for ownership validation. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | ID of the mirror to process. Used for eligibility check (Trade.Mirror) and duplicate check (History.MirrorDividend). Passed to Trade.ChangeMirrorAmount. |
| 3 | @NewSLAmount | money | NO | - | CODE-BACKED | New mirror stop-loss amount in dollars. Passed to Trade.ChangeMirrorAmount when @MirrorDividendAmount < 0. Output parameter of ChangeMirrorAmount (passed as inout). |
| 4 | @ParentOperationID | BIGINT | NO | - | CODE-BACKED | ID of the triggering financial event (DepositID, WithdrawID, or CreditID depending on @CreditTypeID). Validated against the source table in Real environment. Written to History.MirrorDividend.ParentOperationID. Used in duplicate check. |
| 5 | @ParentOperationPercentage | decimal(5,4) | NO | - | CODE-BACKED | The withdrawal/deposit amount as a fraction of the leader's RealizedEquity (e.g., 0.10 = 10%). Written to History.MirrorDividend.ParentOperationPercentage for audit. |
| 6 | @ParentOperationOccurred | datetime | NO | - | CODE-BACKED | Timestamp when the triggering parent operation occurred. Mirror must have Occurred < this value to qualify (no dividend for mirrors opened after the event). |
| 7 | @MirrorDividendAmount | dbo.dtPrice | NO | - | CODE-BACKED | The calculated proportional amount to apply to the mirror (in dollars). Negative = withdrawal (mirror decreases); positive = deposit (only logged, balance not changed). Written to History.MirrorDividend.MirrorDividendAmount. |
| 8 | @MirrorRealizedEquity | money | NO | - | CODE-BACKED | Current realized equity of the mirror at time of processing. Written to History.MirrorDividend.MirrorRealizedEquity for audit. |
| 9 | @MirrorUnrealizedEquity | money | NO | - | CODE-BACKED | Current unrealized equity (including open positions PnL). Written to History.MirrorDividend.MirrorUnrealizedEquity. Used as base for MSL calculation in Trade.ChangeMirrorAmount when @MirrorDividendAmount < 0. |
| 10 | @MirrorSLPercentage | decimal(18,2) | NO | - | CODE-BACKED | Current MSL percentage of the mirror. Written to History.MirrorDividend.MirrorSLPercentage for audit snapshot. |
| 11 | @MinimumDividendAmount | dbo.dtPrice | NO | - | CODE-BACKED | Minimum threshold for a dividend to be processed (applied by caller before invocation). Written to History.MirrorDividend.MinimumDividendAmount for audit. |
| 12 | @OperationBuffer | decimal(3,2) | NO | - | CODE-BACKED | A buffer percentage applied by the caller when calculating the dividend amount. Written to History.MirrorDividend.OperationBuffer. |
| 13 | @CreditTypeID | INT | NO | - | CODE-BACKED | Type of triggering event: 1=Deposit, 2=Cashout, 6=Compensation, 7=Bonus. Determines which table is used for ParentOperationID validation. Written to History.MirrorDividend.CreditTypeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=22 | Maintenance.Feature | Read | Detects Real vs Demo to gate parent operation validation |
| @ParentOperationID, CreditTypeID=1 | Billing.Deposit | Read | Validates deposit exists in Real environment |
| @ParentOperationID, CreditTypeID=2 | Billing.Withdraw | Read | Validates cashout exists in Real environment |
| @ParentOperationID, CreditTypeID=6/7 | History.ActiveCredit | Read | Validates compensation/bonus credit exists |
| MirrorID, ParentOperationID | History.MirrorDividend | Read/Write | Duplicate check (SELECT); audit INSERT |
| @MirrorID | Trade.Mirror | Read | Eligibility check (IsActive, UseCopyDividend, Occurred, Amount) |
| @CID, @MirrorID, @MirrorDividendAmount | Trade.ChangeMirrorAmount | EXEC | Deducts dividend from mirror balance when negative (MIMOOperationTypeIID=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SP callers found) | - | - | Called by external application (copy-dividend service); no SP callers in Trade schema. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MirrorDividendWithdrawal (procedure)
├── Maintenance.Feature (table)
├── Billing.Deposit (table)
├── Billing.Withdraw (table)
├── History.ActiveCredit (table)
├── History.MirrorDividend (table)
├── Trade.Mirror (table)
└── Trade.ChangeMirrorAmount (procedure)
      ├── Trade.Mirror (table)
      ├── History.Mirror (table)
      ├── Customer.Customer (table)
      └── Customer.SetBalanceChangeMirrorAmount (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECTed for FeatureID=22 (Real vs Demo flag) |
| Billing.Deposit | Table | SELECTed to validate DepositID when CreditTypeID=1 (Real env only) |
| Billing.Withdraw | Table | SELECTed to validate WithdrawID when CreditTypeID=2 (Real env only) |
| History.ActiveCredit | Table | SELECTed to validate CreditID when CreditTypeID=6 or 7 (Real env only) |
| History.MirrorDividend | Table | SELECTed for duplicate check; INSERTed with full audit snapshot |
| Trade.Mirror | Table | SELECTed NOLOCK to check eligibility and read Amount for @ExpectedMirrorAmountInCents |
| Trade.ChangeMirrorAmount | Procedure | EXECuted when @MirrorDividendAmount < 0 to deduct from mirror and customer balance |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No SP dependents found) | - | Called by external copy-dividend processing service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Transaction wraps the History.MirrorDividend INSERT + Trade.ChangeMirrorAmount call. CATCH block rolls back on any error and re-THROWs.

---

## 8. Sample Queries

### 8.1 Check mirror dividend history for a specific mirror

```sql
SELECT MD.MirrorDividendID, MD.MirrorID, MD.CID, MD.ParentOperationID,
       MD.CreditTypeID, MD.MirrorDividendAmount, MD.ParentOperationPercentage,
       MD.MirrorRealizedEquity, MD.Occurred
FROM History.MirrorDividend AS MD WITH (NOLOCK)
WHERE MD.MirrorID = <MirrorID>
ORDER BY MD.Occurred DESC;
```

### 8.2 Find mirrors eligible for a specific parent operation (UseCopyDividend=1, active, opened before event)

```sql
SELECT TM.MirrorID, TM.CID, TM.Amount * 100 AS AmountCents,
       TM.UseCopyDividend, TM.IsActive, TM.Occurred
FROM Trade.Mirror AS TM WITH (NOLOCK)
WHERE TM.IsActive = 1
  AND ISNULL(TM.UseCopyDividend, 1) = 1
  AND TM.Occurred < <ParentOperationOccurred>;
```

### 8.3 Check for duplicate processing (what error 60094 detects)

```sql
SELECT MirrorID, ParentOperationID, CreditTypeID, Occurred
FROM History.MirrorDividend WITH (NOLOCK)
WHERE MirrorID = <MirrorID>
  AND ParentOperationID = <ParentOperationID>
  AND CreditTypeID = <CreditTypeID>;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.MirrorDividendWithdrawal | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.MirrorDividendWithdrawal.sql*
