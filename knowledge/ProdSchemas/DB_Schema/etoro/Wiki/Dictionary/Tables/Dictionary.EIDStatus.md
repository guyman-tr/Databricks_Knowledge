# Dictionary.EIDStatus

## 1. Business Meaning

### What It Is
A lookup table defining the completion states of Electronic Identity (EID) verification for customers — tracking whether a customer has undergone identity verification and to what degree.

### Why It Exists
Regulatory KYC (Know Your Customer) requirements mandate identity verification. This table tracks the progression of electronic identity checks: from no verification attempted, through partial completion, to fully completed.

### How It's Used
Referenced by `BackOffice.Customer.EIDStatusID` to track a customer's electronic identity verification state. Read by multiple procedures including `BackOffice.UpdateRiskUserInfoRemote` (writer) and various `Customer.GetRiskUserInfo` / `Customer.GetAggregatedInfo` variants (readers) in both the etoro and UserApiDB databases.

---

## 2. Business Logic

### Verification Progression
```
None (0) ─────── No EID verification attempted
    │
    ▼
PartiallyCompleted (1) ─── Some verification steps done, not all
    │
    ▼
Completed (2) ─────── All EID verification steps passed
```

The progression is one-directional in normal flow: None → PartiallyCompleted → Completed. However, `BackOffice.UpdateRiskUserInfoRemote` can set any status directly.

---

## 3. Data Overview

| EIDStatusID | EIDStatusName |
|------------|---------------|
| 0 | None |
| 1 | PartiallyCompleted |
| 2 | Completed |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **EIDStatusID** | `int` | NO | Primary key. Verification state (0=None, 1=PartiallyCompleted, 2=Completed). | `MCP` |
| **EIDStatusName** | `varchar(50)` | YES | Status label. Nullable but all current rows have values. | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | Relationship |
|-------|--------|-------------|
| BackOffice.Customer | EIDStatusID | Implicit FK — customer's electronic identity verification state |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `BackOffice.Customer` — stores the EID status per customer
- `BackOffice.UpdateRiskUserInfoRemote` — procedure that updates customer EID status
- `Customer.GetRiskUserInfo` (etoro) — reads EID status as part of risk assessment
- `Customer.GetRiskUserInfoWithoutDocuments` (UserApiDB) — reads EID status
- `Customer.GetSingleAggregatedInfo` / `GetManyAggregatedInfo` (UserApiDB) — aggregate customer data including EID status

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `EIDStatusID` (clustered, PK_EIDStatus) |
| **Filegroup** | DICTIONARY |
| **Row Count** | 3 |
| **Identity** | No — starts at 0 |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all EID verification statuses
SELECT  EIDStatusID,
        EIDStatusName
FROM    Dictionary.EIDStatus WITH (NOLOCK)
ORDER BY EIDStatusID;

-- Count customers by EID verification state
SELECT  e.EIDStatusName,
        COUNT(*)            AS CustomerCount
FROM    BackOffice.Customer c WITH (NOLOCK)
JOIN    Dictionary.EIDStatus e WITH (NOLOCK)
        ON c.EIDStatusID = e.EIDStatusID
GROUP BY e.EIDStatusName
ORDER BY CustomerCount DESC;

-- Find customers with completed EID verification
SELECT  c.CustomerID
FROM    BackOffice.Customer c WITH (NOLOCK)
WHERE   c.EIDStatusID = 2;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
