# AffiliateAdmin Schema Overview

> Complete back-office administration schema for the affiliate management platform, covering user identity, organizational grouping, access control, and all CRUD/reporting operations.

## Purpose

The AffiliateAdmin schema manages the **internal administrative side** of the affiliate platform. It provides:

1. **User Identity**: Azure AD-synced employee accounts (`Users`, `UserTableType`) representing back-office staff
2. **Organizational Grouping**: Categorizes affiliates into groups by marketing channel, business relationship, or account manager portfolio (`AffiliatesGroups`)
3. **Access Control**: Controls which employees can view which groups' data (`AffiliateGroups_Viewers`)
4. **Full CRUD Operations**: 64 stored procedures covering all affiliate administration workflows
5. **Reporting**: Summary reporting for affiliate performance (`ReportSummaryByAffiliate`)

## Object Inventory

| Type | Count | Description |
|------|-------|-------------|
| Tables | 9 | 3 core tables + 6 backup/junk tables (Noga migration snapshots) |
| User Defined Types | 1 | UserTableType for Azure AD sync batch operations |
| Stored Procedures | 64 | Full CRUD for affiliates, groups, banners, categories, languages, brands, pixels, announcements, media tags + reporting |
| Views | 0 | - |
| Functions | 0 | - |

## Schema Diagram

```
AffiliateAdmin.Users (18 rows)
  |
  | UserObjectID (GUID, from Azure AD)
  |
  +--< AffiliateAdmin.AffiliatesGroups (292 rows)
  |     via ManagerUserID (who manages this group)
  |     |
  |     | AffiliatesGroupsID (int IDENTITY)
  |     |
  |     +--< dbo.tblaff_Affiliates (cross-schema)
  |     |     via AffiliatesGroupsID (which group each affiliate belongs to)
  |     |
  |     +--< AffiliateAdmin.AffiliateGroups_Viewers (379 rows)
  |           via AffiliatesGroupsID + UserObjectID (composite PK)
  |           Controls which users can see which groups
  |
  +--< AffiliateAdmin.UserTableType (parameter type)
        Used by SyncUsersFromAzure for batch insert
```

## Stored Procedure Categories

### Read Operations (GET procedures - 32 SPs)
- **Affiliate Management**: GetAffiliates, GetAffiliatesAndBlockedCountries, GetAffiliateTierHierarchy
- **Group Management**: GetAffiliateGroupByID, GetAffiliateGroups, GetAffiliateGroupsList, GetAffiliateGroupsWithoutPermissions, GetNumberOfAffiliatesInGroups
- **Type Management**: GetAffiliateTypeData, GetAffiliateTypes, GetAffiliateTypesByGroup, GetAllAffiliateTypes
- **Banner & Media**: GetAllBanners, GetBannerById, GetBanners, GetAllMediaTagsByAffiliateId, GetMediaTags
- **Announcements**: GetAnnouncementByID, GetAnnouncements
- **Lookup/Dropdown**: GetAllCategories, GetAllCurencies, GetAllMarketingExpense, GetAuditSections, GetBrands, GetCategoryById, GetCountries, GetGeneralAffiliateResource, GetGeneralAffiliateTypeResource, GetGeneralBannerResource, GetIdentificationType, GetMarketingRegion
- **User/Audit**: GetUsers, GetAuditLog, GetAffiliatePixelByID, GetAffiliatePixels

### Write Operations (Create/Update/Delete - 32 SPs)
- **Upserts**: UpdateInsertAffiliate, UpdateInsertAffiliateGroup, UpdateInsertAffiliatePixel, UpdateInsertAffiliateType, UpdateInsertAnnouncement, UpdateInsertBanners, UpdateInsertBlockedCountries, UpdateInsertBrand, UpdateInsertCategory, UpdateInsertLanguage
- **Batch Updates**: UpdateAffiliatesWithAffiliateType, UpdateBannersArchive, UpdateBannersPriority, UpdateMediaTag, UpdateRegistrationRateCountry
- **Moves**: MoveAffiliatesToAffiliateGroup, MoveAllAffiliatesToAffiliateGroup
- **Deletes**: DeleteAffiliateGroups, DeleteAffiliateType, DeleteAnnouncements, DeleteCategory, DeleteLanguages, RemoveAffiliatePixel, RemoveBrands, RemoveMediaTags
- **Creates**: CreateMediaTag, CreateMediaTagBanner
- **Sync**: SyncUsersFromAzure
- **Category Assignment**: SetAffiliateTypeCategory
- **Reporting**: ReportSummaryByAffiliate, ReportSummaryByAffiliateNoga

## Cross-Schema Dependencies

The AffiliateAdmin schema heavily depends on objects in other schemas:

| Schema | Objects Referenced | Usage |
|--------|-------------------|-------|
| dbo | tblaff_Affiliates, tblaff_AffiliateTypes, tblaff_Banners, tblaff_Categories, tblaff_Languages, tblaff_Brands, tblaff_AffiliatePixels, tblaff_Country, tblaff_Announcement, AuditLog, MediaTag, MediaTagBanner, etc. | Core affiliate data tables |
| Dictionary | ChangedSections, AccountStatus, PixelTypes, IdentificationType, MarketingRegion, Currency, Action, ISAProduct, AccountType | Lookup/reference data |
| Affiliate | BlockedCountries, tblaff_AffiliateURLs, NvarcharList255 | Affiliate configuration |
| AffiliateCommission | RegistrationCommission, RegistrationVW, CreditVW, CreditCommission, Credit, CreditAccountMapping | Commission reporting |
| AffiliateConfiguration | FirstPositionAssetPlan, IOBPlan, ISAPlan, RegistrationCountryRateType, TraderFirstAssetPosition | Commission plan configuration |

## Key Patterns

1. **Audit Logging**: Nearly all write operations log changes to `dbo.AuditLog` with section ID, action type, old/new values, and user email
2. **Delete-If-Empty**: Delete procedures check for child records before allowing deletion (e.g., can't delete a group with affiliates, can't delete a category with banners)
3. **Upsert Pattern**: Most UpdateInsert* procedures use `@ID = 0` for INSERT and `@ID > 0` for UPDATE
4. **Pagination**: List procedures use ROW_NUMBER() OVER(ORDER BY ...) with dynamic sort columns
5. **TVP Parameters**: Batch operations use dbo.IDTableType for passing multiple IDs
6. **Binary Collation**: Azure AD sync uses Latin1_General_BIN for exact matching

## Documentation Status

| Metric | Value |
|--------|-------|
| Total objects | 74 |
| Documented | 74 (100%) |
| Average quality | 8.3/10 |
| Batches completed | 4 |
| Completed date | 2026-04-12 |

*Generated: 2026-04-12*
