# History.ManagerToPermission

> Trigger-based audit log recording every permission grant and revocation for BackOffice managers, capturing the full history of who gained or lost which access rights in the back office system.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on ID) |

---

## 1. Business Meaning

History.ManagerToPermission records every permission change in the back office access control system. BackOffice.ManagerToPermission holds the current set of permissions for each back office manager (the live access control table). Whenever a permission is granted (INSERT) or revoked (DELETE) in the live table, the trigger Tr_BackOffice_ManagerToPermission writes one row here, creating an immutable chronological audit trail.

This audit table satisfies financial services compliance requirements around access control. Regulators and internal audit teams can answer questions like: "Who had access to instrument X on date Y?", "When was manager Z's access revoked?", "Which permissions were added during the onboarding of manager 729?" The SystrmUser, AppName, and HostName columns capture the technical context of who triggered the database change.

With ~5 million rows (active production-level accumulation in the test environment), this is a heavily used audit table written on every permission assignment through the BackOffice application.

---

## 2. Business Logic

### 2.1 IsNew Flag - Grant vs Revoke Pattern

**What**: The trigger uses SQL Server's Inserted and Deleted pseudo-tables to record both granted (IsNew=1) and revoked (IsNew=0) permissions, mirroring the same pattern used in History.Maintenance and History.ManagerToPermission (Deleted=old, Inserted=new).

**Columns/Parameters Involved**: `IsNew`, `ManagerID`, `PermissionID`, `ProviderID`, `Occurred`

**Rules**:
- INSERT into BackOffice.ManagerToPermission: one row with IsNew=1 (permission granted)
- DELETE from BackOffice.ManagerToPermission: one row with IsNew=0 (permission revoked)
- UPDATE is not typical for this join table (the PK is the permission itself) - but if it occurs, both IsNew=0 (old) and IsNew=1 (new) rows are written
- Multiple permissions can be granted simultaneously (e.g., ManagerAdd assigns all permissions at once), producing multiple rows with the same Occurred timestamp

**Diagram**:
```
Maintenance.ManagerAdd creates a new BackOffice manager:
  INSERT BackOffice.ManagerToPermission(ManagerID=729, PermissionID=1, ProviderID=1)
  INSERT BackOffice.ManagerToPermission(ManagerID=729, PermissionID=2, ProviderID=1)
  ...
  INSERT BackOffice.ManagerToPermission(ManagerID=729, PermissionID=N, ProviderID=1)

  --> Trigger fires for each INSERT, writing to History:
  ID=4940149, IsNew=1, ManagerID=729, PermissionID=1, ProviderID=1, AppName=BackOffice
  ID=4940150, IsNew=1, ManagerID=729, PermissionID=2, ProviderID=1, AppName=BackOffice
  ...

Later: Maintenance.ManagerEdit removes a permission:
  DELETE BackOffice.ManagerToPermission WHERE ManagerID=729 AND PermissionID=3

  --> Trigger fires, writing:
  ID=5000001, IsNew=0, ManagerID=729, PermissionID=3, ProviderID=1, AppName=BackOffice
```

### 2.2 Context Capture - Who Made the Change

**What**: The SystrmUser, AppName, and HostName columns automatically capture the technical context of the database session that triggered the permission change, providing a technical audit trail beyond just what changed.

**Columns/Parameters Involved**: `SystrmUser`, `AppName`, `HostName`

**Rules**:
- SystrmUser: SQL Server login making the change (from suser_sname() - e.g., "BOUser_stg", "BOUser_prod")
- AppName: Application name from SQL Server connection string (from app_name() - e.g., "BackOffice")
- HostName: Machine name from SQL Server connection (from host_name() - e.g., "stg-bo-we01", "prod-bo-we03")
- These DEFAULT values are captured at INSERT time from the trigger's session context
- All three are sysname type (nvarchar(128)) - SQL Server system identifier type

---

## 3. Data Overview

