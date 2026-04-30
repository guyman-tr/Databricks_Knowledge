# Trade.JUNK_ChangeMirrorAmount

> Deprecated mirror balance adjustment procedure that atomically adds or subtracts a delta amount from a CopyTrader mirror allocation, updates realized equity and MSL threshold, logs to History.Mirror, and calls Customer.SetBalanceChangeMirrorAmount to adjust the customer's balance in the opposite direction.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - identifies the mirror to modify |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.JUNK_ChangeMirrorAmount handles the business operation of a copier depositing into or withdrawing from a CopyTrader mirror - that is, increasing or decreasing the funds allocated to copying a leader. The "JUNK" prefix marks this as a deprecated procedure targeted for removal (per the inline comment "muli dont do this" and Jira TRADNA-1459). The active equivalent is Trade.ChangeMirrorAmountForMoe or the standard ChangeMirrorAmount path.

This procedure exists because changing a mirror's allocation is a two-sided financial operation: adding $100 to a mirror means subtracting $100 from the customer's general account balance. Both sides must happen atomically in a single transaction. The procedure also recalculates the mirror stop-loss (MSL) threshold when the amount changes, since MSL is derived as a percentage of total mirror funds.

Data flows: the procedure acquires a row-level lock on Trade.Mirror using a dummy UPDATE (SET CID=CID with OUTPUT), validates the operation, executes the delta UPDATE on Trade.Mirror, INSERTs an audit snapshot into History.Mirror (MirrorOperationID=3 = balance change), then calls Customer.SetBalanceChangeMirrorAmount with the inverted delta to mirror the debit/credit on the customer's account balance. No callers found in the Trade schema - this procedure appears to be dead code targeted for cleanup.

---

## 2. Business Logic

### 2.1 Optimistic Concurrency Check

**What**: If the caller provides @ExpectedMirrorAmountInCents, the procedure validates that the current amount plus the delta equals the expected result, catching race conditions.

**Columns/Parameters Involved**: `@ExpectedMirrorAmountInCents`, `@DeltaAmountInCents`, `Trade.Mirror.Amount`

**Rules**:
- The dummy UPDATE (SET CID=CID) serves as a row-level lock; the OUTPUT clause captures the current Amount*100 into @MirrorValidation before any other reads.
- If @ExpectedMirrorAmountInCents is NULL, the check is skipped (ISNULL default).
- If CurrentAmountInCents + @DeltaAmountInCents <> @ExpectedMirrorAmountInCents, RAISERROR with a descriptive message including the three values.
- Error 60050: MirrorID not found (@@ROWCOUNT=0 after main SELECT).

**Diagram**:
```
Lock row:  UPDATE Trade.Mirror SET CID=CID OUTPUT INSERTED.Amount*100
              |
              v
Validate:  CurrentAmountInCents + DeltaAmountInCents = ExpectedMirrorAmountInCents?
              | YES (or NULL) -> continue
              | NO -> RAISERROR
```

### 2.2 Mirror Stop-Loss Recalculation

**What**: When the mirror amount changes, the MSL absolute threshold (@NewSLAmountCents) is recalculated from the percentage unless @EditMirrorSL=0.

**Columns/Parameters Involved**: `@EditMirrorSL`, `@IsRealizedFlow`, `@NewSLAmountCents` (OUTPUT), `Trade.Mirror.MirrorSLPercentage`, `Trade.Mirror.RealizedEquity`, `Trade.Mirror.MirrorSL`

**Rules**:
- If @EditMirrorSL=1 (default): NewSLAmountCents = (base * MirrorSLPercentage / 100), where base = RealizedEquity*100 + DeltaAmountInCents (for @IsRealizedFlow=1) or @MirrorCalculatedUnrealized (for @IsRealizedFlow=0).
- If @EditMirrorSL=0: NewSLAmountCents = existing MirrorSL * 100 (no recalculation - used for operations that should not move the MSL).
- Error 60097: If new mirror amount would trigger MSL closure (NewSLAmountCents >= @MirrorCalculatedUnrealized and mirror is active), the operation is rejected.

**Diagram**:
```
@EditMirrorSL=1 AND @IsRealizedFlow=1:
  NewSLCents = (RealizedEquity*100 + DeltaCents) * MirrorSLPercentage / 100
@EditMirrorSL=1 AND @IsRealizedFlow=0:
  NewSLCents = @MirrorCalculatedUnrealized * MirrorSLPercentage / 100
@EditMirrorSL=0:
  NewSLCents = MirrorSL * 100  (unchanged)
```

