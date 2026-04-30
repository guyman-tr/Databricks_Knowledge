# Trade.UpdateEtorianUsersCopiedBlockRestriction

> Backfills copy-trading block restrictions for all Israeli eToro employees (CountryID=250) who do not yet have an OperationTypeID=2/BlockReasonID=3 entry in Customer.BlockedCustomerOperations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A - no parameters; targets all CountryID=250 customers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateEtorianUsersCopiedBlockRestriction is a one-time backfill migration procedure. It was created to populate `Customer.BlockedCustomerOperations` with copy-trading blocks for all eToro employees (identified by CountryID=250, Israel) who did not yet have that restriction in the new table.

The context is a system migration: eToro originally enforced the "employee accounts cannot be copied" rule directly in `Trade.RegisterMirror` via inline validation (checking the parent username or CountryID=250 in the SP logic). The new architecture moves that enforcement to `Customer.BlockedCustomerOperations` (a dedicated restriction table), where OperationTypeID=2 means "block from being copied" and BlockReasonID=3 means "eToro employee account." The comment at the bottom of the DDL confirms this: "remove parent user name and Not eTorian validation from Trade.RegisterMirror SP."

This procedure was designed to run once as part of that migration - seeding the restriction table for all existing employees so that the new table-based check would have the same coverage as the old inline check. The NOT IN subquery makes it idempotent: re-running it will only insert for employees who still lack the restriction, making it safe to execute multiple times or schedule as a maintenance job.

---

## 2. Business Logic

### 2.1 Employee Identification - CountryID=250 (Israel)

**What**: eToro employees are identified by their registration country being Israel (CountryID=250) in Customer.Customer.

**Columns/Parameters Involved**: `Customer.Customer.CountryID`, `Customer.Customer.CID`

**Rules**:
- CountryID=250 = Israel = eToro employee accounts (eToro is headquartered in Tel Aviv)
- All CIDs with CountryID=250 are treated as employees requiring the copy-trading block
- No explicit employee flag or role check is used - country of registration is the sole discriminator
- Customer table is read WITH(NOLOCK) - acceptable for a backfill where dirty reads have no material impact

### 2.2 Idempotent Insert - NOT IN Filter

**What**: Only inserts for employees who do not already have the copy-trading restriction, preventing duplicate rows.

**Columns/Parameters Involved**: `Customer.BlockedCustomerOperations.CID`, `.OperationTypeID`, `.BlockReasonID`

**Rules**:
- Subquery: `SELECT CID FROM Customer.BlockedCustomerOperations WHERE OperationTypeID=2 AND BlockReasonID=3`
- OperationTypeID=2 = Copied block (prevents the user from being copied)
- BlockReasonID=3 = eToro employee account
- If a CID is already in BlockedCustomerOperations with this combination, it is excluded from the INSERT
- Makes the procedure safe to re-run - duplicate blocks are never created

### 2.3 Inserted Row Values

**What**: Each new block record is inserted with fixed values for all required columns.

**Columns/Parameters Involved**: `CID`, `OperationTypeID`, `Occurred`, `BlockReasonID`, `RequestGUID`

**Rules**:
- CID: from Customer.Customer WHERE CountryID=250 (the employee's account ID)
- OperationTypeID=2: copy-trading block
- Occurred: GETUTCDATE() at the time of execution (wall-clock UTC)
- BlockReasonID=3: employee account reason code
- RequestGUID='': empty string (no originating request UUID for this batch backfill)

**Diagram**:
```
Customer.Customer (CountryID=250 employees)
    |
    +-- MINUS already-blocked CIDs (OperationTypeID=2, BlockReasonID=3)
    |
    v
INSERT Customer.BlockedCustomerOperations
  CID=<employee CID>, OperationTypeID=2, Occurred=NOW, BlockReasonID=3, RequestGUID=''
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No parameters. The procedure takes no input and produces no output - it is entirely self-contained, deriving all target CIDs from Customer.Customer WHERE CountryID=250.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Customer.Customer | Read | Identifies eToro employee accounts via CountryID=250 |
| INSERT target / NOT IN subquery | Customer.BlockedCustomerOperations | Modifier / Read | Inserts copy-trading blocks; checks for existing restrictions to avoid duplicates |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no callers found in SSDT. This was designed as a one-time migration job, run manually or via SQL Agent during the BlockedCustomerOperations system rollout.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateEtorianUsersCopiedBlockRestriction (procedure)
+-- Customer.Customer (table)
+-- Customer.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Source of eToro employee CIDs (WHERE CountryID=250) |
| Customer.BlockedCustomerOperations | Table | INSERT target for new copy-trading blocks; also read in NOT IN subquery to avoid duplicates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (migration tooling / SQL Agent job) | - | One-time execution during BlockedCustomerOperations rollout to backfill employee restrictions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. The NOT IN subquery on BlockedCustomerOperations with NOLOCK hint makes this idempotent. No TRY/CATCH - errors propagate to the caller. The trailing comment "remove parent user name and Not eTorian validation from Trade.RegisterMirror SP" documents the companion code change this procedure was shipped alongside.

---

## 8. Sample Queries

### 8.1 Preview employees who would be inserted (dry run)
```sql
SELECT c.CID, c.UserName, c.CountryID
FROM   Customer.Customer c WITH(NOLOCK)
WHERE  c.CountryID = 250
  AND  c.CID NOT IN (
       SELECT CID
       FROM   Customer.BlockedCustomerOperations WITH(NOLOCK)
       WHERE  OperationTypeID = 2
         AND  BlockReasonID   = 3
       );
```

### 8.2 Count current copy-trading blocks for employees
```sql
SELECT COUNT(*) AS EmployeeBlocks
FROM   Customer.BlockedCustomerOperations WITH(NOLOCK)
WHERE  OperationTypeID = 2
  AND  BlockReasonID   = 3;
```

### 8.3 Verify all Israeli employees have the restriction
```sql
SELECT c.CID, c.UserName,
       CASE WHEN b.CID IS NOT NULL THEN 'Blocked' ELSE 'MISSING' END AS CopyStatus
FROM   Customer.Customer c WITH(NOLOCK)
LEFT JOIN Customer.BlockedCustomerOperations b WITH(NOLOCK)
       ON b.CID = c.CID AND b.OperationTypeID = 2 AND b.BlockReasonID = 3
WHERE  c.CountryID = 250
ORDER  BY CopyStatus;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateEtorianUsersCopiedBlockRestriction | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateEtorianUsersCopiedBlockRestriction.sql*
