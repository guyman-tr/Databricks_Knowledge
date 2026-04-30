# Eligibility.StatusMap

> Configuration table that resolves a customer's effective crypto eligibility status by combining the group-level status (country/tier) with the customer-level override status.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Table |
| **Key Identifier** | Id (int, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table is the status resolution matrix at the heart of the Eligibility system. It answers the question: "Given a group-level eligibility setting and an optional customer-level override, what is this customer's effective crypto access status?" The platform assigns eligibility at two levels - groups (country, account tier) define a baseline, and individual customer overrides can restrict or adjust access. This table resolves conflicts between those two layers.

Without this table, the system would need hardcoded resolution logic to determine what happens when a group says "AllOperations" but the customer has been individually set to "ReadOnly." By storing the resolution matrix in a database table, the business can modify conflict resolution rules without deploying code changes. The Confluence HLD (July 2024) describes this as the "condition table" that resolves "group vs individual status conflicts at the application level."

The table is read by `Eligibility.GetResolvedAllowedUsingWalletStatus` (direct lookup by GroupValue + CustomerValue) and `Eligibility.GetEligibilityStatusMap` (full table dump for caching). It is also referenced by `Eligibility.AllowedUpdateStatusMap` which uses the StatusMap rows as context for determining which status transitions are permitted.

---

## 2. Business Logic

### 2.1 Two-Layer Status Resolution

**What**: Resolves the effective eligibility status from a group-level and customer-level input pair.

**Columns/Parameters Involved**: `GroupValue`, `CustomerValue`, `Status`

**Rules**:
- When `CustomerValue` is NULL (no customer-level override), `Status` equals `GroupValue` - the group setting applies directly
- When `GroupValue` = BlockedFromAccess (0), `Status` is ALWAYS BlockedFromAccess (0) regardless of `CustomerValue` - a group-level block cannot be overridden by any individual setting
- When `CustomerValue` = BlockedFromAccess (0), `Status` is ALWAYS BlockedFromAccess (0) - an individual block always takes effect
- The general rule is "most restrictive wins": the resolved status is always equal to or more restrictive than both inputs
- AllOperationsForExistingUsersOnly (3) is treated as more restrictive than AllOperations (2) but less restrictive than ReadOnly (1)

**Diagram**:
```
Resolution Priority (most restrictive wins):
  BlockedFromAccess (0)  -- highest restriction, always wins
  > ReadOnly (1)
  > AllOperationsForExistingUsersOnly (3)
  > AllOperations (2)    -- least restrictive

Examples:
  Group=AllOperations + Customer=NULL      -> AllOperations (group applies)
  Group=AllOperations + Customer=ReadOnly  -> ReadOnly (customer restricts)
  Group=Blocked       + Customer=AllOps    -> Blocked (group block wins)
  Group=ReadOnly      + Customer=AllOps    -> ReadOnly (group more restrictive)
```

### 2.2 Complete Resolution Matrix

**What**: All 20 possible combinations of group and customer eligibility statuses.

**Columns/Parameters Involved**: `GroupValue`, `CustomerValue`, `Status`

**Rules**:
- 4 rows have `CustomerValue` = NULL (one per GroupValue) - baseline with no customer override
- 16 rows cover all 4x4 combinations of GroupValue x CustomerValue
- The resolved Status follows the "most restrictive wins" pattern consistently across all combinations

---

## 3. Data Overview

| Id | GroupValue | CustomerValue | Status | Meaning |
|---|---|---|---|---|
| 1 | 2 (AllOps) | NULL | 2 (AllOps) | No customer override - group grants full access, so effective status is full access. |
| 3 | 2 (AllOps) | 1 (ReadOnly) | 1 (ReadOnly) | Customer individually restricted to ReadOnly despite group allowing all operations. The more restrictive customer-level setting wins. |
| 12 | 0 (Blocked) | 2 (AllOps) | 0 (Blocked) | Group is blocked - even though customer has an AllOperations override, the group block cannot be overridden. Blocked always wins. |
| 7 | 1 (ReadOnly) | 2 (AllOps) | 1 (ReadOnly) | Group limits to ReadOnly. Customer has AllOperations override, but the group restriction is more restrictive and wins. |
| 17 | 3 (ExistingOnly) | 2 (AllOps) | 3 (ExistingOnly) | Group limits to existing users only. Customer AllOperations override does not lift this restriction - ExistingOnly is more restrictive. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Surrogate primary key identifying each unique combination in the resolution matrix. 20 rows total (4 group values x 5 customer values including NULL). Referenced by Eligibility.AllowedUpdateStatusMap via StatusMapId FK. |
| 2 | GroupValue | tinyint | NO | - | VERIFIED | Group-level eligibility status derived from the customer's country, account tier, or other group attributes. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. This is the "AllowedUsingWalletStatus" from InfraSetting, per HLD. See [Eligibility Statuses](../_glossary.md#eligibility-statuses). |
| 3 | CustomerValue | tinyint | YES | - | VERIFIED | Customer-level eligibility override, set individually via BackOffice or API. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. NULL means no customer-level override exists - the group status applies directly. Per HLD: "AllowedUsingWalletStatusCustomerLevel." |
| 4 | Status | tinyint | NO | - | VERIFIED | Resolved effective eligibility status after applying conflict resolution between GroupValue and CustomerValue. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. This is the final status returned by `Eligibility.GetResolvedAllowedUsingWalletStatus` and consumed by all services that validate crypto access. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GroupValue | Dictionary.EligibilityStatuses | FK | Group-level eligibility tier from settings/infrastructure |
| CustomerValue | Dictionary.EligibilityStatuses | FK | Customer-level eligibility override (nullable - NULL means no override) |
| Status | Dictionary.EligibilityStatuses | FK | Resolved effective eligibility status after conflict resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Eligibility.AllowedUpdateStatusMap | StatusMapId | FK | Links permitted status transitions to specific GroupValue/CustomerValue contexts |
| Eligibility.GetResolvedAllowedUsingWalletStatus | FROM source | READER | Looks up resolved Status for a given GroupValue + CustomerValue pair |
| Eligibility.GetEligibilityStatusMap | FROM source | READER | Returns all rows for application-level caching of the resolution matrix |
| Eligibility.GetAllowedUpdateCustomerValuesStatuses | JOIN source | READER | JOINs with AllowedUpdateStatusMap to find permitted transitions for a given context |

---

## 6. Dependencies

This object has no code-level dependencies. All FK targets are Dictionary tables (external schema).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EligibilityStatuses | Table | FK target for GroupValue, CustomerValue, and Status columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.AllowedUpdateStatusMap | Table | FK via StatusMapId - associates permitted transitions with resolution contexts |
| Eligibility.GetResolvedAllowedUsingWalletStatus | Stored Procedure | READER - resolves effective status for a GroupValue + CustomerValue pair |
| Eligibility.GetEligibilityStatusMap | Stored Procedure | READER - dumps entire matrix for caching |
| Eligibility.GetAllowedUpdateCustomerValuesStatuses | Stored Procedure | READER - JOINs to find allowed transitions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StatusMap | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_StatusMap_CustomerValue | FOREIGN KEY | CustomerValue -> Dictionary.EligibilityStatuses(Id). Ensures customer override is a valid eligibility tier. |
| FK_StatusMap_GroupValue | FOREIGN KEY | GroupValue -> Dictionary.EligibilityStatuses(Id). Ensures group status is a valid eligibility tier. |
| FK_StatusMap_Status | FOREIGN KEY | Status -> Dictionary.EligibilityStatuses(Id). Ensures resolved status is a valid eligibility tier. |

---

## 8. Sample Queries

### 8.1 Resolve effective eligibility for a group/customer combination
```sql
SELECT Status
FROM Eligibility.StatusMap WITH (NOLOCK)
WHERE GroupValue = @GroupValue
  AND CustomerValue = @CustomerValue
```

### 8.2 Show full resolution matrix with human-readable labels
```sql
SELECT sm.Id,
    gv.Name AS GroupStatus, cv.Name AS CustomerOverride, rs.Name AS ResolvedStatus
FROM Eligibility.StatusMap sm WITH (NOLOCK)
LEFT JOIN Dictionary.EligibilityStatuses gv WITH (NOLOCK) ON gv.Id = sm.GroupValue
LEFT JOIN Dictionary.EligibilityStatuses cv WITH (NOLOCK) ON cv.Id = sm.CustomerValue
JOIN Dictionary.EligibilityStatuses rs WITH (NOLOCK) ON rs.Id = sm.Status
ORDER BY sm.Id
```

### 8.3 Find all combinations where customer override has no effect (resolved = group)
```sql
SELECT sm.Id, gv.Name AS GroupStatus, cv.Name AS CustomerOverride
FROM Eligibility.StatusMap sm WITH (NOLOCK)
JOIN Dictionary.EligibilityStatuses gv WITH (NOLOCK) ON gv.Id = sm.GroupValue
LEFT JOIN Dictionary.EligibilityStatuses cv WITH (NOLOCK) ON cv.Id = sm.CustomerValue
WHERE sm.Status = sm.GroupValue AND sm.CustomerValue IS NOT NULL
ORDER BY sm.Id
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [User Eligibility Status Update HLD](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/12488704146) | Confluence | Describes this table (originally "Eligibility.CombinedStatuses") as the condition table that resolves group vs individual status conflicts. Provides the complete resolution matrix and identifies the Eligibility Service as the single consumer. Confirms GroupValue maps to "AllowedUsingWalletStatus" and CustomerValue maps to "AllowedUsingWalletStatusCustomerLevel." |

---

*Generated: 2026-04-15 | Quality: 9.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.StatusMap | Type: Table | Source: WalletDB/Eligibility/Tables/Eligibility.StatusMap.sql*