### 2.3 Balance Transfer Direction

**What**: The delta's sign determines whether funds move balance->mirror or mirror->balance, setting CreditTypeID accordingly.

**Columns/Parameters Involved**: `@DeltaAmountInCents`, `@CreditTypeID`, `Trade.Mirror.DepositSummary`, `Trade.Mirror.WithdrawalSummary`

**Rules**:
- @DeltaAmountInCents > 0: move money FROM balance TO mirror. CreditTypeID=18. DepositSummary += delta.
- @DeltaAmountInCents < 0: move money FROM mirror TO balance. CreditTypeID=19. WithdrawalSummary += abs(delta).
- The delta sent to Customer.SetBalanceChangeMirrorAmount has its sign INVERTED (0 - @DeltaAmountInCents): adding to mirror = debiting from balance; withdrawing from mirror = crediting to balance.
- Error 60052: Withdrawal > AmountInMirror (removing more than what is allocated).
- Error 60054: Deposit > Customer.Credit (customer lacks funds).

**Diagram**:
```
DeltaAmountInCents > 0 (add to mirror):
  Trade.Mirror.Amount += delta         CreditTypeID=18
  Trade.Mirror.DepositSummary += delta
  Customer.SetBalance( -delta )        (balance decreases)

DeltaAmountInCents < 0 (withdraw from mirror):
  Trade.Mirror.Amount += delta         CreditTypeID=19
  Trade.Mirror.WithdrawalSummary += abs(delta)
  Customer.SetBalance( -delta )        (balance increases)
```

### 2.4 Validation Gates

**What**: Multiple pre-execution validations ensure the operation is safe.

**Rules**:
- Error 60050: MirrorID not found.
- Error 60051: Mirror is not active (IsActive=0) and delta > 0 (cannot add to closed mirror).
- Error 60052: @IsRealizedFlow=1, delta < 0, abs(delta) > AmountInMirror.
- Error 60054: delta > 0, delta > Customer.Credit.
- Error 60097: New mirror amount would immediately trigger MSL closure.
- Error 60064: @CID passed != CID stored in Trade.Mirror.
- All validations bypassed for @ValidateUserBalance=0 (Reopen Trade feature only).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the copier. Validated against Trade.Mirror.CID (error 60064 if mismatch). Passed to Customer.SetBalanceChangeMirrorAmount. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | ID of the mirror to modify. FK to Trade.Mirror.MirrorID. Error 60050 if not found. |
| 3 | @DeltaAmountInCents | dtPrice | NO | - | CODE-BACKED | Change in allocation, in cents. Positive = deposit into mirror (balance->mirror); negative = withdrawal (mirror->balance). Converted to dollars internally (divide by 100). |
| 4 | @MirrorCalculatedUnrealized | Money | NO | - | CODE-BACKED | Caller-supplied current unrealized equity of the mirror (in dollars * 100 cents? - used as base for MSL when @IsRealizedFlow=0). Used to check error 60097 (would new amount trigger MSL?). |
| 5 | @NewSLAmountCents | Money | YES (OUTPUT) | - | CODE-BACKED | OUTPUT: the recalculated mirror stop-loss threshold in cents after the amount change. Caller uses this to update any dependent records. |
| 6 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Session identifier for audit. Written to History.Mirror.SessionID. NULL if not provided. |
| 7 | @MIMOOperationTypeIID | tinyint | NO | 0 | CODE-BACKED | MIMO (Mirror In Mirror Out) operation type identifier. Written to History.Mirror.MIMOOperationTypeID for audit categorization. Default 0. |
| 8 | @MirrorDividendID | INT | NO | 0 | CODE-BACKED | ID of the dividend record if this balance change is driven by a dividend payment. Written to History.Mirror.MirrorDividendID. 0 = not dividend-driven (per FB 31696). |
| 9 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client-supplied idempotency GUID. Written to History.Mirror.ClientRequestGuid. Used for duplicate detection. |
| 10 | @ValidateUserBalance | TINYINT | NO | 1 | CODE-BACKED | 1 = apply balance validations (errors 60052, 60054, 60097). 0 = skip validations (used by Reopen Trade feature per FB 52839). |
| 11 | @EditMirrorSL | BIT | NO | 1 | CODE-BACKED | 1 = recalculate MirrorSL after amount change (default). 0 = keep existing MirrorSL unchanged regardless of new amount. |
| 12 | @ExpectedMirrorAmountInCents | MONEY | YES | NULL | CODE-BACKED | Optimistic concurrency: expected resulting amount in cents. If provided and CurrentAmount+Delta != Expected, RAISERROR with amount mismatch message. NULL = skip check. |
| 13 | @IsRealizedFlow | tinyint | NO | 1 | CODE-BACKED | 1 = use RealizedEquity as base for MSL recalculation (standard path). 0 = use @MirrorCalculatedUnrealized as base. Controls which equity snapshot is used in MSL formula. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | Read/Write | Locks row, reads mirror state, updates Amount/RealizedEquity/DepositSummary/WithdrawalSummary/MirrorSL |
| @MirrorID | History.Mirror | Write | Inserts audit snapshot with MirrorOperationID=3 (balance change) |
| Trade.Mirror.CID | Customer.Customer | JOIN/Read | Reads Credit balance for error 60054 validation |
| @CID, @AmountInCents | Customer.SetBalanceChangeMirrorAmount | EXEC | Applies the inverted delta to customer's account balance with credit type 18 or 19 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No callers found) | - | - | No stored procedures in the Trade schema call this procedure. JUNK_ prefix indicates it is deprecated and not in active use. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.JUNK_ChangeMirrorAmount (procedure)
├── Trade.Mirror (table)
├── History.Mirror (table)
├── Customer.Customer (table)
└── Customer.SetBalanceChangeMirrorAmount (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Row-level lock via dummy UPDATE; SELECTed for state; UPDATEd with new Amount/RealizedEquity/DepositSummary/WithdrawalSummary/MirrorSL |
| History.Mirror | Table | INSERTed with full mirror snapshot at time of change; MirrorOperationID=3 |
| Customer.Customer | Table | JOINed to Trade.Mirror to read Credit for balance validation (error 60054) |
| Customer.SetBalanceChangeMirrorAmount | Procedure | EXECuted with inverted delta to debit/credit customer account balance; returns 0 on success |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Deprecated - no active callers) | - | JUNK_ prefix and comment "muli dont do this" indicate this procedure is not called in production. See Trade.ChangeMirrorAmountForMoe for the active equivalent. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: uses a two-phase TRY/CATCH/transaction pattern - first TRY for validation (ROLLBACK on failure), second TRY for the actual DML (ROLLBACK on failure).

