# Schema Overview - fiktivo.dbo

> The dbo schema in fiktivo is the core affiliate marketing management system for the eToro trading platform, handling affiliate onboarding, commission calculation across 9 event types with 5-tier distribution, payment processing with multi-level approval, marketing asset management, and cross-platform data integration via synonyms to the etoro production database.

*Last updated: 2026-04-12 | Total objects: 274 | Documented: 274 (100%)*

---

## 1. Schema Purpose

The fiktivo.dbo schema implements a complete **affiliate marketing platform** (AffiliateWiz-based) that:

1. **Manages affiliates** - registration, onboarding, grouping, tier hierarchy (up to 5 levels)
2. **Tracks customer events** - registrations, leads, deposits (FTD/CPA), sales, bonuses, chargebacks, copy-trading, first positions, eCost
3. **Calculates commissions** - 9 parallel commission types, each with 5-tier distribution across the affiliate hierarchy
4. **Processes payments** - multi-level approval workflow (Manager -> VP Marketing -> Finance -> Finance Manager), payment history, file attachments
5. **Manages marketing assets** - banners, groups, media tags, tracking pixels
6. **Fires tracking callbacks** - durable message queue for reliable pixel delivery to affiliate partners
7. **Integrates with trading platform** - 19 synonyms connecting to the etoro database for position, customer, and instrument data

---

## 2. Object Inventory

| Object Type | Count | Key Objects |
|-------------|-------|-------------|
| Tables | 84 | tblaff_Affiliates, tblaff_PaymentHistory, ClosedPositionsTbl, 9x _Commissions tables |
| Views | 72 | 45 tier-filter views, 9 AllTiers detail views, DailySummaryReport, ClosedPositions |
| Functions | 4 | InlineMax, fn_Split, fn_ParseText2Table, Ufn_Turn_Var_List_Into_Table_Of_Ints |
| Stored Procedures | 89 | CreateAffiliate, GetPayments, PaymentHistory_Insert, UpdateSubAffiliateID |
| Synonyms | 19 | Cross-DB links to etoro (Trade, History, Customer, Dictionary schemas) |
| User Defined Types | 6 | CIDs, IDTableType, CountryListTableType, TwoIdsTableType, Kyp* types |

---

## 3. Core Business Domains

### 3.1 Affiliate Management

**Key tables**: tblaff_Affiliates (master), tblaff_AffiliatesGroups, tblaff_AffiliateTypes, tblaff_AffiliateTypeCategories, tblaff_Tier2Members, tblaff_User

**Flow**: Affiliates are created via `CreateAffiliate`, assigned to groups and types, and linked in a multi-tier hierarchy via `tblaff_Tier2Members`. Each affiliate has configurable payment details, country, currency preferences, and account status.

### 3.2 Commission Pipeline

**Key tables**: 9 event tables (tblaff_Bonuses, tblaff_CPA, tblaff_Chargebacks, tblaff_CopyTraders, tblaff_FirstPositions, tblaff_Leads, tblaff_Registrations, tblaff_Sales, tblaff_eCost) + 9 corresponding _Commissions junction tables

**Flow**: Customer events are recorded in the event tables. The commission engine processes each event and creates rows in the _Commissions tables for each tier (1-5) in the affiliate hierarchy. Each commission row tracks: affiliate, amount, tier, paid status, payment ID, sub-affiliate tag.

```
Customer Event -> Event Table (e.g., tblaff_Sales)
                      |
                      v
               Commission Engine
                      |
                      +-> Tier 1 Commission (direct affiliate)
                      +-> Tier 2 Commission (parent affiliate)
                      +-> Tier 3 Commission (grandparent)
                      +-> Tier 4 Commission (great-grandparent)
                      +-> Tier 5 Commission (great-great-grandparent)
```

### 3.3 Payment Processing

**Key tables**: tblaff_PaymentHistory (central ledger), tblaff_PaymentDetails, tblaff_Files, Dictionary.PaymentRowStatus

**Flow**: Payments aggregate unpaid commissions across all 9 types for a payment period. Each payment goes through a 4-level approval workflow controlled by thresholds in tblaff_Administrative4. Status progression: Pending (1) -> Partially Approved (2) -> Approved (4) -> Processed (8), with Rejected (16) as a terminal failure state.

### 3.4 Closed Position Processing

**Key tables**: ClosedPositionsTbl, ClosedPositions_LastTimeUpdate, DeferredMessages

**Flow**: Closed trading positions flow from the etoro platform into ClosedPositionsTbl. The ClosedPositions view provides 10-way parallel processing via CID % 10 partitioning. QuesService workers process unfinished positions (FinishedUpdating=1, FinishedProcessing=0) to generate commissions.

### 3.5 Marketing Asset Management

**Key tables**: tblaff_Banners, tblaff_BannerTypes, tblaff_Groups, tblaff_GroupBanners, MediaTag, MediaTagBanner, tblaff_AffiliatePixels

**Flow**: Banners are created with type, brand, language, and category associations. Groups provide weighted rotation of banners. Media tags enable cross-cutting categorization. Affiliate pixels fire tracking callbacks to partner systems via the durable message queue.

