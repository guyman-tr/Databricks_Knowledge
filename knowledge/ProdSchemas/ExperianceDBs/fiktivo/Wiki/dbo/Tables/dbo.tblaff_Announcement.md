# dbo.tblaff_Announcement

> System announcements and news items displayed to affiliates in the affiliate portal, with scheduled publication and expiration dates.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | AnnouncementID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 on AnnouncementDate+ExpirationDate) |

---

## 1. Business Meaning

This table stores announcements and news items that are displayed to affiliates when they log in to the affiliate portal. Each announcement has a publication date, an expiration date, and can be flagged as news content. Announcements can be targeted to specific affiliate types via the junction table tblaff_Announcement_AffiliateType.

Without this table, the platform could not communicate updates, promotions, or policy changes to affiliates through the portal. Announcements are managed by admin users with Announcements_* permissions. The table is small (15 rows) and primarily contains test/development entries.

Deleting an announcement cascade-deletes its affiliate type targeting via the tblaff_Announcement_DTrig trigger.

---

## 2. Business Logic

### 2.1 Scheduled Publication

**What**: Announcements have a defined visibility window controlled by date range.

**Columns/Parameters Involved**: `AnnouncementDate`, `AnnouncementExpirationDate`

**Rules**:
- An announcement is visible only when current date is between AnnouncementDate and AnnouncementExpirationDate
- Both default to GETDATE() on creation - must be explicitly set to meaningful dates
- AnnouncementNews flag differentiates persistent announcements (0) from news items (1)

---

## 3. Data Overview

| AnnouncementID | AnnouncementHeadline | AnnouncementDate | ExpirationDate | News | Meaning |
|----------------|---------------------|-----------------|---------------|------|---------|
| 149 | This announcement headline 3 | 2019-07-01 | 2020-01-01 | Yes | Example news item with a 6-month visibility window, created for testing the news feature |
| 184 | (Hebrew text) | 2025-09-14 | 2025-10-06 | No | Recent test announcement created by developers validating Hebrew language support |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AnnouncementID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Referenced by tblaff_Announcement_AffiliateType.AnnouncementID for type targeting. |
| 2 | AnnouncementDate | datetime | NO | GETDATE() | CODE-BACKED | Publication start date - announcement becomes visible to affiliates on this date. |
| 3 | AnnouncementExpirationDate | datetime | NO | GETDATE() | CODE-BACKED | Publication end date - announcement is hidden after this date. |
| 4 | AnnouncementHeadline | nvarchar(1000) | NO | - | CODE-BACKED | Title/headline text displayed prominently in the affiliate portal announcement section. |
| 5 | AnnouncementBody | nvarchar(max) | YES | - | CODE-BACKED | Full HTML/rich text body content of the announcement. |
| 6 | AnnouncementImage | nvarchar(1000) | YES | - | NAME-INFERRED | URL or path to an image associated with the announcement. |
| 7 | AnnouncementNews | bit | NO | 0 | CODE-BACKED | Content type flag. 0 = standard announcement (operational notice). 1 = news item (marketing/informational content). Controls display section in portal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Announcement_AffiliateType | AnnouncementID | Implicit FK | Maps which affiliate types see this announcement. Cascade-deleted via trigger. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Announcement_AffiliateType | Table | AnnouncementID referenced; cascade-deleted on announcement removal |
| dbo.GetAnnouncementById | Stored Procedure | READER |
| dbo.GetAnnouncements | Stored Procedure | READER |
| dbo.UpdateInsertAnnouncement | Stored Procedure | WRITER/MODIFIER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_Announcement | CLUSTERED PK | AnnouncementID | - | - | Active |
| Announcement_Covered | NONCLUSTERED | AnnouncementDate, AnnouncementExpirationDate | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Announcement_AnnouncementDate | DEFAULT | GETDATE() |
| DF_tblaff_Announcement_AnnouncementExpirationDate | DEFAULT | GETDATE() |
| DF_tblaff_Announcement_AnnouncementNews_1 | DEFAULT | 0 (standard announcement) |
| tblaff_Announcement_DTrig | TRIGGER (DELETE) | Cascade-deletes tblaff_Announcement_AffiliateType rows |

---

## 8. Sample Queries

### 8.1 Get currently visible announcements
```sql
SELECT AnnouncementID, AnnouncementHeadline, AnnouncementBody, AnnouncementNews
FROM dbo.tblaff_Announcement WITH (NOLOCK)
WHERE GETDATE() BETWEEN AnnouncementDate AND AnnouncementExpirationDate
ORDER BY AnnouncementDate DESC
```

### 8.2 Get announcements targeted to a specific affiliate type
```sql
SELECT a.AnnouncementID, a.AnnouncementHeadline, a.AnnouncementDate
FROM dbo.tblaff_Announcement a WITH (NOLOCK)
JOIN dbo.tblaff_Announcement_AffiliateType aat WITH (NOLOCK) ON a.AnnouncementID = aat.AnnouncementID
WHERE aat.AffiliateTypeID = 2
  AND GETDATE() BETWEEN a.AnnouncementDate AND a.AnnouncementExpirationDate
```

### 8.3 List news items
```sql
SELECT AnnouncementID, AnnouncementHeadline, AnnouncementDate, AnnouncementExpirationDate
FROM dbo.tblaff_Announcement WITH (NOLOCK)
WHERE AnnouncementNews = 1
ORDER BY AnnouncementDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.9/10 (Elements: 8.6/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Announcement | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Announcement.sql*
