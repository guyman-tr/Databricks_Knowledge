# BackOffice.AccountPendingClosureStatusChange

> Updates a customer account's pending closure status, used by BackOffice operators to mark accounts as suggested or approved for closure.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the single write path for changing a customer's pending closure status on the eToro platform. When a BackOffice compliance or operations agent determines that an account should be reviewed for closure, they progress it through a three-stage workflow: No pending closure (1), Suggested for Closure (2), and Approved for Closure (3). This procedure records that state transition in the core Customer record.

The procedure exists because account closure is a regulated, auditable operation. By routing all state changes through a dedicated procedure with validation, the platform ensures that only valid status codes are ever written to `Customer.Customer.PendingClosureStatusID`, preventing invalid states that could cause downstream processing errors.

Data flows as follows: a BackOffice application calls this procedure when an agent changes the pending closure state via the UI. The procedure validates the new status code against the `Dictionary.PendingClosureStatus` lookup, then writes the change to `Customer.Customer`. No history record is created here - audit trails are captured separately via the audit action system.

---

## 2. Business Logic

### 2.1 Pending Closure State Machine

**What**: A three-state workflow for marking accounts targeted for closure.

**Columns/Parameters Involved**: `@PendingClosureStatusID`, `Customer.Customer.PendingClosureStatusID`

**Rules**:
- Status must be one of the three valid values from `Dictionary.PendingClosureStatus`; any other value raises error 60000 with sub-code -1
- The customer (CID) must exist in `Customer.Customer`; if no row is updated, error 60000 sub-code -2 is raised
- The procedure does not enforce directional transitions - any valid status can be set at any time (e.g., can revert from 3 back to 1)
- Exactly one customer row must be updated; multi-row or zero-row updates both trigger the same error

**Diagram**:
```
PendingClosureStatusID values:
  1 = No (default - no pending closure)
       |
       v (operator suggests closure)
  2 = Suggested for Closure
       |
       v (compliance approves)
  3 = Approved for Closure
       |
       v (can revert at any stage)
  1 = No
```

### 2.2 Validation and Error Handling

**What**: Two-stage validation guards data integrity at the SP level.

**Columns/Parameters Involved**: `@PendingClosureStatusID`, `@CID`

**Rules**:
- Pre-update: validates @PendingClosureStatusID exists in `Dictionary.PendingClosureStatus` using EXISTS check (RAISERROR 60000, sub-code -1 on failure)
- Post-update: validates @@ROWCOUNT = 1, ensuring the CID matched exactly one customer (RAISERROR 60000, sub-code -2 on failure)
- All errors are caught in CATCH block and re-raised with RETURN 60000

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID of the account whose pending closure status is being changed. Must match exactly one row in `Customer.Customer.CID`. Error 60000 (-2) raised if no matching customer found. |
| 2 | @PendingClosureStatusID | tinyint | NO | - | VERIFIED | New pending closure status to assign. Must exist in `Dictionary.PendingClosureStatus`: 1=No (not pending), 2=Suggested for Closure, 3=Approved for Closure. Error 60000 (-1) raised for invalid values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PendingClosureStatusID | Dictionary.PendingClosureStatus | Lookup (validated) | Validates the status ID exists before writing; enforces referential integrity in code |
| @CID | Customer.Customer | FK (implicit) | Identifies the customer account; updates PendingClosureStatusID on the matching row |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found in the BackOffice schema. Called directly from the BackOffice application layer. Granted via EXECUTE permissions to multiple regional BackOffice user groups (China, UK, Russia, EastEU, US).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AccountPendingClosureStatusChange (procedure)
|- Dictionary.PendingClosureStatus (table) [validation - exists check]
+-- Customer.Customer (table) [UPDATE target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PendingClosureStatus | Table | EXISTS check to validate @PendingClosureStatusID before update |
| Customer.Customer | Table | UPDATE target - sets PendingClosureStatusID WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Called directly via ADO.NET/ORM to change pending closure state |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Status validation | Application CHECK | @PendingClosureStatusID must exist in Dictionary.PendingClosureStatus; enforced via EXISTS check in code, not DDL constraint |
| Single row guarantee | Application CHECK | @@ROWCOUNT must equal 1 after UPDATE; ensures CID uniqueness is respected |

---

## 8. Sample Queries

### 8.1 Set account as Suggested for Closure

```sql
-- Mark a customer account as suggested for closure
EXEC BackOffice.AccountPendingClosureStatusChange
    @CID = 12345,
    @PendingClosureStatusID = 2  -- Suggested for Closure
```

### 8.2 Revert account to No pending closure

```sql
-- Clear pending closure status (revert to normal)
EXEC BackOffice.AccountPendingClosureStatusChange
    @CID = 12345,
    @PendingClosureStatusID = 1  -- No
```

### 8.3 Check current pending closure status for a customer

```sql
SELECT
    c.CID,
    c.PendingClosureStatusID,
    pcs.PendingClosureStatusName
FROM Customer.Customer c WITH (NOLOCK)
JOIN Dictionary.PendingClosureStatus pcs WITH (NOLOCK)
    ON c.PendingClosureStatusID = pcs.PendingClosureStatusID
WHERE c.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AccountPendingClosureStatusChange | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.AccountPendingClosureStatusChange.sql*
