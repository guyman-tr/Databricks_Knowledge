# AffiliateConfiguration Schema Overview

> Commission plan configuration schema for CPA (first-position), IOB (Interest on Balance), and ISA (Individual Savings Account) affiliate commission models, plus runtime tracking of customer first-position events.

## Purpose

The AffiliateConfiguration schema provides the configuration and runtime tracking layer for three affiliate commission models beyond traditional revenue share:

1. **CPA First-Position Plans** - Commission paid when a referred customer opens their first trading position, segmented by asset class and country
2. **IOB Plans** - Commission paid when a referred customer activates Interest on Balance, segmented by country
3. **ISA Plans** - Commission paid when a referred customer signs up for a UK ISA product (Cash, Managed, or DIY)

All three models are configured per affiliate type and managed via the [AffiliateAdmin.UpdateInsertAffiliateType](../AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAffiliateType.md) stored procedure using table-valued parameters for atomic bulk operations.

## Architecture

```
CONFIGURATION (admin-managed)          RUNTIME (system-managed)
+----------------------------+         +----------------------------------+
| FirstPositionAssetPlan     |         | TraderFirstAssetPosition         |
| (CPA rates per asset/country)|  -->  | (per-customer first position     |
| 3,379 plan entries         |         |  tracking + revenue progress)    |
+----------------------------+         | 33,523 customer records          |
                                       +----------------------------------+
+----------------------------+
| IOBPlan                    |
| (IOB rates per country)    |
| 1,067 plan entries         |
+----------------------------+

+----------------------------+
| ISAPlan                    |
| (ISA rates per product)    |
| 28 plan entries            |
+----------------------------+

TVPs (parameter types for bulk operations):
  FirstPositionAssetPlanType  --> FirstPositionAssetPlan
  ISAPlanType                 --> ISAPlan
  RegistrationCountryRateType --> IOBPlan (reused) + tblaff_Registration2Country
```

## Commission Priority

When multiple commission models are configured for the same affiliate type:
- **IOB wins over CPA** - If the customer activates IOB and the affiliate has an IOBPlan, IOB commission is used
- **ISA is independent** - ISA commissions are product-specific and evaluated separately
- **CPA is the default** - Used when neither IOB nor ISA applies

## Key Business Rules

- **One row per customer** in TraderFirstAssetPosition (anti-join insert pattern)
- **Revenue threshold tracking** via computed RevenuesPercentage column (0-100%)
- **Country 0 = global default** across all three plan types
- **Airdrop events are ignored** for first-position tracking
- **Atomic plan replacement** via delete-and-reinsert with STRING_AGG comparison
- **System versioning** on FirstPositionAssetPlan for audit compliance

## Cross-Schema Dependencies

| Dependency | Schema | Purpose |
|-----------|--------|---------|
| dbo.tblaff_AffiliateTypes | dbo | Commission plan templates that reference these config tables |
| dbo.tblaff_Country | dbo | Country reference for geo-segmented rates |
| Dictionary.PositionAssetType | Dictionary | Asset class classification for CPA plans |
| Dictionary.ISAProduct | Dictionary | ISA product variants for ISA plans |
| Dictionary.AccountType | Dictionary | Account type (Moneyfarm=4) for ISA sub-account classification |

## Object Inventory

| Object | Type | Quality | Description |
|--------|------|---------|-------------|
| FirstPositionAssetPlanType | UDT | 9.0 | TVP for CPA plan bulk operations |
| ISAPlanType | UDT | 9.0 | TVP for ISA plan bulk operations |
| RegistrationCountryRateType | UDT | 9.2 | Reusable TVP for country-rate pairs (IOB + registration) |
| FirstPositionAssetPlan | Table | 9.4 | CPA rates per affiliate type / country / asset class |
| IOBPlan | Table | 9.4 | IOB rates per affiliate type / country |
| ISAPlan | Table | 9.2 | ISA rates per affiliate type / product |
| TraderFirstAssetPosition | Table | 9.4 | Customer first-position tracking and revenue progress |

## Key Jira Tickets

- **PART-2448** (Dec 2023): CPA New Compensation Design - created FirstPositionAssetPlan, TraderFirstAssetPosition, FirstPositionAssetPlanType, RegistrationCountryRateType
- **PART-3174** (Jun 2024): Fixed SetTraderFirstAssetPosition anti-join insert logic
- **PART-4262** (Apr 2025): Updated registration rate handling
- **PART-4763** (Sep 2025): IOB feature - created IOBPlan, added RegistrationCountryRateType reuse for @IOBPerCountry
- **PART-5461** (Jan 2026): ISA plan feature - created ISAPlan, ISAPlanType

---

*Generated: 2026-04-13 | Objects: 7 | Average Quality: 9.2*