| ID | IsNew | ManagerID | PermissionID | ProviderID | SystrmUser | AppName | HostName | Meaning |
|---|---|---|---|---|---|---|---|---|
| 4940149 | 1 | 729 | 1 | 1 | BOUser_stg | BackOffice | stg-bo-we01 | Permission 1 granted to ManagerID 729 in ProviderID 1. Part of a batch of 5 permissions (IDs 4940149-4940153) granted simultaneously on 2026-03-17. Executed from the staging BackOffice server (stg-bo-we01). |
| 4940150 | 1 | 729 | 2 | 1 | BOUser_stg | BackOffice | stg-bo-we01 | Permission 2 granted to same manager in same batch. Same timestamp as others - all 5 permissions were assigned in one operation (likely Maintenance.ManagerAdd or Maintenance.ManagerEdit call). |
| 4940153 | 1 | 729 | 5 | 1 | BOUser_stg | BackOffice | stg-bo-we01 | Last of the 5 permissions granted (1-5) in this batch. Pattern shows ManagerID=729 was granted a standard default permission set (permissions 1-5 = likely standard BackOffice operator access level). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Auto-incrementing surrogate key. NOT FOR REPLICATION - identity does not fire during replication inserts, preserving original values on replicas. CLUSTERED PK - sequential ordering reflects chronological permission changes. High values (~5M) indicate production-level volume of permission changes over time. |
| 2 | IsNew | bit | NO | - | CODE-BACKED | Indicates whether this row records a permission grant (1=IsNew=true, from Inserted pseudo-table) or a permission revocation (0=IsNew=false, from Deleted pseudo-table). The interpretation: 1 means the manager gained this permission at Occurred time; 0 means the manager lost this permission at Occurred time. |
| 3 | ManagerID | int | NO | - | CODE-BACKED | The back office manager whose permissions changed. References BackOffice.Manager.ManagerID (no FK enforced here - history must persist even if the manager account is deleted). Used to reconstruct the full permission history of any specific operator. |
| 4 | PermissionID | int | NO | - | CODE-BACKED | The specific permission being granted or revoked. References Dictionary.Permission.PermissionID (no FK enforced here). PermissionIDs classify what operations a back office manager can perform (e.g., view customer data, approve KYC, process refunds). The exact permission meanings are in Dictionary.Permission. |
| 5 | ProviderID | int | NO | - | CODE-BACKED | The provider/broker scope for which the permission applies. BackOffice managers may have different permissions for different providers (e.g., eToro UK vs eToro Europe). ProviderID=1 is the default/primary provider. No FK enforced. |
| 6 | Occurred | datetime | YES | getdate() | CODE-BACKED | Local server timestamp when the trigger fired and wrote this row. Note: uses getdate() (local time) not UTC. Multiple permission rows from the same batch operation share the same Occurred timestamp. NULL is theoretically possible if the default does not apply, but should not occur in practice. |
| 7 | SystrmUser | sysname | NO | suser_sname() | CODE-BACKED | The SQL Server database login name of the session that performed the BackOffice.ManagerToPermission DML. sysname is nvarchar(128). DEFAULT = suser_sname() captured at trigger execution. Examples: "BOUser_stg" (staging BackOffice service account), "BOUser_prod" (production service account). Identifies the DB-level identity, which may be a shared service account. |
| 8 | AppName | sysname | NO | app_name() | CODE-BACKED | The application name reported by the SQL Server connection that performed the DML. DEFAULT = app_name() from the connection's Application Name property. Example: "BackOffice" for the BackOffice web application. Distinguishes permission changes from the UI versus admin scripts or automated processes. |
| 9 | HostName | sysname | NO | host_name() | CODE-BACKED | The machine hostname of the client that opened the SQL Server connection. DEFAULT = host_name() from the connection. Examples: "stg-bo-we01" (staging BackOffice web server 1), "prod-bo-we03" (production). Useful for tracing which specific server instance processed the permission change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerID | BackOffice.Manager | Implicit | References the manager whose permissions changed. No FK enforced. |
| PermissionID | Dictionary.Permission | Implicit | References the specific permission type. No FK enforced. |
| ProviderID | (provider reference) | Implicit | Provider scope for the permission. No FK enforced. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.ManagerToPermission | Tr_BackOffice_ManagerToPermission | Writer (trigger) | The ONLY writer - trigger fires on INSERT/UPDATE/DELETE |
| BackOffice.LogIn | ManagerID | Reader | Reads permission history during back office login flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ManagerToPermission (table)
  - No code-level dependencies (leaf table, populated by trigger)
  - Source: BackOffice.ManagerToPermission (table) via Tr_BackOffice_ManagerToPermission trigger
```

### 6.1 Objects This Depends On

No dependencies. Written automatically by trigger.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.ManagerToPermission | Table | Source table - trigger Tr_BackOffice_ManagerToPermission fires on all DML |
| BackOffice.LogIn | Stored Procedure | Reader - references this table during back office authentication |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed PK) | PRIMARY KEY | Clustered PK on ID |
| DEFAULT | DEFAULT | Occurred = getdate() |
| DEFAULT | DEFAULT | SystrmUser = suser_sname() |
| DEFAULT | DEFAULT | AppName = app_name() |
| DEFAULT | DEFAULT | HostName = host_name() |

---

## 8. Sample Queries

### 8.1 Get the full permission history for a specific manager

```sql
SELECT
    ID,
    CASE IsNew WHEN 1 THEN 'Granted' ELSE 'Revoked' END AS Action,
    PermissionID,
    ProviderID,
    Occurred,
    SystrmUser,
    AppName,
    HostName
FROM [History].[ManagerToPermission] WITH (NOLOCK)
WHERE ManagerID = 729
ORDER BY Occurred DESC
```

### 8.2 Get current effective permissions per manager (latest state)

```sql
-- Permissions currently granted (last action was IsNew=1, no subsequent revoke)
SELECT h.ManagerID, h.PermissionID, h.ProviderID, h.Occurred AS GrantedAt
FROM [History].[ManagerToPermission] h WITH (NOLOCK)
WHERE h.IsNew = 1
  AND NOT EXISTS (
    SELECT 1 FROM [History].[ManagerToPermission] h2 WITH (NOLOCK)
    WHERE h2.ManagerID = h.ManagerID
      AND h2.PermissionID = h.PermissionID
      AND h2.ProviderID = h.ProviderID
      AND h2.IsNew = 0
      AND h2.Occurred > h.Occurred
  )
ORDER BY h.ManagerID, h.PermissionID
```

### 8.3 Audit all permission changes in a date range with permission names

```sql
SELECT
    h.Occurred,
    CASE h.IsNew WHEN 1 THEN 'Granted' ELSE 'Revoked' END AS Action,
    h.ManagerID,
    p.PermissionDescription,
    h.ProviderID,
    h.SystrmUser,
    h.AppName,
    h.HostName
FROM [History].[ManagerToPermission] h WITH (NOLOCK)
JOIN [Dictionary].[Permission] p WITH (NOLOCK) ON p.PermissionID = h.PermissionID
WHERE h.Occurred >= DATEADD(DAY, -30, GETDATE())
ORDER BY h.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (BackOffice.LogIn reference) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.ManagerToPermission | Type: Table | Source: etoro/etoro/History/Tables/History.ManagerToPermission.sql*
