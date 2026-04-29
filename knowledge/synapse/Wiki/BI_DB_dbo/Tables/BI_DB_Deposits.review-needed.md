# Review Needed — BI_DB_dbo.BI_DB_Deposits

## Open Questions

- **OldPaymentID**: Hardcoded NULL in SP_H_Deposits. Was this column previously populated from a legacy source? The DDL retains it as `bigint NULL` but the SP explicitly sets `null AS [OldPaymentID]`. Confirm if it can be deprecated.
- **Code**: Also hardcoded NULL. Same question — legacy column with no current source.
- **Limited date range**: The table currently holds only ~28 days of data (2023-12-20 to 2024-01-16). Confirm whether this is expected (rolling window) or indicates an SP initialization issue.
- **RiskManagementStatus columns**: Sourced from `External_etoro_Dictionary_RiskManagementStatus` which has no upstream wiki. The production table `Dictionary.RiskManagementStatus` may have documentation — verify and upgrade to Tier 1 if found.
- **Region**: Sourced from `External_etoro_Dictionary_MarketingRegion` rather than `Dim_Country.Region` directly. Both carry the same value from `Dictionary.MarketingRegion.Name`. Could be simplified to use Dim_Country.Region.
- **FirstDepositAttempt / FirstDepositDate**: Sourced from `External_etoro_BackOffice_CustomerAllTimeAggregatedData`. Dim_Customer also has `FirstDepositDate` (updated from CustomerFinanceDB). Verify whether these two sources agree or if there's a known divergence.
- **ResponseName**: Only populated for deposits with a matching `External_etoro_History_DepositAction_Yesterday` row. For deposits older than yesterday's action history, ResponseName may be stale or NULL.

## Tier 2 Columns Potentially Upgradeable

| Column | Current Tier | Potential Upgrade | Action |
|--------|-------------|-------------------|--------|
| RiskManagementStatus_RiskManagementStatusID | Tier 2 | Tier 1 if Dictionary.RiskManagementStatus wiki exists | Search DB_Schema/etoro/Wiki/Dictionary/ |
| RiskManagementStatus_Name | Tier 2 | Tier 1 if Dictionary.RiskManagementStatus wiki exists | Same |
| Region | Tier 2 | Tier 1 via Dim_Country.Region if routed through that dim | Verify source equivalence |
| CardSubType | Tier 2 | Tier 1 if Dictionary.CountryBin6 wiki documents this field | Check upstream wiki |
| CardCategory | Tier 2 | Tier 1 if Dictionary.CountryBin6 wiki documents this field | Check upstream wiki |
