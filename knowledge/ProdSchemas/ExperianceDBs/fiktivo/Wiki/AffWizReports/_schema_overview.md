# AffWizReports Schema Overview

## Purpose

The AffWizReports schema contains 27 stored procedures that collectively power the **Affiliate Wizard (AffWiz) reporting system**. This is a dynamic SQL reporting framework that generates customizable affiliate performance reports with configurable dimensions and metrics.

## Architecture

The AffWiz report is assembled by an external orchestrator (not in the SSDT project) that calls these procedures in sequence to build a complete SQL query. The architecture follows a **modular dynamic SQL builder pattern**:

```
Orchestrator (external)
|
+-- FieldSelection         -> Builds inner SELECT (column list)
+-- QueryHeader            -> Builds outer SELECT (GROUP BY aggregations)
|
+-- Get{Entity}Data SPs    -> Build UNION ALL fragments for allDataUnion
|   +-- GetRegistrationsData
|   +-- GetLeadsData
|   +-- GetSalesData
|   +-- GetFTDData
|   +-- GetFPData
|   +-- GeteCostData
|   +-- GetDownloadsData
|   +-- GetInstallsData
|   +-- GetFTRData
|   +-- GetCopyTraderData
|   +-- (Installs - legacy)
|
+-- Get{Entity}AggregatedData SPs -> Build temp tables + LEFT JOIN clauses
    +-- GetRegistrationsAggregatedData  -> #RegistrationsAggregatedData
    +-- GetLeadsAggregatedData          -> #LeadsAggregatedData
    +-- GetSalesAggregatedData          -> #SalesAggregatedData
    +-- GetFTDAggregatedData            -> #FTDAggregatedData
    +-- GetFTDEAggregatedData           -> #FTDEAggregatedData
    +-- GetDepositAggregatedData        -> #DepositAggregatedData
    +-- GetFirstPositionAggregatedData  -> #FirstPositionAggregatedData
    +-- GetFPAggregatedData             -> #FPAggregatedData
    +-- GeteCostAggregatedData          -> #eCostAggregatedData
    +-- GetDownloadsAggregatedData      -> #DownloadsAggregatedData
    +-- GetInstallsAggregatedData       -> #InstallsAggregatedData
    +-- GetFTRAggregatedData            -> #FTRAggregatedData
    +-- GetCopyTraderAggregatedData     -> #CopyTradersAggregatedData
```

## SP Categories

### 1. Header/Utility SPs (2)
- **FieldSelection**: Builds the inner SELECT clause with conditional column inclusion
- **QueryHeader**: Builds the outer SELECT with GROUP BY and SUM/COUNT aggregations

### 2. Data SPs (12)
Build SELECT DISTINCT fragments for the allDataUnion - the dimensional backbone of the report. Each produces one row per unique (AffiliateID, Date, SerialID, CountryID, ...) combination for its event type.

### 3. AggregatedData SPs (13)
Execute dynamic SQL to populate temp tables with aggregated metrics (COUNT, SUM), then append LEFT JOIN clauses to the orchestrator's query string.

## Key Entities and Source Tables

| Entity | Source Table | Commission Table | Metrics |
|--------|-------------|-----------------|---------|
| Registrations | tblaff_Registrations | tblaff_Registrations_Commissions | Count, Commission |
| Leads | tblaff_Leads | tblaff_Leads_Commissions | Count, Commission |
| Sales | tblaff_Sales | tblaff_Sales_Commissions | Count, Revenue, PnL, Hedge, UsedBonus, Commission |
| FTD | tblaff_CPA (Optional2=1) | tblaff_CPA_Commissions | Count, Amount, LTV |
| FTDE | tblaff_CPA (Optional2=1, Valid=1) | tblaff_CPA_Commissions | Count, Amount, LTV |
| Deposit | tblaff_CPA (all) | tblaff_CPA_Commissions | Amount |
| FirstPosition | tblaff_FirstPositions | tblaff_FirstPositions_Commissions | Commission sum |
| FP | tblaff_FirstPositions | tblaff_FirstPositions_Commissions | Count, LTV |
| Downloads | fiktivo.etoro_Download (status=1) | - | Count |
| Installs | fiktivo.etoro_Install (status=1) | - | Count |
| FTR | fiktivo.etoro_Install (status=3) | - | Count |
| eCost | tblaff_eCost | tblaff_eCost_Commissions | Count, Commission |
| CopyTrader | tblaff_CopyTraders | tblaff_CopyTraders_Commissions | FTCT, Commission |

## Common Parameters

All SPs share a standard interface with @Show* bit flags controlling which dimensions to include:
- **Date/Time**: @ShowDate, @ShowMonth
- **Geography**: @ShowCountryName, @ShowMarketingRegion
- **Affiliate**: @ShowAffiliateID, @ShowAffiliateGroups, @ShowAffiliateCountry
- **Attribution**: @ShowSerialID (sub-affiliate), @ShowBanner, @ShowChannelID
- **Customer**: @ShowCustomerID, @ShowPlayerLevel, @ShowLabelID, @ShowFunnelID
- **Metrics**: @ShowRegistrations, @ShowLeads, @ShowSales, @ShowFTD, etc.
- **Commissions**: @ShowRegistrationCommissions, @ShowLeadCommissions, etc.
- **Filtering**: @fromDate, @toDate, @BannerId, @Tier, @PaymentStatus, @ShowRelevantRevenues

## Cross-Schema Dependencies

- **dbo**: All tblaff_* tables (event and commission tables)
- **fiktivo**: etoro_Install, etoro_Download, qry_aff_LeadRegistrationDate view
- **Dictionary**: MarketingRegion, PlayerLevel (referenced in FieldSelection SQL output)

## Deprecated Features

Several features were removed in July 2022 (by developer Noga):
- Clicks and Impressions tracking
- RealProviderID dimension
- Category display
- Customer Support commissions
