# dbo.GetAnnouncementsByAffiliateType

> Returns non-expired announcements targeted to a specific affiliate type, joining tblaff_Announcement to tblaff_Announcement_AffiliateType and filtering by both affiliate type and expiration date.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown |
| **Created** | Unknown |

---

## 1. Business Meaning

Different affiliate types on the platform (e.g., standard, IB, white-label) may receive different announcements tailored to their programme. This procedure returns only the live announcements that are explicitly targeted at the affiliate type supplied by the caller.

By combining an expiration-date filter with an affiliate-type filter, the procedure ensures that the portal displays only timely, relevant messages to each affiliate. An INNER JOIN to the targeting table means that announcements with no targeting rows (untargeted) are excluded, ensuring that only intentionally targeted announcements are surfaced.

---

## 2. Business Logic

### 2.1 Affiliate-Type Scoped, Non-Expired Announcements

**What**: Returns active announcements targeted to the specified affiliate type.

**Columns/Parameters Involved**: `@AffiliateTypeId`, `@ReferenceDate`, `Announcement.AnnouncementExpirationDate`, `Announcement_AffiliateType.AffiliateTypeID`

**Rules**:
- The INNER JOIN ensures only announcements that have at least one targeting row are returned; untargeted announcements are excluded
- AffiliateTypeID must equal @AffiliateTypeId; announcements targeting other types are excluded
- AnnouncementExpirationDate must be strictly greater than @ReferenceDate; expired announcements are excluded
- If no announcements match, zero rows are returned with no error
- The same announcement can appear in multiple rows of tblaff_Announcement_AffiliateType but will produce only one result row here because only the announcement columns are selected (the targeting table is used only as a join filter)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @AffiliateTypeId | IN | int | (required) | The affiliate type identifier used to filter announcement targeting rows. Only announcements explicitly targeted to this type are returned. |
| 2 | @ReferenceDate | IN | datetime | (required) | The cutoff datetime. Announcements with AnnouncementExpirationDate greater than this value are considered active. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Announcement | SELECT (INNER JOIN) | Source of announcement content |
| dbo.tblaff_Announcement_AffiliateType | SELECT (INNER JOIN) | Filters to announcements targeted at the requested affiliate type |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| AnnouncementID | tblaff_Announcement | Primary key |
| AnnouncementDate | tblaff_Announcement | Publication date |
| AnnouncementExpirationDate | tblaff_Announcement | Expiry date (always greater than @ReferenceDate in results) |
| AnnouncementHeadline | tblaff_Announcement | Short title |
| AnnouncementBody | tblaff_Announcement | Full announcement text |
| AnnouncementImage | tblaff_Announcement | Optional image URL |
| AnnouncementNews | tblaff_Announcement | News-type classification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAnnouncementsByAffiliateType (stored procedure)
+-- dbo.tblaff_Announcement (table) [INNER JOIN]
+-- dbo.tblaff_Announcement_AffiliateType (table) [INNER JOIN, filter]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Announcement | Table | Source of announcement content |
| dbo.tblaff_Announcement_AffiliateType | Table | Provides affiliate-type targeting filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate portal per-type announcement feed | Application | Calls this procedure to display type-specific announcements to logged-in affiliates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- WITH (NOLOCK) on both tables; accepts dirty reads consistent with portal read pattern
- INNER JOIN excludes untargeted announcements; use dbo.GetAnnouncements for untargeted feed
- No duplicate-elimination logic; if somehow the same announcement has two rows for the same AffiliateTypeID, it would appear twice

---

## 8. Sample Queries

### 8.1 Get active announcements for affiliate type 3

```sql
EXEC dbo.GetAnnouncementsByAffiliateType
    @AffiliateTypeId = 3,
    @ReferenceDate   = GETDATE();
```

### 8.2 Get announcements that were active on a specific date

```sql
EXEC dbo.GetAnnouncementsByAffiliateType
    @AffiliateTypeId = 1,
    @ReferenceDate   = '2025-06-01 00:00:00';
```

### 8.3 Find distinct affiliate types that have targeted announcements

```sql
SELECT DISTINCT AffiliateTypeID
FROM dbo.tblaff_Announcement_AffiliateType WITH (NOLOCK)
ORDER BY AffiliateTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetAnnouncementsByAffiliateType | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAnnouncementsByAffiliateType.sql*
