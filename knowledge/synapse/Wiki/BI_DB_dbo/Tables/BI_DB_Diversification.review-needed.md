# BI_DB_dbo.BI_DB_Diversification — Review Needed

## Tier 4 Items
None — all columns traced to SP code or upstream wikis.

## Reviewer Questions

1. **NumOfAssets/NumOfIndustries/NumOfCFD semantic**: These columns are only populated when the count = 1 (concentration detection). Is this by design, or should they always show the count? The SP #oneAsset/#oneIndustry/#oneCFD temp tables filter to `WHERE NumOfAssets = 1`, suggesting this is intentional single-asset detection.

2. **InstrumentDisplayName/CryptoName sparsity**: Only populated when NumOfInstruments = 1 across ALL asset classes (not just within the class). Confirm this strict constraint is intentional — most users won't have a name populated.

3. **Legacy zero columns**: V_Liabilities.TotalStockOrders and InProcessCashouts appear to always be 0 since 2019. The Equity formula includes them but they don't contribute. Is there a plan to deprecate these from the formula?

4. **Country varchar(4)**: The column is varchar(4) which fits 'US' and 'Rest' but would not fit 'United States'. This confirms the US/Rest simplification is structural, not just a data pattern.

5. **No consumers**: No downstream SPs or views reference this table in the SSDT repo. Confirm whether this feeds any reports or dashboards (likely consumed by direct SQL queries or BI tools).

## Corrections Applied
- Column count: Batch assignment listed 20 columns; DDL has 22 (Balance, Equity, Revenue, UpdateDate were missing from the count).

## Data Quality Notes
- ActiveUser distribution on 2026-03-31: 88.7% inactive (0), 11.3% active (1) — reasonable for funded-depositor population
- Country split: 93.6% Rest, 6.4% US — consistent with eToro's global user base
- NumOfInstruments: 44.5% hold 1 class, 36.4% have NULL (no positions), 15.9% hold 2, 3.0% hold 3, 0.2% hold 4
