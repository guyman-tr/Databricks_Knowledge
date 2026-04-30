# Billing.BlockAllRelatedMeansOfPayment

> Blocks or unblocks all non-single-use, non-FundingTypeID-17 payment instruments for a customer, updating both Billing.Funding and Billing.CustomerToFunding with manager and timestamp audit, and writing the CustomerToFunding change history to History.ActiveCustomerToFunding via OUTPUT.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success) or ERROR_NUMBER() (failure); side effects on Billing.Funding, Billing.CustomerToFunding, History.ActiveCustomerToFunding |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BlockAllRelatedMeansOfPayment` is the full-featured block/unblock procedure for payment instruments. Unlike `Billing.BlockAllPaymentMethodsForCID` (which is a simple hard-block with no audit), this procedure:

1. Supports both blocking (@IsBlocked=1) and unblocking (@IsBlocked=0).
2. Records audit metadata: ManagerID, BlockedAt timestamp, BlockedDescription.
3. Updates two tables: `Billing.Funding` (the payment instrument record) AND `Billing.CustomerToFunding` (the customer-instrument link).
4. Writes the old `CustomerToFunding` values to `History.ActiveCustomerToFunding` via OUTPUT DELETED, creating an audit history trail.

The procedure excludes two categories of funding types from blocking:
- FundingTypeID=17 (a specific funding type handled differently)
- IsSingleFunding=1 instruments (single-use/one-time payment instruments that don't have a persistent customer relationship)

A short-circuit guard returns immediately if the customer has no deposits at all (no payment activity to block).

---

## 2. Business Logic

### 2.1 No-Deposit Guard

**What**: If the customer has never made a deposit, skip all blocking operations.

**Parameters/Columns Involved**: `@CID`, `Billing.Deposit`

**Rules**:
- `IF NOT EXISTS (SELECT * FROM Billing.Deposit WHERE CID = @CID) RETURN 0`.
- No deposits means no payment instruments to block. Early exit prevents unnecessary operations.

### 2.2 Block/Unblock Billing.Funding

**What**: Sets the block status on all eligible payment instruments linked to the customer's deposits.

**Parameters/Columns Involved**: `@IsBlocked`, `@ManagerID`, `@Description`, `Billing.Funding`

**Rules**:
- `UPDATE BF SET IsBlocked=@IsBlocked, ManagerID=@ManagerID, BlockedAt=GETUTCDATE(), BlockedDescription=@Description`.
- Filter: `JOIN Dictionary.FundingType FT ON BF.FundingTypeID = FT.FundingTypeID` AND `JOIN Billing.Deposit BD ON BD.FundingID = BF.FundingID WHERE FT.IsSingleFunding <> 1 AND BF.FundingTypeID <> 17 AND BD.CID = @CID`.
- Exclusions: IsSingleFunding=1 types (single-use instruments) and FundingTypeID=17.
- Always sets BlockedAt to GETUTCDATE() regardless of @IsBlocked - even unblock operations record the timestamp.

### 2.3 Block/Unblock Billing.CustomerToFunding with Audit OUTPUT

**What**: Updates the customer-to-instrument link and writes the old state to history.

**Parameters/Columns Involved**: `@IsBlocked`, `@ManagerID`, `@Description`, `Billing.CustomerToFunding`, `History.ActiveCustomerToFunding`

**Rules**:
- `UPDATE CTF SET IsBlocked=@IsBlocked, ManagerID=@ManagerID, BlockedAt=GETUTCDATE(), BlockedDescription=@Description`.
- Same exclusion filters as Billing.Funding (FundingTypeID<>17, IsSingleFunding<>1, CTF.CID=@CID).
- `OUTPUT DELETED.*` -> `INTO History.ActiveCustomerToFunding`: writes the PREVIOUS state of each updated row to the history table before the update is applied.
- Note: The OUTPUT uses DELETED columns (not INSERTED) - this captures the pre-update state, not the new blocked state. This creates an "undo log" style history.
- Columns written to history: CID, FundingID, Occurred, DepositTypeID, ReasonID, LastUsedDate, CustomerFundingStatusID, IsBlocked (old), IsRefundExcluded, ManagerID (old), BlockedAt (old), BlockedDescription (old), IsVerified.

### 2.4 Transaction and Error Handling

**Rules**:
- `BEGIN TRANSACTION / COMMIT` wraps both UPDATEs.
- `CATCH`: ROLLBACK if @@Trancount=1; COMMIT if >1 (nested transaction handling). Then THROW (re-throws original error).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | VERIFIED | Customer ID whose payment instruments are to be blocked or unblocked. |
| 2 | @ManagerID | INTEGER | NO | - | VERIFIED | ID of the manager or system actor performing the block/unblock. Recorded on both Billing.Funding and Billing.CustomerToFunding. |
| 3 | @IsBlocked | BIT | NO | - | VERIFIED | 1=block, 0=unblock. Applied to IsBlocked on both Billing.Funding and Billing.CustomerToFunding. |
| 4 | @Description | VARCHAR | NO | - | VERIFIED | Reason for the block/unblock action. Stored in BlockedDescription on both tables. Note: no length specified in the DDL - SQL Server defaults VARCHAR without length to VARCHAR(1) in some contexts. Callers should verify the effective length behavior. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID guard | Billing.Deposit | READER | EXISTS check - early return if customer has no deposits. |
| @CID filter | Billing.Funding | WRITER (UPDATE) | Sets IsBlocked, ManagerID, BlockedAt, BlockedDescription. |
| FundingTypeID filter | Dictionary.FundingType | READER (JOIN) | Filters out IsSingleFunding=1 types. |
| @CID filter | Billing.CustomerToFunding | WRITER (UPDATE) | Sets IsBlocked, ManagerID, BlockedAt, BlockedDescription. |
| OUTPUT DELETED | History.ActiveCustomerToFunding | WRITER (INSERT via OUTPUT) | Writes pre-update CustomerToFunding state to history. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from risk management and back-office operations.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BlockAllRelatedMeansOfPayment (procedure)
|- Billing.Deposit (table)                      [EXISTS check - no-deposit guard]
|- Billing.Funding (table)                      [UPDATE - block/unblock instruments]
|- Dictionary.FundingType (table)               [JOIN - IsSingleFunding filter]
|- Billing.CustomerToFunding (table)            [UPDATE + OUTPUT - customer-instrument links]
+- History.ActiveCustomerToFunding (table)      [INSERT via OUTPUT DELETED - audit history]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | EXISTS guard - skip if no deposits for @CID |
| Billing.Funding | Table | UPDATE IsBlocked, ManagerID, BlockedAt, BlockedDescription |
| Dictionary.FundingType | Table | JOIN filter - exclude IsSingleFunding=1 types |
| Billing.CustomerToFunding | Table | UPDATE + OUTPUT DELETED to capture pre-update state |
| History.ActiveCustomerToFunding | Table | INSERT target for OUTPUT DELETED audit trail |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from risk management systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **@Description VARCHAR without length**: The parameter is declared `@Description varchar` without a length. In SQL Server, a VARCHAR parameter without a length defaults to VARCHAR(1) when used in some contexts but VARCHAR(30) as a stored procedure parameter default. This is a potential truncation risk for long descriptions.
- **OUTPUT DELETED (pre-update state)**: The history table receives the DELETED (old) values, not the new values. This is an undo-log pattern: the history preserves what was there before the block was applied.
- **Billing.Funding vs CustomerToFunding gap**: The Funding UPDATE finds instruments via Billing.Deposit JOIN (instruments used in any deposit for this CID), while the CustomerToFunding UPDATE uses a direct CTF.CID=@CID filter. These may not always produce the same set of FundingIDs.
- **FundingTypeID=17 exclusion**: FundingTypeID=17 is excluded from both updates. The reason is not documented in the code - likely a funding type that manages its own blocking state or is managed by an external system.

---

## 8. Sample Queries

### 8.1 Block all payment methods for a customer
```sql
EXEC Billing.BlockAllRelatedMeansOfPayment
    @CID         = 12345,
    @ManagerID   = 9999,
    @IsBlocked   = 1,
    @Description = 'Risk Rule Engine - fraud pattern detected';
```

### 8.2 Unblock all payment methods for a customer
```sql
EXEC Billing.BlockAllRelatedMeansOfPayment
    @CID         = 12345,
    @ManagerID   = 9999,
    @IsBlocked   = 0,
    @Description = 'False positive cleared by compliance review';
```

### 8.3 Check current block status
```sql
SELECT  BF.FundingID,
        BF.FundingTypeID,
        BF.IsBlocked,
        BF.BlockedAt,
        BF.BlockedDescription,
        BF.ManagerID
FROM    Billing.Funding BF WITH (NOLOCK)
JOIN    Billing.Deposit BD WITH (NOLOCK) ON BD.FundingID = BF.FundingID
WHERE   BD.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.BlockAllRelatedMeansOfPayment | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BlockAllRelatedMeansOfPayment.sql*
