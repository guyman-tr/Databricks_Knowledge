# Review Needed: BI_DB_dbo.BI_DB_Affiliate_Fraud_Loss

Generated: 2026-04-21 | Batch 13 #4

## Tier 4 Items (Low Confidence — Needs Verification)

_No Tier 4 items. All columns resolved to Tier 1, Tier 2, or Tier 5._

## Open Questions for Reviewers

1. **Country vs KYCCountry redundancy**: Both `Country` and `KYCCountry` are resolved from `Dim_Country.Name` via `Dim_Customer.CountryID`. In the SP, `Country` is populated in `#all` and `KYCCountry` in `#FINAL` — both join on the same `CountryID`. In the live data, these should always be identical. Confirm whether `KYCCountry` is intentionally a second lookup (e.g., meant to use a different ID like KYC-verified country), or whether it is redundant and can be removed/aliased.

2. **'Suspicous Affiliate' typo in data**: The SP hardcodes `RiskStatus = 'Suspicous Affiliate'` (one 'i' instead of two). This typo is in the stored data. Any filter using `WHERE RiskStatus = 'Suspicious Affiliate'` will return zero rows. Confirm whether a backfill/correction is planned or whether the typo is accepted as-is.

3. **AffiliatePayment = 0 for block-only rows**: Block-triggered rows (#blockeinmonth) can have `AffiliatePayment = 0` when the affiliate had no CompensationToAffiliate payment on @Date. SUM or AVG on AffiliatePayment without filtering will mix zero-payment block events with real payment events. Confirm whether these zero-payment rows are intended to be treated as payment records or purely as event records.

4. **Loss = total all-time payments vs fraud loss**: The `Loss` column is labeled as a "loss" amount but is computed as the SUM of ALL CompensationToAffiliate paid to the affiliate across ALL time, not just fraudulent payments. This overstates the fraud loss if only a portion of the payments occurred after the affiliate became suspicious. Confirm whether this is the intended loss metric or whether it should be limited to payments made after the block date.

5. **Dead or unintended join logic in #blocked + #risk**: The #blockedaffiliates temp table joins #blocked (blocked accounts) with #risk (RiskStatusID=60 events). However, #risk is built from External_etoro_BackOffice_CustomerRisk with the join `Dim_Customer cc ON cc.GCID=cr.GCID` followed by `#all a ON a.RealCID=cc.RealCID`. Confirm that this GCID→RealCID path reliably links the risk event to the affiliate's account. If GCID is NULL for older accounts, those affiliates would be missed.

6. **FundingType: most recent deposit method**: FundingType is the most recent deposit method from Fact_CustomerAction (ActionTypeID IN (7,8)), ordered by Occurred DESC. This reflects the affiliate's own deposit method (as an eToro customer), not the clients they referred. Confirm this interpretation is correct for the fraud monitoring use case.

7. **AccountTypeID filter scope**: The SP includes `AccountTypeID IN (6, 15)` — Affiliate Private Account and Affiliate Corporate Account. Confirm these are the complete set of affiliate account types, or whether other AccountTypeIDs should be included for full coverage.

## Correction Notes

- Column names `YearMonth-Block` and `YearMonthDay-Block` contain hyphens, which require square-bracket quoting in T-SQL. This is a DDL naming convention issue — hyphens in column names are legal in SQL Server but non-standard.
- `RiskStatus = 'Suspicous Affiliate'` (hardcoded in SP) has a typo — should be 'Suspicious Affiliate'. This is preserved verbatim from the SP and appears as-is in the data.
