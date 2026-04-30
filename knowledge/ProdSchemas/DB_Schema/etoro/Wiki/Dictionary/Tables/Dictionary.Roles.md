# Dictionary.Roles

## 1. Business Meaning

**What it is**: A role-based access control (RBAC) definition table that maps named roles to specific application objects with read/write permission flags. Each role grants or restricts access to a particular area of the Configuration Manager / Dealing Reports internal tool.

**Why it exists**: eToro's internal tools (Configuration Manager, CEP engine, Dealing Reports) require granular access control. Rather than hardcoding permissions, this table allows dynamic assignment of read/write access per application object. Roles are assigned to user groups via the `Internal.GroupsAndRoles` junction table, enabling group-based permission inheritance.

**How it works**: When an internal user performs an operation in an admin tool, the system calls `Internal.CheckSinglePermission`, which joins `Dictionary.Groups` → `Internal.GroupsAndRoles` → `Dictionary.Roles` → `Dictionary.Objects` to determine whether the user's group has read or write access to the requested object. The role's `CanRead`/`CanWrite` flags are evaluated against the requested operation type.

---

## 2. Business Logic

### Role Pattern
Every application object typically has **two roles**: a read-only role and a read+write role. The naming convention is:
- `Read{ObjectName}` — `CanRead=1, CanWrite=0`
- `Update{ObjectName}` / `Edit{ObjectName}` / `Execute{ObjectName}` — `CanRead=1, CanWrite=1`

### Permission Domains
The 36 roles cover these functional areas:
- **Tradonomi Contracts** (Roles 1-8): Liquidity provider contract management
- **Feature Thresholds** (Roles 10-13): Trading feature configuration (volatility, spread, delay)
- **Dealing Reports** (Roles 14-17): Hedge cost, slippage, markup reports
- **Dealing Configuration** (Roles 18-22): Basic → Advanced → Critical dealing configuration tiers
- **Trading Configuration** (Role 23): Instrument trading settings (delist, allow buy/sell)
- **Bulk Operations** (Roles 24-28): Reopen positions, bulk open orders with CID whitelisting
- **System Operations** (Role 31): Cache reload and system-wide technical ops
- **CEP** (Role 32): Complex Event Processing engine access
- **CopyTrading** (Roles 34-36): SmartCopy restrictions, close positions at price, unregister mirrors

### Permission Check Flow
```
User Request → Extract GroupNames from XML
    → Dictionary.Groups (resolve GroupID)
    → Internal.GroupsAndRoles (junction)
    → Dictionary.Roles (get CanRead/CanWrite for ObjectID)
    → MAX(permission) across all user's groups
    → 0 = denied, 1 = granted
```

---

## 3. Data Overview

| RoleID | RoleName | ObjectID | CanRead | CanWrite | Business Meaning |
|--------|----------|----------|---------|----------|------------------|
| 1 | UpdateTradonomiContracts | 1 | 1 | 1 | Full access to Tradonomi contract data |
| 2 | ReadTradonomiContracts | 1 | 1 | 0 | Read-only Tradonomi contracts |
| 9 | ExecuteRollActions | 5 | 1 | 1 | Perform contract roll operations |
| 18 | EditDealingBasicConfiguration | 12 | 1 | 1 | Edit basic dealing config |
| 23 | EditTradingConfigurations | 17 | 1 | 1 | Edit instrument trading settings (delist, allow orders) |

*36 rows total — full RBAC definition for internal tools*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **RoleID** | int | NOT NULL | — | Primary key. Sequential identifier for each role definition. Range: 1-36. | `DDL` |
| **RoleName** | varchar(50) | NOT NULL | — | Human-readable role name following `{Verb}{ObjectName}` convention. Used in Group-to-Role assignment and audit. Verbs: Read, Update, Edit, Execute, Create. | `MCP+CODE` |
| **RoleDesc** | varchar(500) | NULL | — | Free-text description of what the role permits. Written by developers when adding roles. Documents the business action allowed. | `MCP` |
| **ObjectID** | int | NOT NULL | — | FK → `Dictionary.Objects`. The application object this role controls access to. Each object typically has 2 roles (read + write). | `DDL+MCP` |
| **CanRead** | int | NOT NULL | 0 | Read permission flag. 1 = role grants read access to the object. All 36 roles have CanRead=1 (every role grants at least read). | `MCP` |
| **CanWrite** | int | NOT NULL | 0 | Write permission flag. 1 = role grants modify/execute access. 0 = read-only. `Internal.CheckSinglePermission` evaluates this based on the requested operation ("Read" vs "Write"). | `CODE+MCP` |

---

## 5. Relationships

### References To (this table points to)
| Referenced Table | FK Column | Relationship | Business Meaning |
|-----------------|-----------|--------------|------------------|
| Dictionary.Objects | ObjectID | FK_Roles_Objects | Each role controls access to one application object |

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| Internal.GroupsAndRoles | RoleID | FK_GroupsAndRoles_Roles | Junction table assigning roles to BackOffice permission groups |
| Internal.CheckSinglePermission | RoleID | JOIN | Procedure that evaluates permission for a user operation |

---

## 6. Dependencies

### Depends On
- `Dictionary.Objects` — target objects for access control

### Depended On By
- `Internal.GroupsAndRoles` — role-to-group assignment
- `Internal.CheckSinglePermission` — runtime permission evaluation

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `RoleID` (clustered) |
| Indexes | PK only |
| Foreign Keys | `FK_Roles_Objects` → `Dictionary.Objects(ObjectID)` |
| Constraints | `DF_Roles_CanRead` DEFAULT 0, `DF_Roles_CanWrite` DEFAULT 0 |
| Filegroup | PRIMARY |
| Row Count | 36 |

---

## 8. Sample Queries

```sql
-- Get all roles with their object names
SELECT  R.RoleID, R.RoleName, R.RoleDesc, O.ObjectName,
        R.CanRead, R.CanWrite
FROM    Dictionary.Roles R WITH (NOLOCK)
JOIN    Dictionary.Objects O WITH (NOLOCK) ON O.ObjectID = R.ObjectID
ORDER BY R.RoleID;

-- Find all write-enabled roles
SELECT  RoleID, RoleName, RoleDesc
FROM    Dictionary.Roles WITH (NOLOCK)
WHERE   CanWrite = 1
ORDER BY RoleID;

-- Check which groups have access to a specific object
SELECT  G.GroupName, R.RoleName, R.CanRead, R.CanWrite
FROM    Dictionary.Groups G WITH (NOLOCK)
JOIN    Internal.GroupsAndRoles GAR WITH (NOLOCK) ON GAR.GroupID = G.GroupID
JOIN    Dictionary.Roles R WITH (NOLOCK) ON R.RoleID = GAR.RoleID
WHERE   R.ObjectID = 1
ORDER BY G.GroupName;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table. The permission model is documented through the `Internal.CheckSinglePermission` procedure's inline XML schema comments.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (36 rows), codebase traced (1 procedure consumer, 1 FK table, 1 junction table)*
