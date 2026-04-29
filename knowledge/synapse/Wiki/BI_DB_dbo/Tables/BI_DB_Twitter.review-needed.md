# BI_DB_dbo.BI_DB_Twitter — Review Needed

## Tier 4 Items (Unverified)

- None — all columns traced to SP code and external table sources.

## Questions for Reviewer

1. **Affiliate IDs 52350/52351**: Are these the only Twitter affiliate IDs, or should other IDs also be tracked in AW_Reg/AW_FTD? The SP hardcodes `WHERE fd.SerialID IN (52350, 52351)`.
2. **Cost currency**: The cost column divides billed_charge_local_micro by 1M — is this always USD, or does it vary by Twitter account currency? The column name says "local_micro" suggesting local currency.
3. **Late conversion window**: The 30-day rolling window is hardcoded in the SP. Does Twitter's actual attribution window differ (e.g., 7-day click, 30-day view)?
4. **Platform detection**: The CASE pattern only checks for 'ios' and 'android' in campaign names. Are there web/desktop campaigns that should be tagged differently?

## Cross-Object Consistency Notes

- Region/Desk/EU descriptions inherited verbatim from Dim_Country wiki (same tier and origin preserved).
- No Tier 1 columns expected — primary source is Fivetran (third-party, no upstream wiki).

## Potential Data Quality Issues

- 62% of rows have NULL Platform — campaign naming convention inconsistency
- 2% of rows have NULL EU (8,191 rows) — countries not in Ext_Dim_Country lookup
- AW-only rows have empty string AccountID/AccountName (not NULL) — may affect NULL-based filters
