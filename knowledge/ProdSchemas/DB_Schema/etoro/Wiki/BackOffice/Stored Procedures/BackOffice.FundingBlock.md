# BackOffice.FundingBlock

> Blocks or unblocks a payment funding method and all associated customer-funding links, cascading the block state with OUTPUT-captured history records. Guards against blocking the system's primary funding (FundingID=1).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID - the funding method to block/unblock |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.FundingBlock is the procedure for blocking (or unblocking) a payment funding method across the entire system. When a funding method is blocked, the procedure:
1. Updates the `Billing.Funding` record with the block state, manager, timestamp, and reason.
2. Cascades the block to ALL `Billing.CustomerToFunding` rows associated with that funding, capturing the pre-update state to `History.ActiveCustomerToFunding` via OUTPUT clause.

This is typically used for fraud mitigation, regulatory compliance, or when a payment provider is suspended. The related `BackOffice.FundingBlockToCustomer` is the single-customer variant.

A hard guard prevents blocking FundingID=1, which is the system's primary/default funding method. Blocking it would be catastrophic. This guard was added in February 2022 (PTL-67).

---

## 2. Business Logic

### 2.1 FundingID=1 Guard

**What**: Prevents accidental blocking of the system's primary funding method.

**Columns/Parameters Involved**: `@FundingID`

**Rules**:
- IF @FundingID = 1: RAISERROR('Billing.FundingBlock Trying to block FundingID Number 1', 16, 1) + RETURN 6000.
- This check runs BEFORE the transaction - no partial writes possible.
- Added 09/02/2022, Jira ticket PTL-67.

### 2.2 Block Billing.Funding Record

**What**: Updates the funding method's own block state.

**Columns/Parameters Involved**: `@FundingID`, `@IsBlocked`, `@ManagerID`, `@Description`, `Billing.Funding`

**Rules**:
- SET @Now = GETDATE().
- UPDATE Billing.Funding SET IsBlocked=@IsBlocked, ManagerID=@ManagerID, BlockedAt=@Now, BlockedDescription=@Description WHERE FundingID = @FundingID.
- Check @@ERROR and @@ROWCOUNT: if error OR zero rows updated (funding not found) -> RAISERROR(60000) + triggers CATCH.
- No rows updated = FundingID not found = bad input; the @@ROWCOUNT=0 check prevents silent no-ops.

### 2.3 Cascade Block to All Customer-Funding Links with History

**What**: Propagates the block state to every customer who uses this funding, with pre-change state captured to history.

**Columns/Parameters Involved**: `@FundingID`, `Billing.CustomerToFunding`, `History.ActiveCustomerToFunding`

**Rules**:
- UPDATE Billing.CustomerToFunding SET IsBlocked=@IsBlocked, ManagerID=@ManagerID, BlockedAt=@Now, BlockedDescription=@Description OUTPUT DELETED.* INTO History.ActiveCustomerToFunding WHERE FundingID = @FundingID.
- OUTPUT DELETED captures all pre-update column values into History.ActiveCustomerToFunding atomically.
- Captured columns: CID, FundingID, Occurred, DepositTypeID, ReasonID, LastUsedDate, CustomerFundingStatusID, IsBlocked, IsRefundExcluded, ManagerID, BlockedAt, BlockedDescription.
- @@ERROR check: if error -> RAISERROR(60000) + CATCH. No @@ROWCOUNT check here - zero matching customers is valid (funding exists but no customers have used it).
- COMMIT on success.

