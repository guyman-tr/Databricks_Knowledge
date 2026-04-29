# BI_DB_dbo.BI_DB_AffData — Review Needed

## Tier 4 Items (require human verification)

| Column | Current Tier | Question |
|--------|-------------|----------|
| All columns | Tier 4 | No writer SP and 0 rows — all descriptions are inferred from column names only |

## Questions for Reviewer

1. **Decommission candidate**: This table has 0 rows and no writer SP. Should it be dropped from Synapse or is there a plan to re-implement the ETL?
2. **On-prem origin**: Was this table populated on the legacy on-prem BI_DB SQL Server? If so, is the data still available there?
3. **Relationship to active affiliate tables**: Is BI_DB_AffID_Dictionary + BI_DB_Affiliate_Report the intended replacement for this table's functionality?
4. **ContractName/ContractType**: What are the actual values these columns were designed to hold? CPA vs Revenue Share vs Hybrid?

## Dormant Table Assessment

- **Evidence of dormancy**: 0 rows, no writer SP in SSDT, no external table source, no staging table
- **Only references**: PII masking permission scripts (DataplatformPII, DataScienceAnalysts roles)
- **Recommendation**: Consider adding to blacklist or marking as decommission candidate
