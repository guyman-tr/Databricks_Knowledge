# Dictionary.DowntimeSeverity

## 1. Business Meaning

### What It Is
A lookup table defining severity levels for downtime incidents, used to prioritize incident response in the BackOffice incident management system.

### Why It Exists
Severity classification drives incident prioritization and escalation. When a downtime is reported, the severity level communicates the business impact and urgency of the issue.

### How It's Used
Referenced by `BackOffice.Downtime.DowntimeSeverityID` (explicit FK). Assigned when a downtime incident is created via `BackOffice.DowntimeAdd` and can be modified via `BackOffice.DowntimeEdit`.

---

## 2. Business Logic

### Severity Hierarchy
Standard 4-tier severity model following industry incident management practices:

```
Critical (1) ──── Complete system failure, all users affected
    │
  High (2) ────── Major functionality impaired, significant user impact
    │
 Medium (3) ───── Partial degradation, workaround available
    │
  Low (4) ─────── Minor issue, minimal user impact
```

> **Note**: IDs are sequential 1-4, with 1 being most severe. The ordering is severity-descending (Critical=1 is highest priority).

---

## 3. Data Overview

| DowntimeSeverityID | Name |
|-------------------|------|
| 1 | Critical |
| 2 | High |
| 3 | Medium |
| 4 | Low |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **DowntimeSeverityID** | `int` | NO | Primary key. Severity level (1=Critical, 2=High, 3=Medium, 4=Low). Lower value = higher severity. | `MCP` |
| **Name** | `varchar(50)` | NO | Severity label. Unique index ensures no duplicate names. | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | FK Name | Relationship |
|-------|--------|---------|-------------|
| BackOffice.Downtime | DowntimeSeverityID | FK_DDTSV_BODT | Explicit FK — severity classification of the incident |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `BackOffice.Downtime` — stores the severity level of each incident
- `BackOffice.DowntimeAdd` — sets initial severity when opening an incident
- `BackOffice.DowntimeEdit` — allows severity changes during incident lifecycle

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `DowntimeSeverityID` (clustered, PK_DDTSV) |
| **Indexes** | `DDTSV_NAME` — unique on Name |
| **Filegroup** | DICTIONARY |
| **Row Count** | 4 |
| **Identity** | No |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all severity levels ordered by priority
SELECT  DowntimeSeverityID,
        Name
FROM    Dictionary.DowntimeSeverity WITH (NOLOCK)
ORDER BY DowntimeSeverityID;

-- Count open incidents by severity
SELECT  ds.Name             AS Severity,
        COUNT(*)            AS OpenIncidents
FROM    BackOffice.Downtime d WITH (NOLOCK)
JOIN    Dictionary.DowntimeSeverity ds WITH (NOLOCK)
        ON d.DowntimeSeverityID = ds.DowntimeSeverityID
WHERE   d.Closed = 0
GROUP BY ds.DowntimeSeverityID, ds.Name
ORDER BY ds.DowntimeSeverityID;

-- Get critical incidents still open
SELECT  d.DowntimeID,
        d.TimeOpened,
        d.OpenComment
FROM    BackOffice.Downtime d WITH (NOLOCK)
WHERE   d.DowntimeSeverityID = 1
AND     d.Closed = 0
ORDER BY d.TimeOpened;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
