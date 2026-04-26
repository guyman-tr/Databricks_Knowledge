---
object: BI_DB_dbo.BI_DB_Cross_Selling_Daily
review_generated: 2026-04-23
status: needs_review
---

# Review Notes — BI_DB_Cross_Selling_Daily

## Tier 4 Inferences (Reviewer Verification Required)

| Column | Inferred Claim | Confidence | Evidence |
|--------|---------------|------------|----------|
| High_Bronze+ | Threshold $1,000 equity (ActualNWA + Liabilities ≥ 1000) maps to "Bronze+" club tier | Medium | SP CASE expression explicit; but club tier label "Bronze+" not confirmed against Dim_PlayerLevel mapping |
| CFD_ActiveOpen3M | Counts ALL non-settled positions (IsSettled=0) as CFD, regardless of InstrumentTypeID | Medium | SP filter uses IsSettled=0 with no InstrumentTypeID filter — could include non-CFD open positions if data model allows |
| eMoney_ActiveOpen3M | ActionTypeID=44 specifically represents "eMoney IBAN trade/transaction" | Medium | Inferred from eMoney_Dim_Account join context; ActionTypeID=44 not confirmed in Dim_ActionType lookup |
| Total_Products | Sums exactly 7 product flag columns (ETF_Hold + Smart_Portfolios_Hold + Copy_Trader_Hold + CFD_ActiveOpen3M + Real_Crypto + Real_Non_US_Stocks + Real_US_Stocks + eMoney_ActiveOpen3M) | High | Explicit in SP SELECT; but note CFD_ActiveOpen3M is a COUNT (can be >1), others are binary — SUM semantics may differ |

## Open Questions for Business Reviewer

1. **[High_Bronze+] column naming** — The `+` in the column name is unusual and requires bracket quoting in all SQL. Was this intentional or a legacy naming artifact? Should this be renamed?

2. **eMoney hardcoded start date** — `ActionTypeID=44` lookback is hard-capped at `DateID >= 20240401` (April 2024 launch). Is this date expected to remain fixed or should it be a parameter? Affects comparability of eMoney_ActiveOpen3M for pre-April 2024 analysis.

3. **EOM lookback window** — SP uses `@beginning_of_Month` (2-month window) for end-of-month dates and `DATEADD(month, -3, @date)` (3-month window) for mid-month runs. Cross-Selling_Monthly uses 2-month window exclusively. Is this asymmetry intentional?

4. **Total_Products > 0 filter** — Customers with zero product engagement are excluded from INSERT. Downstream joins to this table for population analysis will silently exclude zero-product customers. Should this be documented in a data contract?

5. **IsValidETM=1 AND GCID_Unique_Count=1** — eMoney eligibility filter in eMoney_Dim_Account. Confirm `GCID_Unique_Count=1` means the eToro CID maps to exactly one eMoney account (no multi-account customers). If a customer has 2 eMoney accounts, are they excluded from eMoney_ActiveOpen3M?

## UC Migration Status

- **UC Target**: `_Not_Migrated` — not present in `bronze_opsdb_dbo_vw_unitycatalog_mapping_tables`
- No Databricks lake path or UC schema assignment found
- Action: If migration is planned, this table will need a pipeline registration before UC ALTER can be generated
