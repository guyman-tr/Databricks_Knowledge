# EXW_TestUsers — Review Notes

Generated: 2026-04-20 | Reviewer: —

## Tier 4 Items

None — all 5 columns have confirmed lineage (4 × Tier 1 from Customer.CustomerStatic, 1 × Tier 2 from SP).

## Open Questions

- **Refresh schedule**: No OpsDB schedule found for SP_EXW_TestUsers. Confirm whether this runs daily, weekly, or ad-hoc. UpdateDate goes to 2026-03-20 suggesting it is still active.
- **Missing pattern removal**: Users who no longer match any test pattern (e.g., renamed) are never removed. Is this intentional? Should there be a DELETE step for accounts that no longer match?
- **958 rows scope**: Confirm this list is complete — are there other test-user identification criteria not yet encoded in the SP?
- **GCID NULL risk**: GCID is nullable in the DDL. Can test users have NULL GCID? If so, SP_DimUser's LEFT JOIN on GCID=GCID would miss them.

## No Reviewer Corrections at Time of Generation