---

## 8. Sample Queries

### 8.1 Find recent History.Mirror entries for balance-change operations (MirrorOperationID=3)

```sql
SELECT TOP 20 HM.MirrorID, HM.CID, HM.Amount, HM.RealizedEquity,
       HM.MIMOOperationTypeID, HM.MirrorDividendID, HM.ClientRequestGuid,
       HM.Occurred, HM.SessionID
FROM History.Mirror AS HM WITH (NOLOCK)
WHERE HM.MirrorOperationID = 3
ORDER BY HM.Occurred DESC;
```

### 8.2 Check current mirror state vs History.Mirror for a specific mirror

```sql
SELECT TM.MirrorID, TM.Amount, TM.RealizedEquity, TM.DepositSummary,
       TM.WithdrawalSummary, TM.MirrorSL, TM.MirrorSLPercentage, TM.IsActive
FROM Trade.Mirror AS TM WITH (NOLOCK)
WHERE TM.MirrorID = <MirrorID>;

SELECT TOP 10 HM.Amount, HM.RealizedEquity, HM.MirrorOperationID,
       HM.MIMOOperationTypeID, HM.Occurred
FROM History.Mirror AS HM WITH (NOLOCK)
WHERE HM.MirrorID = <MirrorID>
ORDER BY HM.Occurred DESC;
```

### 8.3 Find mirrors where a dividend-driven balance change occurred

```sql
SELECT HM.MirrorID, HM.CID, HM.Amount, HM.MirrorDividendID, HM.Occurred
FROM History.Mirror AS HM WITH (NOLOCK)
WHERE HM.MirrorOperationID = 3
  AND HM.MirrorDividendID <> 0
ORDER BY HM.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| TRADNA-1459 (referenced in SP header) | Jira | Referenced in code header as origin ticket for this procedure (not fetched - no content found in search) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.JUNK_ChangeMirrorAmount | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.JUNK_ChangeMirrorAmount.sql*
