# BackOffice.CustomerSetManagerFromDynamics

> Translates one or two manager email addresses to a ManagerID via BackOffice.Manager lookup, then delegates the assignment to BackOffice.CustomerSetManager with CalledFromDynamics=1.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to assign manager to |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerSetManagerFromDynamics is a thin adapter procedure created in 2010 by Dean Bar for Dynamics CRM integration. When Dynamics CRM assigns a manager to a customer, it knows the manager's email address(es) - not their internal BackOffice ManagerID. This procedure bridges that gap: it accepts up to two email addresses, resolves them to a ManagerID from `BackOffice.Manager`, and calls `BackOffice.CustomerSetManager` to perform the actual assignment.

The procedure hardcodes `@CalledFromDynamics = 1` when calling CustomerSetManager, identifying this as a CRM-originated assignment (the parameter is currently unused in CustomerSetManager but preserved for historical tracking).

Key behaviors:
- If NEITHER email matches a manager: @ManagerID is NULL -> CustomerSetManager is called with NULL -> **the customer's manager is unassigned**.
- If BOTH emails match managers: `MIN(ManagerID)` is used as a tiebreaker - deterministic but arbitrary.
- Email matching is case-insensitive (LOWER() applied to both sides).

---

## 2. Business Logic

### 2.1 Email-to-ManagerID Resolution

**What**: Resolves up to two manager email addresses to a single ManagerID.

**Columns/Parameters Involved**: `@Email1`, `@Email2`, `BackOffice.Manager.Email`, `BackOffice.Manager.ManagerID`, `@ManagerID`

**Rules**:
- SELECT @ManagerID = MIN(ManagerID) FROM BackOffice.Manager WITH (NOLOCK) WHERE LOWER(Email) IN (LOWER(@Email1), LOWER(@Email2)).
- Case-insensitive: LOWER() applied to both stored email and parameters.
- @Email2 is optional (default NULL): when NULL, IN clause effectively becomes a single-email lookup (LOWER(NULL) = NULL, which never matches).
- If no manager found (neither email in table): @ManagerID = NULL (unresolved).
- If two managers found (both emails match): MIN(ManagerID) - smallest ManagerID wins. Uncommon but handled deterministically.
- WITH (NOLOCK) - non-blocking read from manager directory.

### 2.2 Delegate to CustomerSetManager

**What**: Calls the canonical manager assignment procedure with the resolved ManagerID.

**Columns/Parameters Involved**: `@CID`, `@ManagerID`, `@CalledFromDynamics = 1`

**Rules**:
- EXEC BackOffice.CustomerSetManager @CID, @ManagerID, 1 (CalledFromDynamics hardcoded to 1).
- CustomerSetManager applies a change-guard: only updates if new ManagerID differs from current (NULL-safe).
- If @ManagerID is NULL (no email matched): CustomerSetManager will UNASSIGN the customer's current manager (if one is set).
- No error check on the EXEC return value - errors from CustomerSetManager propagate naturally.

**Diagram**:
```
@Email1 + @Email2 (optional)
  -> SELECT MIN(ManagerID) FROM BackOffice.Manager WHERE Email IN (emails)
  -> @ManagerID (NULL if not found)
  -> EXEC BackOffice.CustomerSetManager @CID, @ManagerID, CalledFromDynamics=1
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer to assign manager to. Passed directly to BackOffice.CustomerSetManager. FK to BackOffice.Customer.CID. |
| 2 | @Email1 | NVARCHAR(50) | NO | - | CODE-BACKED | Primary manager email address. Case-insensitive lookup against BackOffice.Manager.Email. Required - no default. |
| 3 | @Email2 | NVARCHAR(50) | YES | NULL | CODE-BACKED | Optional secondary manager email. When NULL, only @Email1 is used. Allows Dynamics CRM to pass a fallback email if the primary is not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Email1, @Email2 | BackOffice.Manager | Lookup | SELECT MIN(ManagerID) WHERE LOWER(Email) IN (emails). Email-to-ID resolution. |
| @CID, @ManagerID | BackOffice.CustomerSetManager | Caller | EXEC - delegates manager assignment after email resolution. CalledFromDynamics=1 passed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dynamics CRM integration | EXEC | Caller | Called when Dynamics CRM assigns a manager to a customer. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetManagerFromDynamics (procedure)
├── BackOffice.Manager (table) - email -> ManagerID lookup
└── BackOffice.CustomerSetManager (procedure) - actual assignment
    └── BackOffice.Customer (table) - UPDATE ManagerID, PreviousManagerID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | SELECT MIN(ManagerID) WHERE LOWER(Email) IN (@Email1, @Email2) |
| BackOffice.CustomerSetManager | Procedure | EXEC - canonical manager assignment with change-guard |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dynamics CRM integration | External | EXEC - called by CRM system with manager email(s) instead of ManagerID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NULL @ManagerID = unassignment | Behavior | If no email matches, @ManagerID is NULL. CustomerSetManager is called with NULL -> manager is cleared if one was assigned. Callers should ensure valid emails to avoid accidental unassignment. |
| MIN(ManagerID) tiebreaker | Behavior | If both @Email1 and @Email2 match different managers, MIN(ManagerID) selects one deterministically. No error is raised. |
| Case-insensitive email match | Design | LOWER() applied to both stored emails and parameters. Prevents case mismatch rejections from CRM. |
| CalledFromDynamics=1 hardcoded | Convention | Identifies all assignments made by this adapter as Dynamics-originated. The parameter is currently unused in CustomerSetManager. |
| WITH (NOLOCK) on Manager read | Performance | Non-blocking read. Manager table is rarely updated; dirty reads are acceptable here. |
| No EXEC return value check | Behavior | Return value of CustomerSetManager is not checked. Errors propagate up naturally. |

---

## 8. Sample Queries

### 8.1 Assign manager from Dynamics CRM by email
```sql
EXEC BackOffice.CustomerSetManagerFromDynamics
    @CID = 12345,
    @Email1 = 'john.smith@etoro.com',
    @Email2 = NULL
```

### 8.2 Assign with fallback email
```sql
EXEC BackOffice.CustomerSetManagerFromDynamics
    @CID = 12345,
    @Email1 = 'john.smith@etoro.com',
    @Email2 = 'j.smith@etoro.com'  -- fallback if primary not found
```

### 8.3 Verify manager lookup before calling
```sql
SELECT ManagerID, FirstName, LastName, Email
FROM BackOffice.Manager WITH (NOLOCK)
WHERE LOWER(Email) IN (LOWER('john.smith@etoro.com'), LOWER('j.smith@etoro.com'))
```

### 8.4 Check current manager assignment for a customer
```sql
SELECT C.CID, C.ManagerID, C.PreviousManagerID,
       M.FirstName + ' ' + M.LastName AS ManagerName
FROM BackOffice.Customer C WITH (NOLOCK)
LEFT JOIN BackOffice.Manager M WITH (NOLOCK) ON C.ManagerID = M.ManagerID
WHERE C.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerSetManagerFromDynamics | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetManagerFromDynamics.sql*
