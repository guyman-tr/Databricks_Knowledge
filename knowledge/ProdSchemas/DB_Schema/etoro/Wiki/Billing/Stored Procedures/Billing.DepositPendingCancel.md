# Billing.DepositPendingCancel

> Bulk-cancels all Pending deposits for a given payment method within a date range - a back-office cleanup procedure for clearing stale pending deposits after a gateway session or batch window closes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.Deposit.PaymentStatusID (13->6) + INSERT History.DepositAction |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositPendingCancel` is the batch cancellation procedure for deposits stuck in Pending status (PaymentStatusID=13). It finds all Pending deposits for a specific payment method (FundingTypeID) within a date range and transitions them to Cancelled status (PaymentStatusID=6), recording each cancellation in `History.DepositAction`.

The typical use case is operational cleanup: after a payment gateway batch window closes, any deposits still in Pending status that haven't been approved or declined are considered stale and should be cancelled. This prevents customers from having funds indefinitely in a limbo state. The `@FundingTypeID` parameter targets a specific payment method, allowing selective cleanup without affecting other methods.

The optional `@SessionID` parameter allows the calling operation to override the session ID on cancelled deposits (useful when a batch job session initiated the cleanup). If not provided, the original deposit session ID is preserved.

---

## 2. Business Logic

### 2.1 Pending-to-Cancelled Transition

**What**: Transitions all deposits matching the criteria from Pending (13) to Cancelled (6).

**Columns/Parameters Involved**: `@FundingTypeID`, `@FromDate`, `@ToDate`, `Billing.Deposit.PaymentStatusID`, `Billing.Deposit.PaymentDate`

**Rules**:
- Filter: `PaymentStatusID = 13 (Pending) AND PaymentDate BETWEEN @FromDate AND @ToDate AND FundingTypeID = @FundingTypeID`.
- FundingTypeID is joined via Billing.Funding (Deposit.FundingID -> Funding.FundingTypeID).
- Update: `SET PaymentStatusID = 6 (Cancelled), ModificationDate = GETDATE()`.
- All matching deposits are cancelled in a single UPDATE within a transaction.
- No per-deposit validation - all Pending deposits in range for the funding type are cancelled.

### 2.2 Session ID Override

**What**: Optional session ID override that applies uniformly across all cancelled deposits.

**Columns/Parameters Involved**: `@SessionID`, `Billing.Deposit.SessionID`

**Rules**:
- `CASE WHEN @SessionID IS NULL THEN SessionID ELSE @SessionID END` - preserves existing if NULL, overrides if provided.
- Applied both to the `@Info` table variable AND to `Billing.Deposit.SessionID` in the UPDATE.
- Enables batch job operators to tag all cancellations with a specific operation session for traceability.

### 2.3 Audit Trail

**What**: Inserts a cancellation action into History.DepositAction for each cancelled deposit.

**Columns/Parameters Involved**: `History.DepositAction.PaymentActionStatusID`, `PaymentActionTypeID`, `PaymentStatusID`

**Rules**:
- `PaymentActionStatusID = 3 (Closed)` - the action's completion state.
- `PaymentActionTypeID = 7 (Cancelled)` - the action type performed.
- `PaymentStatusID = 6 (Cancelled)` - the new deposit status.
- ManagerID and ExchangeRate preserved from the original deposit (not changed by cancellation).
- ModificationDate set to `GETDATE()` for all rows consistently.

```
Filter: PaymentStatusID=13 AND PaymentDate IN [@FromDate, @ToDate] AND FundingTypeID=@FundingTypeID
  -> Collect matching deposits into @Info (DepositID, ManagerID, ExchangeRate, SessionID)
  -> UPDATE Billing.Deposit SET PaymentStatusID=6 (Cancelled) + ModificationDate + SessionID
  -> INSERT History.DepositAction (ActionStatusID=3/Closed, ActionTypeID=7/Cancelled, StatusID=6/Cancelled)
  -> COMMIT
