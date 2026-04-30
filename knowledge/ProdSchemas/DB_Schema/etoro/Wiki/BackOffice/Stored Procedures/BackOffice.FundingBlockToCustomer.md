# BackOffice.FundingBlockToCustomer

> Blocks or unblocks a single customer's specific funding method link, capturing the pre-update state to History.ActiveCustomerToFunding via OUTPUT clause.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID + @CID - the customer-funding link to block/unblock |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.FundingBlockToCustomer is the single-customer variant of `BackOffice.FundingBlock`. While FundingBlock operates on ALL customers associated with a funding method, this procedure targets exactly one customer's link to a specific funding method. It is used when one particular customer must be blocked from a payment method due to individual fraud, compliance, or risk concerns, without affecting other customers using the same funding method.

Like FundingBlock, it captures the pre-update `Billing.CustomerToFunding` state to `History.ActiveCustomerToFunding` via OUTPUT clause, maintaining a full audit trail.

Unlike FundingBlock, this procedure:
- Has no FundingID=1 guard
- Has no transaction wrapping (no BEGIN/COMMIT)
- Raises an error if 0 rows are updated (the customer-funding link must exist)

---

## 2. Business Logic

### 2.1 Block Customer-Funding Link with History

**What**: Targets exactly one row in Billing.CustomerToFunding and captures its pre-update state.

**Columns/Parameters Involved**: `@FundingID`, `@CID`, `@IsBlocked`, `@ManagerID`, `@Description`, `Billing.CustomerToFunding`, `History.ActiveCustomerToFunding`

**Rules**:
- SET @Now = GETDATE().
- UPDATE Billing.CustomerToFunding SET IsBlocked=@IsBlocked, ManagerID=@ManagerID, BlockedAt=@Now, BlockedDescription=@Description OUTPUT DELETED.CID, DELETED.FundingID, DELETED.Occurred, DELETED.DepositTypeID, DELETED.ReasonID, DELETED.LastUsedDate, DELETED.CustomerFundingStatusID, DELETED.IsBlocked, DELETED.IsRefundExcluded, DELETED.ManagerID, DELETED.BlockedAt, DELETED.BlockedDescription INTO History.ActiveCustomerToFunding (...) WHERE FundingID = @FundingID AND CID = @CID.
- OUTPUT DELETED captures the PRIOR state of the row into History.ActiveCustomerToFunding within the same statement.

### 2.2 Row Count + Error Validation

**What**: Validates that exactly the target row was updated.

**Columns/Parameters Involved**: `@LocalError`, `@LocalRowCount`

**Rules**:
- SELECT @LocalError = @@ERROR, @LocalRowCount = @@ROWCOUNT.
- IF (@LocalError != 0) OR (@LocalRowCount = 0): RAISERROR(60000, 16, 1, 'BackOffice.FundingBlockToCustomer', @LocalError) + RETURN 60000.
- @@ROWCOUNT = 0 means the customer-funding link does not exist (invalid @FundingID + @CID combination). This raises an error - unlike FundingBlock's cascade which allows zero-customer results.
- RETURN 0 on success.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INTEGER | NO | - | CODE-BACKED | The payment funding method. Part of the composite WHERE key. FK to Billing.Funding.FundingID. No FundingID=1 guard (unlike FundingBlock). |
| 2 | @CID | INTEGER | NO | - | CODE-BACKED | The customer whose link to this funding is being blocked. Part of the composite WHERE key. FK to Billing.CustomerToFunding.CID. |
| 3 | @ManagerID | INTEGER | NO | - | CODE-BACKED | BackOffice agent performing the action. Written to Billing.CustomerToFunding.ManagerID. FK to BackOffice.Manager. |
| 4 | @IsBlocked | BIT | NO | - | CODE-BACKED | Block state: 1 = block this customer's access to the funding, 0 = unblock. Written to Billing.CustomerToFunding.IsBlocked. |
| 5 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Reason for the block/unblock. Written to Billing.CustomerToFunding.BlockedDescription. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID + @CID | Billing.CustomerToFunding | Modifier | UPDATE IsBlocked, ManagerID, BlockedAt, BlockedDescription WHERE FundingID AND CID. Must match 1 row or error. |
| OUTPUT DELETED | History.ActiveCustomerToFunding | Writer | INSERT pre-update state of the CustomerToFunding row atomically via OUTPUT clause. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice payments management | EXEC | Caller | Called when blocking a specific customer from a specific funding method. No SQL-layer callers found. |
| BackOffice.FundingBlock | Related | Parallel | System-wide block variant; this procedure is the per-customer variant. Both write to History.ActiveCustomerToFunding. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.FundingBlockToCustomer (procedure)
├── Billing.CustomerToFunding (table) - UPDATE block state + OUTPUT to history
└── History.ActiveCustomerToFunding (table) - INSERT via OUTPUT DELETED
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | UPDATE block fields WHERE FundingID AND CID; OUTPUT DELETED into history; @@ROWCOUNT checked |
| History.ActiveCustomerToFunding | Table | INSERT via OUTPUT - pre-update state of the targeted CustomerToFunding row |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice payments tooling | External | EXEC - block individual customer from funding |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No FundingID=1 guard | Risk | Unlike FundingBlock, there is no protection against blocking a customer on FundingID=1. Individual customer blocks on system funding are allowed. |
| @@ROWCOUNT=0 is an error | Behavior | Zero rows updated means the customer-funding link does not exist. RAISERROR(60000) + RETURN 60000. Callers should pre-validate the link exists. |
| No transaction wrapping | Convention | No explicit BEGIN/COMMIT. Single UPDATE statement with no transaction boundary. If OUTPUT fails mid-write, behavior is undefined. |
| OUTPUT DELETED audit | Safety | Pre-update state is captured atomically within the UPDATE statement into History.ActiveCustomerToFunding. |
| @Now shared timestamp | Consistency | BlockedAt is set to @Now = GETDATE() at procedure start, ensuring a consistent timestamp. |

---

## 8. Sample Queries

### 8.1 Block a specific customer from a funding method
```sql
EXEC BackOffice.FundingBlockToCustomer
    @FundingID = 12345,
    @CID = 67890,
    @ManagerID = 42,
    @IsBlocked = 1,
    @Description = 'Chargeback detected - individual block applied'
```

### 8.2 Unblock a specific customer
```sql
EXEC BackOffice.FundingBlockToCustomer
    @FundingID = 12345,
    @CID = 67890,
    @ManagerID = 42,
    @IsBlocked = 0,
    @Description = 'Chargeback resolved - block lifted'
```

### 8.3 Check if a customer-funding link exists before calling
```sql
SELECT FundingID, CID, IsBlocked, BlockedAt, BlockedDescription
FROM Billing.CustomerToFunding WITH (NOLOCK)
WHERE FundingID = 12345 AND CID = 67890
```

### 8.4 View audit history for a specific customer-funding block
```sql
SELECT CID, FundingID, IsBlocked, BlockedAt, ManagerID, BlockedDescription
FROM History.ActiveCustomerToFunding WITH (NOLOCK)
WHERE FundingID = 12345 AND CID = 67890
ORDER BY BlockedAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.FundingBlockToCustomer | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.FundingBlockToCustomer.sql*
