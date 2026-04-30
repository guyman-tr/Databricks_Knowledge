# dbo.UpdateBanner

## 1. Overview

Updates an existing banner record in `tblaff_Banners` with the supplied configuration and, when media tag IDs are provided, delegates tag-to-banner association management to `dbo.CreateMediaTagBanner`. All operations run within an explicit transaction with TRY/CATCH error handling to ensure atomicity between the banner update and tag association changes.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_Banners |
| Secondary Tables | dbo.MediaTagBanner (via CreateMediaTagBanner), dbo.AuditLog (via CreateMediaTagBanner) |
| Operation | UPDATE, EXEC |
| Transaction | Yes (explicit BEGIN/COMMIT with TRY/CATCH) |

## 3. Return / Result Set

N/A for stored procedure.

No result set is returned.

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @BannerID | IN | int | required | ID of the banner to update. |
| @CategoryID | IN | INT | NULL | Banner category. |
| @TypeID | IN | int | NULL | Banner type. |
| @BannerName | IN | nvarchar(255) | required | Display name of the banner. |
| @ImageURL | IN | nvarchar(255) | NULL | URL of the banner image. |
| @TargetURL | IN | nvarchar(255) | NULL | Destination URL when the banner is clicked. |
| @AltText | IN | nvarchar(255) | NULL | Alt text for accessibility. |
| @Width | IN | int | NULL | Banner width in pixels. |
| @Height | IN | int | NULL | Banner height in pixels. |
| @NotesToAffiliate | IN | nvarchar(1000) | NULL | Notes visible to the affiliate. |
| @AdvancedBanner | IN | bit | required | Whether this is an advanced (HTML) banner. |
| @AdCode | IN | ntext | NULL | Raw HTML/ad code for advanced banners. |
| @TargetWindow | IN | nvarchar(50) | NULL | Link target window (e.g., _blank). |
| @LanguageId | IN | int | NULL | Language associated with the banner. |
| @BrandId | IN | int | NULL | Brand associated with the banner. |
| @Priority | IN | int | NULL | Display priority ordering. |
| @IsArchived | IN | bit | required | Whether the banner is archived. |
| @ChangedByUserID | IN | int | NULL | UserID performing the update; passed to CreateMediaTagBanner for audit. |
| @IdTable | IN | dbo.IDTableType READONLY | required | Table of media tag IDs to associate; empty table means no tag changes. |

## 5. Business Logic

1. Opens an explicit transaction (`BEGIN TRAN`).
2. UPDATEs `tblaff_Banners` setting all fields for `@BannerID`.
3. If `@IdTable` contains at least one row (`EXISTS (SELECT 1 FROM @IdTable)`), calls `EXEC dbo.CreateMediaTagBanner @BannerID, @IdTable, @ChangedByUserID, @NotesToAffiliate` to manage the media tag associations.
4. COMMITs the transaction.
5. CATCH block: rolls back if outermost transaction; commits otherwise; re-throws via `THROW`.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.tblaff_Banners | Table | dbo | Target banner record |
| dbo.CreateMediaTagBanner | Stored Procedure | dbo | Manages MediaTagBanner associations for the banner |
| dbo.IDTableType | User-Defined Table Type | dbo | Table type for @IdTable media tag IDs |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- Single-row UPDATE; performance is minimal.
- The conditional EXEC of `CreateMediaTagBanner` only fires when tag IDs are supplied, avoiding unnecessary work on pure banner-attribute updates.
- `@AdCode` is typed `ntext`, a deprecated SQL Server type; consider migrating to `nvarchar(max)` in a future schema update.

## 8. Usage Examples

```sql
DECLARE @tags dbo.IDTableType;
INSERT INTO @tags VALUES (5), (12);

EXEC dbo.UpdateBanner
    @BannerID        = 100,
    @CategoryID      = 3,
    @TypeID          = 1,
    @BannerName      = N'Summer Campaign Banner',
    @ImageURL        = N'https://cdn.example.com/summer.png',
    @TargetURL       = N'https://example.com/landing',
    @AdvancedBanner  = 0,
    @IsArchived      = 0,
    @ChangedByUserID = 99,
    @IdTable         = @tags;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2022-07-03 | Gil Haba | PART-210 | Created |
| 2022-01-03 | Gil Haba | N/A | Improved AuditLog values with better ReasonOfChange (approved by Noga) |

---
*Object: dbo.UpdateBanner | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateBanner.sql*
