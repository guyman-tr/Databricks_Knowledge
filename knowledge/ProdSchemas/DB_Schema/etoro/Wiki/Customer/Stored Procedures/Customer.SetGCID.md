# Customer.SetGCID

> Assigns a Global Customer ID (GCID) to a customer's demo and real accounts by registering in the global customer registry, then stamping both legacy account tables with the returned GCID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID OUTPUT - returns the newly assigned global customer ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SetGCID is a legacy account-linking procedure that ties a customer's demo account (DemoCID) and real account (RealCID) together under a single Global Customer ID (GCID). The GCID is a cross-system identifier assigned by an external global customer registry (GlobalRegister_InsertGlobalCustomer). Once assigned, it allows different parts of the platform to refer to the same logical customer regardless of whether they are acting on the demo or real account side.

The procedure exists because early in eToro's architecture, demo and real trading accounts were tracked separately (DemoCustomers and RealCustomers tables). GCID was introduced as a unification key to correlate these two account types and serve as the canonical identity in downstream systems. Without this procedure, a customer's demo and real accounts would remain unlinked, preventing cross-account features like account migration, social features, and cross-system identity lookups.

Data flow: called during account registration or account-linking flows. Reads UserName and Email from RealCustomers to call GlobalRegister_InsertGlobalCustomer. If the global register returns -1, the call failed (raises an error). Otherwise, it updates both RealCustomers.GCID and DemoCustomers.GCID to the new value - but ONLY if the current GCID is 0 (preventing re-assignment of an already-linked account). Customer.DelSetGCID references this procedure in the account deletion/reset flow.

---

## 2. Business Logic

### 2.1 GCID Assignment via External Global Register

**What**: GCID is not generated locally - it is assigned by an external stored procedure (GlobalRegister_InsertGlobalCustomer) that maintains a cross-system global customer registry.

**Columns/Parameters Involved**: `@RealCID`, `@UserName` (internal), `@GCID OUTPUT`

**Rules**:
- UserName and Email are read from RealCustomers by @RealCID and passed to GlobalRegister_InsertGlobalCustomer
- GlobalRegister_InsertGlobalCustomer returns the assigned GCID as its return value
- Return value of -1 means registration failed; the procedure raises an error and does not update either account table
- On success: @GCID receives the integer GCID value, and both RealCustomers and DemoCustomers are updated

**Diagram**:
```
@RealCID -> SELECT UserName, Email FROM RealCustomers
              |
              v
GlobalRegister_InsertGlobalCustomer(UserName, Email)
              |
        @GCID returned
              |
    @GCID = -1? -> RAISERROR (abort)
    @GCID > 0?  -> UPDATE RealCustomers.GCID = @GCID (WHERE GCID = 0)
                -> UPDATE DemoCustomers.GCID = @GCID (WHERE GCID = 0)
```

### 2.2 Safe GCID Update (Only If Not Already Set)

**What**: The GCID update on both legacy tables uses WHERE GCID = 0 to prevent overwriting an already-assigned GCID.

**Columns/Parameters Involved**: `@DemoCID`, `@RealCID`, `@GCID OUTPUT`

**Rules**:
- UPDATE RealCustomers SET GCID = @GCID WHERE CID = @RealCID AND GCID = 0
- UPDATE DemoCustomers SET GCID = @GCID WHERE CID = @DemoCID AND GCID = 0
- If GCID is already non-zero for either account, that UPDATE is a no-op (0 rows affected) - no error is raised
- This means calling the procedure twice for the same account would register a new GCID but only update the tables if they still have GCID = 0

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DemoCID | int | NO | - | CODE-BACKED | The customer's demo account CID. Used in the UPDATE DemoCustomers SET GCID = @GCID WHERE CID = @DemoCID AND GCID = 0 step. Links the demo account to the assigned GCID. |
| 2 | @RealCID | int | NO | - | CODE-BACKED | The customer's real account CID. Used to look up UserName and Email from RealCustomers (for GlobalRegister call), and in the UPDATE RealCustomers SET GCID = @GCID step. The real account is the source of identity data passed to the global registry. |
| 3 | @GCID | int | NO (OUTPUT) | - | CODE-BACKED | Output parameter. Receives the Global Customer ID assigned by GlobalRegister_InsertGlobalCustomer. A value of -1 means the global registry call failed (procedure will raise an error). On success, this value is used to update both DemoCustomers and RealCustomers. Callers receive this output to store or use as the canonical customer identity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RealCID | RealCustomers (legacy) | Reader + Modifier | Reads UserName/Email for GlobalRegister call; updates GCID column if currently 0 |
| @DemoCID | DemoCustomers (legacy) | Modifier | Updates GCID column if currently 0 |
| @GCID | GlobalRegister_InsertGlobalCustomer (external proc) | EXEC call | External global customer registry that assigns the canonical GCID; return value of -1 signals failure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.DelSetGCID | - | Caller | References SetGCID in the account deletion/reset flow (del + re-set GCID) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetGCID (procedure)
├── RealCustomers (legacy table - SELECT + UPDATE)
├── DemoCustomers (legacy table - UPDATE)
└── GlobalRegister_InsertGlobalCustomer (external procedure - EXEC)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RealCustomers | Table (legacy) | SELECT UserName, Email for GlobalRegister call; UPDATE GCID on success |
| DemoCustomers | Table (legacy) | UPDATE GCID on success |
| GlobalRegister_InsertGlobalCustomer | Stored Procedure (external) | EXEC to assign a new GCID; return value is the assigned ID or -1 on failure |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.DelSetGCID | Stored Procedure | Calls SetGCID as part of demo/real GCID reset flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH | Error handling | Any error within the TRY block (including GlobalRegister failure or RAISERROR on @GCID=-1) is re-raised via CATCH using ERROR_MESSAGE() |
| GCID = 0 guard | Conditional UPDATE | Both UPDATE statements only apply if GCID is currently 0, preventing re-assignment to already-linked accounts |

---

## 8. Sample Queries

### 8.1 Assign a GCID to a demo+real account pair
```sql
DECLARE @NewGCID INT;
EXEC Customer.SetGCID
    @DemoCID = 10001,
    @RealCID = 20001,
    @GCID = @NewGCID OUTPUT;
SELECT @NewGCID AS AssignedGCID;
```

### 8.2 Check current GCID assignment on both legacy tables
```sql
SELECT 'Real' AS AccountType, CID, GCID, UserName, Email
FROM RealCustomers WITH (NOLOCK) WHERE CID = 20001
UNION ALL
SELECT 'Demo', CID, GCID, NULL, NULL
FROM DemoCustomers WITH (NOLOCK) WHERE CID = 10001;
```

### 8.3 Find customers with GCID = 0 (not yet linked)
```sql
SELECT CID, UserName, Email
FROM RealCustomers WITH (NOLOCK)
WHERE GCID = 0
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetGCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetGCID.sql*