**Diagram**:
```
IF @FundingID = 1 -> RAISERROR + RETURN 6000

BEGIN TRY / BEGIN TRANSACTION
  UPDATE Billing.Funding (block fields) WHERE FundingID
    IF error OR 0 rows -> RAISERROR(60000)
  ELSE
    UPDATE Billing.CustomerToFunding (block fields)
    OUTPUT DELETED.* INTO History.ActiveCustomerToFunding
    WHERE FundingID
      IF error -> RAISERROR(60000)
COMMIT
END TRY
BEGIN CATCH -> ROLLBACK/COMMIT + THROW
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INTEGER | NO | - | CODE-BACKED | The payment funding method to block or unblock. FK to Billing.Funding.FundingID. Value 1 is forbidden (guard raises error). |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | BackOffice agent performing the action. Written to Billing.Funding.ManagerID and Billing.CustomerToFunding.ManagerID for all affected rows. FK to BackOffice.Manager. |
| 3 | @IsBlocked | BIT | NO | - | CODE-BACKED | Block state: 1 = block this funding method, 0 = unblock. Written to Billing.Funding.IsBlocked and Billing.CustomerToFunding.IsBlocked for all associated customers. |
| 4 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Reason for the block/unblock. Written to Billing.Funding.BlockedDescription and Billing.CustomerToFunding.BlockedDescription for all associated customers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.Funding | Modifier | UPDATE IsBlocked, ManagerID, BlockedAt, BlockedDescription WHERE FundingID. |
| @FundingID | Billing.CustomerToFunding | Modifier | Cascade UPDATE - block all customer-funding links for this funding method. OUTPUT DELETED into History. |
| @FundingID | History.ActiveCustomerToFunding | Writer | INSERT via OUTPUT DELETED - captures pre-update CustomerToFunding state for audit. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice payments management | EXEC | Caller | Called when blocking/unblocking a payment method system-wide. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.FundingBlock (procedure)
├── Billing.Funding (table) - UPDATE block state
├── Billing.CustomerToFunding (table) - CASCADE UPDATE + OUTPUT to history
└── History.ActiveCustomerToFunding (table) - INSERT via OUTPUT DELETED
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | UPDATE IsBlocked/ManagerID/BlockedAt/BlockedDescription WHERE FundingID; @@ROWCOUNT check for existence |
| Billing.CustomerToFunding | Table | Cascade UPDATE same block fields for all rows with matching FundingID; OUTPUT DELETED into history |
| History.ActiveCustomerToFunding | Table | INSERT via OUTPUT - pre-update state of all affected CustomerToFunding rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice payments tooling | External | EXEC - block/unblock funding method |
| BackOffice.FundingBlockToCustomer | Related | Single-customer variant using same history table |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FundingID=1 guard | Safety | Hard-coded protection for system primary funding. RAISERROR + RETURN 6000 before any transaction. Added PTL-67 (2022). |
| Billing.Funding @@ROWCOUNT check | Safety | If 0 rows updated (FundingID not found), RAISERROR(60000). Prevents silent no-op on invalid FundingID. |
| CustomerToFunding no @@ROWCOUNT check | Behavior | Zero customers using this funding is valid - UPDATE can affect 0 rows without error. |
| OUTPUT DELETED into History | Audit | Entire pre-update state of CustomerToFunding rows is atomically captured to History.ActiveCustomerToFunding within the same transaction. |
| @Now = GETDATE() shared | Consistency | Funding.BlockedAt and CustomerToFunding.BlockedAt are set to the same @Now timestamp - ensures consistent audit trail. |
| TRY/CATCH with nested-transaction pattern | Convention | @@TRANCOUNT=1 -> ROLLBACK; >1 -> COMMIT; THROW to re-raise. |
| RAISERROR(60000) inside TRY | Pattern | @@ERROR-style error number raised inside TRY - triggers CATCH for ROLLBACK. Same error code for both failure modes. |

---

## 8. Sample Queries

### 8.1 Block a funding method
```sql
EXEC BackOffice.FundingBlock
    @FundingID = 12345,
    @ManagerID = 42,
    @IsBlocked = 1,
    @Description = 'Fraud detected - all transactions suspended pending investigation'
```

### 8.2 Unblock a funding method
```sql
EXEC BackOffice.FundingBlock
    @FundingID = 12345,
    @ManagerID = 42,
    @IsBlocked = 0,
    @Description = 'Investigation complete - funding cleared'
```

### 8.3 Check how many customers are affected before blocking
```sql
SELECT COUNT(*) AS AffectedCustomers
FROM Billing.CustomerToFunding WITH (NOLOCK)
WHERE FundingID = 12345
AND IsBlocked = 0  -- currently active
```

### 8.4 View audit history for a funding method block
```sql
SELECT CID, FundingID, IsBlocked, BlockedAt, ManagerID, BlockedDescription
FROM History.ActiveCustomerToFunding WITH (NOLOCK)
WHERE FundingID = 12345
ORDER BY BlockedAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Jira ticket PTL-67 (2022) added the FundingID=1 guard.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.FundingBlock | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.FundingBlock.sql*
