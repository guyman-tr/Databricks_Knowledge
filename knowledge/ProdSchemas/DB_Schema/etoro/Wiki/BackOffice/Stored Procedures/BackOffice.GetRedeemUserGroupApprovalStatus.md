# BackOffice.GetRedeemUserGroupApprovalStatus

> Returns all approval group decisions for a single redeem request - used to check which groups have approved or denied a redeem and identify any pending approvals.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemID (required); returns BackOffice.RedeemApproval rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetRedeemUserGroupApprovalStatus` is a lightweight lookup procedure that returns the complete multi-group approval decision record for a specific redeem request. In eToro's redeem workflow, redeem requests require approval from multiple Back Office user groups (compliance, risk, operations, etc.) before proceeding. Each group's decision is stored as a separate row in `BackOffice.RedeemApproval`.

This procedure allows callers to see all group decisions at once: which groups have approved, which have denied, and which have not yet acted (by checking for the absence of rows). The commented-out GRANT statement suggests that `ApprovalUserEtoro` (a BO application role) calls this procedure as part of the approval workflow.

---

## 2. Business Logic

### 2.1 Multi-Group Approval Pattern

**What**: Each redeemID can have multiple rows - one per approval user group that has acted on it.

**Columns/Parameters Involved**: `UserGroupID`, `Approved`, `ManagerID`, `Occurred`

**Rules**:
- No UserGroupID filter - returns ALL groups' decisions for the given RedeemID
- Approved = 1 (approved by this group) or 0 (denied by this group)
- A group with no row has not yet taken action (caller must infer pending status from absence)
- Multiple groups with Approved = 1 all needed for the redeem to advance to next status
- Any group with Approved = 0 blocks the redeem (Rejected status)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemID | INTEGER | NO | - | CODE-BACKED | ID of the redeem request to retrieve approval status for. Returns all BackOffice.RedeemApproval rows matching this RedeemID. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Approved | BIT | NO | - | CODE-BACKED | Whether this approval group approved the redeem. 1 = approved. 0 = denied/rejected. |
| 2 | ManagerID | INT | YES | - | CODE-BACKED | ID of the BackOffice manager who submitted this group's decision (BackOffice.RedeemApproval.ManagerID). |
| 3 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp when this group submitted their approval decision (BackOffice.RedeemApproval.Occurred). |
| 4 | RedeemID | INT | NO | - | CODE-BACKED | Echo of the input @RedeemID (BackOffice.RedeemApproval.RedeemID). Repeated in output for convenience. |
| 5 | UserGroupID | INT | NO | - | CODE-BACKED | ID of the approval user group that made this decision. Each group in the required approval chain has one row. Caller compares this list against the required groups to determine if all approvals are obtained. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RedeemID | BackOffice.RedeemApproval | Read | Returns all rows matching this RedeemID |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ApprovalUserEtoro (role) | (direct EXEC) | Application | DB role granted EXECUTE on this procedure - used by BO approval workflow application |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetRedeemUserGroupApprovalStatus (procedure)
└── BackOffice.RedeemApproval (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.RedeemApproval | Table | WHERE RedeemID = @RedeemID - returns all group approval rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | ApprovalUserEtoro application role has EXECUTE permission. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOLOCK hints | Implementation | This procedure does not use WITH (NOLOCK) - reads committed data from BackOffice.RedeemApproval for accurate approval state |
| ApprovalUserEtoro permission | Security | GRANT EXECUTE ON this procedure TO ApprovalUserEtoro (commented out in DDL - applied separately) |

---

## 8. Sample Queries

### 8.1 Get approval status for a specific redeem
```sql
EXEC [BackOffice].[GetRedeemUserGroupApprovalStatus] @RedeemID = 10001
```

### 8.2 Check which groups have approved vs pending for a redeem
```sql
SELECT RA.UserGroupID,
       CASE WHEN RA.Approved = 1 THEN 'Approved' ELSE 'Denied' END AS Decision,
       RA.ManagerID, RA.Occurred
FROM BackOffice.RedeemApproval RA WITH (NOLOCK)
WHERE RA.RedeemID = 10001
ORDER BY RA.Occurred
```

### 8.3 Find redeems waiting on a specific user group's approval
```sql
SELECT BR.RedeemID, BR.RequestDate
FROM Billing.Redeem BR WITH (NOLOCK)
WHERE BR.RedeemStatusID IN (1, 100, 3)
  AND BR.RedeemID NOT IN (
      SELECT RedeemID FROM BackOffice.RedeemApproval WITH (NOLOCK)
      WHERE UserGroupID = 5  -- Group 5 has not yet acted
  )
ORDER BY BR.RequestDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetRedeemUserGroupApprovalStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetRedeemUserGroupApprovalStatus.sql*
