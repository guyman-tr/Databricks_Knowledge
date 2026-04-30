# BackOffice.Webinars

> Historical event log of customer webinar registrations, attendance, and views from 2014, keyed by email, action type, and language. No longer actively used.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_Webinars: Email + WebinarActionID + Occurred + LanguageID (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (clustered composite PK) |

---

## 1. Business Meaning

`BackOffice.Webinars` is a historical record of customer engagement with eToro's educational webinar program. During 2014, eToro ran a series of webinars (live online educational sessions for traders), and this table tracked customer participation: who registered, who actually attended, and who later viewed the recording.

The table is stored on the `HISTORY` filegroup, reinforcing its archival nature. Live data: 10,727 rows, all dated 2014. There are no SPs referencing this table in the current BackOffice schema, and no recent writes. The webinar program as tracked here has been discontinued or moved to an external platform (such as GoToWebinar, Zoom, or a dedicated LMS integration).

The composite PK (Email + WebinarActionID + Occurred + LanguageID) ensures that the same customer cannot have duplicate records for the same action/date/language combination, while allowing the same customer to have multiple rows for different webinar events.

---

## 2. Business Logic

### 2.1 Three-Stage Webinar Engagement Tracking

**What**: Each customer can have up to 3 rows per webinar event: registration, attendance, and view.

**Columns/Parameters Involved**: `Email`, `WebinarActionID`, `Occurred`, `LanguageID`

**Rules**:
- `WebinarActionID=0` (Registered): Customer signed up for the webinar.
- `WebinarActionID=1` (Attended): Customer attended the live session.
- `WebinarActionID=2` (Viewed): Customer watched the recorded replay.
- The same email can have all three rows for the same webinar event.
- `LanguageID` tracks the language of the webinar the customer engaged with.
- `Occurred` is the date/time of the action.

**WebinarAction values** (from Dictionary.WebinarAction):

| WebinarActionID | Name |
|----------------|------|
| 0 | Registered |
| 1 | Attended |
| 2 | Viewed |

---

## 3. Data Overview

| Column | Observed Values |
|--------|----------------|
| Total rows | 10,727 |
| Date range | All records from 2014 |
| Most common WebinarActionID | 0 (Registered) - majority of rows |
| Email format | Various customer emails (e.g., gmail.com, hotmail.com, yahoo.co.uk) |
| LanguageID | 1 (English) dominant in sample |
| Status | Legacy - no new data since 2014 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate identity column. NOT FOR REPLICATION. Note: despite being an IDENTITY column, it is NOT the PK. The composite (Email + WebinarActionID + Occurred + LanguageID) is the PK. |
| 2 | Email | varchar(100) | NO | - | CODE-BACKED | Customer's email address. Part of the composite PK. Not linked by FK to Customer schema - email was used as the identifier in the webinar registration system (an external signup flow pre-dating CID linkage). |
| 3 | WebinarActionID | int | NO | - | CODE-BACKED | FK to Dictionary.WebinarAction. Part of composite PK. 0=Registered, 1=Attended, 2=Viewed. Tracks which engagement stage this row represents for the customer. |
| 4 | Occurred | datetime | NO | - | CODE-BACKED | Timestamp of the webinar action (registration time, attendance time, or view time). Part of composite PK. All values in live data are from 2014. |
| 5 | LanguageID | int | NO | - | CODE-BACKED | FK to Dictionary.Language. Part of composite PK. Identifies the language of the webinar the customer engaged with (e.g., 1=English). Allows tracking of multilingual webinar programs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WebinarActionID | Dictionary.WebinarAction.WebinarActionID | FK (FK_BOW_WAID) | Registration, attendance, or view action |
| LanguageID | Dictionary.Language.LanguageID | FK (FK_BOW_LID) | Language of the webinar |

### 5.2 Referenced By (other objects point to this)

No current SP references found. Table was likely written to from an external webinar integration system.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Webinars (table)
+-- Dictionary.WebinarAction (table) [FK_BOW_WAID]
+-- Dictionary.Language (table) [FK_BOW_LID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.WebinarAction | Table | FK: WebinarActionID must be a valid action type |
| Dictionary.Language | Table | FK: LanguageID must be a valid language |

### 6.2 Objects That Depend On This

No current dependents in BackOffice schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Webinars | CLUSTERED PK | Email ASC, WebinarActionID ASC, Occurred ASC, LanguageID ASC (FILLFACTOR=90) | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BOW_LID | FK | LanguageID -> Dictionary.Language |
| FK_BOW_WAID | FK | WebinarActionID -> Dictionary.WebinarAction |
| Storage | Filegroup | Table stored on HISTORY filegroup (archival placement) |

---

## 8. Sample Queries

### 8.1 Get registration counts by action type

```sql
SELECT
    wa.Name AS ActionType, COUNT(w.ID) AS Count
FROM BackOffice.Webinars w WITH (NOLOCK)
JOIN Dictionary.WebinarAction wa WITH (NOLOCK) ON wa.WebinarActionID = w.WebinarActionID
GROUP BY wa.WebinarActionID, wa.Name
ORDER BY wa.WebinarActionID;
```

### 8.2 Check webinar engagement for a specific email

```sql
SELECT w.Email, wa.Name AS Action, w.Occurred, w.LanguageID
FROM BackOffice.Webinars w WITH (NOLOCK)
JOIN Dictionary.WebinarAction wa WITH (NOLOCK) ON wa.WebinarActionID = w.WebinarActionID
WHERE w.Email = 'customer@example.com'
ORDER BY w.Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Live Data, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Webinars | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.Webinars.sql*
