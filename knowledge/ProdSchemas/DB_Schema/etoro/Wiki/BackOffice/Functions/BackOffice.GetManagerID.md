# BackOffice.GetManagerID

> Resolves a BackOffice manager's login username to their numeric ManagerID, enabling procedures to accept a username string and work with the integer ID internally.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INT - ManagerID or NULL |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetManagerID is a simple lookup helper that converts a BackOffice manager's Login (username string, e.g., "john.smith") to their integer ManagerID. BackOffice.Manager stores staff with a unique login name as their human-readable identifier, but most system operations use the integer ManagerID as the key. This function bridges the gap when code has a username but needs the ID.

The function exists to avoid duplicating the `SELECT ManagerID FROM BackOffice.Manager WHERE Login = @loginName` pattern across multiple procedures. Without it, each procedure needing this lookup would need to inline the query or use a separate variable declaration. The function also inherits the case-sensitive behavior of the `=` operator on the Login column, matching the Login index (BMNG_LOGIN).

It is called by BackOffice.InsertDocument and BackOffice.InsertTncDocument - both document insertion procedures that accept a manager login name as input and need to record the corresponding ManagerID in their audit trail or ownership field.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @loginName | VARCHAR(50) | NO | - | CODE-BACKED | The Login username of the BackOffice manager to look up. Matched against BackOffice.Manager.Login using exact equality. Maximum 50 chars (note: BackOffice.Manager.Login is VARCHAR(20) - the parameter is wider than the column, which is valid). |
| 2 | Return value | INT | YES | - | CODE-BACKED | The ManagerID of the manager with the given login name. Returns NULL if no active or inactive manager exists with that Login. Callers (InsertDocument, InsertTncDocument) should handle NULL to detect invalid/unknown login names. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @loginName | BackOffice.Manager.Login | Lookup | Matches Login column - uses the BMNG_LOGIN unique index for efficient single-row lookup. |
| Return value | BackOffice.Manager | Implicit FK | Returned ManagerID is the PK of BackOffice.Manager. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.InsertDocument | (manager login param) | Function call | Resolves the submitting manager's login to ManagerID for document ownership record |
| BackOffice.InsertTncDocument | (manager login param) | Function call | Resolves the submitting manager's login to ManagerID for T&C document ownership |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetManagerID (scalar function)
└── BackOffice.Manager (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | SELECT ManagerID WHERE Login = @loginName - single-row lookup using Login unique index |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.InsertDocument | Stored Procedure | Calls function to resolve manager login to ManagerID |
| BackOffice.InsertTncDocument | Stored Procedure | Calls function to resolve manager login to ManagerID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Resolve a manager's login to their ManagerID
```sql
SELECT BackOffice.GetManagerID('john.smith') AS ManagerID
-- Returns the ManagerID if 'john.smith' exists in BackOffice.Manager
-- Returns NULL if not found
```

### 8.2 Validate multiple manager logins in a batch
```sql
SELECT
    login_list.LoginName,
    BackOffice.GetManagerID(login_list.LoginName) AS ManagerID,
    CASE WHEN BackOffice.GetManagerID(login_list.LoginName) IS NULL
         THEN 'NOT FOUND'
         ELSE 'OK'
    END AS Status
FROM (VALUES ('admin'), ('support'), ('john.smith')) AS login_list(LoginName)
```

### 8.3 Get full manager details from a login name
```sql
SELECT
    m.ManagerID,
    m.FirstName,
    m.LastName,
    m.Email,
    m.IsActive,
    m.UserGroupID
FROM BackOffice.Manager m WITH (NOLOCK)
WHERE m.ManagerID = BackOffice.GetManagerID('john.smith')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetManagerID | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetManagerID.sql*
