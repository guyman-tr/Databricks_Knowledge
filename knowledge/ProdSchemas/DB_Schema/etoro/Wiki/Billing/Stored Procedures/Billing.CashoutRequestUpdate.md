# Billing.CashoutRequestUpdate

> Advances a pending withdrawal request to InProcess status (CashoutStatusID 1 -> 2), validating it is still pending before delegating the UPSERT and audit logging to `Billing.UpsertWithdraw`.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CashoutID (WithdrawID in Billing.Withdraw) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CashoutRequestUpdate` is the status-transition procedure that moves a withdrawal request from Pending (CashoutStatusID=1) to InProcess (CashoutStatusID=2). It is called when the payment operations system or BackOffice accepts a pending withdrawal for active processing - the moment the system commits to fulfilling the request and begins the payout sequence.

The procedure exists to enforce the Pending->InProcess transition rule with a pre-check. It guards against double-processing or processing an already-cancelled/completed request by verifying `CashoutStatusID=1` before any update. If the check fails, error 60012 is raised.

Note: despite its name including "Cashout", this procedure operates entirely on `Billing.Withdraw` (the modern withdrawal table), not `Billing.Cashout` (the legacy table). The "Cashout" naming is historical. The original implementation (visible in commented-out code) used a direct `UPDATE Billing.Withdraw` with its own `INSERT History.WithdrawAction` - this was refactored by Shay Oren (23/09/2021, DBA-648) to use `Billing.UpsertWithdraw` for centralized history logging and consistency.

Data flow: caller passes `@CashoutID` (=WithdrawID). Procedure checks pending status, builds a `[Billing].[TBL_Withdraw]` TVP with only the transition fields populated, then calls `Billing.UpsertWithdraw` which performs the partial UPDATE on `Billing.Withdraw` and logs to `History.WithdrawAction`.

---

## 2. Business Logic

### 2.1 Pending-Only Transition Guard (Error 60012)

**What**: The procedure validates that the withdrawal is in Pending status before proceeding. This prevents re-processing an already InProcess, Processed, or Cancelled withdrawal.

**Parameters Involved**: `@CashoutID`, `Billing.Withdraw.CashoutStatusID`

**Rules**:
- Queries: `SELECT * FROM Billing.Withdraw WHERE WithdrawID = @CashoutID AND CashoutStatusID = 1`
- If NOT EXISTS: `RAISERROR(60012, 16, 1, @CashoutID)` and `RETURN 60012`
- Error 60012 = "Withdrawal is not in Pending status" (cannot advance a non-pending withdrawal to InProcess)
- If EXISTS: proceeds with the status transition

**Diagram**:
```
Input: @CashoutID

CHECK: Billing.Withdraw WHERE WithdrawID=@CashoutID AND CashoutStatusID=1
  NOT FOUND -> RAISERROR(60012) -> RETURN 60012 (abort)
  FOUND -> proceed to status transition

STATUS TRANSITION:
  CashoutStatusID: 1 (Pending) -> 2 (InProcess)
  ModificationDate: GETDATE()
  Remark: @Remark (if @OverrideRemark=1) or preserved (if @OverrideRemark=0)
  WithrawActionManagerID: 0 (system-initiated, no specific manager)
  Comment: @Remark (always set in history)
