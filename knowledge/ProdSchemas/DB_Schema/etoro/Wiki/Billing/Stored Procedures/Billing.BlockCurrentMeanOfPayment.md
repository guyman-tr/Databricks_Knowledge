# Billing.BlockCurrentMeanOfPayment

> Blocks or unblocks a specific funding instrument for a specific customer by updating both the global Billing.Funding record and the per-customer Billing.CustomerToFunding record, with full audit trail written to History.ActiveCustomerToFunding.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN ERROR_NUMBER() (catch) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BlockCurrentMeanOfPayment` is an operations/compliance procedure used to block (or unblock) a specific payment instrument for a specific customer. It updates two tables in a single transaction: the global `Billing.Funding` record (shared across all customers who use the same instrument) and the per-customer `Billing.CustomerToFunding` record (the customer's individual link to the funding).

This procedure is called by compliance or risk staff when a specific customer's use of a particular payment method needs to be restricted - for example, when a card is associated with fraudulent activity originating from that specific customer. Unlike `Billing.BlockCardAdd` (which blocks the card globally by hash for all customers), this procedure allows per-customer blocking with a reason description and manager attribution.

The guard at the start ensures the funding was actually used in a deposit by this customer before any changes are made - preventing silent no-ops for funding IDs that were never deposited with. Two important exclusion rules apply: FundingTypeID=17 (a specific excluded payment type) and IsSingleFunding=1 methods are not affected.

---

## 2. Business Logic

### 2.1 Dual-Table Block with Guard

**What**: Atomically updates IsBlocked state on both the global Billing.Funding and the per-customer Billing.CustomerToFunding records.

**Columns/Parameters Involved**: `@FundingID`, `@IsBlocked`, `@ManagerID`, `@Description`, `@CID`

**Rules**:
- **Pre-condition**: If no row in `Billing.Deposit` has `FundingID = @FundingID`, RETURN 0 (no-op, no error). Only funds that were actually deposited with can be blocked.
- **Billing.Funding update**: Sets `IsBlocked`, `ManagerID`, `BlockedAt = GETUTCDATE()`, `BlockedDescription` WHERE `FundingTypeID <> 17 AND IsSingleFunding <> 1`.
- **Billing.CustomerToFunding update**: Same fields, same exclusions, AND `CID = @CID` (scoped to this customer). Uses OUTPUT clause to write DELETED rows into `History.ActiveCustomerToFunding` for audit.
- **FundingTypeID=17 exclusion**: A specific payment type (likely a system or internal transfer type) that is excluded from blocking operations.
- **IsSingleFunding exclusion**: Single-use payment methods (one-time instruments) cannot be blocked as they are not persistent.
- Both updates in one transaction; rolls back on error (@@Trancount logic in CATCH).

```
EXEC BlockCurrentMeanOfPayment @FundingID=X, @IsBlocked=1, @CID=Y
  Guard: Billing.Deposit exists for @FundingID? No -> RETURN 0 (no-op)
  BEGIN TRANSACTION
    UPDATE Billing.Funding SET IsBlocked, ManagerID, BlockedAt, BlockedDescription
      WHERE FundingID=@FundingID AND FundingTypeID<>17 AND IsSingleFunding<>1
    UPDATE Billing.CustomerToFunding OUTPUT INTO History.ActiveCustomerToFunding
      SET IsBlocked, ManagerID, BlockedAt, BlockedDescription
      WHERE FundingID=@FundingID AND CID=@CID AND FundingTypeID<>17 AND IsSingleFunding<>1
  COMMIT
