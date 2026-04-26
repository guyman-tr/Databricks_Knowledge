# BI_DB_dbo.BI_DB_EOMExposures — Review Needed

## Tier 4 Items

None — all columns traced to SP code logic.

## Open Questions

1. **Column count mismatch**: DDL has 12 columns but batch assignment listed 7. Verified 12 columns from SSDT DDL.
2. **BVI CID exceptions**: CIDs 5969870/5969868/5969875 are hardcoded exceptions included in client NOP despite PlayerLevelID=4. What makes these BVI accounts special?
3. **Instrument unit adjustments**: The LP NOP calculation applies special multipliers for InstrumentIDs 18, 19, 22, 28 based on AvgRate thresholds. These appear to be historical lot-size corrections. Are these still relevant?
4. **No Tier 1 columns**: All 12 columns are ETL-computed (Tier 2) with no direct upstream wiki passthrough. The instrument names come from Dim_Instrument but are heavily transformed through exchange classification and major currency pair resolution.
5. **Commodity ETF reclassification**: Three ETFs (United States Gasoline Fund, Teucrium Corn Fund, Teucrium Wheat Fund) are hardcoded as Commodities instead of ETF. Is this list maintained elsewhere?

## Corrections for Reviewer

- The SP uses WITH (NOLOCK) hints on Synapse which is unnecessary (snapshot isolation by default) but does not affect correctness.
- FULL JOIN between client and LP final results means some rows may have only client-side or only LP-side data (NULLs on the other side).