```

### 2.4 Transaction Error Handling

**What**: Legacy error handling using @@ERROR (not TRY/CATCH).

**Columns/Parameters Involved**: N/A

**Rules**:
- Uses `SELECT @LocalError = @@ERROR` after each DML statement.
- If `@LocalError != 0`: ROLLBACK, RAISERROR(60000, ...), RETURN 60000.
- Old-style error handling (pre-SQL 2005 TRY/CATCH). Functional but less robust than modern pattern.
- Two error check points: after the UPDATE and after the INSERT.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Payment method to target for cancellation. Matched via Billing.Funding.FundingTypeID JOIN. Only deposits using this funding type will be cancelled. Implicit FK to Dictionary.FundingType. |
| 2 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of the PaymentDate range to scan for Pending deposits. Inclusive (BETWEEN). |
| 3 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of the PaymentDate range to scan for Pending deposits. Inclusive (BETWEEN). |
| 4 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Optional session ID of the cancellation operation. If provided, overrides the SessionID on all affected deposits and their DepositAction audit rows. If NULL, each deposit retains its original SessionID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID via FundingID | Billing.Deposit | MODIFIER (UPDATE) | Updates PaymentStatusID from 13 to 6 for matching deposits. |
| FundingID | Billing.Funding | JOIN | Resolves FundingTypeID filter. LEFT JOIN to Deposit. |
| (all cancelled deposits) | History.DepositAction | WRITER (INSERT) | Creates cancellation audit records: ActionStatus=3, ActionType=7, PaymentStatus=6. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Back-office operations / scheduled jobs) | - | EXEC | Called by operations staff or automation to clear stale pending deposits after gateway batch windows. Not referenced by other stored procedures in SSDT. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositPendingCancel (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
└── History.DepositAction (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ (filter) then UPDATE (PaymentStatusID, ModificationDate, SessionID). |
| Billing.Funding | Table | JOIN to resolve FundingTypeID filter. |
| History.DepositAction | Table (cross-schema) | INSERT - creates cancellation audit records. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Error codes**:
- `RAISERROR(60000, 16, 1, 'Billing.DepositPendingCancel', @LocalError)` - wrapper for any DML failure.
- `RETURN 60000` on failure; `RETURN 0` (implicit) on success.

**Hardcoded status values**:
- `PaymentStatusID = 13` - Pending (source filter)
- `PaymentStatusID = 6` - Cancelled (target status)
- `PaymentActionStatusID = 3` - Closed
- `PaymentActionTypeID = 7` - Cancelled

---

## 8. Sample Queries

### 8.1 Cancel all pending CreditCard deposits from yesterday

```sql
EXEC [Billing].[DepositPendingCancel]
    @FundingTypeID = 1,   -- CreditCard
    @FromDate = DATEADD(d, -1, CAST(GETDATE() AS DATE)),
    @ToDate = CAST(GETDATE() AS DATE),
    @SessionID = NULL;
```

### 8.2 Preview deposits that would be cancelled (dry run check)

```sql
SELECT D.DepositID, D.CID, D.PaymentStatusID, D.PaymentDate, D.Amount, F.FundingTypeID
FROM [Billing].[Deposit] D WITH (NOLOCK)
JOIN [Billing].[Funding] F WITH (NOLOCK) ON D.FundingID = F.FundingID
WHERE D.PaymentStatusID = 13  -- Pending
  AND F.FundingTypeID = 1     -- CreditCard
  AND D.PaymentDate BETWEEN '2026-03-17' AND '2026-03-18';
```

### 8.3 Verify cancellation history for affected deposits

```sql
SELECT TOP 20 DepositActionID, DepositID, PaymentActionStatusID, PaymentActionTypeID,
    PaymentStatusID, ManagerID, ModificationDate, SessionID
FROM [History].[DepositAction] WITH (NOLOCK)
WHERE PaymentActionTypeID = 7    -- Cancelled
  AND PaymentStatusID = 6
  AND ModificationDate >= DATEADD(hh, -1, GETDATE())
ORDER BY DepositActionID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositPendingCancel | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositPendingCancel.sql*