```

### 2.2 Audit Trail

**What**: Every CustomerToFunding change is written to History via OUTPUT DELETED.

**Columns Written to History.ActiveCustomerToFunding**:
- CID, FundingID, Occurred, DepositTypeID, ReasonID, LastUsedDate, CustomerFundingStatusID
- IsBlocked, IsRefundExcluded, ManagerID, BlockedAt, BlockedDescription, IsVerified (added PAYIL-5743, Jan 2023)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INTEGER | NO | - | CODE-BACKED | The payment instrument to block/unblock. Must exist in Billing.Deposit for any action to occur. References Billing.Funding.FundingID. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | ID of the operations/compliance manager performing the block. Recorded in both Billing.Funding.ManagerID and Billing.CustomerToFunding.ManagerID for audit trail. |
| 3 | @IsBlocked | BIT | NO | - | CODE-BACKED | 1 = block the funding instrument (prevent deposits/refunds); 0 = unblock (re-enable). Applied to both Billing.Funding and Billing.CustomerToFunding for this customer. |
| 4 | @Description | VARCHAR | NO | - | CODE-BACKED | Free-text reason for the block/unblock action. Written to BlockedDescription in both Billing.Funding and Billing.CustomerToFunding. Unlimited length (no size declared in parameter). |
| 5 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Scopes the CustomerToFunding update to this specific customer only. The Billing.Funding update applies globally to the instrument regardless of this CID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.Deposit | Guard READ | Verifies the funding was actually used before making changes |
| @FundingID | Billing.Funding | MODIFIER | Updates IsBlocked, ManagerID, BlockedAt, BlockedDescription globally |
| @FundingID + @CID | Billing.CustomerToFunding | MODIFIER | Updates same fields per-customer with audit output |
| - | History.ActiveCustomerToFunding | Write (OUTPUT) | Receives deleted CustomerToFunding state for audit trail |
| Billing.Funding.FundingTypeID | Dictionary.FundingType | READ (JOIN) | Joins to check IsSingleFunding flag and exclude FundingTypeID=17 |

### 5.2 Referenced By (other objects point to this)

No callers found in the Billing schema SP files. Called from back-office or compliance tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BlockCurrentMeanOfPayment (procedure)
+-- Billing.Deposit (table)              [SELECT guard - must have deposit]
+-- Billing.Funding (table)              [UPDATE - global block state]
|   +-- Dictionary.FundingType (table)   [JOIN - IsSingleFunding check, exclude type 17]
+-- Billing.CustomerToFunding (table)    [UPDATE + OUTPUT - per-customer block]
+-- History.ActiveCustomerToFunding (table) [INSERT via OUTPUT clause - audit trail]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Guard SELECT - confirms funding was deposited with |
| Billing.Funding | Table | UPDATE - global block state for the instrument |
| Dictionary.FundingType | Table | JOIN on Billing.Funding - IsSingleFunding exclusion + type 17 exclusion |
| Billing.CustomerToFunding | Table | UPDATE + OUTPUT - per-customer block state |
| History.ActiveCustomerToFunding | Table | OUTPUT target for audit trail |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Partial @@TRANCOUNT logic in CATCH**: IF @@Trancount = 1 -> ROLLBACK; IF @@Trancount > 1 -> COMMIT. This handles nested transaction scenarios.
- **@Description VARCHAR (no length)**: The parameter is declared as `VARCHAR` without explicit length, which defaults to VARCHAR(1) in some SQL Server contexts for procedure parameters. This is a potential bug - descriptions may be silently truncated to 1 character.
- **PAYIL-5743 (Jan 2023)**: Added IsVerified column to the OUTPUT clause for History.ActiveCustomerToFunding.
- **FundingTypeID=17 exclusion**: Hardcoded type exclusion. No comment in code explaining why type 17 is special.
- **IsSingleFunding**: Sourced from Dictionary.FundingType.IsSingleFunding column - single-use payment methods cannot be blocked.

---

## 8. Sample Queries

### 8.1 Block a funding instrument for a specific customer
```sql
DECLARE @Result INT;
EXEC @Result = Billing.BlockCurrentMeanOfPayment
    @FundingID    = 590850,
    @ManagerID    = 12345,
    @IsBlocked    = 1,
    @Description  = 'Blocked per fraud investigation case 2026-001',
    @CID          = 98765;
SELECT @Result AS ReturnCode;  -- 0 = success
```

### 8.2 Verify block state after procedure call
```sql
SELECT
    f.FundingID,
    f.IsBlocked       AS FundingIsBlocked,
    f.ManagerID       AS FundingManagerID,
    f.BlockedAt,
    ctf.IsBlocked     AS CTFIsBlocked,
    ctf.CID
FROM  Billing.Funding f WITH (NOLOCK)
JOIN  Billing.CustomerToFunding ctf WITH (NOLOCK)
    ON f.FundingID = ctf.FundingID
WHERE f.FundingID = 590850 AND ctf.CID = 98765;
```

### 8.3 View audit history for a funding block
```sql
SELECT TOP 10
    CID, FundingID, IsBlocked, ManagerID, BlockedAt, BlockedDescription
FROM History.ActiveCustomerToFunding WITH (NOLOCK)
WHERE FundingID = 590850
ORDER BY BlockedAt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure. See also [Block Funding Api](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11578968620/Block+Funding+Api) (MG space, PAYIL-3790, Mar 2022) for the related `Billing.BlockFundingUpdate` API documentation.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 1 Confluence (context only) + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.BlockCurrentMeanOfPayment | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BlockCurrentMeanOfPayment.sql*
