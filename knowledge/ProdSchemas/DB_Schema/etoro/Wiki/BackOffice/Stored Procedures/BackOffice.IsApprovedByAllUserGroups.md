# BackOffice.IsApprovedByAllUserGroups

> Returns the subset of Redeem IDs that have been fully approved (Approved=1) by ALL specified user groups - the multi-group approval gate check for the redeem workflow.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemIDs + @UserGroupIdList (both TVPs); returns RedeemIDs that passed all-group approval |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`IsApprovedByAllUserGroups` answers the question: "Which of these redeem requests have received an Approved=1 vote from EVERY required user group?" It is the approval completeness gate in the redeem (cashout) multi-group approval workflow.

The redeem approval process requires sign-off from multiple Back Office user groups before a redeem can proceed (e.g. Compliance must approve AND Finance must approve AND Risk must approve). This SP accepts a list of redeem IDs and a list of required group IDs, then returns only those redeems where:
1. Every required group has an entry in `BackOffice.RedeemApproval` with `Approved = 1`
2. No required group has an entry with `Approved = 0` (rejected)
3. No required group is missing entirely from `BackOffice.RedeemApproval` (not yet voted)

The logic is implemented via a cartesian product CTE (all redeems x all groups) with three exclusion filters applied sequentially.

No callers found in SSDT - called by an external Back Office service managing the redeem approval workflow.

---

## 2. Business Logic

### 2.1 All-Groups Approval Gate (Three-Filter Logic)

**What**: Identifies redeems where every required group has approved and none have rejected or are pending.

**Columns/Parameters Involved**: `@RedeemIDs`, `@UserGroupIdList`, `BackOffice.RedeemApproval.Approved`

**Rules**:
- CTE `AllRedeemsWithAllGroups`: Cross joins all @RedeemIDs with all @UserGroupIdList entries, creating every required (RedeemID, UserGroupID) pair
- Main SELECT: RedeemIDs that have at least one Approved=1 entry per group (INNER JOIN on RedeemID+UserGroupID+Approved=1)
- Exclusion 1 (`NOT IN`): Removes redeems where ANY group has Approved=0 (rejected)
- Exclusion 2 (`NOT IN`): Removes redeems where ANY group has NO entry at all in RedeemApproval (missing = not yet voted)
- Result: Only redeems where all groups exist and all are approved

**Diagram**:
```
ALL (RedeemID, UserGroupID) pairs from TVPs
           |
INNER JOIN RedeemApproval WHERE Approved=1
           |
EXCLUDE: any pair with Approved=0 (at least one rejection)
EXCLUDE: any pair with no RedeemApproval row (group hasn't voted)
           |
RESULT: RedeemIDs approved by ALL groups
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemIDs | [BackOffice].[IDs] READONLY | NO | - | CODE-BACKED | TVP of redeem IDs to evaluate. The SP checks each of these against the required user groups. |
| 2 | @UserGroupIdList | [BackOffice].[IDs] READONLY | NO | - | CODE-BACKED | TVP of user group IDs that must ALL approve. The cartesian product of @RedeemIDs x @UserGroupIdList defines every required approval pair. |

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RedeemID | INT | NO | - | CODE-BACKED | Redeem ID that has been approved by all required user groups (Approved=1 for every group in @UserGroupIdList, no rejections, no missing votes). RedeemIDs NOT in the result set are either pending (some groups haven't voted) or rejected (at least one group has Approved=0). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RedeemIDs | BackOffice.RedeemApproval | Lookup | Checks approval records per redeem |
| @UserGroupIdList | BackOffice.RedeemApproval | Lookup | Checks whether each group has approved |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.IsApprovedByAllUserGroups (procedure)
├── BackOffice.IDs (user defined type) [TVP x2]
└── BackOffice.RedeemApproval (table) [3 JOIN/EXISTS checks]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.IDs | User Defined Type | TVP type for both @RedeemIDs and @UserGroupIdList |
| BackOffice.RedeemApproval | Table | Three-way check: INNER JOIN (Approved=1), INNER JOIN (Approved=0 exclusion), LEFT JOIN (missing exclusion) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by external redeem approval service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| CROSS JOIN in CTE | Logic | Cartesian product ensures every Redeem+Group pair is evaluated |
| DISTINCT | Deduplication | Removes duplicate RedeemIDs from the final result |
| NOT IN (two exclusions) | Filter | Sequential exclusion of rejected (Approved=0) and unapproved (missing) pairs |

---

## 8. Sample Queries

### 8.1 Check which redeems are fully approved by two groups

```sql
DECLARE @Redeems BackOffice.IDs;
INSERT INTO @Redeems VALUES (1001), (1002), (1003);

DECLARE @Groups BackOffice.IDs;
INSERT INTO @Groups VALUES (5), (7); -- e.g. Compliance=5, Finance=7

EXEC [BackOffice].[IsApprovedByAllUserGroups]
    @RedeemIDs = @Redeems,
    @UserGroupIdList = @Groups;
-- Returns only the RedeemIDs where both groups approved
```

### 8.2 Check current approval state for a specific redeem

```sql
SELECT
    ra.RedeemID,
    ra.UserGroupID,
    ra.Approved,
    ra.ModificationDate
FROM BackOffice.RedeemApproval WITH (NOLOCK) ra
WHERE ra.RedeemID = 1001
ORDER BY ra.UserGroupID;
```

### 8.3 Find redeems with at least one rejection

```sql
SELECT DISTINCT RedeemID
FROM BackOffice.RedeemApproval WITH (NOLOCK)
WHERE Approved = 0
  AND RedeemID IN (SELECT ID FROM BackOffice.Redeems WITH (NOLOCK) WHERE RedeemStatusID = 5);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.IsApprovedByAllUserGroups | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.IsApprovedByAllUserGroups.sql*
