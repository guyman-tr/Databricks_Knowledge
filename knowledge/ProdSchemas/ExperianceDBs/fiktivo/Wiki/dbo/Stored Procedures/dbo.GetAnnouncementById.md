# dbo.GetAnnouncementById

> Retrieves a single announcement record with its affiliate-type targeting rows by announcement ID, joining tblaff_Announcement to tblaff_Announcement_AffiliateType.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown |
| **Created** | Unknown |

---

## 1. Business Meaning

Announcements are platform-wide or affiliate-type-specific messages (news items, notices) displayed on the affiliate portal. Each announcement can be targeted to one or more affiliate types via rows in tblaff_Announcement_AffiliateType.

This procedure fetches a single announcement by its primary key together with all of its affiliate-type targeting rows. It is the canonical read path for loading an announcement for display or for editing in the admin UI. The LEFT JOIN ensures the announcement record is always returned even if no affiliate-type targeting has been configured (i.e., the announcement applies globally).

---

## 2. Business Logic

### 2.1 Announcement Lookup with Targeting

**What**: Returns one announcement and its associated affiliate-type targeting rows.

**Columns/Parameters Involved**: `@Id`, `Announcement.AnnouncementID`, `Announcement_AffiliateType.AffiliateTypeID`

**Rules**:
- @Id must match an existing AnnouncementID; if no match exists, zero rows are returned
- The LEFT JOIN to tblaff_Announcement_AffiliateType means that if the announcement has N affiliate-type rows, N result rows are returned (one per targeting row); if zero targeting rows exist, one row is returned with NULL values for the AffiliateType columns
- No expiration-date filter is applied; the procedure returns the announcement regardless of whether it is still active

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @Id | IN | int | (required) | The AnnouncementID primary key of the announcement to retrieve. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Announcement | SELECT | Primary source of announcement content |
| dbo.tblaff_Announcement_AffiliateType | SELECT (LEFT JOIN) | Affiliate-type targeting rows for the announcement |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| AnnouncementID | tblaff_Announcement | Primary key |
| AnnouncementDate | tblaff_Announcement | Date the announcement was published |
| AnnouncementExpirationDate | tblaff_Announcement | Date after which the announcement should no longer be shown |
| AnnouncementHeadline | tblaff_Announcement | Short title displayed at the top of the announcement |
| AnnouncementBody | tblaff_Announcement | Full body text of the announcement |
| AnnouncementImage | tblaff_Announcement | URL or path to an optional image attached to the announcement |
| AnnouncementNews | tblaff_Announcement | Flag or text field indicating news-type classification |
| ID | tblaff_Announcement_AffiliateType | Primary key of the targeting row (NULL if no targeting configured) |
| AffiliateTypeID | tblaff_Announcement_AffiliateType | The affiliate type this announcement is targeted to (NULL if no targeting) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAnnouncementById (stored procedure)
+-- dbo.tblaff_Announcement (table) [SELECT]
+-- dbo.tblaff_Announcement_AffiliateType (table) [LEFT JOIN]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Announcement | Table | Primary source of announcement data |
| dbo.tblaff_Announcement_AffiliateType | Table | Provides affiliate-type targeting rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Announcement detail/edit UI | Application | Calls this procedure to load announcement content and targeting for display or editing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON is present; no rowcount messages are sent to the caller
- WITH (NOLOCK) hints on both tables allow dirty reads, consistent with the read-heavy affiliate portal pattern
- The LEFT JOIN produces multiple rows per announcement when multiple affiliate-type targets exist; callers must handle the fan-out

---

## 8. Sample Queries

### 8.1 Fetch a specific announcement

```sql
EXEC dbo.GetAnnouncementById @Id = 7;
```

### 8.2 Verify targeting rows for an announcement

```sql
SELECT ID, AnnouncementID, AffiliateTypeID
FROM dbo.tblaff_Announcement_AffiliateType WITH (NOLOCK)
WHERE AnnouncementID = 7;
```

### 8.3 Check whether an announcement is still active

```sql
SELECT AnnouncementID, AnnouncementHeadline, AnnouncementExpirationDate
FROM dbo.tblaff_Announcement WITH (NOLOCK)
WHERE AnnouncementID = 7
  AND AnnouncementExpirationDate > GETDATE();
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetAnnouncementById | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAnnouncementById.sql*
