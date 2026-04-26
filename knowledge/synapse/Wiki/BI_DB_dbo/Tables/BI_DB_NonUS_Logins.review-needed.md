# BI_DB_dbo.BI_DB_NonUS_Logins — Review Needed

## Tier 4 Items

None — all columns traced to SP code (Tier 2).

## Questions for Reviewer

1. **Column count**: DDL has 5 columns, batch assignment said 6. Verified: 5 in DDL and INSERT.
2. **Vestigial Dim_Country join**: The #final temp table joins Dim_Customer → Dim_Country but uses no columns from it. This join is dead code — possibly remnant of a removed column.
3. **USLogins>0 filter**: Only customers with at least one US login are included. This means the table is a regulatory exception list, not a comprehensive login geo table.
4. **RegulationID NOT IN (6,7)**: Excludes NFA (6) and eToroUS (7) — these are legitimately US-regulated. Verify these IDs are current.
5. **CountryID NOT IN (219)**: Excludes US-registered customers. Combined with the regulation filter, this targets non-US customers logging in from US IPs.
6. **UC migration**: _Not_Migrated.

## Corrections Applied

- Column count corrected from 6 to 5.
