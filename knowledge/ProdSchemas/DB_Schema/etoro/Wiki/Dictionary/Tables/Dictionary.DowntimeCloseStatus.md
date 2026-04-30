# Dictionary.DowntimeCloseStatus

## 1. Business Meaning

### What It Is
A lookup table that defines the resolution categories available when closing a downtime incident in the BackOffice incident management system.

### Why It Exists
When support staff close a downtime incident, they must classify how the issue was resolved. This table provides the standard set of resolution outcomes, enabling consistent categorization and reporting on incident resolution patterns.

### How It's Used
Referenced by `BackOffice.Downtime.DowntimeCloseStatusID` (explicit FK) when a manager closes a downtime incident via the `BackOffice.DowntimeClose` procedure. The resolution status is written alongside the closing manager's ID, timestamp, and comment.

---

## 2. Business Logic

### Resolution Categories
The four statuses mirror standard IT incident management (ITIL-style) resolution classifications:

| Category | Meaning |
|----------|---------|
| **Fixed** | The issue was identified and a fix was applied |
| **Not Reproducible** | The issue could not be replicated during investigation |
| **Duplicate Item** | This incident was already tracked under another downtime record |
| **By Design** | The reported behavior is intentional, not a defect (note: stored as "By Desgin" — legacy typo) |

### Incident Close Flow
```
Downtime Opened (Closed=0, DowntimeCloseStatusID=NULL)
        │
        ▼
  BackOffice.DowntimeClose(@DowntimeID, @DowntimeCloseStatusID, @ManagerID, @TimeClosed, @Comment)
        │
        ▼
Downtime Closed (Closed=1, DowntimeCloseStatusID=1-4, ClosedBy=@ManagerID, TimeClosed=@TimeClosed)
```

---

## 3. Data Overview

| DowntimeCloseStatusID | Name |
|----------------------|------|
| 1 | Fixed |
| 2 | Not Reproducible |
| 3 | Duplicate Item |
| 4 | By Desgin |

> **Note**: Value 4 contains a legacy typo ("By Desgin" instead of "By Design").

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **DowntimeCloseStatusID** | `int` | NO | Primary key. Resolution category identifier (1-4). | `DDL` |
| **Name** | `varchar(50)` | NO | Human-readable resolution label: Fixed, Not Reproducible, Duplicate Item, By Desgin. | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | FK Name | Relationship |
|-------|--------|---------|-------------|
| BackOffice.Downtime | DowntimeCloseStatusID | FK_DDCS_BODT | Explicit FK — classifies how the downtime incident was resolved |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `BackOffice.Downtime` — stores the close status when an incident is resolved
- `BackOffice.DowntimeClose` — procedure that writes DowntimeCloseStatusID when closing an incident

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `DowntimeCloseStatusID` (clustered, PK_DDCS) |
| **Filegroup** | DICTIONARY |
| **Row Count** | 4 |
| **Identity** | No — manually assigned IDs |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all close status options
SELECT  DowntimeCloseStatusID,
        Name
FROM    Dictionary.DowntimeCloseStatus WITH (NOLOCK)
ORDER BY DowntimeCloseStatusID;

-- Count downtime incidents by resolution type
SELECT  dcs.Name            AS CloseStatus,
        COUNT(*)            AS IncidentCount
FROM    BackOffice.Downtime d WITH (NOLOCK)
JOIN    Dictionary.DowntimeCloseStatus dcs WITH (NOLOCK)
        ON d.DowntimeCloseStatusID = dcs.DowntimeCloseStatusID
WHERE   d.Closed = 1
GROUP BY dcs.Name
ORDER BY IncidentCount DESC;

-- Find recently closed downtime incidents with resolution details
SELECT  d.DowntimeID,
        dcs.Name            AS Resolution,
        d.CloseComment,
        d.TimeClosed
FROM    BackOffice.Downtime d WITH (NOLOCK)
JOIN    Dictionary.DowntimeCloseStatus dcs WITH (NOLOCK)
        ON d.DowntimeCloseStatusID = dcs.DowntimeCloseStatusID
WHERE   d.Closed = 1
ORDER BY d.TimeClosed DESC;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
