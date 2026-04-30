# Billing.SetBalanceCompensation

> Billing-schema wrapper for Customer.SetBalanceCompensation that adds GCID-to-CID resolution, allowing balance compensation to be triggered using either an internal CID or a Global Customer ID (GCID).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Delegates to Customer.SetBalanceCompensation after CID resolution |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Balance compensation is the process of crediting or debiting a customer's account for operational reasons - such as resolving a service issue, applying a promotional credit, or correcting an error. `Customer.SetBalanceCompensation` is the core procedure for this in the Customer schema. `Billing.SetBalanceCompensation` is a thin wrapper that adds one capability: accepting a GCID (Global Customer ID) in place of the internal CID, then resolving it before delegating.

Created for the InfraDev POC by Ran Ovadia on 14/04/2025. This wrapper allows Billing-context callers (or cross-system integrations that only have a GCID) to invoke balance compensation without knowing the internal CID.

**Note on declared-but-unused parameters**: Several parameters are declared in the signature but NOT passed to the inner `Customer.SetBalanceCompensation` call: `@ErrOut` (OUTPUT), `@PositionID`, `@InterestMonthlyID`, and `@CreditOut` (OUTPUT). These suggest the wrapper was designed for future enrichment but the current implementation passes only 6 of 11 parameters to the inner procedure. Callers relying on `@ErrOut` or `@CreditOut` being populated will receive empty/null values.

---

## 2. Business Logic

### 2.1 GCID Resolution and Delegation

**What**: Validates that at least one customer identifier is provided, resolves GCID to CID if needed, then calls Customer.SetBalanceCompensation.

**Columns/Parameters Involved**: `@CID`, `@GCID`, `@MoveMoneyReasonID` (required)

**Rules**:
- Guard: IF @CID IS NULL AND @GCID IS NULL -> RAISERROR ('Must supply @CID or @GCID!', severity=11). Returns without executing.
- GCID resolution: IF @CID IS NULL -> SELECT TOP 1 @CID = CID FROM Customer.CustomerStatic WHERE GCID = @GCID.
- Delegation: EXEC Customer.SetBalanceCompensation @CID, @Payment, @Description, @ManagerID, @CompensationReasonID, @MoveMoneyReasonID.
- Parameters NOT forwarded: @ErrOut, @PositionID, @InterestMonthlyID, @CreditOut (declared but unused in current implementation).

**Diagram**:
```
Input: @CID or @GCID (at least one required) + @Payment + @MoveMoneyReasonID (required)
  |
  +-- Guard: both NULL? -> RAISERROR + RETURN
  |
  +-- @CID NULL? -> resolve: SELECT TOP 1 CID FROM Customer.CustomerStatic WHERE GCID=@GCID
  |
  EXEC Customer.SetBalanceCompensation(@CID, @Payment, @Description, @ManagerID, @CompensationReasonID, @MoveMoneyReasonID)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | NULL | CODE-BACKED | Internal Customer ID. Either @CID or @GCID must be provided. If both supplied, @CID is used directly (no GCID lookup). |
| 2 | @GCID | INT | YES | NULL | CODE-BACKED | Global Customer ID (cross-system identifier). If @CID is NULL, procedure resolves CID via Customer.CustomerStatic.GCID. |
| 3 | @Payment | INT | NO | - | CODE-BACKED | Compensation amount (positive=credit, negative=debit). Required. Passed directly to Customer.SetBalanceCompensation. |
| 4 | @Description | VARCHAR(255) | YES | NULL | CODE-BACKED | Human-readable description of the compensation reason. Passed to Customer.SetBalanceCompensation. |
| 5 | @ManagerID | INT | YES | NULL | CODE-BACKED | ID of the manager authorizing the compensation. Audit trail field. Passed to Customer.SetBalanceCompensation. |
| 6 | @CompensationReasonID | INT | YES | NULL | CODE-BACKED | Categorization code for the type of compensation. Passed to Customer.SetBalanceCompensation. |
| 7 | @MoveMoneyReasonID | INT | NO | - | CODE-BACKED | Required. Reason code for the money movement. Passed to Customer.SetBalanceCompensation. |
| 8 | @ErrOut | NVARCHAR(4000) | YES | '' | CODE-BACKED | OUTPUT parameter declared but NOT forwarded to Customer.SetBalanceCompensation. Callers will always receive empty string. Future enrichment placeholder. |
| 9 | @PositionID | BIGINT | YES | NULL | CODE-BACKED | Declared but NOT used. Likely intended for linking compensation to a specific trade position. Not passed to inner procedure. |
| 10 | @InterestMonthlyID | INT | YES | NULL | CODE-BACKED | Declared but NOT used. Likely intended for interest accrual context. Not passed to inner procedure. |
| 11 | @CreditOut | BIGINT | YES | NULL | CODE-BACKED | OUTPUT parameter declared but NOT forwarded. Callers will always receive NULL. Future enrichment placeholder. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID resolution | Customer.CustomerStatic | READ | SELECT TOP 1 CID WHERE GCID = @GCID when @CID is NULL |
| Compensation execution | Customer.SetBalanceCompensation | EXEC (delegate) | Core compensation procedure; this is a wrapper around it |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Created for InfraDev POC; called by Billing-context integrations that need GCID support for balance compensation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SetBalanceCompensation (procedure)
├── Customer.CustomerStatic (table) - GCID resolution
└── Customer.SetBalanceCompensation (procedure) - actual compensation logic
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | GCID-to-CID resolution (when @CID is NULL) |
| Customer.SetBalanceCompensation | Procedure | Delegate: performs the actual balance compensation |

### 6.2 Objects That Depend On This

No SQL dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CID/GCID required | Guard | RAISERROR if both are NULL. Severity=11 (error). |
| GCID resolution | SELECT TOP 1 | If multiple CIDs share a GCID (unusual), takes the first by table scan order. No ordering guarantee. |
| @MoveMoneyReasonID required | No default | Declared without default value; callers must supply it or SQL Server will error. |
| Unused OUTPUT params | Design gap | @ErrOut and @CreditOut are always empty/null. Not forwarded to inner procedure. |

---

## 8. Sample Queries

### 8.1 Compensate by CID

```sql
DECLARE @ErrOut NVARCHAR(4000) = ''
EXEC Billing.SetBalanceCompensation
    @CID = 123456,
    @Payment = 100,
    @Description = 'Service credit for support ticket #789',
    @ManagerID = 9001,
    @MoveMoneyReasonID = 42,
    @ErrOut = @ErrOut OUTPUT
-- Note: @ErrOut will be empty regardless (not forwarded to inner proc)
```

### 8.2 Compensate by GCID (cross-system)

```sql
EXEC Billing.SetBalanceCompensation
    @GCID = 87654321,
    @Payment = 50,
    @MoveMoneyReasonID = 15
-- CID resolved internally from Customer.CustomerStatic
```

### 8.3 Resolve GCID to CID manually

```sql
SELECT TOP 1 CID, UserName, Email
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE GCID = 87654321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Created for InfraDev POC by Ran Ovadia, 14/04/2025.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.SetBalanceCompensation | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.SetBalanceCompensation.sql*
