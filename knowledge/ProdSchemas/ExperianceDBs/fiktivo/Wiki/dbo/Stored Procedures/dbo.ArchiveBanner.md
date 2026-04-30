# dbo.ArchiveBanner

> Archives or unarchives a banner by toggling its IsArchived flag in tblaff_Banners, allowing banners to be hidden from active use without permanent deletion.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Gil Haba |
| **Created** | 2022-07-03 (PART-210) |

---

## 1. Business Meaning

Banners are the creative assets (images, HTML ads) that affiliates use to promote the trading platform. Over time, banners become outdated, are superseded by new creative, or need to be temporarily withdrawn from use. Rather than deleting banners and losing their historical association with clicks and impressions, this procedure soft-deletes them by setting the IsArchived flag.

An archived banner is no longer selectable by affiliates when building their campaigns, but its data and statistics remain intact for historical reporting. The same procedure handles both archiving and unarchiving, with the caller passing the desired final state via @IsArchived.

This procedure was introduced as part of PART-210, the banner management initiative.

---

## 2. Business Logic

### 2.1 Archive Toggle

**What**: Sets the IsArchived column to the specified value for the target banner.

**Columns/Parameters Involved**: `@BannerID`, `@IsArchived`

**Rules**:
- @IsArchived = 1 archives the banner: it disappears from active banner selection in the affiliate portal
- @IsArchived = 0 unarchives the banner: it becomes selectable again
- No validation is performed to check whether the banner exists before the UPDATE; zero-row updates are silent
- The procedure does not log to AuditLog; audit tracking for banner changes is handled elsewhere if at all
- No concurrency guard or optimistic lock is applied

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @BannerID | IN | int | (required) | The primary key of the banner to archive or unarchive. References tblaff_Banners.BannerID. |
| 2 | @IsArchived | IN | bit | (required) | The desired archive state: 1=archive the banner (hide from active use), 0=unarchive (restore to active use). |

---

## 5. Relationships

### 5.1 Tables Written

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Banners | UPDATE | Sets IsArchived on the row matching @BannerID |

### 5.2 Tables Read

None.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.ArchiveBanner (stored procedure)
+-- dbo.tblaff_Banners (table) [UPDATE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Banners | Table | Target of the UPDATE statement |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Admin banner management UI | Application | Calls this procedure from the banner administration panel |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- No transaction wrapper; single-statement UPDATE is atomic
- No output or return value; success is implied by absence of exception
- Introduced under PART-210 (2022-07-03) as part of banner lifecycle management

---

## 8. Sample Queries

### 8.1 Archive a banner

```sql
EXEC dbo.ArchiveBanner
    @BannerID   = 42,
    @IsArchived = 1;
```

### 8.2 Unarchive a banner

```sql
EXEC dbo.ArchiveBanner
    @BannerID   = 42,
    @IsArchived = 0;
```

### 8.3 List all currently archived banners

```sql
SELECT BannerID, BannerName, Width, Height, BrandId
FROM dbo.tblaff_Banners WITH (NOLOCK)
WHERE IsArchived = 1
ORDER BY BannerName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.ArchiveBanner | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.ArchiveBanner.sql*
