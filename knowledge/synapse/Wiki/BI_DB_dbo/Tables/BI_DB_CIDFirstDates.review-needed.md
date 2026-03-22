# Review Sidecar: BI_DB_dbo.BI_DB_CIDFirstDates

> Reviewer checklist for wiki quality and accuracy.

## Generation Metadata

| Property | Value |
|----------|-------|
| Generated | 2026-03-20 |
| Quality Score | 9.5/10 |
| Phases Run | P1, P2, P5, P8, P9, P9B, P10, P10.5, P13, P11 |
| SP Analyzed | SP_CIDFirstDates (1,467 lines) |
| Functions Read | Function_Population_Funded, Function_Population_First_Time_Funded |
| Upstream Wiki | Dim_Customer.md (DWH_dbo) |

## Tier Distribution

| Tier | Count | Description |
|------|-------|-------------|
| Tier 1 | 12 | Upstream wiki verbatim (Dim_Customer → Customer.CustomerStatic, BackOffice.Customer) |
| Tier 2 | 81 | SP code traced (column assignments from SP_CIDFirstDates) |
| Tier 3b | 46 | DDL structure only — disabled, nullified, or not populated by SP |
| **Total** | **139** | (2 columns share identity — CID is both PK and Dim_Customer passthrough) |

## Alias-Level Attribution Verification

The following columns were verified using the Phase 9 Step 2b alias-level source attribution rule:

| Column | SELECT Alias | Resolved Table | Source Type | Verified? |
|--------|-------------|---------------|-------------|-----------|
| FirstDepositDate | `dc` | Dim_Customer | **Direct read** | ✅ SP line 607 |
| FirstDepositAmount | `dc` | Dim_Customer | **Direct read** | ✅ SP line 604 |
| FirstDepositProcessor | `dbd` | Dim_BillingDepot | Join-enriched via Fact_BillingDeposit.DepotID | ✅ SP line 603 |
| FirstDepositFundingType | `F` | Dim_FundingType | Join-enriched via Fact_BillingDeposit.FundingTypeID | ✅ SP line 602 |

The JOIN condition `dc.FTDTransactionID = CAST(D.DepositID AS NVARCHAR(4000))` on SP line 609 serves only `D.*`, `F.*`, and `dbd.*` aliases — NOT `dc.*` columns.

## Items Requiring Review

### [REVIEW] Contact Tracking Columns

The SP populates `LastContactDate`, `FirstContactDate`, and `LastContactDate_ByPhone` from `BI_DB_UsageTracking_SF`. However, the DDL has 8 contact-related columns. The remaining 5 (FirstContactAttemptDate, FirstContactAttemptDate_ByPhone, FirstContactDate_ByPhone, LastContactAttemptDate, LastContactAttemptDate_ByPhone) appear to NOT be populated by the SP. Reviewer should confirm whether any other SP or process populates these.

### [REVIEW] FirstDepositAmountExtended

This column exists in the DDL but is not set by SP_CIDFirstDates. It may be populated by another process or may be legacy. Reviewer should check if any other SP sets this value.

### [REVIEW] Legacy Columns Count

46 columns are marked as Tier 3b (disabled/nullified/not populated). This is a high ratio (33% of all columns). Reviewer may want to confirm that all marked columns are indeed dead and consider DDL cleanup.

### [REVIEW] Credit and RealizedEquity Daily Restriction

These columns are only updated when `@date = @yesterday` (line 833). If the SP is run for historical dates or catch-up, these columns will not be refreshed. The wiki notes this but reviewer should confirm the business impact.

## Reviewer Corrections

_No corrections yet. Add corrections in the format:_

```
### Correction: [Column/Section Name]
**Reviewer**: [name]
**Date**: [date]
**Issue**: [what's wrong]
**Correction**: [what it should be]
**Status**: [PENDING/RESOLVED]
```
