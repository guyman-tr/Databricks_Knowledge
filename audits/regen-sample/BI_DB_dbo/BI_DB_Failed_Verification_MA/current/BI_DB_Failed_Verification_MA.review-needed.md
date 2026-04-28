# BI_DB_dbo.BI_DB_Failed_Verification_MA — Review Needed

## Tier 4 Items

None — all columns traced to SP code.

## Open Questions

1. **No Tier 1 columns**: Source is BI_DB_Operations_Onboarding_Flow_UserKPIs which has no upstream wiki. All columns are Tier 2.
2. **Typo in SP**: 'ManualyVerified' (single 'l') — is this the actual value in the source data or a bug?
3. **Marketing automation consumer**: What marketing automation tool consumes this table? No downstream SP references found.
4. **ReasonNumber=0 coverage**: 19 distinct unmatched rejection texts are not mapped to codes. Should the lookup be expanded?

## Corrections for Reviewer

- EV_MatchStatus distribution verified from live data: blank (64%), NotVerified (27%), PartiallyVerified (9%), None (<1%).
- ReasonNumber distribution verified: POA reasons dominate (11=31%, 10=21%, 8=13%).
