# Review Needed: eMoney_Tribe.CardsSnapshots_CardSnapshot-140457

## Summary

All 67 columns are Tier 3 — no upstream wiki was resolvable for this table. The `_no_upstream_found.txt` marker confirms dormant/no-upstream status. All descriptions are grounded in DDL structure, live sample data (TOP 10), distribution analysis (3 columns), and SP_eMoney_Reconciliation_ETLs code analysis.

## Items Requiring Human Review

### 1. CardStatusCode Values — Completeness

The distribution analysis (Apr 2026 partition) shows 8 distinct values: A, E, N, S, L, R, B, T. Descriptions for L (Lost), R (Reported), B (Blocked), T (Temporary) are inferred from common card industry terminology. A subject-matter expert should confirm the exact business meaning of each code on the card issuer platform.

### 2. CardStatusChangeSource Numeric Codes

Observed values: 0 and 2. The meaning of these numeric codes is not documented. SME should provide the mapping (e.g., 0=system, 2=user-initiated, etc.).

### 3. KycVerification Interpretation

All sampled rows show "0". It is unclear whether 0 means "not verified", "verified", or something else. SME should clarify the KYC status code semantics.

### 4. ActiveWallet Column — Purpose Unknown

Empty/NULL in all sampled rows. Purpose cannot be determined from DDL, sample data, or SP code alone. May be a deprecated or conditionally populated field.

### 5. etr_y / etr_ym / etr_ymd — Deprecation Status

All three columns are empty in recent data. They appear to be legacy eToro partition key columns. SME should confirm whether these are deprecated and can be ignored.

### 6. EmailAddress and PhoneNumber Exclusion from ETL

SP_eMoney_Reconciliation_ETLs does NOT select EmailAddress or PhoneNumber into the temp table (they are excluded from ETL_CardSnapshot). This may be an intentional PII exclusion or an oversight. SME should confirm.

### 7. @Created vs Created — Semantic Difference

Both columns carry datetime2(7) and show identical values in sampled rows. The distinction (if any) between the pipeline-assigned `@Created` and the source-system `Created` should be clarified.

### 8. PII Masking Scope

Multiple columns contain PII (FirstName, LastName, CardNumber, Dob, EmailAddress, PhoneNumber, Address). The masking appears to be applied at query time. Confirm whether masking is enforced at the Synapse level (dynamic data masking) or at the source.

### 9. No Upstream Wiki — All Tier 3

No production wiki exists for FiatDwhDB.Tribe. If a wiki is created for the card issuer platform database in the future, all 67 column descriptions should be upgraded to Tier 1 by inheriting from that upstream wiki.

---

*Generated: 2026-04-30*
