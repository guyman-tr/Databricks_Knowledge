# Review Needed: BI_DB_dbo.BI_DB_QSR_Balance_New

## Items Requiring Human Review

### 1. Stale Data — Table Not Refreshed Since 2024-01-30
- All rows show `UpdateDate = 2024-01-30`. Data stops at Q4 2023.
- **Question**: Is this table still actively used? Has SP_Q_QSR_New been superseded or is it simply awaiting the next quarterly run?
- **Action**: Verify with the QSR/Finance team whether this table is still the active source for CySEC reporting.

### 2. RealizedCFDWithBugPre2021Q2 — Known Copy-Paste Bug
- The SP code computes: `QuarterRealizedPnLRealStocks - QuarterRealizedPnLRealCrypto - QuarterRealizedPnLRealStocks` — subtracting stocks TWICE.
- The correct formula (used for `RealizedCFD`) is: `RealizedPnL - RealizedPnLRealCrypto - RealizedPnLRealStocks`.
- **Question**: Is this bug intentionally preserved for backward compatibility with historical submissions, or should it be fixed?

### 3. StockMargin Column — Recently Added, Mostly Empty
- Added 2025-10 by Markos Ch. Appears NULL/empty in all sampled rows (data only goes to Q4 2023).
- **Question**: Will historical quarters be backfilled, or is StockMargin only expected for future quarters?

### 4. BI_DB_ECB_RateExtractFromAPI — Unresolved Upstream Wiki
- The ECB rate source table does not have a wiki in the bundle. The Rate column description is Tier 2.
- **Action**: Document BI_DB_ECB_RateExtractFromAPI if it doesn't already have a wiki.

### 5. IsEtoroBVI — Hardcoded CID Lists
- The SP hardcodes specific CIDs for eToro Group and eToro Trading Group accounts.
- **Question**: Are these CID lists maintained elsewhere? Should they be in a reference table rather than hardcoded in the SP?

### 6. Sustainability Stamp Staleness
- BI_DB_EquitiesWithSustainabilityStamp has not been refreshed since 2024-01-30 (218 rows).
- The sustainability ratio computation depends on this reference data being current.
- **Question**: Confirm the Google Sheet source is still maintained for EU sustainability compliance.
