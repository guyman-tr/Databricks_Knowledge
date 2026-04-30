# dbo.GetAnnouncements

> Returns all non-expired announcements as of a given reference datetime, without affiliate-type filtering.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown |
| **Created** | Unknown |

---

## 1. Business Meaning

The affiliate portal must display only current, non-expired announcements to users. This procedure returns the full list of announcements whose expiration date is still in the future relative to the supplied @ReferenceDate, regardless of which affiliate type the viewer belongs to.

Callers typically pass the current timestamp as @ReferenceDate so they receive only live announcements. The unfiltered (no affiliate-type constraint) result set is used in contexts where the caller will perform its own type-level filtering after retrieval, or where all affiliate types share the same announcement feed.

---

## 2. Business Logic

### 2.1 Expiration Filter

**What**: Excludes announcements that have passed their expiration date.

**Columns/Parameters Involved**: `@ReferenceDate`, `Announcement.AnnouncementExpirationDate`

**Rules**:
- Only announcements where AnnouncementExpirationDate > @ReferenceDate are returned
- An announcement expiring exactly at @ReferenceDate is excluded (strict greater-than)
- No start-date filter is applied; newly created announcements are returned as soon as they exist in the table
- No affiliate-type filtering; the procedure returns announcements for all types

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @ReferenceDate | IN | datetime | (required) | The cutoff datetime used to determine which announcements are still active. Announcements with AnnouncementExpirationDate greater than this value are returned. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Announcement | SELECT | Source of all announcement records, filtered by expiration date |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| AnnouncementID | tblaff_Announcement | Primary key |
| AnnouncementDate | tblaff_Announcement | Publication date of the announcement |
| AnnouncementExpirationDate | tblaff_Announcement | Expiry date; all returned rows have this value greater than @ReferenceDate |
| AnnouncementHeadline | tblaff_Announcement | Short title of the announcement |
| AnnouncementBody | tblaff_Announcement | Full body text |
| AnnouncementImage | tblaff_Announcement | Optional image URL |
| AnnouncementNews | tblaff_Announcement | News-type classification flag or text |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAnnouncements (stored procedure)
+-- dbo.tblaff_Announcement (table) [SELECT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Announcement | Table | Sole source of announcement records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate portal announcement feed | Application | Calls this procedure to populate the announcement list visible to all affiliates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- WITH (NOLOCK) hint is applied; accepts dirty reads consistent with the read-heavy portal pattern
- No affiliate-type join; use dbo.GetAnnouncementsByAffiliateType for type-scoped retrieval

---

## 8. Sample Queries

### 8.1 Retrieve all currently active announcements

```sql
EXEC dbo.GetAnnouncements @ReferenceDate = GETDATE();
```

### 8.2 Retrieve announcements that were active at a historical point in time

```sql
EXEC dbo.GetAnnouncements @ReferenceDate = '2025-01-01 00:00:00';
```

### 8.3 Count active announcements today

```sql
SELECT COUNT(*)
FROM dbo.tblaff_Announcement WITH (NOLOCK)
WHERE AnnouncementExpirationDate > GETDATE();
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetAnnouncements | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAnnouncements.sql*
