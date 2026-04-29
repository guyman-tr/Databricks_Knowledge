# BI_DB_dbo.BI_DB_WatchListsByFunnel — Review Needed

## Tier 4 Items (Low Confidence)

None — all columns traced to SP code or upstream wikis.

## Questions for Reviewer

1. **FunnelFromID mapping**: The SP uses a `#funnel_name_dictionary` temp table that maps FunnelFromID ranges to AttributedID 0-6. Is this mapping stable or does it change with new funnel types? Confirm the 7 funnels are exhaustive.
2. **PI selection logic**: The SP inserts PIs at region/country level with "3 Permanent PIs" — are these permanently hardcoded CIDs or does the selection rotate?
3. **Version growth**: Table is INSERT-only with ~37K rows per version. At 61 versions = 2.02M rows. Is there a planned archival strategy for old versions?
4. **US crypto restriction (ItemID <= 100002)**: Hardcoded threshold for Bitcoin/Ethereum/Bitcoin Cash. Will this need updating if new crypto are approved for US?

## Corrections Applied

- DDL shows 24 columns (batch assignment said 25 — confirmed 24 from SSDT DDL).
- SP comment says "Weekly Basis" but code confirms monthly (last Sunday of month via IF @Today = @lastSundayOfMonth).

## Cross-Object Consistency Verification

- CountryID: matches BI_DB_CIDFirstDates definition (Tier 1 — Customer.CustomerStatic)
- Country: matches Dim_Country.Name (Tier 1 — Dictionary.Country)
- Region: matches Dim_Country.Region (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse)
- RealCID: matches Dim_Customer.RealCID definition (Tier 1 — Customer.CustomerStatic)
