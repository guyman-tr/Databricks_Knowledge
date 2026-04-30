# History Schema Overview - fiktivo

> The History schema contains temporal history tables and ETL audit tables that preserve the complete change history of the fiktivo affiliate management system.

## Schema Purpose

The History schema serves two distinct purposes in the fiktivo affiliate database:

1. **Temporal History Tables** (17 tables): SQL Server system-versioned temporal history tables that automatically capture every previous version of records in their paired base tables. These provide an immutable audit trail of all changes to affiliate accounts, commission plans, KYP verification records, marketing assets, and customer attribution data.

2. **ETL Bridge/Audit Tables** (3 tables): Standalone tables that support the data synchronization pipeline between the eToro trading platform and the fiktivo affiliate commission system.

## Table Categories

### Temporal History Tables (System-Versioned)

These tables are automatically managed by SQL Server's SYSTEM_VERSIONING feature. When a row in the base table is updated or deleted, the previous version is automatically moved to the corresponding History table with ValidFrom/ValidTo timestamps.

| History Table | Base Table | Base Schema | Rows | Description |
|---|---|---|---|---|
| [History.tblaff_Affiliates](Tables/History.tblaff_Affiliates.md) | dbo.tblaff_Affiliates | dbo | 48,649 | Core affiliate account profiles, plans, payment details |
| [History.RegistrationMetaData](Tables/History.RegistrationMetaData.md) | AffiliateCommission.RegistrationMetaData | AffiliateCommission | 1,834,748 | Customer registration attribution metadata |
| [History.KYPAffiliate](Tables/History.KYPAffiliate.md) | KYP.Affiliate | KYP | 3,180 | KYP verification status and corporate identity |
| [History.KYPAffiliateKYPDocs](Tables/History.KYPAffiliateKYPDocs.md) | KYP.AffiliateKYPDocs | KYP | 1,675 | KYP document submissions |
| [History.AffiliateBlockedCountries](Tables/History.AffiliateBlockedCountries.md) | Affiliate.BlockedCountries | Affiliate | 1,049 | Per-affiliate country blocking |
| [History.KYPAffiliateCorporateMembers](Tables/History.KYPAffiliateCorporateMembers.md) | KYP.AffiliateCorporateMembers | KYP | 905 | Corporate member records |
| [History.tblaff_AffiliateURLs](Tables/History.tblaff_AffiliateURLs.md) | Affiliate.tblaff_AffiliateURLs | Affiliate | 613 | Affiliate website URLs |
| [History.tblaff_AffiliateTypes](Tables/History.tblaff_AffiliateTypes.md) | dbo.tblaff_AffiliateTypes | dbo | 555 | Commission plan configurations (120+ columns) |
| [History.FirstPositionAssetPlan](Tables/History.FirstPositionAssetPlan.md) | AffiliateConfiguration.FirstPositionAssetPlan | AffiliateConfiguration | 485 | CPA rates by asset class and country |
| [History.tblaff_User](Tables/History.tblaff_User.md) | dbo.tblaff_User | dbo | 367 | Admin user permissions (140 columns) |
| [History.tblaff_Tier2Members](Tables/History.tblaff_Tier2Members.md) | dbo.tblaff_Tier2Members | dbo | 294 | Sub-affiliate tier membership |
| [History.tblaff_Banners](Tables/History.tblaff_Banners.md) | dbo.tblaff_Banners | dbo | 286 | Marketing banner/creative definitions |
| [History.KYPAffiliateCountriesOfOperation](Tables/History.KYPAffiliateCountriesOfOperation.md) | KYP.AffiliateCountriesOfOperation | KYP | 150 | KYP affiliate operating countries |
| [History.MediaTag](Tables/History.MediaTag.md) | dbo.MediaTag | dbo | 39 | Media tag definitions |
| [History.MediaTagBanner](Tables/History.MediaTagBanner.md) | dbo.MediaTagBanner | dbo | 15 | Media tag-to-banner associations |
| [History.KYPAffiliateKYPMarketingMethods](Tables/History.KYPAffiliateKYPMarketingMethods.md) | KYP.AffiliateKYPMarketingMethods | KYP | 5 | KYP affiliate marketing methods |
| [History.tblaff_CPACountriesToAffiliateTypeID](Tables/History.tblaff_CPACountriesToAffiliateTypeID.md) | dbo.tblaff_CPACountriesToAffiliateTypeID | dbo | 0 | CPA country eligibility (empty) |

### ETL Bridge/Audit Tables (Standalone)

These tables are NOT temporal history tables. They are standalone tables used by the ETL pipeline between eToro and fiktivo.

| History Table | Rows | Description |
|---|---|---|
| [History.ClosedPosition](Tables/History.ClosedPosition.md) | 2,527,993 | Bridge table mapping individual eToro position IDs to aggregated commission records (legacy linked-server pipeline) |
| [History.ClosedPosition_ADF](Tables/History.ClosedPosition_ADF.md) | 0 | ADF variant of the closed-position bridge (ADF pipeline - pre-production) |
| [History.LastProcessedDataFromeToro](Tables/History.LastProcessedDataFromeToro.md) | 244,834 | Audit log of credit-data batches processed from eToro |

## Key Patterns

### Temporal Table Pattern
- All temporal tables have `ValidFrom` (datetime2(7)) and `ValidTo` (datetime2(7)) columns
- Most have a `Trace` (nvarchar(733)) column containing JSON session context: HostName, AppName, SUserName, SPID, DBName, ObjectName
- Clustered index is always on (ValidTo ASC, ValidFrom ASC) for efficient temporal range queries
- All use PAGE compression
- No PK, FK, or check constraints - integrity enforced on base tables

### Cross-Schema Dependencies
All Dictionary lookup tables referenced by History columns are already documented in the Dictionary schema wiki.

## Data Volume Summary

- **Total rows across all tables**: ~4,662,348
- **Largest table**: History.RegistrationMetaData (1.8M rows)
- **Second largest**: History.ClosedPosition (2.5M rows)
- **Empty tables**: History.ClosedPosition_ADF, History.tblaff_CPACountriesToAffiliateTypeID

---

*Generated: 2026-04-12*
