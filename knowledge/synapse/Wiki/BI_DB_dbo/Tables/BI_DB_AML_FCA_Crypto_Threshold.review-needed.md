# Review: BI_DB_dbo.BI_DB_AML_FCA_Crypto_Threshold

*Sidecar for wiki review. Does NOT contain wiki content — see BI_DB_AML_FCA_Crypto_Threshold.md.*
*Generated: 2026-04-21 | Batch 14 #3*

## Business Logic Questions

1. **Column typo — "Regualtion"**: The column is permanently misspelled in the DDL and SP (missing 'a'). Has this ever been flagged for correction? A DDL change requires downstream query updates across all consumers. Until corrected, all queries must use the misspelling.

2. **NULL Regualtion rows (~660)**: Live data contains ~660 rows where `Regualtion IS NULL`. The SP uses INNER JOINs across all three UNION branches — NULLs should not appear from missing regulation joins. Possible explanations: (a) historical rows inserted before the UNION ALL expansion; (b) Dim_Regulation.Name is NULL for some regulation IDs; (c) source data corruption. Reviewer should confirm: are these rows from legitimate historical loads, and should a data quality check be added?

3. **Table name vs. scope**: `BI_DB_AML_FCA_Crypto_Threshold` includes CySEC (40.1%) and ASIC (5.3%) customers in addition to FCA (53.6%). The SP was expanded with UNION ALL branches. Should the table and SP be renamed to reflect the broader scope? Or is FCA the "driving" jurisdiction for the AML threshold logic?

4. **Amount threshold currency**: The SP filters `ppnl.Amount >= '80000'` (string literal, auto-cast). The 80,000 threshold currency is not documented in the SP. Is this USD? GBP (FCA jurisdiction)? Position-native currency? This matters for ASIC/CySEC customers where the position amount may be in a different currency.

5. **Amount type**: `ppnl.Amount` is compared with `'80000'` as a string — SQL auto-casts to the column type. Confirm `Amount` in BI_DB_PositionPnL is numeric and this comparison works as expected.

6. **Threshold value documentation**: The 80,000 threshold is a regulatory reporting floor. Is this documented in any AML policy or Confluence page? It may need to be updated if regulations change.

## UC Target Uncertainty

Table not found in generic pipeline mapping. Assumed `_Not_Migrated`. Reviewer should confirm:
- Is there a Databricks/UC equivalent for weekly AML crypto threshold monitoring?
- If migrated, update wiki UC Target field and generate ALTER script.

## No Issues Found

- Element count: 8/8 — matches DDL ✓
- Three UNION ALL regulation branches traced to SP code ✓
- ROW_NUMBER() deduplication logic documented ✓
- Weekly Monday schedule confirmed from SP naming convention ✓
- Club distribution (Diamond 56.9%, Platinum Plus 42.3%) verified via live query ✓
- HasWallet always=1 documented (eligibility filter) ✓
- Historical data from 2021-11-28 — no rolling delete — documented ✓
