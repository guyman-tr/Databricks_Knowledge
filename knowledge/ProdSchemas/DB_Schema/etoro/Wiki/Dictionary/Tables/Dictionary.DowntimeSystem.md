# Dictionary.DowntimeSystem

## 1. Business Meaning

### What It Is
A lookup table identifying the major platform systems that can experience downtime incidents — the "where" of an incident.

### Why It Exists
When reporting a downtime incident, operations staff must specify which system is affected. This table provides the canonical list of monitorable platform components, enabling per-system incident tracking and uptime reporting.

### How It's Used
Referenced by `BackOffice.Downtime.DowntimeSystemID` (explicit FK) and by `Dictionary.DowntimeSystemToDowntype` (explicit FK) which maps each system to its applicable downtime categories.

---

## 2. Business Logic

### Platform Components
Five major system areas are tracked:

| System | Business Area |
|--------|--------------|
| **Tradonomi Real** (1) | Live/production trading platform |
| **Tradonomi Demo** (2) | Demo/practice trading environment |
| **IFx** (3) | IFx trading interface |
| **Dealing** (4) | Dealing desk / hedge server operations |
| **Website** (5) | Public-facing website (etoro.com, partner sites) |

### System-to-Downtype Mapping
Each system has different applicable failure types. The `DowntimeSystemToDowntype` junction table controls which downtype categories are valid for each system:
- **Tradonomi Real/Demo/IFx** share the same set of trading-related downtypes (login, registration, trading, rates, charts, chat, slow response, other)
- **Dealing** has hedge/dealing-specific downtypes
- **Website** has web-specific downtypes (etoro.com, partner sites, affiliate tools)

---

## 3. Data Overview

| DowntimeSystemID | Name |
|-----------------|------|
| 1 | Tradonomi Real |
| 2 | Tradonomi Demo |
| 3 | IFx |
| 4 | Dealing |
| 5 | Website |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **DowntimeSystemID** | `int` | NO | Primary key. System identifier. | `MCP` |
| **Name** | `varchar(250)` | NO | System name. Unique index ensures no duplicates. | `MCP` |

---

## 5. Relationships

### Referenced By
| Table | Column | FK Name | Relationship |
|-------|--------|---------|-------------|
| BackOffice.Downtime | DowntimeSystemID | FK_DDTSY_BODT | Explicit FK — which system experienced the downtime |
| Dictionary.DowntimeSystemToDowntype | DowntimeSystemID | FK_DDTSY_DS2DT | Explicit FK — maps system to applicable downtime categories |

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `BackOffice.Downtime` — identifies the affected system
- `Dictionary.DowntimeSystemToDowntype` — junction table mapping systems to valid downtypes
- `BackOffice.DowntimeAdd` — sets the system when creating an incident
- `BackOffice.DowntimeEdit` — allows system reassignment

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `DowntimeSystemID` (clustered, PK_DDTSY) |
| **Indexes** | `DDTSY_NAME` — unique on Name |
| **Filegroup** | DICTIONARY |
| **Row Count** | 5 |
| **Identity** | No |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all monitored systems
SELECT  DowntimeSystemID,
        Name
FROM    Dictionary.DowntimeSystem WITH (NOLOCK)
ORDER BY DowntimeSystemID;

-- Count incidents per system
SELECT  ds.Name             AS SystemName,
        COUNT(*)            AS TotalIncidents,
        SUM(CASE WHEN d.Closed = 0 THEN 1 ELSE 0 END) AS OpenIncidents
FROM    BackOffice.Downtime d WITH (NOLOCK)
JOIN    Dictionary.DowntimeSystem ds WITH (NOLOCK)
        ON d.DowntimeSystemID = ds.DowntimeSystemID
GROUP BY ds.Name
ORDER BY TotalIncidents DESC;

-- Get valid downtype categories per system
SELECT  ds.Name             AS SystemName,
        dt.Name             AS DowntypeName
FROM    Dictionary.DowntimeSystemToDowntype sd WITH (NOLOCK)
JOIN    Dictionary.DowntimeSystem ds WITH (NOLOCK)
        ON sd.DowntimeSystemID = ds.DowntimeSystemID
JOIN    Dictionary.Downtype dt WITH (NOLOCK)
        ON sd.DowntypeID = dt.DowntypeID
ORDER BY ds.Name, dt.Name;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
