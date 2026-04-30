# Eligibility.GetAllowedUpdateCustomerValuesStatuses

> Returns the list of permitted customer-level eligibility status values that can be set for a given group/customer context, enforcing the transition rules from the AllowedUpdateStatusMap.

| Property | Value |
|----------|-------|
| **Schema** | Eligibility |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns allowed AllowedUpdateCustomerValue list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the transition validation gateway. Before the Eligibility Service accepts a request to change a customer's eligibility status, it calls this procedure to determine which target values are permitted given the current GroupValue and CustomerValue. If the requested new value is not in the returned list, the change is rejected with an error.

The procedure JOINs `Eligibility.AllowedUpdateStatusMap` with `Eligibility.StatusMap` to find the matching context row and returns all permitted target values. This implements the "acceptance/rejection criteria" from the Eligibility HLD.

---

## 2. Business Logic

### 2.1 Transition Validation Lookup

**What**: Returns permitted target statuses for a given group/customer context.

**Columns/Parameters Involved**: `@GroupValue`, `@CustomerValue`

**Rules**:
- JOINs AllowedUpdateStatusMap (aum) with StatusMap (sm) ON aum.StatusMapId = sm.Id
- Filters by sm.GroupValue = @GroupValue AND handles NULL CustomerValue comparison:
  - If @CustomerValue IS NULL AND sm.CustomerValue IS NULL -> match
  - OR sm.CustomerValue = @CustomerValue -> match
- Returns the AllowedUpdateCustomerValue column for all matching rows
- If no rows returned, NO transitions are allowed (the current state is locked)
- The Eligibility Service checks if the requested new value is IN the returned list

**Diagram**:
```
Request: "Change customer 12345 from ReadOnly to AllOperations"
    |
    +-> GetAllowedUpdateCustomerValuesStatuses(@GroupValue=2, @CustomerValue=1)
    |   Returns: [0 (Blocked), 2 (AllOps), 3 (ExistingOnly)]
    |
    +-> Is "AllOperations" (2) in the list? YES -> Allow the change
    
Request: "Change customer 67890 from Blocked-group to AllOperations"
    |
    +-> GetAllowedUpdateCustomerValuesStatuses(@GroupValue=0, @CustomerValue=NULL)
    |   Returns: [0 (Blocked)]
    |
    +-> Is "AllOperations" (2) in the list? NO -> Reject with error
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GroupValue | INT (IN) | NO | - | VERIFIED | Group-level eligibility status from InfraSetting. Maps to Dictionary.EligibilityStatuses: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. |
| 2 | @CustomerValue | INT (IN) | YES | - | VERIFIED | Current customer-level eligibility override. NULL if no customer-level override exists. Maps to Dictionary.EligibilityStatuses. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AllowedUpdateCustomerValue | tinyint | NO | - | VERIFIED | A permitted target status that the customer can be changed to. Multiple rows may be returned - one per allowed target. The Eligibility Service checks if the desired new value is in this result set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Eligibility.AllowedUpdateStatusMap | JOIN source | Source of permitted transition rules |
| JOIN | Eligibility.StatusMap | JOIN | Links transition rules to group/customer contexts |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT project. Called by the Eligibility Service before accepting set-status requests.

---

## 6. Dependencies

```
Eligibility.GetAllowedUpdateCustomerValuesStatuses (procedure)
+-- Eligibility.AllowedUpdateStatusMap (table)
+-- Eligibility.StatusMap (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.AllowedUpdateStatusMap | Table | Source of permitted transition values |
| Eligibility.StatusMap | Table | JOINed to match context by GroupValue + CustomerValue |

### 6.2 Objects That Depend On This

No callers found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Find allowed transitions when group=AllOperations, customer=ReadOnly
```sql
EXEC Eligibility.GetAllowedUpdateCustomerValuesStatuses @GroupValue = 2, @CustomerValue = 1
-- Returns: 0 (BlockedFromAccess), 2 (AllOperations), 3 (AllOperationsForExistingUsersOnly)
```

### 8.2 Find allowed transitions when group=Blocked, no customer override
```sql
EXEC Eligibility.GetAllowedUpdateCustomerValuesStatuses @GroupValue = 0, @CustomerValue = NULL
-- Returns: 0 (BlockedFromAccess) -- only self-assignment allowed
```

### 8.3 Direct equivalent query
```sql
SELECT aum.AllowedUpdateCustomerValue
FROM Eligibility.AllowedUpdateStatusMap aum WITH (NOLOCK)
INNER JOIN Eligibility.StatusMap sm WITH (NOLOCK) ON aum.StatusMapId = sm.Id
WHERE sm.GroupValue = @GroupValue
  AND ((@CustomerValue IS NULL AND sm.CustomerValue IS NULL)
       OR sm.CustomerValue = @CustomerValue)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [User Eligibility Status Update HLD](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/12488704146) | Confluence | Describes the full "acceptance/rejection criteria" matrix that this procedure queries. The HLD specifies that the GW should return a specific error code when a transition is not allowed. |

---

*Generated: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Eligibility.GetAllowedUpdateCustomerValuesStatuses | Type: Stored Procedure | Source: WalletDB/Eligibility/Stored Procedures/Eligibility.GetAllowedUpdateCustomerValuesStatuses.sql*
