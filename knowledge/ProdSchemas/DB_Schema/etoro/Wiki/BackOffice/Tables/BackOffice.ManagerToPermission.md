# BackOffice.ManagerToPermission

> Access control mapping granting specific permissions to BackOffice agents per trading provider/entity. The authorization matrix that determines which BackOffice operations each agent can perform on each regulated entity. All changes are audit-logged to History.ManagerToPermission via trigger.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (ManagerID, PermissionID, ProviderID) - composite CLUSTERED PK |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 4 active (1 clustered composite PK + 3 NC on each FK column) |

---

## 1. Business Meaning

BackOffice.ManagerToPermission is the access control list (ACL) for the BackOffice system. Each row grants one specific permission to one BackOffice agent for one provider/entity. The three-way combination (ManagerID, PermissionID, ProviderID) means the same agent can have different permissions for different regulated entities.

The table drives the BackOffice.LogIn flow: when an agent authenticates, their permissions for the requested ProviderID are loaded from this table. If no row exists for that (Manager, Permission, Provider) combination, the agent cannot perform that operation on that entity.

68,072 rows across 854 managers, 148 permissions, 3 providers. Average ~80 permissions per manager. All INSERT/UPDATE/DELETE operations are audit-logged to History.ManagerToPermission via trigger for compliance purposes.

**ProviderID semantics**: ProviderID maps to eToro's multi-entity structure - different regulated subsidiaries. ProviderID=1 (50,778 rows = 74.6%) is the primary trading entity; ProviderID=0 (17,144 rows = 25.2%) is entity-agnostic/global; ProviderID=2 (150 rows) is a secondary entity.

---

## 2. Business Logic

### 2.1 Permission Grant Model

**What**: Permissions are granted at the (Agent x Permission x Provider) level, enabling fine-grained access control per regulatory entity.

**Columns Involved**: `ManagerID`, `PermissionID`, `ProviderID`

**Rules**:
- A row EXISTS = the agent has that permission on that provider.
- A row DOES NOT EXIST = the agent does NOT have that permission on that provider.
- BackOffice.LogIn queries this table for the authenticated manager and requested ProviderID to return the agent's permission set to the client.
- Permissions are managed by BackOffice administrators (no INSERT/UPDATE/DELETE procedures found in BackOffice schema - managed directly or via application-level tools).
- 148 distinct permissions cover all BackOffice operations (customer management, document review, risk management, payments, etc.) - see Dictionary.Permission for enumeration.

### 2.2 Complete Audit Trail via Trigger

**What**: Every permission change is recorded in History.ManagerToPermission for compliance audit.

**Columns Involved**: All columns

**Rules**:
- Trigger `Tr_BackOffice_ManagerToPermission` fires on INSERT, UPDATE, DELETE.
- On INSERT: writes IsNew=1 row to History with the new values.
- On DELETE: writes IsNew=0 row to History with the old values.
- On UPDATE: writes both IsNew=0 (old) and IsNew=1 (new) rows.
- The UNION ALL in the trigger handles both Inserted and Deleted virtual tables in one statement.
- This creates a complete timeline of every permission grant and revocation.

---

## 3. Data Overview

| ProviderID | Row Count | Share | Meaning |
|-----------|-----------|-------|---------|
| 1 | 50,778 | 74.6% | Primary trading entity |
| 0 | 17,144 | 25.2% | Entity-agnostic / global permissions |
| 2 | 150 | 0.2% | Secondary entity |
| **Total** | **68,072** | | 854 unique managers, 148 unique permissions |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManagerID | int | NO | - | VERIFIED | BackOffice agent receiving the permission. Part of composite PK. FK (WITH CHECK) to BackOffice.Manager. See BackOffice.Manager for agent details. |
| 2 | PermissionID | int | NO | - | VERIFIED | The specific permission being granted. Part of composite PK. FK (WITH CHECK) to Dictionary.Permission. 148 distinct permission types covering all BackOffice operations. |
| 3 | ProviderID | int | NO | - | VERIFIED | The regulated entity/provider for which this permission applies. Part of composite PK. No FK constraint. Values: 0=global/entity-agnostic, 1=primary trading entity, 2=secondary entity. Matches the @ProviderID parameter in BackOffice.LogIn. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerID | BackOffice.Manager | FK (WITH CHECK) | Agent receiving the permission |
| PermissionID | Dictionary.Permission | FK (WITH CHECK) | Permission type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.LogIn | (ManagerID, ProviderID) | READER | Loads agent permission set on authentication |
| Tr_BackOffice_ManagerToPermission | (ManagerID, PermissionID, ProviderID) | TRIGGER | All changes logged to History.ManagerToPermission |
| History.ManagerToPermission | All columns | AUDIT TARGET | Receives IsNew=0/1 rows from trigger |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ManagerToPermission (table)
- FK targets: BackOffice.Manager, Dictionary.Permission
- Trigger writes to: History.ManagerToPermission
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | FK on ManagerID |
| Dictionary.Permission | Table | FK on PermissionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.LogIn | Procedure | READER - permission check at login |
| History.ManagerToPermission | Table | AUDIT TARGET - receives all changes via trigger |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BM2P | CLUSTERED PK | ManagerID ASC, PermissionID ASC, ProviderID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| BM2P_MANAGER | NC | ManagerID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| BM2P_PERMISSION | NC | PermissionID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| BM2P_PROVIDER | NC | ProviderID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BM2P | PK | (ManagerID, PermissionID, ProviderID) uniqueness |
| FK_BMNG_BM2P | FK (WITH CHECK) | ManagerID -> BackOffice.Manager(ManagerID) |
| FK_DPRM_BM2P | FK (WITH CHECK) | PermissionID -> Dictionary.Permission(PermissionID) |

### 7.3 Triggers

| Trigger | Event | Action |
|---------|-------|--------|
| Tr_BackOffice_ManagerToPermission | INSERT, UPDATE, DELETE | Inserts IsNew=0 (deleted) and/or IsNew=1 (inserted) rows into History.ManagerToPermission |

---

## 8. Sample Queries

### 8.1 Get all permissions for a specific agent on a provider
```sql
SELECT
    p.PermissionName,
    m.PermissionID,
    m.ProviderID
FROM BackOffice.ManagerToPermission m WITH (NOLOCK)
JOIN Dictionary.Permission p WITH (NOLOCK) ON p.PermissionID = m.PermissionID
WHERE m.ManagerID = 123
  AND m.ProviderID = 1
ORDER BY p.PermissionName
```

### 8.2 Find all agents who have a specific permission
```sql
SELECT
    mg.Login AS AgentLogin,
    mg.FirstName + ' ' + mg.LastName AS AgentName,
    m.ProviderID
FROM BackOffice.ManagerToPermission m WITH (NOLOCK)
JOIN BackOffice.Manager mg WITH (NOLOCK) ON mg.ManagerID = m.ManagerID
WHERE m.PermissionID = 50  -- replace with target permission
  AND mg.IsActive = 1
ORDER BY mg.LastName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9.2/10, Logic: 9.3/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ManagerToPermission | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.ManagerToPermission.sql*
