# EXW_AMLProviderID — Review Notes

Generated: 2026-04-20 | Reviewer: —

## Tier 2 Items (Derived — May Need Verification)

| # | Column | Description | Verification Needed |
|---|--------|-------------|---------------------|
| 1 | AMLProviderID | Values 1, 3, 4 observed — provider names not in SSDT code | Confirm identity of providers 1, 3, and 4 (e.g., Elliptic, Chainalysis, ComplyAdvantage) |
| 2 | ProviderUserID | Observed to be base64-encoded GCID — but this is inferred from live data sampling, not documented in SP | Confirm with AML team that ProviderUserID is always base64(GCID) for all providers |
| 3 | DateID | Computed from AmlProviderUsers.Occurred — daily grain assumed | Confirm if a GCID can appear more than once per DateID (e.g., submitted to two providers on the same day) — expected YES but verify grain |

## Open Questions

- **AMLProviderID 2 missing**: Values 1, 3, and 4 are present but no ID=2 rows exist in the live table. Was provider 2 deprecated, renamed, or was ID=2 never used?
- **Provider name mapping**: The SP has no CASE WHEN for provider names — is there a dictionary or lookup table elsewhere (e.g., WalletDB or Confluence) that maps 1/3/4 to provider names?
- **INNER JOIN to EXW_DimUser**: The SP uses an INNER JOIN (not LEFT JOIN) to EXW_DimUser for RealCID. This means AML users not in EXW_DimUser are silently excluded. Is this intentional? Could AML submissions for users who don't appear in EXW_DimUser be lost?
- **UC Target**: Listed as `_Not_Migrated` — confirm whether EXW_AMLProviderID should be exported to Unity Catalog for compliance analytics.
- **Refresh schedule**: SP takes a @dt date parameter — confirm what orchestration system schedules daily runs and whether there is failure alerting.

## No Reviewer Corrections at Time of Generation
