# Dictionary.DowntimeSystemToDowntype

## 1. Business Meaning

### What It Is
A many-to-many junction table that maps which downtime categories (downtypes) are applicable to each platform system. Controls the valid dropdown options when reporting a downtime incident.

### Why It Exists
Different systems have different failure modes — a "Dealing Desk" issue doesn't apply to the Website, and "etoro.com" downtime doesn't apply to the trading platform. This table constrains which downtype categories are selectable per system in the BackOffice incident form.

### How It's Used
When an operator selects a system in the downtime reporting form, this mapping determines which downtype categories appear as valid options. Both columns have explicit FKs to their respective lookup tables.

---

## 2. Business Logic

### System-to-Downtype Distribution

| System | Applicable Downtypes |
|--------|---------------------|
| **Tradonomi Real** (1) | Can't Login, Can't Register, Unable to Open Trades, No Rates, Problem with Charts, Chat not Working, Slow Response Times, Other |
| **Tradonomi Demo** (2) | Same as Tradonomi Real |
| **IFx** (3) | Same as Tradonomi Real |
| **Dealing** (4) | Dealing Desk, Delta Diff Issue, Hedge 1, Hedge 8, Hedge 10, Other |
| **Website** (5) | etoro.com, RetailFX.com, Affiliate Wiz, eToro Partners, Other |

> **"Other" (17)** is the universal catch-all — applicable to ALL 5 systems.

### Pattern
- Trading platforms (1-3) share identical downtype sets (user-facing trading issues)
- Dealing (4) has hedge/dealing-specific categories
- Website (5) has web property categories

---

## 3. Data Overview

35 rows mapping 5 systems to 17 downtypes. Representative sample:

| DowntimeSystemID | DowntypeID | System | Downtype |
|-----------------|-----------|--------|----------|
| 1 | 1 | Tradonomi Real | Can't Login |
| 4 | 8 | Dealing | Dealing Desk |
| 5 | 13 | Website | etoro.com |
| 5 | 17 | Website | Other |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **DowntimeSystemID** | `int` | NO | FK to Dictionary.DowntimeSystem. Identifies the platform system. Part of composite PK. | `DDL+MCP` |
| **DowntypeID** | `int` | NO | FK to Dictionary.Downtype. Identifies the downtime category. Part of composite PK. | `DDL+MCP` |

---

## 5. Relationships

### References To
| Table | Column | FK Name | Relationship |
|-------|--------|---------|-------------|
| Dictionary.DowntimeSystem | DowntimeSystemID | FK_DDTSY_DS2DT | Which system this mapping applies to |
| Dictionary.Downtype | DowntypeID | FK_DDTP_DS2DT | Which downtype category is valid for this system |

### Referenced By
None directly — consumed by the BackOffice downtime reporting UI to filter valid downtypes per system.

---

## 6. Dependencies

### Depends On
- `Dictionary.DowntimeSystem` — parent lookup for systems
- `Dictionary.Downtype` — parent lookup for downtime categories

### Depended On By
- BackOffice incident management UI (filters valid downtype options per selected system)

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `(DowntimeSystemID, DowntypeID)` (nonclustered, PK_DS2DT) |
| **Indexes** | `DS2DT_TYPE` — nonclustered on DowntypeID (reverse lookup) |
| **Foreign Keys** | FK_DDTSY_DS2DT → DowntimeSystem; FK_DDTP_DS2DT → Downtype |
| **Filegroup** | DICTIONARY |
| **Row Count** | 35 |
| **Identity** | No |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all system-to-downtype mappings with resolved names
SELECT  ds.Name             AS SystemName,
        dt.Name             AS DowntypeName
FROM    Dictionary.DowntimeSystemToDowntype sd WITH (NOLOCK)
JOIN    Dictionary.DowntimeSystem ds WITH (NOLOCK)
        ON sd.DowntimeSystemID = ds.DowntimeSystemID
JOIN    Dictionary.Downtype dt WITH (NOLOCK)
        ON sd.DowntypeID = dt.DowntypeID
ORDER BY ds.Name, dt.Name;

-- Count how many downtypes each system supports
SELECT  ds.Name             AS SystemName,
        COUNT(*)            AS DowntypeCount
FROM    Dictionary.DowntimeSystemToDowntype sd WITH (NOLOCK)
JOIN    Dictionary.DowntimeSystem ds WITH (NOLOCK)
        ON sd.DowntimeSystemID = ds.DowntimeSystemID
GROUP BY ds.Name
ORDER BY DowntypeCount DESC;

-- Find universal downtypes (applicable to all systems)
SELECT  dt.Name             AS DowntypeName,
        COUNT(*)            AS SystemCount
FROM    Dictionary.DowntimeSystemToDowntype sd WITH (NOLOCK)
JOIN    Dictionary.Downtype dt WITH (NOLOCK)
        ON sd.DowntypeID = dt.DowntypeID
GROUP BY dt.Name
HAVING  COUNT(*) = (SELECT COUNT(*) FROM Dictionary.DowntimeSystem WITH (NOLOCK));
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
