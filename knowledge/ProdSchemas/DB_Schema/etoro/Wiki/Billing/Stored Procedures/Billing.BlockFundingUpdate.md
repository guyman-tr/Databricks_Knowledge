# Billing.BlockFundingUpdate

> Updates the deposit-block and withdraw-exclusion flags on a specific customer-funding link in Billing.CustomerToFunding, with audit trail written to History.ActiveCustomerToFunding. Called via the Funding Service's PUT /api/v2/funding/block endpoint.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No explicit RETURN (falls through with @@ERROR or 0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BlockFundingUpdate` sets or clears the deposit-block (`IsBlocked`) and refund-exclusion (`IsRefundExcluded`) flags on a single customer-funding link, identified by the combination of @CID + @FundingID. Unlike `Billing.BlockCurrentMeanOfPayment` (which also updates Billing.Funding globally and requires a prior deposit), this procedure operates exclusively on `Billing.CustomerToFunding` and requires no pre-conditions.

This procedure is the database back-end for the Funding Service's blocking API endpoint: `PUT /api/v2/funding/block` (PAYIL-3790, Feb-Mar 2022). The Funding Service passes `BlockDeposit -> @BlockDeposit -> IsBlocked` and `BlockWithdraw -> @BlockWithdraw -> IsRefundExcluded`. Either or both can be null (ISNULL pattern preserves existing value).

A full audit trail is written to `History.ActiveCustomerToFunding` via the OUTPUT clause, including the new `IsVerified` and `BlockManagerID` columns added in PAYIL-5743 (Jan 2023).

---

## 2. Business Logic

### 2.1 Selective Field Update (ISNULL Pattern)

**What**: Updates only the fields provided by the caller - null parameters leave existing values unchanged.

**Columns/Parameters Involved**: `@BlockDeposit -> IsBlocked`, `@BlockWithdraw -> IsRefundExcluded`, `@ManagerID`, `@BlockedDescription`, `@BlockManagerID`

**Rules**:
- `IsRefundExcluded = ISNULL(@BlockWithdraw, IsRefundExcluded)` - if @BlockWithdraw is NULL, the existing value is preserved.
- `IsBlocked = ISNULL(@BlockDeposit, IsBlocked)` - same pattern for deposit blocking.
- `ManagerID = ISNULL(@ManagerID, ManagerID)` - manager ID only updated if provided.
- `BlockedDescription = ISNULL(@BlockedDescription, BlockedDescription)` - description only updated if provided.
- `BlockedAt = GETUTCDATE()` - always updated when any change occurs.
- `BlockManagerID = @BlockManagerID` - always set (even to NULL).
- WHERE: `CID = @CID AND FundingID = @FundingID` - must match exactly.

```
BlockFundingRequest (app layer):
  FundingId -> @FundingID
  CId       -> @CID
  BlockDeposit  -> @BlockDeposit -> IsBlocked
  BlockWithdraw -> @BlockWithdraw -> IsRefundExcluded
  ManagerId -> @ManagerID
  BlockDescription -> @BlockedDescription (truncated to 255 chars by app layer)
```

### 2.2 Audit Trail

**What**: The DELETED state (before-image) is written to History.ActiveCustomerToFunding.

**Columns captured**:
- CID, FundingID, Occurred, DepositTypeID, ReasonID, LastUsedDate, CustomerFundingStatusID
- IsBlocked, IsRefundExcluded, ManagerID, BlockedAt, BlockedDescription
- IsVerified (added PAYIL-5743 Jan 2023), BlockManagerID (added PAYIL-5743)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Combined with @FundingID to identify the exact CustomerToFunding row to update. Must match Billing.CustomerToFunding.CID. |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | Payment instrument ID. Combined with @CID to identify the exact CustomerToFunding row. References Billing.Funding.FundingID. |
| 3 | @BlockDeposit | BIT | YES | NULL | VERIFIED | 1 = block this customer from depositing with this funding instrument (sets IsBlocked=1). 0 = unblock. NULL = preserve existing IsBlocked value (no change). Maps to Billing.CustomerToFunding.IsBlocked. (Source: PAYIL-3790 Confluence, eToro.Payments.Dto.Funding) |
| 4 | @BlockWithdraw | BIT | YES | NULL | VERIFIED | 1 = exclude this funding from use as a refund/withdrawal destination (sets IsRefundExcluded=1). 0 = re-enable. NULL = preserve existing IsRefundExcluded value. Maps to Billing.CustomerToFunding.IsRefundExcluded. (Source: PAYIL-3790 Confluence) |
| 5 | @ManagerID | INT | YES | NULL | CODE-BACKED | ID of the manager authorizing the block. Written to Billing.CustomerToFunding.ManagerID. NULL preserves existing value. |
| 6 | @BlockedDescription | VARCHAR(255) | YES | NULL | CODE-BACKED | Reason description for the block action. Max 255 characters (enforced by app layer via truncation). NULL preserves existing value. Written to Billing.CustomerToFunding.BlockedDescription. |
| 7 | @BlockManagerID | INT | YES | NULL | CODE-BACKED | Added in PAYIL-5743. Alternative manager ID field for audit. Always set (including to NULL) without ISNULL preservation. Written to Billing.CustomerToFunding.BlockManagerID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID | Billing.CustomerToFunding | MODIFIER | Updates block flags and audit fields for this customer-funding link |
| - | History.ActiveCustomerToFunding | Write (OUTPUT) | Receives DELETED (before-image) state for audit trail |

