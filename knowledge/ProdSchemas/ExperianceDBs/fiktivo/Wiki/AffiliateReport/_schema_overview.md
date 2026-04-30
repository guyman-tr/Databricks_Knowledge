# AffiliateReport Schema Overview

> Affiliate performance reporting procedures - aggregates registrations, FTDs, sales, chargebacks, clicks, and eCost data for both portal (affiliate self-service) and admin (internal operations) dashboards.

## Purpose

The AffiliateReport schema contains the stored procedures that power affiliate performance reports across both the affiliate portal (self-service) and admin dashboard (internal). All procedures share a common UNION ALL architecture that combines multiple commission event types into a unified result set, then applies conditional grouping and aggregation based on caller-specified flags.

## Architecture

```
Commission Data Sources
+-- AffiliateCommission.RegistrationCommission (AType 0 - Registrations)
+-- AffiliateCommission.CreditVW/Credit (AType 1 - CPA/FTD)
+-- AffiliateCommission.ClosedPositionCommission (AType 3 - Sales/RevShare)
+-- AffiliateCommission.CreditVW/Credit (AType 4 - Chargebacks/Refunds)
+-- dbo.tblaff_eCost (AType 5 - eCost) [admin only]
+-- AffiliateClicks.ClicksImpressionsAggregation (AType 5/Clicks) [newer SPs]
+-- Derived from AType 3 (AType 6 - Active Traders) [admin only]
    |
    | UNION ALL (conditional per @Show/@Aggregate flags)
    v
+-------------------------------------------------------+
|  AffiliateReport Procedures                           |
|                                                       |
|  PORTAL (single affiliate, self-service):             |
|  - PortalReportSummaryByAffiliate (aggregated)        |
|  - PortalReportSummaryPerAffiliate (row-level detail) |
|                                                       |
|  ADMIN (multi-affiliate, internal ops):               |
|  - ReportSummaryByAffiliate (full-featured)           |
|  - ReportSummaryByAffiliate_RAN (legacy variant)      |
+-------------------------------------------------------+
    |
    v
Portal Dashboards / Admin Dashboards
```

## Procedure Comparison

| Feature | PortalByAffiliate | PortalPerAffiliate | ReportSummary | ReportSummary_RAN |
|---------|-------------------|--------------------|--------------|--------------------|
| **Audience** | Portal (affiliate) | Portal (affiliate) | Admin (internal) | Admin (legacy) |
| **Affiliates** | Single | Single + sub-affiliates | Multi (CSV list) | Single |
| **Output** | Aggregated (GROUP BY) | Row-level detail | Aggregated (GROUP BY) | Aggregated (GROUP BY) |
| **Clicks** | Yes | Yes (own tier only) | Yes | No |
| **eCost** | No | No | Yes | Yes |
| **Active Traders** | No | No | Yes | Yes |
| **AdditionalData** | Yes | Yes | Yes | No |
| **Banner Attr Filter** | No | No | Yes | No |
| **Monthly Grouping** | Yes (Month) | No | Yes (Month+Year) | No |
| **Staging Table** | No (inline) | No (inline) | Yes (#Results) | Yes (#Results) |
| **Sub-Affiliate CTE** | No | Yes (5 levels) | No | No |
| **Payment Status** | No | No | Yes | Yes |
| **OPTION(RECOMPILE)** | Yes (main query) | No | Yes (CPA, Sales) | Yes (CPA, Sales) |

## AType Discriminator Values

All procedures use the same AType coding for the UNION ALL pattern:

| AType | Event Type | Source | Description |
|-------|-----------|--------|-------------|
| 0 | Registration | AffiliateCommission.RegistrationCommission + RegistrationVW | New customer registration attributed to an affiliate |
| 1 | CPA/FTD | AffiliateCommission.CreditVW + CreditCommission (CreditTypeID=1) | Customer's first-time deposit (CPA commission event) |
| 2 | (Reserved) | - | Originally CPA Eligible - now handled via IsValid flag on AType 1 |
| 3 | Sale/RevShare | AffiliateCommission.ClosedPositionCommission + ClosedPositionVW | Revenue share from closed trading positions |
| 4 | Chargeback/Refund | AffiliateCommission.CreditVW + CreditCommission (CreditTypeID IN 4,5) | Payment reversals and chargebacks |
| 5 | eCost/Clicks | dbo.tblaff_eCost (admin) / AffiliateClicks.ClicksImpressionsAggregation (portal) | External marketing costs or click/impression tracking |
| 6 | Active Traders | Derived from AType 3 in #Results | Count of unique customers with closed positions |

## Key Business Metrics

- **FTD**: First Time Deposit - customer's first deposit (Optional=1)
- **FTDE**: First Time Deposit Eligible - FTD that passes validation (Optional=1 AND IsValid=1)
- **LCR**: Lead Conversion Rate = Registrations / Clicks * 100
- **FTDCR**: FTD Conversion Rate = FTDs / Clicks * 100
- **CTR**: Click-Through Rate = Clicks / Impressions * 100
- **FTDECR**: FTDE Conversion Rate = FTDEs / Clicks * 100
- **Net Revenue**: Gross Revenue + Chargebacks (chargebacks are negative)
- **RevenuesPercentage**: CPA revenue share percentage for the affiliate

## Evolution Timeline

| Date | Ticket | Change | Author |
|------|--------|--------|--------|
| Aug 2020 | - | Initial Portal variants (replaced AffWizReports) | Ran Ovadia |
| Jun 2022 | PART-44 | Admin report rewrite (ReportSummaryByAffiliate + _RAN) | Ran O & Noga R |
| Aug 2022 | PART-454 | Monthly grouping (@ShowMonth) | Noga |
| Dec 2022 | PART-817/815 | Multi-affiliate ID list support | Noga |
| Mar 2023 | PART-1277 | Registration commission support | Noga |
| Nov 2023 | PART-2146 | RevenuesPercentage for CPA | Gil Haba |
| Dec 2023 | PART-2448 | CPA New Compensation Design | Gil & Noga |
| Mar 2024 | PART-2855 | Clicks and impressions support | Noga |
| May 2024 | PART-3052 | Rounding bug fix | Gil Haba |
| Nov 2024 | PART-3602 | ClosedPositionDailySummary optimization | Noga |
| Nov 2024 | PART-3664 | AdditionalData filter | Noga |
| Nov 2024 | PART-3693 | AdditionalData for clicks | Noga |
| Jul 2025 | PART-4552 | Enhancement | Gil Haba |
| Jul 2025 | PART-4613 | Fix duplicate FTD with banner tags | Noga |
| Aug 2025 | PART-4802 | Refund/chargeback reclassified as CPA | Gil Haba |
| Oct 2025 | PART-4943 | Fix registration TO date issue | Noga |
| Jan 2026 | PART-5499 | ProductType & CommissionSource | Gil Haba |
