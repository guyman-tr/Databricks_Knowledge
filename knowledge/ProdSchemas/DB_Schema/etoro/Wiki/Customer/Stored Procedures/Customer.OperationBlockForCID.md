# Customer.OperationBlockForCID

> Inserts a row into Customer.BlockedCustomerOperations to block a specific operation type for a customer, with an optional block reason (defaults to 1 = "Requested by BO Admin").

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @OperationTypeID -> INSERT Customer.BlockedCustomerOperations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.OperationBlockForCID is the administrative procedure for blocking a specific business operation for a customer account. By inserting a row into Customer.BlockedCustomerOperations, it prevents the customer from performing a particular operation type (e.g., withdrawals, deposits, trading, copy trading) until the block is explicitly lifted via Customer.OperationUnBlockForCID.

This is a compliance and risk management tool, used by Back-Office administrators and automated risk systems. The block is per-operation (a customer can be blocked from withdrawals but still allowed to trade), granular (multiple different OperationTypeIDs can be blocked simultaneously), and audited (the Occurred timestamp records when each block was applied).

**Jira**: FB28429 (02.08.15) - Added default value for @BlockReasonID parameter so callers without a specific reason still record a standardized reason code (1 = 'Requested by BO Admin').

---

## 2. Business Logic

### 2.1 Operational Block Insertion

**What**: Inserts a per-customer, per-operation block record with an optional block reason.

**Columns/Parameters Involved**: `@CID`, `@OperationTypeID`, `@BlockReasonID`

**Rules**:
- Inserts into Customer.BlockedCustomerOperations: (CID, OperationTypeID, BlockReasonID, Occurred=GETUTCDATE())
- @BlockReasonID defaults to 1 when not provided (reason code: 'Requested by BO Admin')
- No duplicate check - if the same CID+OperationTypeID is blocked twice, two rows are inserted; behavior depends on Customer.BlockedCustomerOperations constraints (if unique constraint exists, second insert would fail)
- Occurred is set to GETUTCDATE() at insertion time - UTC timestamp of when the block was applied
- No NOCOUNT, no transaction, no return value - fire-and-forget insert

### 2.2 BlockReasonID Values

**What**: Categorizes why the operation was blocked.

**Rules**:
- @BlockReasonID = 1 (default): 'Requested by BO Admin' - manual administrative block
- Other values correspond to automated or other system-driven block reasons (see Customer.BlockedCustomerOperations.BlockReasonID lookup)
- The FB28429 change added the default specifically so automated batch callers don't need to pass a reason code

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Internal Customer ID of the customer to block. Inserted directly into Customer.BlockedCustomerOperations.CID. |
| 2 | @OperationTypeID | int | NO | - | VERIFIED | Identifies the specific operation type to block (e.g., withdrawal, deposit, trading). FK to operation type lookup. Inserted into Customer.BlockedCustomerOperations.OperationTypeID. |
| 3 | @BlockReasonID | int | NO | 1 | VERIFIED | Reason code for the block. Default=1 ('Requested by BO Admin') added via FB28429 (02.08.15). Other values represent automated or other administrative block reasons. Inserted into Customer.BlockedCustomerOperations.BlockReasonID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @OperationTypeID + @BlockReasonID | Customer.BlockedCustomerOperations | Writer (INSERT) | Creates the active block record with UTC timestamp |

### 5.2 Referenced By (other objects point to this)

No callers found in the codebase. Called externally by Back-Office administration tools and automated risk/compliance systems.

Related: Customer.GetBlockedOperationsForCID (reads current blocks), Customer.OperationUnBlockForCID (removes blocks).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.OperationBlockForCID (procedure)
└── Customer.BlockedCustomerOperations (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | INSERT - creates the active operation block record |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Block a customer from withdrawals (reason: BO Admin)
```sql
-- Using default BlockReasonID=1
EXEC Customer.OperationBlockForCID
    @CID = 12345678,
    @OperationTypeID = 3;  -- 3 = withdrawal (example)
```

### 8.2 Block with explicit reason code
```sql
EXEC Customer.OperationBlockForCID
    @CID = 12345678,
    @OperationTypeID = 3,
    @BlockReasonID = 5;  -- specific compliance/fraud reason
```

### 8.3 Check current blocks after inserting
```sql
SELECT CID, OperationTypeID, BlockReasonID, Occurred
FROM Customer.BlockedCustomerOperations WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY Occurred DESC;
```

### 8.4 Pair with unblock procedure
```sql
-- Block
EXEC Customer.OperationBlockForCID @CID = 12345678, @OperationTypeID = 3;
-- Later, unblock
EXEC Customer.OperationUnBlockForCID @CID = 12345678, @OperationTypeID = 3;
```

---

## 9. Atlassian Knowledge Sources

**Jira**: FB28429 (02.08.15) - Added default value for @BlockReasonID parameter. Default value 1 = 'Requested by BO Admin' so callers without a specific reason still record a standardized reason code.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 1 Jira (FB28429) | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.OperationBlockForCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.OperationBlockForCID.sql*
