# EXW_UserSettingsWalletAllowance — Review Needed

**Generated**: 2026-04-20 | **Batch**: 2 | **Object**: EXW_dbo.EXW_UserSettingsWalletAllowance

---

## Tier 4 Items (Unverified / Needs Human Review)

None — all 12 columns have Tier 1 or Tier 2 lineage traced to confirmed sources.

---

## Open Questions for Reviewer

1. **SelectedValue=3 (AllowedForExistingUsers) usage**: The CASE statement maps SelectedValue=3 to `Allowed` in UserWalletAllowance. How many users currently have SelectedValue=3 in the raw settings? Is AllowedForExistingUsers still an active rule type or a legacy value? Downstream consumers may need to know if `Allowed` means "unrestricted" or "grandfathered existing user."

2. **IsCustomerLevelWin tie-breaking with StatusMap**: When a user has both a group rule and a customer-level override, External_WalletDB_Eligibility_StatusMap determines which takes precedence via the `IsCustomerLevelWin` flag. The StatusMap logic was not fully traced — confirm whether StatusMap always prefers the customer-level rule or whether the group rule can still win in some StatusMap states.

3. **AllowanceBeginDate NULL for 1,672 users**: These users have a winning restriction but no BeginDate in EXW_Settings.SystemRestrictions. Confirm: are these rules intentionally unbounded (always effective from the beginning), or are they legacy rules with missing dates? Should NULL BeginDate be treated as MIN_DATE for time-based filtering?

4. **ComplianceClosureEvent vs Compensated discrepancy**: ComplianceClosureEvent=1 marks users in a closed-wallet country (18,690 users). Compensated=1 marks users who were actually compensated (51,895 users). The compensated count (51,895) exceeds the closure-event count (18,690). Confirm: are some users compensated for reasons other than a country closure (e.g., individual regulatory decisions), or does this reflect a gap in EXW_WalletClosedCountryProjects coverage?

5. **DynamicGroup TagValue resolution**: For DynamicGroup tag winners, TagValue stores the group name from CopyFromLake.SettingsDB_Dictionary_DynamicGroup. Confirm the naming convention for group names and whether these group names are stable (i.e., safe for downstream filtering by hardcoded TagValue strings).

6. **CountryRegionAndRegulation scope (US only)**: The SP comment and logic suggests Priority 1 (CountryRegionAndRegulation) only applies to US users with a RegionID (state-level split). Confirm the exact RegulationID or CountryID constraint used to gate this priority tier — the SP hardcodes this but the rule is not documented in EXW_Settings metadata.

---

## Cross-Object Consistency Check

✅ GCID description matches EXW_DimUser.md verbatim (modified "HASH distribution key and CLUSTERED INDEX key" → "HASH distribution key" because this table is HEAP not CLUSTERED INDEX)
✅ RealCID description matches EXW_DimUser.md verbatim
✅ ComplianceClosureEvent logic matches EXW_WalletClosedCountryProjects.md (RegulationID NULL for 78/89 rows confirmed)
✅ Project column values (A=31, B=35, C=15, D=4, E=1, F=2, H=1) match EXW_WalletClosedCountryProjects batch_context key_findings

---

## Phase Gate Summary

| Phase | Status | Notes |
|-------|--------|-------|
| P1 DDL | PASS | 12 cols, HASH(GCID), HEAP |
| P2 Sample | PASS | 699,692 rows confirmed — 1:1 GCID, UpdateDate 2026-04-13 |
| P3 Distribution | PASS | Allowed=604,796, NotAllowed=79,868, ReadOnly=15,028; TagType breakdown verified |
| P4 Lookup | PASS | EXW_DimUser wiki read for T1 inheritance |
| P5 JOINs | PASS | GCID is HASH join key to EXW_DimUser |
| P6 BizLogic | PASS | 5-priority resolution, compensation flags, compliance closure documented |
| P7 Views | PASS | GetProviderUserIDNormalized identified as consumer view |
| P8 SP Scan | PASS | Writer: SP_EXW_UserSettingsWalletAllowance; 6 downstream consumers identified |
| P9 SP Logic | PASS | Full source-to-target map from SP code (847 lines analyzed) |
| P9B ETL Orch | PASS | Daily TRUNCATE+INSERT; same SP also writes EXW_AML_Users_Report |
| P10 Atlassian | [-] | Skipped — no Atlassian MCP results |
| P10A Upstream | PASS | EXW_DimUser wiki read for GCID/RealCID T1 verbatim |
| P10B Lineage | PASS | .lineage.md written |
| P11 Generate | PASS | .md and .review-needed.md written |
