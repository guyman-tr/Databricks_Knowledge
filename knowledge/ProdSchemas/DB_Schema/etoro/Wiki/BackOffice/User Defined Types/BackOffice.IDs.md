# BackOffice.IDs

> General-purpose table-valued parameter type for passing a set of unique integer IDs to stored procedures as an IN-list filter, with strict duplicate rejection.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | ID (CLUSTERED PK, IGNORE_DUP_KEY=OFF) |
| **Partition** | N/A |
| **Indexes** | 1 (CLUSTERED PK on ID ASC) |

---

## 1. Business Meaning

`BackOffice.IDs` is a general-purpose Table-Valued Type (TVT) that acts as a typed IN-list for integer IDs. Instead of passing comma-separated strings or using dynamic SQL for IN-clause filters, stored procedures accept `@SomeIds AS BackOffice.IDs READONLY` and JOIN or filter against it. This is the standard mechanism for multi-value integer filtering across BackOffice procedures.

This type exists to replace ad-hoc string-split techniques with a type-safe, indexed collection. The CLUSTERED PK on `ID` makes JOIN operations against the TVT efficient and guarantees uniqueness - if the caller accidentally passes the same ID twice, the insert raises an error (IGNORE_DUP_KEY=OFF), making the duplicate visible and debuggable.

Data flows into this type from application code or the back-office UI. Callers declare a variable of this type, INSERT the relevant IDs (player statuses, redeem IDs, user group IDs, etc.), and pass it READONLY to the procedure. The procedure uses `SELECT ID FROM @ids` or `IN (SELECT ID FROM @ids)` for filtering.

---

## 2. Business Logic

### 2.1 IGNORE_DUP_KEY=OFF - Strict Deduplication Contract

**What**: The PK's IGNORE_DUP_KEY=OFF flag means inserting a duplicate ID raises an error rather than silently skipping it - the caller is responsible for providing a deduplicated set.

**Columns/Parameters Involved**: `ID`

**Rules**:
- Every ID in the set must be unique. Duplicates raise a primary key violation error.
- This is intentional: if a caller accidentally passes duplicate IDs, the error surfaces immediately rather than silently filtering to distinct values.
- Contrast with `BackOffice.IDs_DUP` (sibling type) where IGNORE_DUP_KEY=ON silently ignores duplicates - used when the caller's source data may legitimately contain repeats.

**Diagram**:
```
Correct usage:
  INSERT INTO @ids VALUES (1),(2),(3)  -> OK, 3 distinct IDs

Incorrect usage:
  INSERT INTO @ids VALUES (1),(1),(2)  -> ERROR: Primary key violation on ID=1
  (Caller must DISTINCT their source data before inserting)
```

---

## 3. Data Overview

N/A for User Defined Type. This is a transient parameter container, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Generic integer identifier. The semantics depend on context: in BackOffice.GetBlockedCustomers it represents PlayerStatusIDs, PlayerStatusReasonIDs, and PlayerStatusSubReasonIDs; in BackOffice.IsApprovedByAllUserGroups it represents RedeemIDs and UserGroupIDs; in BackOffice.GetCashActivities it represents UnsupportedFundingIds. The CLUSTERED PK ensures uniqueness and efficient JOIN. NOT NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. The semantic meaning of ID is context-dependent per consuming procedure.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetBlockedCustomers | @IDs, @PlayerStatusReasonIDs, @PlayerStatusSubReasonIDs | Schema contract | Filters Customer.Customer by PlayerStatusID, PlayerStatusReasonID, and PlayerStatusSubReasonID |
| BackOffice.IsApprovedByAllUserGroups | @RedeemIDs, @UserGroupIdList | Schema contract | Cross-joins redeems with required user group approvals |
| BackOffice.GetCashActivities | @UnsupportedFundingIds | Schema contract | Excludes specific FundingIDs from cash activity calculations |
| BackOffice.GetAllowedWithdrawsForAutoBreakDownFromGivenWithdraws | (parameter) | Schema contract | Filters withdrawals for auto-breakdown logic |
| BackOffice.GetBlockedCustomers_Test_JUNKYulia0325 | (parameter) | Schema contract | Test variant of GetBlockedCustomers |
| BackOffice.GetPendingClosureAccountsByLastChangeDate | (parameter) | Schema contract | Filters accounts by status IDs |
| BackOffice.GetClosedAccountsByLastChangeDate | (parameter) | Schema contract | Filters closed accounts by status IDs |
| BackOffice.GetCryptoTransferWithdrawRequests | (parameter) | Schema contract | Filters crypto withdraw requests |
| BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion | (parameter) | Schema contract | PCI-compliant crypto withdrawal detail query |
| BackOffice.GetCustomersInfo | (parameter) | Schema contract | Filters customer records by multiple ID sets |
| BackOffice.GetExtraInfoOnFixFiles | (parameter) | Schema contract | Fix file processing filter |
| BackOffice.GetMyCustomers | (parameter) | Schema contract | Used alongside Managers and PlayerLevels types to filter customer list |
| BackOffice.RedeemApprovalAdd | (parameter) | Schema contract | Adds approval records for given redeems |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

See Section 5.2 - 13 consuming stored procedures identified across BackOffice operations.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IGNORE_DUP_KEY = OFF | Index option | Duplicate ID values raise a primary key violation error - caller must provide a deduplicated set. |

---

## 8. Sample Queries

### 8.1 Filter blocked customers by specific player statuses

```sql
DECLARE @statuses BackOffice.IDs;
DECLARE @reasons BackOffice.IDs;
DECLARE @subReasons BackOffice.IDs;

-- Pass empty tables to get all (no filter applied)
-- OR insert specific status IDs to filter:
INSERT INTO @statuses VALUES (2), (4); -- Blocked statuses

EXEC BackOffice.GetBlockedCustomers
    @IDs = @statuses,
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-17',
    @PlayerStatusReasonIDs = @reasons,
    @PlayerStatusSubReasonIDs = @subReasons;
```

### 8.2 Check if all user groups have approved a set of redeems

```sql
DECLARE @redeemIds BackOffice.IDs;
DECLARE @userGroupIds BackOffice.IDs;

INSERT INTO @redeemIds VALUES (5001), (5002), (5003);
INSERT INTO @userGroupIds VALUES (1), (2), (3); -- Required approval groups

EXEC BackOffice.IsApprovedByAllUserGroups
    @RedeemIDs = @redeemIds,
    @UserGroupIdList = @userGroupIds;
```

### 8.3 Inspect IDs in the typed table before passing to a procedure

```sql
DECLARE @ids BackOffice.IDs;

INSERT INTO @ids
SELECT DISTINCT PlayerStatusID
FROM Customer.Customer WITH (NOLOCK)
WHERE AccountStatusID = 1;

SELECT COUNT(*) AS TotalStatuses,
       MIN(ID) AS MinID,
       MAX(ID) AS MaxID
FROM @ids WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.IDs | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.IDs.sql*
