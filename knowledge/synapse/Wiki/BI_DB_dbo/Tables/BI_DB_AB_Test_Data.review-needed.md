# Review Needed: BI_DB_dbo.BI_DB_AB_Test_Data

**Generated**: 2026-04-23
**Quality Score**: 7.0/10
**Status**: NEEDS REVIEW — 2 Tier 4 columns (all-NULL), source system unknown

---

## Tier 4 Items (Require Verification)

| Column | Question | Priority |
|--------|----------|----------|
| IsControlPortfolioEnabled | All NULL in the September 2019 experiment. When would this be non-NULL? What does "control portfolio enabled" mean in experiment design? | MEDIUM |
| ServiceLevelAnchored | All NULL in the September 2019 experiment. What service levels can be anchored? Is this a customer tier (e.g., "Club", "Platinum")? | MEDIUM |

## Open Questions

1. **What populated this table?** No writer SP in SSDT BI_DB_dbo. Was it:
   - A Python/notebook script run by the Data Science team?
   - A manual SQL INSERT?
   - A tool connected to Synapse (Databricks notebook, Azure Data Factory)?

2. **Portfolio anchoring semantics**: The experiment tested `IsPortfolioAnchored`. What does "portfolio anchoring" mean in eToro's product context? Was this a CopyPortfolio feature, a Smart Portfolio feature, or something else?

3. **IsControlPortfolioEnabled**: Even though all values are NULL, this column's name implies a scenario where the control group has portfolio features enabled or disabled. What experiment design would require this flag?

4. **ServiceLevelAnchored**: Implies a service level (e.g., "Club Black", "Diamond") could be anchored for an experiment variant. Was this ever populated in any experiment or was it purely speculative schema design?

5. **Why only one experiment?** This table was presumably designed to hold multiple experiments (generalized schema), yet only one was ever loaded. Was it replaced by `BI_DB_AB_Test` after the 2019 experiment, or was it always a one-off?

6. **JUNK migration table**: `BI_DB_Migration.JUNK_BI_DB_AB_Test_Data` exists in the SSDT migration scripts. The "JUNK" prefix typically indicates the table was slated for cleanup during the Sept 2024 migration. Should this live table also be decommissioned?

## Corrections

- If `IsControlPortfolioEnabled` or `ServiceLevelAnchored` are explained, upgrade from Tier 4 to Tier 3 or higher
- Quality score should be revised upward once all-NULL columns' semantics are understood

## Reviewer Instructions

1. Check with the Data Science team for the September 2019 experiment context and loading method
2. Ask product/engineering about "portfolio anchoring" and whether `IsControlPortfolioEnabled`/`ServiceLevelAnchored` were ever used
3. Determine if this table should be decommissioned (given the JUNK migration staging table)
