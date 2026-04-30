# Dictionary.Downtype

## 1. Business Meaning

### What It Is
A lookup table defining the categories of downtime incidents — the "what kind" of problem occurred across platform systems.

### Why It Exists
Categorizing downtime incidents by type enables pattern analysis (e.g., "we have recurring hedge failures") and helps route incidents to the appropriate team. Each category maps to a specific functional area of the platform.

### How It's Used
Referenced by `BackOffice.Downtime.DowntypeID` (explicit FK) and by `Dictionary.DowntimeSystemToDowntype` which maps valid downtypes per system. Not all downtypes apply to all systems.

---

## 2. Business Logic

### Category Groups
The 17 downtypes fall into three functional groups based on which systems they map to:

**Trading Platform Issues (Tradonomi Real/Demo, IFx)**
| ID | Name | Description |
|----|------|-------------|
| 1 | Can't Login | Authentication/login failures |
| 2 | Can't Register | New account registration failures |
| 3 | Unable to Open Trades | Trade execution blocked |
| 4 | No Rates | Price feed unavailable |
| 5 | Problem with Charts | Chart rendering/data issues |
| 6 | Chat not Working | In-platform chat failures |
| 7 | Slow Response Times | Performance degradation |

**Dealing/Hedge Issues (Dealing system)**
| ID | Name | Description |
|----|------|-------------|
| 8 | Dealing Desk | General dealing desk failures |
| 9 | Delta Diff Issue | Delta/exposure calculation discrepancies |
| 10 | Hedge 1 | Hedge provider 1 failures |
| 11 | Hedge 8 | Hedge provider 8 failures |
| 12 | Hedge 10 | Hedge provider 10 failures |

**Website Issues (Website system)**
| ID | Name | Description |
|----|------|-------------|
| 13 | etoro.com | Main website issues |
| 14 | RetailFX.com | Legacy RetailFX brand site |
| 15 | Affiliate Wiz | Affiliate management tool |
| 16 | eToro Partners | Partner portal |

**Universal**
| ID | Name | Description |
|----|------|-------------|
| 17 | Other | Catch-all for unclassified issues (applies to all systems) |

---

## 3. Data Overview

| DowntypeID | Name |
|-----------|------|
| 1 | Can't Login |
| 2 | Can't Register |
| 3 | Unable to Open Trades |
| 4 | No Rates |
| 5 | Problem with Charts |
| 6 | Chat not Working |
| 7 | Slow Response Times |
| 8 | Dealing Desk |
| 9 | Delta Diff Issue |
| 10 | Hedge 1 |
| 11 | Hedge 8 |
| 12 | Hedge 10 |
| 13 | etoro.com |
| 14 | RetailFX.com |
| 15 | Affiliate Wiz |
| 16 | eToro Partners |
| 17 | Other |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **DowntypeID** | `int` | NO | Primary key. Downtime category identifier (1-17). | `MCP` |
| **Name** | `varchar(50)` | NO | Category label. Unique index ensures no duplicates. | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | FK Name | Relationship |
|-------|--------|---------|-------------|
| BackOffice.Downtime | DowntypeID | FK_DDTP_BODT | Explicit FK — categorizes the type of downtime incident |
| Dictionary.DowntimeSystemToDowntype | DowntypeID | FK_DDTP_DS2DT | Explicit FK — maps which systems this downtype applies to |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `BackOffice.Downtime` — records the downtime category
- `Dictionary.DowntimeSystemToDowntype` — junction table controlling system-to-downtype mapping
- `BackOffice.DowntimeAdd` — sets the downtype when creating an incident
- `BackOffice.DowntimeEdit` — allows downtype reassignment

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `DowntypeID` (clustered, PK_DDTP) |
| **Indexes** | `DDTP_NAME` — unique on Name |
| **Filegroup** | DICTIONARY |
| **Row Count** | 17 |
| **Identity** | No |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all downtime categories
SELECT  DowntypeID,
        Name
FROM    Dictionary.Downtype WITH (NOLOCK)
ORDER BY DowntypeID;

-- Count incidents by downtype category
SELECT  dt.Name             AS DowntypeCategory,
        COUNT(*)            AS IncidentCount
FROM    BackOffice.Downtime d WITH (NOLOCK)
JOIN    Dictionary.Downtype dt WITH (NOLOCK)
        ON d.DowntypeID = dt.DowntypeID
GROUP BY dt.Name
ORDER BY IncidentCount DESC;

-- Find which systems a specific downtype applies to
SELECT  ds.Name             AS SystemName
FROM    Dictionary.DowntimeSystemToDowntype sd WITH (NOLOCK)
JOIN    Dictionary.DowntimeSystem ds WITH (NOLOCK)
        ON sd.DowntimeSystemID = ds.DowntimeSystemID
WHERE   sd.DowntypeID = 17;  -- "Other"
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
