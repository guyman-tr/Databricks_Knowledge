# Review Needed: EXW_dbo.EXW_Payment_Allowed_Country

## Open Questions

1. **PaymentAllowed uniformly 0**: All 52,548 rows have PaymentAllowed=0. Is this feature intentionally disabled, or is it pre-launch / deprecated? The SP comment history says "Remove conversion, payment and staking part, activity is not active, we will keep tables, no need to re fill them" (2026-04-14, Inessa). This suggests payment activity was deactivated but the table continues to be populated.

2. **No downstream consumers found**: No views, SPs, or other tables in the Synapse SSDT repo reference `EXW_Payment_Allowed_Country`. If this table is consumed externally (e.g., by an API or Databricks downstream), that relationship is not captured here.

3. **UC Target = _Not_Migrated**: This table has not been migrated to Unity Catalog. Given the inactive status of the payment feature, confirm whether UC migration is planned.

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 2 | CountryID, Country (dim-lookup passthrough from Dim_Country → Dictionary.Country) |
| Tier 2 | 14 | All remaining columns grounded in SP_EXW_WalletElligibleCountries code |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## Upstream Bundle Status

- `_no_upstream_found.txt` present — no production wiki was resolvable for the source objects (EXW_Settings, EXW_Wallet.CryptoTypes).
- Local Synapse wiki for DWH_dbo.Dim_Country was used for Tier 1 inheritance on CountryID and Country.
- Local Synapse wiki for DWH_dbo.Dim_State_and_Province was read but columns had CASE transforms → Tier 2.

## SP Comment History

- **2021-04-07** (Inessa K): Original creation — runs on settings to pull activity eligibility.
- **2026-04-14** (Inessa): Added new tag CountryRegionAndRegulation. Removed conversion, payment, and staking parts — activity is not active, tables kept but not refilled for those sections.