```

### 2.2 Conditional Remark Override

**What**: The `@OverrideRemark` flag controls whether the caller's remark text replaces the existing Remark on the Withdraw record.

**Parameters Involved**: `@Remark`, `@OverrideRemark`

**Rules**:
- `@OverrideRemark = 1` (default): `Remark = @Remark` in `Billing.Withdraw` (existing remark replaced)
- `@OverrideRemark = 0`: `Remark = NULL` passed to UpsertWithdraw, which via ISNULL logic preserves the existing remark in the DB
- `Comment = @Remark` is always written to `History.WithdrawAction` regardless of `@OverrideRemark` - history always records the remark

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CashoutID | INTEGER | NO | - | CODE-BACKED | WithdrawID of the withdrawal request to advance. Must be a `Billing.Withdraw` row with `CashoutStatusID=1` (Pending); otherwise error 60012 is raised. Named "CashoutID" for historical reasons - maps to `Billing.Withdraw.WithdrawID`. |
| 2 | @Remark | VARCHAR(250) | YES | NULL | CODE-BACKED | Processing remark text. Written to `Billing.Withdraw.Remark` if `@OverrideRemark=1` (replaces existing). Always written to `History.WithdrawAction.Comment` as an audit note. NULL = no remark provided. |
| 3 | @OverrideRemark | BIT | YES | 1 | CODE-BACKED | Controls whether `@Remark` replaces the existing `Billing.Withdraw.Remark`: 1=override (replace existing remark with @Remark), 0=preserve (keep existing remark in Withdraw row, only log @Remark in history). DEFAULT=1 means override by default. |
| 4 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Session identifier linking this status transition to a specific user or system session. Written to `Billing.Withdraw.SessionID`. NULL = no session context (system-initiated transitions). Added 20/10/2015 by Eitan. |

**Return values**:
- `RETURN 0` on success
- `RETURN 60012` if withdrawal not found or not in Pending status
- `RETURN 60000` on SQL execution error (via RAISERROR(60000,...))

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CashoutID | Billing.Withdraw | Read + Write (via UpsertWithdraw) | Validates pending status, then updates CashoutStatusID to 2 |
| (delegates to) | Billing.UpsertWithdraw | EXEC | Performs the actual partial UPDATE on Billing.Withdraw and logs History.WithdrawAction |
| (implicit) | Billing.TBL_Withdraw | TVP | Local @Info variable used to stage the update fields |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment processing workflows | @CashoutID | Caller | Called when the system accepts a pending withdrawal for payment processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CashoutRequestUpdate (procedure)
+-- Billing.Withdraw (table) [validation SELECT + UPDATE target via UpsertWithdraw]
+-- Billing.UpsertWithdraw (procedure) [delegates UPSERT and audit logging]
      +-- Billing.Withdraw (table) [MERGE target]
      +-- History.WithdrawAction (table) [audit INSERT]
      +-- Billing.TBL_Withdraw (type) [TVP input]
      +-- History.TBL_WithdrawAction (type) [internal OUTPUT capture]
+-- Billing.TBL_Withdraw (type) [local @Info TVP declaration]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Validates CashoutStatusID=1 before update |
| Billing.UpsertWithdraw | Stored Procedure | Delegates partial UPDATE + audit logging |
| Billing.TBL_Withdraw | User Defined Type | Local @Info table variable for staging update fields |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment processing services | External | Called to advance withdrawals from Pending to InProcess |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Notable behavior**: Uses a manual `BEGIN TRANSACTION / COMMIT TRANSACTION` wrapper (old-style). If `@@ERROR != 0` after `UpsertWithdraw`, it performs `ROLLBACK TRANSACTION` and raises error 60000. This is a pre-DBA-648 pattern (the TRAN was part of the original design before UpsertWithdraw was introduced). `SET NOCOUNT ON` suppresses row-count messages.

---

## 8. Sample Queries

### 8.1 Execute the status transition for a pending withdrawal

```sql
DECLARE @Result INT
EXEC @Result = Billing.CashoutRequestUpdate
    @CashoutID = 12345,
    @Remark = 'Processing initiated by workflow engine',
    @OverrideRemark = 1,
    @SessionID = NULL

SELECT @Result AS ReturnCode
-- 0 = success; 60012 = not pending; 60000 = SQL error
```

### 8.2 Check the audit trail after the transition

```sql
SELECT
    ha.WithdrawID,
    ha.CashoutStatusID,
    ha.ManagerID,
    ha.Comment,
    ha.ModificationDate,
    ha.SessionID
FROM History.WithdrawAction ha WITH (NOLOCK)
WHERE ha.WithdrawID = 12345
ORDER BY ha.ModificationDate DESC
```

### 8.3 Find withdrawals eligible for CashoutRequestUpdate

```sql
SELECT TOP 20
    w.WithdrawID,
    w.CID,
    w.FundingTypeID,
    w.Amount,
    w.RequestDate,
    w.ModificationDate
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.CashoutStatusID = 1  -- Pending
ORDER BY w.RequestDate ASC
-- These are valid inputs for @CashoutID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 (UpsertWithdraw) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CashoutRequestUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CashoutRequestUpdate.sql*
