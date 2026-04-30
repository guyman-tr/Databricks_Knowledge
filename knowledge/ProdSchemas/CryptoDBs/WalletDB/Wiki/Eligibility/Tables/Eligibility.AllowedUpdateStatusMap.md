# Eligibility.AllowedUpdateStatusMap

> Configuration table defining which customer-level eligibility status transitions are permitted for each current group/customer status combination, enforcing the transition rules from the eligibility HLD.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table is the transition enforcement matrix for customer-level eligibility changes. While `Eligibility.StatusMap` resolves what a customer's effective status IS, this table determines what a customer's status CAN BE CHANGED TO. It prevents invalid transitions - for example, when a group is set to "BlockedFromAccess," you cannot upgrade a customer to "AllOperations" regardless of their current customer-level status.

Without this table, the Eligibility Service would need hardcoded transition rules, making it impossible for the business to adjust permitted transitions without code changes. The table encodes the "acceptance/rejection criteria" from the Eligibility HLD, which defines for each combination of group status and current customer status, which new customer-level values are legal targets.

The table is read by `Eligibility.GetAllowedUpdateCustomerValuesStatuses`, which JOINs it with `Eligibility.StatusMap` to answer: "Given a GroupValue and CustomerValue, what values can the CustomerValue be changed to?" The Eligibility Service calls this before accepting a set-status request, rejecting any transition not in this table.

---

## 2. Business Logic

### 2.1 Transition Enforcement Rules

**What**: Controls which customer-level eligibility changes are permitted based on the current group + customer context.

**Columns/Parameters Involved**: `StatusMapId`, `AllowedUpdateCustomerValue`

**Rules**:
- Each row says: "When the current situation is StatusMapId X, you may set the customer value to AllowedUpdateCustomerValue Y"
- If no row exists for a given StatusMapId + target value, the transition is REJECTED
- When Group=Blocked and Customer=Blocked (StatusMapId 14), NO transitions are allowed at all - the customer is fully locked
- When Group=Blocked, only BlockedFromAccess (0) and ReadOnly (34) are ever permitted as targets
- You can never upgrade a customer to AllOperations (2) when the group restricts it
- The "most restrictive wins" principle from StatusMap carries over: transitions that would result in a less restrictive resolved status than the group allows are blocked

### 2.2 Context-Sensitive Permission Cardinality

**What**: Different group/customer contexts allow different numbers of target transitions.

**Columns/Parameters Involved**: `StatusMapId`, `AllowedUpdateCustomerValue`

**Rules**:
- Group=AllOperations contexts (StatusMapId 1-5) allow the most transitions (2-3 targets each)
- Group=ReadOnly contexts (StatusMapId 6-10) allow fewer transitions (1-2 targets)
- Group=Blocked contexts (StatusMapId 11-15) allow the fewest transitions (mostly just BlockedFromAccess)
- Group=ExistingUsersOnly contexts (StatusMapId 16-20) allow 2-3 targets similar to AllOperations

**Diagram**:
```
Transition Permissions by Group Level:

Group=AllOperations:     2-3 targets per context (most flexible)
Group=ExistingUsersOnly: 2-3 targets per context
Group=ReadOnly:          1-2 targets per context (restrictive)
Group=Blocked:           0-1 targets per context (most restrictive)

Example: Group=AllOperations, Customer=NULL (StatusMapId 1):
  Allowed targets: [BlockedFromAccess, ReadOnly]
  Blocked targets: [AllOperations (already at this level), ExistingUsersOnly]
```

---

## 3. Data Overview

| Id | AllowedUpdateCustomerValue | StatusMapId | GroupName | CustomerName | Meaning |
|---|---|---|---|---|---|
| 1 | 0 (Blocked) | 1 | AllOperations | NULL | When group grants full access and no customer override exists, you may block the customer. This is the compliance restriction path. |
| 2 | 1 (ReadOnly) | 1 | AllOperations | NULL | When group grants full access and no customer override exists, you may set customer to ReadOnly. Partial restriction. |
| 7 | 2 (AllOps) | 3 | AllOperations | ReadOnly | When group=AllOps but customer was restricted to ReadOnly, you may restore full access. This is the unblock/upgrade path. |
| 21 | 0 (Blocked) | 12 | Blocked | AllOperations | When group is Blocked but customer has AllOps override, you can only set to Blocked. The group block prevents any non-blocked target. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Surrogate primary key. 35 rows total, each representing one permitted transition for a specific group/customer context. |
| 2 | AllowedUpdateCustomerValue | tinyint | NO | - | VERIFIED | The target customer-level eligibility status that is permitted for this context. FK to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. This is the value that the API/BackOffice can set the customer to. Queried by `Eligibility.GetAllowedUpdateCustomerValuesStatuses`. |
| 3 | StatusMapId | int | NO | - | VERIFIED | FK to Eligibility.StatusMap identifying the current group/customer context. Links to the resolution matrix to determine which combination of GroupValue + CustomerValue this transition rule applies to. The JOIN in `GetAllowedUpdateCustomerValuesStatuses` filters by `sm.GroupValue = @GroupValue AND sm.CustomerValue = @CustomerValue`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AllowedUpdateCustomerValue | Dictionary.EligibilityStatuses | FK | The permitted target status for this transition rule |
| StatusMapId | Eligibility.StatusMap | FK | The current group/customer context this rule applies to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Eligibility.GetAllowedUpdateCustomerValuesStatuses | FROM source | READER | Queries this table JOINed with StatusMap to find permitted targets for a given context |

