# BI_DB_dbo.BI_DB_Finance_Staking_Report — Review Needed

## Tier 4 Items (None)

No Tier 4 items — all columns traced to SP code.

## Questions for Reviewer

1. **InstrumentID 100017 and 100026**: What crypto staking instruments are these? The SP hardcodes these IDs but does not document what they represent. Likely ETH staking (100017) and another crypto staking product.

2. **No author/date in SP comment block**: The SP has no comment header identifying the author or creation date. Was this created as part of the staking feature launch?

3. **DELETE scope asymmetry**: The DELETE only matches on StakingMonth from #Temp_AirDrop — it does not delete Compensations rows independently. If the compensation source data changes retroactively, stale Compensations rows may persist for historical months.

4. **StakingMonthID is varchar, not int**: This is unusual — most other DateID columns in the schema are int. Is this intentional for the YYYYMM format?

5. **0 Tier 1 columns**: This table aggregates from DWH dimensions with no direct production upstream wiki. All descriptions derived from SP code analysis (Tier 2).

## Corrections Applied

- None required.

## Cross-Object Consistency

- Regulation_Name values match Dim_Regulation.Name (verified against Dim_Regulation wiki).
- No shared columns with other documented tables requiring consistency check.

*Generated: 2026-04-26*
