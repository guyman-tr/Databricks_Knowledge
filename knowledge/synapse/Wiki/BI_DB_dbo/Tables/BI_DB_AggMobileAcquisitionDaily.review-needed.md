# BI_DB_dbo.BI_DB_AggMobileAcquisitionDaily — Review Needed

## Tier 4 Items (require human verification)

| Column | Current Tier | Question |
|--------|-------------|----------|
| All 28 non-ETL columns | Tier 4 | No writer SP, no data — descriptions inferred from mobile acquisition domain knowledge |

## Questions for Reviewer

1. **Decommission candidate**: 0 rows, no SP references. Should this table be dropped?
2. **Column typo**: `Cocntact` should be `Contact` — confirm this is indeed a typo and not intentional
3. **Mobile analytics location**: Where did mobile app acquisition reporting move to? Databricks? AppsFlyer dashboard? Looker?
4. **Platform values**: Confirmed iOS/Android only? Or were there other values (Web, Windows)?
5. **TierCountry values**: What are the tier definitions? Tier 1 = UK, DE, AU? Tier 2 = other EU? Tier 3 = rest?
6. **PaymentTrigger values**: What events trigger commission? FTD only? Or also Verification, FirstAction?
7. **Rev8Y_LTV calculation**: What model produces the 8-year LTV? Is it still maintained elsewhere?
8. **FraudFTDs**: What system flags fraud? Internal fraud team? Automated rules?

## Dormant Table Assessment

- **Evidence**: 0 rows, no writer SP, no reader SP, no references in any SP
- **Rich schema**: 29 columns with sophisticated metrics (LTV, fraud, CPA economics)
- **Column typo never fixed**: Strong evidence this table was never actively used in Synapse
- **Recommendation**: Strong candidate for DROP — the typo alone proves no one uses this