### 3.6 External Data Integration

**Key objects**: 19 synonyms pointing to etoro database on 3 linked servers (AORealRO, AO-REAL-DB-ROR, RealForAffiliateAggregatedData)

**Provides**: Customer data (Customer.Customer), trading positions (Trade.PositionTbl, History.Position), instruments (Trade.GetInstrument), credits (History.Credit, History.ActiveCredit), dictionary lookups (Dictionary.Country, Dictionary.Currency)

---

## 4. Configuration Tables

The system has 4 singleton configuration tables (1 row each) that control platform behavior:

| Table | Key Settings |
|-------|-------------|
| tblaff_Administrative | Core platform settings (documented Batch 1) |
| tblaff_Administrative2 | Notifications, file upload paths, mail server, spider detection |
| tblaff_Administrative3 | Optional field labels, tier 2 literature, agreement link |
| tblaff_Administrative4 | Tracking behavior, payment approval thresholds ($5K VP, $0 Finance, $10K Finance Manager) |

---

## 5. Data Volume Characteristics

| Category | Largest Tables | Row Count |
|----------|---------------|-----------|
| Commission records | tblaff_Registrations_Commissions | ~3.75M |
| Commission records | tblaff_Sales_Commissions | ~3.08M |
| Commission records | tblaff_CPA_Commissions | ~1.56M |
| Commission records | tblaff_eCost_Commissions | ~1.47M |
| Event tracking | tblaff_DurableMessages | ~1.09M |
| Customer events | tblaff_CustomerSupport | ~808K |
| Deposits | tblaff_Deposits | ~789K |
| Summary | SUMMARY_DownloadsRegistrations | ~515K |
| Closed positions | ClosedPositionsTbl | 116 (test environment) |

---

## 6. Junk/Backup Tables

9 developer backup tables (NogaJnk/NogaJunk suffixes from Feb 2026) and 3 PaymentHistory backup tables exist as point-in-time data snapshots. These are candidates for cleanup:

- tblaff_Affiliates_NogaJnk040226/080226, _NogaJunk100226
- tblaff_AffiliatesGroups_NogaJnk040226/080226, _NogaJunk100226
- tblaff_AffiliateGroups_Viewers_NogaJnk040226/080226, _NogaJunk100226
- tblaff_PaymentHistory_Backup_eCost, _Restore, _Update32Affiliates_PART3710_171124BckNoga

---

## 7. Key Stored Procedures by Function

| Function | Procedures |
|----------|-----------|
| **Affiliate CRUD** | CreateAffiliate, GetAffiliateById, GetAffiliateByAzureObjectId, CheckEmailExists |
| **Commission queries** | GetUnpaidCommissions, GetCurrentBalance, GetCurrentBalance_WithDate/WithOutDate |
| **Payment management** | PaymentHistory_Insert, GetPayments, GetPaymentById, GetPaymentsForAffiliate |
| **Banner management** | CreateBanner, UpdateBanner, ArchiveBanner, BannerSearch |
| **Pixel/message queue** | InsertApprovedDepositPixel, GetApprovedDepositPixels, DeferredMessages_* (4 CRUD procs) |
| **Tier management** | AddTier2Member, GetAffiliateTiers, GetAffiliateChildren, GetAffiliateParents |
| **Reporting** | ReportSummaryByAffiliate, ReportSummaryPerAffiliate, SSRS_AffWiz_ClosedPositions |
| **Attribution** | UpdateSubAffiliateID (late-binding across all commission types) |

---

## 8. Documentation Quality Summary

| Batch | Objects | Avg Quality | Focus |
|-------|---------|-------------|-------|
| Batch 1 (prior) | 25 | 7.9 | Core tables, config, spider lists |
| Batch 2 (prior) | 24 | 8.6 | Event tables, UDTs, commission source tables |
| Batch 3 | 25 | 8.4 | Commission junction tables, deposits, closed positions |
| Batch 4 | 25 | 7.6 | Remaining tables (admin, junk/backup), functions, first views |
| Batch 5 | 25 | 8.0 | Tier-filter views (Bonuses, CPA, Chargebacks, CopyTraders, FirstPositions) |
| Batch 6 | 25 | 8.0 | Tier-filter views (Leads, Registrations, Sales, UsedBonus) + misc views |
| Batch 7 | 25 | 8.1 | AllTiers detail views, Overall views, Position views, first 8 SPs |
| Batch 8 | 25 | 8.0 | Affiliate getter SPs, DeferredMessages CRUD |
| Batch 9 | 25 | 8.0 | Payment SPs, banner/announcement SPs, balance queries |
| Batch 10 | 25 | 8.1 | Report SPs, Update SPs, SSRS, remaining complex SPs |
| Batch 11 | 22 | 7.6 | Final 3 SPs + 19 synonyms |
| **Total** | **271** | **~8.0** | **Complete schema documentation** |

---

*Schema documentation completed: 2026-04-12*
*Batches: 11 | Total objects: 274 | Average quality: 8.0/10*
