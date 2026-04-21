# Review Needed — eMoney_dbo.eMoney_Reports_AcquisitionFunnel

**Generated**: 2026-04-21 | **Batch**: 12 | **Quality**: 8.9/10

---

## Tier 1 Columns

| Column | Upstream Source | Verified |
|--------|----------------|---------|
| CID | eMoney_Dim_Account wiki → Customer.CustomerStatic | ✓ Copy-verified |
| GCID | eMoney_Dim_Account wiki → dbo.FiatAccount | ✓ Copy-verified |

---

## Open Questions

1. **IsValidForFunnel=0 (710 rows)**: What makes eMoney_Dim_Account.IsValidETM = 0? Is this a data quality flag, regulatory exclusion, or another business rule? Should these customers be excluded from analysis or tracked separately?
2. **ActionTypeID 7 and 8 for IsActiveMIMO**: What specific actions do these represent? The description says "MIMO actions" but the exact action names from Dim_ActionType should be confirmed.
3. **Country vs trading country divergence**: When HasCountryChanged=1 in eMoney_Dim_Account, do both Country (eMoney registered) and the customer's trading Dim_Customer.CountryName change? Worth documenting which country is authoritative for regulatory purposes.
4. **IseMoneyAccount vs IsFMI gap**: 1,726,054 have eMoney accounts but only 1,201,484 have FMI. The ~525K difference represents enrolled customers who have never funded their eMoney wallet. Is this expected/tracked?
5. **Switzerland in sample data**: Switzerland appears in the sample but may not be in the eMoney_Dim_Country_Rollout (which tracks only 34 countries). Is Switzerland in the rollout? CountryID for Switzerland should be verified.

---

## No Structural Issues

All 15 elements present. Tier assignments confirmed by SP code review. Cross-object consistency with eMoney_Dim_Account verified (CID/GCID descriptions match verbatim).
