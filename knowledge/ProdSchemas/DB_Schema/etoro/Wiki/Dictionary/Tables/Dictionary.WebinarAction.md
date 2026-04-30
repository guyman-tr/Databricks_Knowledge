# Dictionary.WebinarAction

> Lookup table defining the three stages of customer engagement with webinars — Registered, Attended, or Viewed (recording) — used to track customer participation in educational and marketing webinar events.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | WebinarActionID (INT, manually assigned) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 clustered (PK on WebinarActionID) |

---

## 1. Business Meaning

Dictionary.WebinarAction defines the possible engagement actions a customer can take with a webinar event. Webinars are a key customer education and marketing tool — the platform tracks whether customers register for webinars, actually attend live sessions, or watch recordings afterward. This data feeds customer engagement scoring, marketing funnel analysis, and sales team follow-up prioritization.

Without this table, the system could not distinguish between passive interest (registration) and active participation (attendance or viewing). A customer who registered but never attended represents a different engagement signal than one who watched the full recording — both are valuable for different sales and marketing strategies.

The table is consumed by BackOffice.InsertWebinarData (which records webinar engagement events) and referenced by BackOffice.Webinars (which stores the webinar event records with their associated action types).

---

## 2. Business Logic

### 2.1 Webinar Engagement Funnel

**What**: Three progressive stages of customer engagement with webinar content.

**Columns/Parameters Involved**: `WebinarActionID`, `Name`

**Rules**:
- ID 0 (Registered) — customer signed up for a webinar but hasn't attended or viewed yet. Shows intent/interest
- ID 1 (Attended) — customer participated in the live webinar session. Strongest engagement signal; most likely to convert or increase trading activity
- ID 2 (Viewed) — customer watched the webinar recording after the live event. Good engagement but weaker than live attendance
- These actions form a funnel: Registered → Attended (live) or Registered → Viewed (recording)
- BackOffice.InsertWebinarData records each action as it occurs, building a timeline of engagement per customer per webinar

**Diagram**:
```
Webinar Engagement Funnel:
  Customer ──► 0=Registered (signed up)
                    │
                    ├─ Live event ──► 1=Attended
                    │
                    └─ Recording  ──► 2=Viewed
```

---

## 3. Data Overview

| WebinarActionID | Name | Meaning |
|---|---|---|
| 0 | Registered | Customer signed up for the webinar — shows initial interest. Used to send reminders before the live event and as a marketing touchpoint for sales team outreach. |
| 1 | Attended | Customer participated in the live webinar session — strongest engagement signal. Indicates active learning/interest; these customers are prioritized for sales follow-up and feature adoption campaigns. |
| 2 | Viewed | Customer watched the webinar recording — good engagement but asynchronous. Indicates interest that couldn't be expressed during the live event (timezone, scheduling conflicts). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WebinarActionID | int | NO | - | CODE-BACKED | Unique identifier for the webinar engagement action: 0=Registered, 1=Attended, 2=Viewed. Referenced by BackOffice.Webinars and BackOffice.InsertWebinarData to classify customer webinar participation. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Display name for the engagement action. Used in BackOffice reporting screens and marketing analytics to label customer webinar interactions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Webinars | WebinarActionID | Implicit | Stores the engagement action type per webinar event record |
| BackOffice.InsertWebinarData | @WebinarActionID | Reader | Records customer webinar engagement events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.WebinarAction (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Webinars | Table | Stores WebinarActionID per event |
| BackOffice.InsertWebinarData | Stored Procedure | Records webinar engagement |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DWA | CLUSTERED | WebinarActionID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all webinar actions
```sql
SELECT  WebinarActionID,
        Name AS ActionName
FROM    [Dictionary].[WebinarAction] WITH (NOLOCK)
ORDER BY WebinarActionID;
```

### 8.2 Count webinar events by action type
```sql
SELECT  wa.Name AS ActionType,
        COUNT(*) AS EventCount
FROM    [BackOffice].[Webinars] w WITH (NOLOCK)
JOIN    [Dictionary].[WebinarAction] wa WITH (NOLOCK)
        ON wa.WebinarActionID = w.WebinarActionID
GROUP BY wa.Name
ORDER BY EventCount DESC;
```

### 8.3 Find customers who registered but never attended
```sql
SELECT  w.CustomerID
FROM    [BackOffice].[Webinars] w WITH (NOLOCK)
JOIN    [Dictionary].[WebinarAction] wa WITH (NOLOCK)
        ON wa.WebinarActionID = w.WebinarActionID
WHERE   wa.Name = 'Registered'
        AND w.CustomerID NOT IN (
            SELECT w2.CustomerID
            FROM   [BackOffice].[Webinars] w2 WITH (NOLOCK)
            WHERE  w2.WebinarActionID IN (1, 2) -- Attended or Viewed
        );
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WebinarAction | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.WebinarAction.sql*
