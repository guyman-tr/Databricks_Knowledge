# Dictionary.DowntimeStatus

## 1. Business Meaning

### What It Is
A lookup table defining the operational impact status of a downtime incident — how severely the affected system is impaired.

### Why It Exists
While `DowntimeSeverity` classifies priority, `DowntimeStatus` describes the nature of the failure: whether the system is completely down, partially malfunctioning, or experiencing an isolated feature failure. This distinction helps operations teams understand what level of functionality remains.

### How It's Used
Referenced by `BackOffice.Downtime.DowntimeStatusID` (explicit FK). Set when an incident is created via `BackOffice.DowntimeAdd` and updateable via `BackOffice.DowntimeEdit`.

---

## 2. Business Logic

### Impact Levels
Three tiers of operational impact, from total failure to localized issue:

```
Not Working (1) ──────────────── System completely unavailable
    │
Not Working as Should (2) ───── System running but behaving incorrectly
    │
Specific Feature not Working (3) ── Isolated functionality failure
```

---

## 3. Data Overview

| DowntimeStatusID | Name |
|-----------------|------|
| 1 | Not Working |
| 2 | Not Working as Should |
| 3 | Specific Feature not Working |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **DowntimeStatusID** | `int` | NO | Primary key. Impact classification (1=Not Working, 2=Not Working as Should, 3=Specific Feature not Working). | `MCP` |
| **Name** | `varchar(50)` | NO | Impact description. Two unique indexes enforce name uniqueness (DDCS_NAME and DDTST_NAME — legacy duplication). | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | FK Name | Relationship |
|-------|--------|---------|-------------|
| BackOffice.Downtime | DowntimeStatusID | FK_DDTST_BODT | Explicit FK — operational impact classification |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `BackOffice.Downtime` — records the impact status of each incident
- `BackOffice.DowntimeAdd` — sets initial impact when creating an incident
- `BackOffice.DowntimeEdit` — allows impact status changes

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `DowntimeStatusID` (clustered, PK_DDTST) |
| **Indexes** | `DDCS_NAME` — unique on Name; `DDTST_NAME` — unique on Name (duplicate index, legacy) |
| **Filegroup** | DICTIONARY |
| **Row Count** | 3 |
| **Identity** | No |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all operational impact statuses
SELECT  DowntimeStatusID,
        Name
FROM    Dictionary.DowntimeStatus WITH (NOLOCK)
ORDER BY DowntimeStatusID;

-- Count incidents by impact type
SELECT  ds.Name             AS ImpactStatus,
        COUNT(*)            AS IncidentCount
FROM    BackOffice.Downtime d WITH (NOLOCK)
JOIN    Dictionary.DowntimeStatus ds WITH (NOLOCK)
        ON d.DowntimeStatusID = ds.DowntimeStatusID
GROUP BY ds.Name
ORDER BY IncidentCount DESC;

-- Get open incidents where system is completely down
SELECT  d.DowntimeID,
        d.TimeOpened,
        d.OpenComment
FROM    BackOffice.Downtime d WITH (NOLOCK)
WHERE   d.DowntimeStatusID = 1
AND     d.Closed = 0;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