### 5.2 Referenced By (other objects point to this)

No callers found in Billing schema SP files. Called from the Funding Service via `PUT /api/v2/funding/block`.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BlockFundingUpdate (procedure)
+-- Billing.CustomerToFunding (table)       [UPDATE + OUTPUT - per-customer block flags]
+-- History.ActiveCustomerToFunding (table) [INSERT via OUTPUT - audit trail]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | UPDATE target - sets IsBlocked, IsRefundExcluded, ManagerID, BlockedDescription, BlockManagerID, BlockedAt |
| History.ActiveCustomerToFunding | Table | OUTPUT INTO target - receives before-image for audit |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files. Callers: Funding Service (external application).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **No TRY-CATCH**: No explicit error handling. If the UPDATE fails, the error propagates to the caller.
- **No RETURN statement**: The procedure falls through with no explicit RETURN. Return code is 0 (SQL Server default).
- **Always updates BlockedAt**: `BlockedAt = GETUTCDATE()` is always set regardless of which fields changed. This can update BlockedAt even when only @BlockManagerID changed with other fields null.
- **No existence check**: If no row matches (CID, FundingID), the UPDATE silently affects 0 rows. No error is raised.
- **See also**: `Billing.BlockFundingUpdate_v2` - the successor version with @CID as optional alternative filter and a validation guard.
- **PAYIL-3790 (Feb-Mar 2022)**: Original creation and @ManagerID/@BlockedDescription addition (KateM + ElromB).
- **PAYIL-5743 (Jan 2023 - Shay Oren)**: Added IsVerified and BlockManagerID columns to OUTPUT clause.

---

## 8. Sample Queries

### 8.1 Block a customer from depositing with a specific funding
```sql
EXEC Billing.BlockFundingUpdate
    @CID                = 98765,
    @FundingID          = 590850,
    @BlockDeposit       = 1,
    @BlockWithdraw      = 1,
    @ManagerID          = 12345,
    @BlockedDescription = 'Blocked per risk review - case 2026-001',
    @BlockManagerID     = 12345;
```

### 8.2 Unblock deposit-only while keeping refund exclusion
```sql
EXEC Billing.BlockFundingUpdate
    @CID          = 98765,
    @FundingID    = 590850,
    @BlockDeposit = 0,
    @BlockWithdraw = NULL;  -- preserve IsRefundExcluded
```

### 8.3 Check current block status for a customer-funding pair
```sql
SELECT
    CID, FundingID,
    IsBlocked, IsRefundExcluded,
    ManagerID, BlockedAt, BlockedDescription, BlockManagerID
FROM Billing.CustomerToFunding WITH (NOLOCK)
WHERE CID = 98765 AND FundingID = 590850;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Block Funding Api](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11578968620/Block+Funding+Api) | Confluence (MG space, Mar 2022) | API endpoint PUT /api/v2/funding/block; DTO BlockFundingRequest (BlockWithdraw->IsRefundExcluded, BlockDeposit->IsBlocked); created for PAYIL-3790 by ElromB/KateM |

---

*Generated: 2026-03-17 | Quality: 9.3/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos (eToro.Payments.Funding repo referenced but not scanned) | Corrections: 0 applied*
*Object: Billing.BlockFundingUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BlockFundingUpdate.sql*
