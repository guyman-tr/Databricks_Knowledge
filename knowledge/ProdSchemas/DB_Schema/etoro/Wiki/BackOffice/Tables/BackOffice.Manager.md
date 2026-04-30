# BackOffice.Manager

> Registry of all internal eToro staff who access the BackOffice system, including their department assignment, authentication credentials, role flags, and customer management relationships.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | ManagerID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 5 active (1 clustered PK + 4 nonclustered) |

---

## 1. Business Meaning

BackOffice.Manager is the central user directory for all internal eToro employees who operate the BackOffice platform. Each row represents one staff member - a sales agent, account manager, risk analyst, compliance officer, operations specialist, or administrator. The table stores their identity (name, login, email), organizational placement (department/UserGroup), role flags (team leader, customer manager), and system access settings (active status, password change requirements, read-replica override).

Without this table the entire BackOffice system loses its authentication and authorization foundation. Every authenticated action in BackOffice traces to a ManagerID - cashout approvals, customer notes, document reviews, task assignments, downtime records, and withdrawal approvals all carry a ManagerID as the acting agent. The table is the "who did what" anchor for BackOffice audit trails.

Data flows in three directions: the BackOffice application writes rows when new staff join (INSERT) or modifies them as employment status changes (UPDATE IsActive=0 on offboarding). The authentication procedure BackOffice.LogIn reads this table on every login, checking IsActive=1 and verifying Login credentials to issue a session. Downstream objects (BackOffice.Customer, BackOffice.Task, BackOffice.Downtime, BackOffice.RedeemApproval, BackOffice.WithdrawApproval) store ManagerID foreign keys to record which staff member performed each operation.

---

## 2. Business Logic

### 2.1 Authentication Flow

**What**: BackOffice staff log in via Login/Password credentials, and the system resolves their ManagerID to authorize further actions.

**Columns Involved**: `Login`, `Password`, `IsActive`, `ManagerID`

**Rules**:
- BackOffice.LogIn matches Login (case-insensitive via LOWER()) and IsActive=1 - inactive managers cannot authenticate even with valid credentials
- On successful authentication, a row is inserted into BackOffice.Login (session record) and a Broker listener is registered
- ManagerID=0 is the "System" pseudo-manager for automated operations; ManagerID=1 is the bootstrap admin account; both are IsActive=0 in production

**Diagram**:
```
App Login Request (@Login, @Password, @ProviderID)
        |
        v
BackOffice.Manager WHERE Login=@Login AND IsActive=1
        |
    [Not found] --> Return NULL ManagerID (authentication failed)
        |
    [Found] --> @ManagerID = ManagerID
        |
        v
BackOffice.ManagerToPermission WHERE ManagerID + ProviderID --> PermissionIDs
        |
        v
INSERT BackOffice.Login (session record)
INSERT Broker.ListenerAdd (message listener)
```

### 2.2 Organizational Hierarchy

**What**: Managers are organized into departments (UserGroup) and optionally under a regional manager, forming a two-level hierarchy.

**Columns Involved**: `UserGroupID`, `RegionalManagerID`, `IsTeamLeader`, `ManagerTitleID`

**Rules**:
- UserGroupID assigns managers to departments (Administrators, Sales/Support, Account Management, Risk, Operations, Trading, Accounting, etc.) - used for permission scoping and team filtering
- RegionalManagerID is a self-referential pointer to another Manager row; used for regional offices (IBs) but 99% of internal staff have RegionalManagerID=NULL
- IsTeamLeader=1 flags team leads within a department (30 active team leads in production)
- ManagerTitleID defines job title independent of department, primarily for customer-facing roles (Sales Representative, Account Manager, Customer Success Agent)

**Diagram**:
```
Dictionary.UserGroup
    1=Administrators
    2=Operations
    7=Sales/Support  <-- UserGroupID
    8=Account Management

BackOffice.Manager (Team Leader)  <-- IsTeamLeader=1, RegionalManagerID=NULL
       |
       | RegionalManagerID (self-ref)
       v
BackOffice.Manager (Regional Manager)   <-- RegionalManagerID=NULL (top of sub-hierarchy)
       |
       | RegionalManagerID
       v
BackOffice.Manager (IB Local Office Staff)  <-- UserGroupID in 16-30 range
```

