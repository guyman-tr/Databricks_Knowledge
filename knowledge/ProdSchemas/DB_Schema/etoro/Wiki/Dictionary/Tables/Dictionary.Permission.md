# Dictionary.Permission

> Master registry of 148 BackOffice permission definitions — granular access controls covering trading operations, customer management, compliance, financial operations, CopyTrading, and administrative functions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PermissionID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK clustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.Permission defines every granular permission available in the eToro BackOffice system. Each permission controls access to a specific function, screen, or operation — from viewing customer data and processing deposits to changing compliance statuses and managing CopyTrading relationships.

This table exists because the BackOffice is used by hundreds of operators across multiple teams (sales, compliance, risk, accounting, support, management) and each team needs different access levels. The permission system allows fine-grained control: a sales agent can view customer cards but cannot approve withdrawals, while a compliance officer can change customer status but cannot process deposits.

Permissions are linked to BackOffice managers through BackOffice.ManagerToPermission (direct user-level assignment) and to user groups through Dictionary.UserGroupToPermission (group-level assignment). The combination determines what each operator can do.

---

## 2. Business Logic

### 2.1 Permission Categories

**What**: The 148 permissions organize into functional categories matching the BackOffice's operational areas.

**Columns/Parameters Involved**: `PermissionID`, `Name`, `Description`

**Rules**:
- **Tab Visibility** (1, 4-8, 31-32, 71, 74, 84-85, 110, 146-147) — Controls which BackOffice tabs/sections are visible to the operator.
- **Financial Operations** (10, 16, 22-23, 27-30, 47, 52, 54, 60-62, 67-68, 70, 73, 76, 88, 98-99, 126-127) — Deposit, withdrawal, bonus, compensation, and cashout permissions with amount tiers (Basic/Low/Medium/High).
- **Customer Management** (12, 19, 42-50, 58-59, 64-66, 72, 80, 95-96, 106, 125, 134) — Profile edits, status changes, affiliate changes, risk attributes.
- **Compliance/KYC** (46, 105-109, 111-114, 121-122, 128-133, 137-145, 148) — Document management, MiFID, KYC, AML, GDPR, regulatory gap management.
- **Trading Operations** (3, 9, 51, 53, 57, 69, 81-82, 89, 97, 103, 142) — Position management, order closure, copy block, manual execution.
- **CopyTrading** (63, 69, 81-82, 89, 137, 139) — Guru status, copy block, copied block, mirror management.
- **Championship/Gamification** (33-36) — Tournament player management.
- **Administrative** (20-21, 39-41, 43, 100-102, 104, 116-120) — User management, exports, downtime, mass operations.

### 2.2 Amount-Tiered Financial Permissions

**What**: Financial permissions use a tiered system to control maximum amounts operators can process.

**Columns/Parameters Involved**: `PermissionID` 10, 16, 54, 126

**Rules**:
- **BasicAmount (126)** — Up to $200 per operation.
- **LowAmount (10)** — Low-tier financial operations (bonuses, compensations, transfers).
- **MediumAmount (16)** — Medium-tier financial operations.
- **HighAmount (54)** — High-tier financial operations (largest amounts, most senior operators).
- Operators are typically assigned ONE tier — the system checks the highest tier they hold.

**Diagram**:
```
Financial Permission Tiers
├── 126 = BasicAmount (≤$200)
├── 10  = LowAmount
├── 16  = MediumAmount
└── 54  = HighAmount (senior operators)
```

---

## 3. Data Overview

| PermissionID | Name | Description | Meaning |
|---|---|---|---|
| 7 | BO Admin | BO Admin Tab Visible | Controls visibility of the BackOffice Admin tab — reserved for system administrators who manage platform configuration. |
| 42 | Change Customer Status | Change Customer Status | Allows changing a customer's account status (active/blocked/closed). Critical compliance permission — misuse could lock customers out of their accounts. |
| 51 | Allow close position | Allow close position | Permits closing trading positions on behalf of customers. Used by trading desk operators for error correction or compliance-mandated closures. |
| 105 | Compliance | Allow BO User Manage Compliance Data | Grants access to compliance data management — KYC document review, AML flags, regulatory status. Key permission for compliance officers. |
| 114 | RightToBeForgotten | Allow to delete this user from eToro | GDPR "right to be forgotten" — the most destructive permission. Permanently deletes customer data. Restricted to senior compliance staff. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PermissionID | int | NO | - | VERIFIED | Primary key identifying the permission. 148 values covering all BackOffice functions. Referenced by Dictionary.UserGroupToPermission (group assignment) and BackOffice.ManagerToPermission (direct user assignment). |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Unique short code for the permission. Enforced unique by DPRM_NAME index. Used programmatically in permission checks (e.g., "Allow close position", "Compliance", "RightToBeForgotten"). |
| 3 | Description | varchar(250) | YES | - | VERIFIED | Human-readable description explaining what the permission grants. Displayed in BackOffice user management screens. Some entries are empty (PermissionID 127). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.UserGroupToPermission | PermissionID | Implicit | Maps permissions to user groups |
| BackOffice.ManagerToPermission | PermissionID | Implicit | Maps permissions directly to individual managers |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.UserGroupToPermission | Table | Maps permissions to user groups |
| BackOffice.ManagerToPermission | Table | Maps permissions directly to managers |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPRM | CLUSTERED PK | PermissionID ASC | - | - | Active |
| DPRM_NAME | UNIQUE NC | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPRM | PRIMARY KEY | Unique permission identifier |
| DPRM_NAME | UNIQUE | Ensures each permission has a unique name code |

---

## 8. Sample Queries

### 8.1 List all permissions
```sql
SELECT  PermissionID,
        Name,
        Description
FROM    [Dictionary].[Permission] WITH (NOLOCK)
ORDER BY PermissionID;
```

### 8.2 Find compliance-related permissions
```sql
SELECT  PermissionID,
        Name,
        Description
FROM    [Dictionary].[Permission] WITH (NOLOCK)
WHERE   Name LIKE '%Compliance%'
   OR   Name LIKE '%KYC%'
   OR   Name LIKE '%AML%'
   OR   Name LIKE '%GDPR%'
   OR   Name LIKE '%RightToBeForgotten%'
ORDER BY PermissionID;
```

### 8.3 Find financial amount-tiered permissions
```sql
SELECT  PermissionID,
        Name,
        Description
FROM    [Dictionary].[Permission] WITH (NOLOCK)
WHERE   Name LIKE '%Amount%'
ORDER BY PermissionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Permission | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Permission.sql*
