# Review Needed: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Verifications

## Staleness Warning

- **CRITICAL**: This table has not been refreshed since 2025-07-28 (approximately 9 months stale).
- Writer SP code was removed from SP_Operations_Monthly_KPIs_FullData on 2025-04-14 with commit message: "remove kyc verification part completely - created new SP for that".
- The replacement SP is NOT in the SSDT repository. It needs to be located on the Synapse server or confirmed as decommissioned.
- All 810,829 rows have UpdateDate = 2025-07-28.

## Tier 3 / Low Confidence Items

The following 25 columns are Tier 3 (inferred from column name only -- writer SP code no longer available in SSDT):

- **VerificationDate**: Assumed to be date of full verification (VL3). Exact derivation unknown without SP code.
- **DaysToVerify**: Assumed calendar days to verify. Start date (registration vs FTD) unknown.
- **"Uploaded 2 Docs (not EV)"**: Column name with spaces/parentheses. Exact logic unknown.
- **DidCO**: Assumed cashout completion flag. Exact source unknown.
- **Liquidated**: bigint type unusual for a flag -- could be an amount rather than boolean.
- **EffectiveAddDate**: Could be registration date, account activation, or something else.
- **FirstReviewed**: Assumed first BO review timestamp. Source table unknown.
- **FirstTouch**: Assumed days to first touch. Could be hours or another unit.
- **VerificationLevel1Date / VerificationLevel2Date**: Assumed from History_BackOfficeCustomer. Exact query unknown.
- **EvMatchStatusDate**: Assumed from History_BackOfficeCustomer. Exact query unknown.
- **SuggestedPOA / SuggestedPOI**: Flag derivation logic unknown.
- **WorkingDaysToVerify**: Weekday calculation method unknown (DATEDIFF-based or custom).
- **UnderOneDay / OverOneDay**: Threshold definition unknown (1 calendar day vs 1 working day).
- **FirstTouchSLA / VerificationSLA**: SLA threshold values unknown.
- **IsVerifyB4Deposit**: Comparison logic (strict less-than vs less-than-or-equal) unknown.
- **HoursToVerify / MinutesToVerify / FirstTouchHour / FirstTouchMinute**: Start/end timestamps unknown.
- **KYCFlow**: Classification logic and possible values unknown.

## Open Questions

- Is this table still consumed by any dashboards or reports? If not, should it be marked as deprecated?
- Where is the replacement SP? Is it on the Synapse server under a different name?
- Should the table be dropped or preserved as historical reference?
- The Region and Regulation columns use nvarchar(1000) -- significantly oversized relative to source varchar(50). Was this intentional?
- The table has 810K rows but DaysToVerify/WorkingDaysToVerify distributions are unknown. Are there data quality issues (negative values, extreme outliers)?