### 2.3 Database Connection Group Routing

**What**: Managers can be assigned to a database connection group that routes their queries to specific DB environments (multi-region, multi-tenant).

**Columns Involved**: `ManagerGroupID`, `OverrideReplicaSettings`

**Rules**:
- ManagerGroupID links to BackOffice.T_GroupsDictionary (group description) and BackOffice.T_ManagerAccessGroupToConnectionStrings (connection string)
- When ManagerGroupID is set, BackOffice.LoadManagerByUsername and BackOffice.LoadManagers return the ManagerGroupType from T_ManagerAccessGroupToConnectionStrings to direct the application's DB routing
- OverrideReplicaSettings=1 forces this manager's queries to the primary DB, bypassing read-replica routing (used for real-time accuracy requirements)
- 346 of 960 managers have ManagerGroupID set (primarily MimoOps and MimoApps groups)

---

## 3. Data Overview

| ManagerID | Login | UserGroupID | IsActive | ManagerTitleID | Meaning |
|-----------|-------|-------------|----------|----------------|---------|
| 0 | system | 1 (Administrators) | 0 | 1 | Pseudo-manager for system-generated operations. eToroCID=1193000 links to the system's own customer account. CalendlyID="etoro-club" is a placeholder. |
| 1 | admin | 1 (Administrators) | 0 | 1 | Bootstrap administrator account. Deactivated in production but kept as ManagerID=1 anchor for legacy foreign key references. |
| 2 | supportuse | 1 (Administrators) | 0 | 1 | Legacy eToro support account (eToroCID=1000002). Inactive but retained for historical records that reference this ManagerID. |
| 12 | support | 7 (Sales/Support) | 0 | 1 | Generic support account. LastName="*" indicates a functional/shared account rather than a named individual. |
| 13 | Bahaa | 2 (Operations) | 0 | 1 | Example of a named individual staff member (Bahaa Abdel). Note login name in parentheses shows original vs. current name - common for merged/renamed accounts. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManagerID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-generated unique integer identifier for each BackOffice staff member. PK for the entire BackOffice authorization system. ManagerID=0 is the reserved System account; ManagerID=1 is the bootstrap Admin. All BackOffice action tables (BackOffice.Customer, Task, Downtime, etc.) store ManagerID as the "acting staff" reference. |
| 2 | UserGroupID | int | NO | - | VERIFIED | Department/team assignment. FK to Dictionary.UserGroup. Determines access scope and team membership. Values: 1=Administrators, 2=Operations, 3=Risk, 4=Marketing, 5=Accounting, 6=Trading, 7=Sales/Support, 8=Account Management, 9=Sales 1, 10=Sales 2, 11-13=Account Management 1-3, 16=Local Offices (IBs), 17-30=Regional IB offices (Singapore, Brazil, Australia, etc.), 20=Support, 31=BackOffice, 32=Training, 33=Turkey, 34=MimoOps, 35=MimoApps, 36=AML. See [UserGroup](_glossary.md) for hierarchy. Largest groups: Administrators (431), Account Management (112), MimoOps (98). |
| 3 | FirstName | nvarchar(50) | NO | - | CODE-BACKED | Staff member's first name. Combined with LastName in views and procedures to produce display names (e.g., BackOffice.GetMyCustomers sets [Manager] = FirstName + ' ' + LastName). |
| 4 | LastName | nvarchar(50) | NO | - | CODE-BACKED | Staff member's last name. Combined with FirstName for display. LastName='*' indicates a functional/shared account (e.g., the generic 'support' account). |
| 5 | Login | varchar(20) | NO | - | VERIFIED | Unique username for BackOffice authentication. Used as the primary lookup key in BackOffice.LogIn (case-insensitive match via LOWER()). Has unique index BMNG_LOGIN enforcing uniqueness. Maximum 20 characters. Exposed as UserName in LoadManagers and LoadManagerByUsername procedures. |
| 6 | Password | varchar(20) | YES | - | VERIFIED | Authentication credential. Masked in application layer with partial(0, "XXXXXXXX", 0) - all characters replaced with X when queried by non-privileged users. BackOffice.GetManager view exposes this column (legacy view used by older BackOffice app versions). NULL values indicate SSO-authenticated managers or deactivated accounts. |
| 7 | Email | varchar(50) | NO | - | CODE-BACKED | Staff member's eToro corporate email address. Used by the email notification subsystem when IsEmailNotified=1. Exposed in LoadManagers, GetManagers, and related procedures for manager roster APIs. |
| 8 | IsEmailNotified | bit | NO | - | CODE-BACKED | Controls whether this manager receives automated email notifications from BackOffice system events (e.g., deposit alerts, escalation triggers). 1=email notifications enabled, 0=email silent. Exposed in LoadManagers procedure for application-side notification routing. |
| 9 | IsActive | bit | NO | - | VERIFIED | Logical soft-delete flag controlling login access and visibility. 1=active (staff currently employed, can authenticate). 0=deactivated (former staff or suspended; LOGIN is blocked by BackOffice.LogIn which checks IsActive=1). BackOffice.GetManager view filters WHERE IsActive=1, hiding deactivated managers from most application queries. Do NOT physically delete manager rows - use IsActive=0 to preserve audit history. 505 active, 455 inactive in production. |
| 10 | IsTeamLeader | bit | NO | - | CODE-BACKED | Marks this manager as a team leader within their department. 1=team leader role. 0=individual contributor. Used in LoadManagers/LoadManagerByUsername responses for role-based UI rendering. 30 active team leaders in production. |
| 11 | ForceChangePassword | bit | YES | (0) | CODE-BACKED | When set to 1, forces this manager to change their password at the next login session. Default 0 (no forced change). Used by administrators after password resets or security policy enforcement. |
| 12 | OverrideReplicaSettings | bit | YES | - | CODE-BACKED | When 1, bypasses read-replica routing for this manager's BackOffice queries, directing all reads to the primary database. Used for managers requiring real-time data accuracy (e.g., risk managers monitoring live positions). Exposed in LoadManagers and LoadManagerByUsername for application-layer routing decisions. |
| 13 | IsCustomerManager | bit | NO | (0) | VERIFIED | Indicates this manager directly manages and is responsible for a portfolio of customers. 1=customer-facing manager who appears in GetMyCustomers results. 0=back-office operations role without direct customer assignment. BackOffice.GetMyCustomers filters BackOffice.Customer WHERE ManagerID IN (@ManagerIds) - the ManagerIds parameter is the set of IsCustomerManager=1 managers. 31 active customer managers in production. |
| 14 | RegionalManagerID | int | YES | - | CODE-BACKED | Self-referential FK (no constraint defined) pointing to another Manager's ManagerID. Represents the regional manager responsible for this staff member, primarily used for IB (Introducing Broker) local offices. 951 of 960 managers have NULL (flat org structure internally). Only populated for regional office managers (UserGroupID 16-30 range) where a parent regional coordinator exists. |
| 15 | ManagerGroupID | int | YES | - | VERIFIED | FK to BackOffice.T_GroupsDictionary (no explicit constraint). Assigns this manager to a database connection group for multi-environment routing. When set, LoadManagerByUsername and LoadManagers also return ManagerGroupType from T_ManagerAccessGroupToConnectionStrings, which the application uses to select the appropriate connection string. 346 managers have this set (primarily MimoOps/MimoApps groups). NULL = default connection routing. |
| 16 | CalendlyID | nvarchar(50) | YES | - | CODE-BACKED | Calendly scheduling identifier for this manager. Exposed via GetManagers procedure for the customer-facing scheduler that lets customers book calls with their account manager. 958 of 960 managers have this populated (default value "etoro-club" used as placeholder for system/generic accounts). |
| 17 | ManagerTitleID | int | YES | - | VERIFIED | Job title classification FK to Dictionary.ManagerTitle. Values: 1=Sales Team, 2=Sales Representative, 3=Account Management Team, 4=Account Manager (note: DDL typo "Account Manger"), 5=Customer Success Agent. Exposed via GetManagers procedure. 293 managers have NULL (non-customer-facing roles: Administrators, Risk, Operations, Trading teams). Most populated: 4=Account Manager (176), 1=Sales Team (164), 3=Account Management Team (163), 2=Sales Representative (163). |
| 18 | eToroCID | int | YES | - | CODE-BACKED | The manager's own eToro customer account CID (Customer ID). Links to Customer.CustomerStatic. Many staff members are also eToro customers themselves. Exposed as CID in GetManagers procedure. 659 of 960 managers have this populated. NULL for system accounts and staff who do not have personal eToro accounts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UserGroupID | Dictionary.UserGroup | FK (WITH CHECK) | Department assignment. One UserGroup contains many Managers. |
| ManagerTitleID | Dictionary.ManagerTitle | FK (WITH CHECK) | Job title classification for customer-facing staff. |
| RegionalManagerID | BackOffice.Manager | Self-Reference | Points to the regional manager in the org hierarchy. No FK constraint - logical relationship only. |
| ManagerGroupID | BackOffice.T_GroupsDictionary | Implicit (no constraint) | DB connection group for multi-environment routing. |
| eToroCID | Customer.CustomerStatic | Implicit (no constraint) | Manager's personal customer account - cross-schema link. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | ManagerID | Implicit FK | Primary account manager assigned to this customer. |
| BackOffice.Customer | PreviousManagerID | Implicit FK | Previous manager before last reassignment. |
| BackOffice.Customer | FTDPoolManagerID | Implicit FK | Manager credited with customer's first-time deposit conversion. |
| BackOffice.Login | ManagerID | Implicit FK | Session records for all BackOffice logins by this manager. |
| BackOffice.ManagerToPermission | ManagerID | Implicit FK | Permission grants for this manager across providers. |
| BackOffice.Task | ManagerID | Implicit FK | Tasks assigned to or created by this manager. |
| BackOffice.Task | OpenedBy | Implicit FK | Manager who opened the task. |
| BackOffice.Downtime | OpenedBy | Implicit FK | Manager who opened the downtime record. |
| BackOffice.Downtime | ClosedBy | Implicit FK | Manager who closed the downtime record. |
| BackOffice.RedeemApproval | ManagerID | Implicit FK | Manager who approved/rejected the redeem. |
| BackOffice.WithdrawApproval | ManagerID | Implicit FK | Manager who approved/rejected the withdrawal. |
| BackOffice.Affiliate | ManagerID | Implicit FK | Manager responsible for this affiliate. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Manager (table)
- No code-level dependencies (tables are leaf nodes)
- FK targets: Dictionary.UserGroup (table), Dictionary.ManagerTitle (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.UserGroup | Table | FK constraint on UserGroupID - department assignment |
| Dictionary.ManagerTitle | Table | FK constraint on ManagerTitleID - job title |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetManager | View | Reads active managers with UserGroupName join - legacy BackOffice UI data source |
| BackOffice.GetCustomerNote | View | JOINs to resolve manager names in customer note history |
| BackOffice.JUNK_CashierHistory | View | References Manager for cashier history reporting (JUNK prefix = legacy/deprecated) |
| BackOffice.LogIn | Procedure | READER - authenticates manager by Login+IsActive, returns ManagerID for session |
| BackOffice.LoadManagers | Procedure | READER - loads full manager roster for application startup/cache |
| BackOffice.LoadManagerByUsername | Procedure | READER - single manager lookup by username including group info |
| BackOffice.GetManagers | Procedure | READER - manager listing API, optional filter by ManagerID |
| BackOffice.GetMyCustomers | Procedure | READER - fetches customer portfolio for a set of manager IDs |
| BackOffice.CustomerSetManagerFromDynamics | Procedure | Resolves ManagerID from Dynamics CRM integration for customer assignment |
| BackOffice.P_GetManagerId | Procedure | READER - resolves ManagerID from login for internal lookups |
| BackOffice.P_GetManagersAndGroups | Procedure | READER - manager+group combinations for admin UI |
| BackOffice.P_SetManagerGroup | Procedure | MODIFIER - updates ManagerGroupID assignment |
| BackOffice.GetCashOutRequests | Procedure | READER - joins Manager for approver name in cashout request lists |
| BackOffice.GetWithdrawRequests | Procedure | READER - joins Manager for approver name in withdrawal lists |
| BackOffice.GetAuditHistory | Procedure | READER - joins Manager to show who performed audited actions |
| BackOffice.Customer | Table | Stores ManagerID (3 FKs) - customer-manager relationships |
| BackOffice.GetManagerID | Function | READER - resolves login username to ManagerID by querying Manager.Login |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BMNG | CLUSTERED PK | ManagerID ASC | - | - | Active |
| BMNG_LOGIN | NC UNIQUE | Login ASC | - | - | Active |
| BMNG_NAME | NC UNIQUE | FirstName ASC, LastName ASC | - | - | Active |
| BMNG_USERGROUP | NC | UserGroupID ASC | - | - | Active |
| IX_BackOfficeManager_RegionalManagerID | NC | RegionalManagerID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_BMNG_FCPS | DEFAULT | ForceChangePassword = 0 - new managers do not require immediate password change by default |
| (unnamed) | DEFAULT | IsCustomerManager = 0 - new managers are not customer managers by default |
| FK_BackOfficeManager_DictionaryManagerTitle | FK | ManagerTitleID -> Dictionary.ManagerTitle(ID) |
| FK_DGRP_BMNG | FK | UserGroupID -> Dictionary.UserGroup(UserGroupID) |
| BMNG_LOGIN | UNIQUE INDEX | Login must be unique across all managers |
| BMNG_NAME | UNIQUE INDEX | FirstName + LastName combination must be unique |

---

## 8. Sample Queries

### 8.1 Get all active managers with department and title
```sql
SELECT
    m.ManagerID,
    m.FirstName + ' ' + m.LastName AS ManagerName,
    m.Login,
    m.Email,
    ug.Name AS Department,
    mt.Name AS Title,
    m.IsTeamLeader,
    m.IsCustomerManager
FROM BackOffice.Manager m WITH (NOLOCK)
LEFT JOIN Dictionary.UserGroup ug WITH (NOLOCK) ON m.UserGroupID = ug.UserGroupID
LEFT JOIN Dictionary.ManagerTitle mt WITH (NOLOCK) ON m.ManagerTitleID = mt.ID
WHERE m.IsActive = 1
ORDER BY ug.Name, m.LastName, m.FirstName
```

### 8.2 Get all customers assigned to a specific manager
```sql
SELECT
    bc.CID,
    m.FirstName + ' ' + m.LastName AS ManagerName,
    m.Email AS ManagerEmail,
    m.CalendlyID
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN BackOffice.Manager m WITH (NOLOCK) ON bc.ManagerID = m.ManagerID
WHERE bc.ManagerID = 12345  -- replace with target ManagerID
  AND m.IsActive = 1
```

### 8.3 Get managers by department with connection group routing info
```sql
SELECT
    m.ManagerID,
    m.FirstName + ' ' + m.LastName AS ManagerName,
    ug.Name AS Department,
    gd.GroupDescription AS ConnectionGroup,
    ag.ManagerGroupType,
    m.OverrideReplicaSettings
FROM BackOffice.Manager m WITH (NOLOCK)
LEFT JOIN Dictionary.UserGroup ug WITH (NOLOCK) ON m.UserGroupID = ug.UserGroupID
LEFT JOIN BackOffice.T_GroupsDictionary gd WITH (NOLOCK) ON m.ManagerGroupID = gd.ManagerGroupID
LEFT JOIN BackOffice.T_ManagerAccessGroupToConnectionStrings ag WITH (NOLOCK) ON m.ManagerGroupID = ag.ManagerGroupID
WHERE m.IsActive = 1
ORDER BY ug.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 16 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Manager | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.Manager.sql*
