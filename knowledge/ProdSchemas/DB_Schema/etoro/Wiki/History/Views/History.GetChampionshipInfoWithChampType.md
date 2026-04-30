# History.GetChampionshipInfoWithChampType

> Extended view of completed trading championships that adds the championship type classification and setup template title by joining History.Championship with the Championship.Championship setup catalog.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | ChampionshipID (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

History.GetChampionshipInfoWithChampType extends `History.GetChampionshipInfo` by joining the championship run data with the cross-schema championship setup catalog (`Championship.Championship`). The join adds two fields: `ChampionshipTypeID` (whether the championship was Public or Private) and `Title` (the human-readable name given to the competition type in the setup template, e.g., "Weekly").

The view distinguishes Public championships (open to all customers) from Private ones (invite-only or restricted competitions). This context is necessary for historical analysis where you need to understand not just what championships ran, but what type they were and what they were called - for example, "how many Public Weekly championships ran in Q1 2012?"

Like `History.GetChampionshipInfo`, this view covers exclusively historical gaming-platform data from 2012. The gaming/championship feature has been inactive in production for many years. No stored procedures reference this view directly - it is an ad-hoc analytical interface. The cross-schema JOIN to `Championship.Championship` means queries against this view touch two schemas.

**Key observation**: Live data shows Title="Weekly" for all observed championships across both setup IDs (31 and 32), confirming both setups were named "Weekly" competitions. The Duration computed column is NULL for all rows (same DurationType mismatch as in `History.GetChampionshipInfo`).

---

## 2. Business Logic

### 2.1 Setup Template Join (INNER JOIN)

**What**: The INNER JOIN to Championship.Championship enriches each championship run with its setup template's metadata.

**Columns/Parameters Involved**: `ChampionshipSetupID`, `ChampionshipTypeID`, `Title`

**Rules**:
- JOIN condition: `hc.ChampionshipSetupID = cc.ChampionshipSetupID`
- The JOIN is INNER - championship runs without a matching setup in Championship.Championship are excluded
- ChampionshipTypeID comes from History.Championship (the historical run record)
- Title comes from Championship.Championship (the setup catalog)
- Live data: both setups (31 and 32) have Title="Weekly" and both Public (1) and Private (2) championships existed

**Diagram**:
```
History.Championship (hc)           Championship.Championship (cc)
  ChampionshipID                    ChampionshipSetupID
  ChampionshipSetupID  -------->    Title
  ChampionshipTypeID                (setup name for this competition type)
  DurationType (->Duration)
  StartDateTime
  EndDateTime
  WHERE EndDateTime IS NOT NULL

Result: Championship runs enriched with their setup's display title and type classification
```

### 2.2 Public vs Private Championships

**What**: ChampionshipTypeID distinguishes open-to-all from restricted competitions.

**Columns/Parameters Involved**: `ChampionshipTypeID`

**Rules**:
- ChampionshipTypeID=1 (Public): open to all customers, standard player acquisition vehicle
- ChampionshipTypeID=2 (Private): restricted access, invite-only or promotional
- Values from Dictionary.ChampionshipType (FK on History.Championship)
- Live data: ChampionshipID=266 is Private (type=2); all others in sample are Public (type=1)

### 2.3 Duration Label (Computed - Currently Non-Functional)

**What**: Same CASE expression as History.GetChampionshipInfo - translates DurationType to 'Daily'/'Weekly'/'Manual'.

**Columns/Parameters Involved**: `Duration`

**Rules**:
- Returns NULL for all live rows - DurationType values don't match 1/2/3 CASE branches
- The Title field from Championship.Championship ("Weekly") provides the actual human-readable duration label that Duration was intended to provide
- Duration and Title are effectively redundant concepts but Duration is computed from a different source (DurationType int) than Title (setup catalog string)

---

## 3. Data Overview

| ChampionshipID | ChampionshipSetupID | StartDateTime | EndDateTime | Duration | ChampionshipTypeID | Title |
|---|---|---|---|---|---|---|
| 270 | 32 | 2012-02-26 15:45 | 2012-03-04 08:27 | NULL | 1 (Public) | Weekly | A Public Weekly championship - the most common competition type in the dataset. Duration=NULL (DurationType mismatch) but Title="Weekly" from the setup catalog provides the label. |
| 269 | 32 | 2012-02-19 14:56 | 2012-02-26 15:43 | NULL | 1 (Public) | Weekly | Successive weekly cycle of the same Public championship setup. Sequential ChampionshipIDs with ~7-day windows confirm a recurring weekly schedule. |
| 266 | 31 | 2012-02-05 19:22 | 2012-02-05 22:45 | NULL | 2 (Private) | Weekly | A Private championship (~3.5 hours) using setup 31. Despite also being named "Weekly", this was a short Private competition. ChampionshipTypeID=2 identifies it as restricted access. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChampionshipID | int | NO | - | VERIFIED | Unique identifier for the completed championship run. Assigned by Internal.GetChampionshipID at championship start. Primary key of History.Championship. |
| 2 | ChampionshipSetupID | int | NO | 0 | VERIFIED | ID of the setup template (Championship.Championship) used for this championship. JOIN key to the setup catalog. Multiple championship runs share the same ChampionshipSetupID. |
| 3 | StartDateTime | datetime | YES | - | VERIFIED | Wall-clock datetime when the championship started. From History.Championship. |
| 4 | EndDateTime | datetime | YES | - | VERIFIED | Wall-clock datetime when the championship ended. Non-NULL guaranteed by this view's WHERE filter. From History.Championship. |
| 5 | Duration | varchar (computed) | YES | - | CODE-BACKED | CASE on DurationType: 1='Daily', 2='Weekly', 3='Manual'. Returns NULL for all live rows (DurationType values don't match 1/2/3). The Title column from Championship.Championship provides the actual label. |
| 6 | ChampionshipTypeID | int | NO | 0 | VERIFIED | Championship access type from History.Championship. 1=Public (open to all), 2=Private (restricted). Inherited from the historical snapshot preserved at championship start time. (Source: Dictionary.ChampionshipType) |
| 7 | Title | nvarchar (from Championship.Championship) | YES | - | VERIFIED | Human-readable name of the championship type from the setup catalog. Live data shows "Weekly" for all observed rows. This is the setup template's display title - what the championship was called in the UI. From Championship.Championship.Title. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ChampionshipSetupID | History.Championship | View (JOIN source) | Championship run data - WHERE EndDateTime IS NOT NULL |
| ChampionshipSetupID | Championship.Championship | View (INNER JOIN) | Setup catalog providing Title; joins on ChampionshipSetupID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.GetPlayerRankWithChampType | ChampionshipID | View (JOIN) | Extends this view further with player ranking data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetChampionshipInfoWithChampType (view)
├── History.Championship (table - leaf node)
└── Championship.Championship (table - cross-schema leaf node)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Championship | Table | Primary data source - 5 columns + CASE Duration, WHERE EndDateTime IS NOT NULL |
| Championship.Championship | Table | INNER JOIN on ChampionshipSetupID to provide Title |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.GetPlayerRankWithChampType | View | Uses this view's base logic, extends with ChampionshipPlayer data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. History.Championship clustered PK (ChampionshipID) and Championship.Championship indexes serve this view.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 List all completed Public championships with their titles
```sql
SELECT
    ChampionshipID,
    Title,
    ChampionshipTypeID,
    StartDateTime,
    EndDateTime,
    DATEDIFF(HOUR, StartDateTime, EndDateTime) AS DurationHours
FROM History.GetChampionshipInfoWithChampType WITH (NOLOCK)
WHERE ChampionshipTypeID = 1  -- Public only
ORDER BY ChampionshipID DESC;
```

### 8.2 Count championships by type and title
```sql
SELECT
    ChampionshipTypeID,
    Title,
    COUNT(*) AS ChampionshipCount,
    MIN(StartDateTime) AS FirstRun,
    MAX(EndDateTime) AS LastRun
FROM History.GetChampionshipInfoWithChampType WITH (NOLOCK)
GROUP BY ChampionshipTypeID, Title
ORDER BY ChampionshipCount DESC;
```

### 8.3 Find all championships for a specific setup template
```sql
SELECT
    ChampionshipID,
    ChampionshipSetupID,
    ChampionshipTypeID,
    Title,
    StartDateTime,
    EndDateTime
FROM History.GetChampionshipInfoWithChampType WITH (NOLOCK)
WHERE ChampionshipSetupID = 32
ORDER BY StartDateTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.GetChampionshipInfoWithChampType. Business context inherited from History.Championship and Championship.Championship documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 consumers | App Code: 0 repos | Corrections: 0 applied*
*Object: History.GetChampionshipInfoWithChampType | Type: View | Source: etoro/etoro/History/Views/History.GetChampionshipInfoWithChampType.sql*