---

## 6. Dependencies

```
Eligibility.AllowedUpdateStatusMap (table)
+-- Eligibility.StatusMap (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.StatusMap | Table | FK target for StatusMapId - provides the group/customer context |
| Dictionary.EligibilityStatuses | Table | FK target for AllowedUpdateCustomerValue |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.GetAllowedUpdateCustomerValuesStatuses | Stored Procedure | READER - queries permitted transitions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AllowedUpdateStatusMap | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_AllowedUpdateStatusMap_AllowedUpdateCustomerValue | FOREIGN KEY | AllowedUpdateCustomerValue -> Dictionary.EligibilityStatuses(Id). Ensures target status is a valid tier. |
| FK_AllowedUpdateStatusMap_StatusMap | FOREIGN KEY | StatusMapId -> Eligibility.StatusMap(Id). Ensures context references a valid group/customer combination. |

---

## 8. Sample Queries

### 8.1 Find allowed transitions for a specific group/customer context
```sql
SELECT aum.AllowedUpdateCustomerValue, es.Name AS AllowedTarget
FROM Eligibility.AllowedUpdateStatusMap aum WITH (NOLOCK)
INNER JOIN Eligibility.StatusMap sm WITH (NOLOCK) ON aum.StatusMapId = sm.Id
JOIN Dictionary.EligibilityStatuses es WITH (NOLOCK) ON es.Id = aum.AllowedUpdateCustomerValue
WHERE sm.GroupValue = @GroupValue
  AND ((@CustomerValue IS NULL AND sm.CustomerValue IS NULL)
       OR sm.CustomerValue = @CustomerValue)
```

### 8.2 Show full transition matrix with readable labels
```sql
SELECT gv.Name AS GroupStatus, cv.Name AS CurrentCustomer,
    es.Name AS AllowedTarget
FROM Eligibility.AllowedUpdateStatusMap aum WITH (NOLOCK)
JOIN Eligibility.StatusMap sm WITH (NOLOCK) ON aum.StatusMapId = sm.Id
JOIN Dictionary.EligibilityStatuses gv WITH (NOLOCK) ON gv.Id = sm.GroupValue
LEFT JOIN Dictionary.EligibilityStatuses cv WITH (NOLOCK) ON cv.Id = sm.CustomerValue
JOIN Dictionary.EligibilityStatuses es WITH (NOLOCK) ON es.Id = aum.AllowedUpdateCustomerValue
ORDER BY sm.GroupValue, sm.CustomerValue, aum.AllowedUpdateCustomerValue
```

### 8.3 Find contexts with the most/fewest allowed transitions
```sql
SELECT sm.Id AS StatusMapId, gv.Name AS GroupStatus, cv.Name AS CustomerStatus,
    COUNT(*) AS AllowedTransitions
FROM Eligibility.AllowedUpdateStatusMap aum WITH (NOLOCK)
JOIN Eligibility.StatusMap sm WITH (NOLOCK) ON aum.StatusMapId = sm.Id
JOIN Dictionary.EligibilityStatuses gv WITH (NOLOCK) ON gv.Id = sm.GroupValue
LEFT JOIN Dictionary.EligibilityStatuses cv WITH (NOLOCK) ON cv.Id = sm.CustomerValue
GROUP BY sm.Id, gv.Name, cv.Name
ORDER BY AllowedTransitions DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [User Eligibility Status Update HLD](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/12488704146) | Confluence | Originally named "Eligibility.PotentialNewCustomerValues" in the HLD. Contains the complete "acceptance/rejection criteria" matrix that this table implements. Confirms that the Eligibility Service must check this table before accepting any status change request, returning a specific error code when a transition is not allowed. |

---

*Generated: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.AllowedUpdateStatusMap | Type: Table | Source: WalletDB/Eligibility/Tables/Eligibility.AllowedUpdateStatusMap.sql*
