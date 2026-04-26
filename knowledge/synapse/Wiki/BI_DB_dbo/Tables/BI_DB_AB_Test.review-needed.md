# Review Needed: BI_DB_dbo.BI_DB_AB_Test

**Generated**: 2026-04-23
**Quality Score**: 7.5/10
**Status**: NEEDS REVIEW — no writer SP, stale since 2023, source system unknown

---

## Tier 4 Items

None — all 8 columns are Tier 3 (inferred from live data sampling and domain context). No unresolvable unknowns at column description level.

## Open Questions

1. **What populated this table?** No writer SP found in SSDT BI_DB_dbo. Was this fed by:
   - An internal experiment management tool (e.g., Optimizely, LaunchDarkly, or a custom eToro platform)?
   - A manual SQL INSERT or Python script run by the data science team?
   - A now-deleted SP?

2. **AB_Test_Onboarding_202007 has zero treatment rows (IsControl=0)**. All 75,054 rows are IsControl=1. Is this:
   - A baseline/control-only period before the treatment variant was deployed?
   - A data loading error where treatment rows were omitted?
   - Intentional — was the "treatment" in a different system and only the control group was tracked here?

3. **Is the A/B test program still active?** The last row is 2023-04-30. Was the program:
   - Discontinued and replaced by a different experimentation platform?
   - Migrated to another table or system?
   - Simply not run any new experiments since April 2023?

4. **varchar(14/15) for BI_Owner/Business_Owner** — are these free-text fields prone to inconsistency? If they're used to filter by owner, are there known variants or typos?

5. **BI_DB_AB_Test_Data relationship**: Both tables cover A/B tests but use different schemas and time periods. Were they fed by different tools? Are they meant to complement each other or are they independent experiments?

## Corrections

- If the feeding system is identified, upgrade all Tier 3 columns to Tier 2 or Tier 1 as appropriate
- If AB_Test_Onboarding_202007 missing treatment rows is confirmed as a data issue, note this explicitly in the Gotchas section

## Reviewer Instructions

1. Check with the BI team (Tom Boksenbojm or successor) for the experiment loading process
2. Check if a tool like Optimizely or Amplitude was connected to Synapse for experiment data
3. Confirm whether new A/B tests are now tracked elsewhere or if the program is dormant
