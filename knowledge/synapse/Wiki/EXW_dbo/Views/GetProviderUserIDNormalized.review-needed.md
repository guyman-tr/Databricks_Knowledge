# EXW_dbo.GetProviderUserIDNormalized — Review Needed

**Generated**: 2026-04-20 | **Batch**: 4 | **Type**: View

## Tier 4 / Unverified Items

| Column | Issue | Notes |
|--------|-------|-------|
| Country (T3) | Type assumed nvarchar — not explicitly declared in view DDL | Inherited from Dim_Country.Name |
| Regulation (T3) | Type assumed nvarchar — not explicitly declared in view DDL | Inherited from Dim_Regulation.Name |
| PlayerStatus (T3) | Type assumed nvarchar — not explicitly declared in view DDL | Inherited from Dim_PlayerStatus.Name |

## Open Questions for Reviewer

1. **Multiple rows per GCID**: Confirm analysts understand this view returns one row per AML submission event (date × provider), not one row per user. Is a current-state version of this view needed?

2. **Consumer coverage**: Only BI_DB_dbo.SP_W_Tue_Email_for_KYT found as consumer. Are there other non-SSDT consumers (Power BI, Excel, SSRS) querying this view directly?

3. **NCHAR trailing spaces**: UserWalletAllowance is NCHAR(50) from EXW_UserSettingsWalletAllowance — trailing spaces confirmed in live data sample. Should a RTRIM() wrapper be added to the view definition?

## Cross-Object Consistency

- CID description matches EXW_AMLProviderID.RealCID (Tier 1 — Customer.CustomerStatic) ✓
- GCID description matches EXW_AMLProviderID.GCID (Tier 2) ✓
- ProviderUserIDNormalized description matches EXW_AMLProviderID (Tier 2) ✓
- UserWalletAllowance description matches EXW_UserSettingsWalletAllowance (Tier 2) ✓

## No ALTER Script

ALTER script deferred to /generate-alter-dwh. UC Target = `_Not_Migrated`.
