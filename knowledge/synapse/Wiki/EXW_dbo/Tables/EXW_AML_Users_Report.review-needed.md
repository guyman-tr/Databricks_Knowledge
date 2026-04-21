# EXW_AML_Users_Report — Review Needed

**Generated**: 2026-04-20 | **Batch**: 2 | **Object**: EXW_dbo.EXW_AML_Users_Report

---

## Tier 4 Items (Unverified / Needs Human Review)

None — all 53 columns have Tier 1 or Tier 2 lineage traced to confirmed sources.

---

## Open Questions for Reviewer

1. **IsAMLProblematic age thresholds (≤25 and ≥65)**: The SP hardcodes age-based flagging (Age≤25 or Age≥65 → IsAMLProblematic=1). These thresholds produce significant volume — young users are a large proportion of the 225,962 flagged users. Confirm whether these age bounds are intentional AML policy or legacy from a regulatory framework that has since changed. Is there documentation linking these specific thresholds to a compliance requirement?

2. **RiskScore NULL treated as problematic**: BI_DB_RiskClassification JOIN uses INNER JOIN on RealCID — users without a risk score have NULL RiskScoreName. The IsAMLProblematic CASE checks `RiskScoreName NOT IN ('Low', 'Medium')`, so NULL is treated as high-risk (145,442 users flagged solely because they have no score). Confirm whether this is intentional (unscored = suspicious) or a logic gap (unscored = not yet processed → should be excluded from this condition).

3. **AML provider fan-out — not documented in any existing comment**: The LEFT JOIN EXW_AMLProviderID produces 160 duplicate GCID rows (users with 2 active providers). This is not mentioned in the SP header comments. Confirm: is this understood behavior (AML team queries by AMLProviderID and deduplication is intentional at query time), or is it an untracked data quality issue?

4. **HasCryptoTransfer SenderAddress hardcode**: The sender address '0x5be786ad38f5846f605a8003550074cdfd4899a1' is hardcoded in the SP with no comment explaining its origin. Confirm: is this the canonical eToro Wallet hot wallet address? Should this be maintained in a config table rather than hardcoded? Does it need updating if the wallet address rotates?

5. **HasRiskCountryLogins 60-day window**: The login lookback is hardcoded as `DateID >= CAST(CONVERT(VARCHAR(8), getdate()-60, 112) AS INT)`. Confirm the 60-day window is the correct compliance requirement and whether this lookback period should be configurable.

6. **RelatedCIDs biometric key construction**: The linked-account key concatenates FirstName+LastName+BirthDate+Gender+Zip+CountryID without normalization (no LOWER(), no TRIM()). This means case differences or whitespace will prevent matching across otherwise identical records. Confirm whether this is intentional (strict match) or a quality gap.

7. **ScreeningStatus dual-source ambiguity**: Col 20 (ScreeningStatus) is from DWH internal Dim_Customer.ScreeningStatusID; Col 51 (ScreeningStatusExt) is from the external BI_DB ScreeningService. These two systems can disagree. Which is authoritative for compliance reporting? Is the AML team aware there are two different screening systems and which statuses map to which?

8. **CountryID=219 → IsUS mapping**: The SP maps CountryID=219 to IsUS='Y'. Confirm that CountryID=219 is indeed Tuvalu and that the US mapping is an intentional legacy encoding rather than a data error. If confirmed, add a code comment to avoid future confusion.

---

## Cross-Object Consistency Check

✅ GCID description matches EXW_DimUser.md verbatim (HEAP adaptation: "HASH distribution key for this table")
✅ RealCID description matches EXW_DimUser.md verbatim
✅ VerificationLevelID description matches EXW_DimUser.md verbatim
✅ EvMatchStatus description: "Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed." — verbatim from Dim_Customer.md (Tier 1 — BackOffice.Customer)
✅ IsValidCustomer description matches EXW_DimUser.md
✅ PlayerStatusID: T1 (Customer.CustomerStatic) consistent with Dim_Customer.md
✅ CountryID: T1 (Customer.CustomerStatic) consistent with Dim_Customer.md
✅ BirthDate: T1 (Customer.CustomerStatic) confirmed from Dim_Customer.md element table
✅ RiskClassificationID: T1 (BackOffice.Customer) confirmed from Dim_Customer.md element table
✅ AMLProviderID distribution (NULL=493,445, 1=166,322, 3=27,381, 4=12,704) consistent with EXW_AMLProviderID batch_context key_findings (166K, 27K, 13K rows respectively)
✅ ClosingProject project letters (A-H) consistent with EXW_WalletClosedCountryProjects batch_context
✅ UserWalletAllowance passthrough: distribution matches EXW_UserSettingsWalletAllowance (Allowed, ReadOnly, NotAllowed)

---

## Phase Gate Summary

| Phase | Status | Notes |
|-------|--------|-------|
| P1 DDL | PASS | 53 cols, HASH(GCID), HEAP |
| P2 Sample | PASS | 699,852 rows total, 699,692 distinct GCIDs; UpdateDate 2026-04-13 |
| P3 Distribution | PASS | IsRealUser, IsAMLProblematic, CountryRankDescription, RiskScoreName, AMLProviderID, IsUS distributions verified |
| P4 Lookup | PASS | Dim_Customer.md, EXW_DimUser.md, EXW_DimUser_Enriched.md read |
| P5 JOINs | PASS | GCID is HASH join key to all EXW_dbo co-distributed tables |
| P6 BizLogic | PASS | IsAMLProblematic 7-condition logic, IsRealUser, CountryRank, AML fan-out all documented |
| P7 Views | PASS | No views reference EXW_AML_Users_Report |
| P8 SP Scan | PASS | Writer: SP_EXW_UserSettingsWalletAllowance; no SSDT-tracked downstream consumers |
| P9 SP Logic | PASS | Full #all and #finalaml source-to-target map traced through all 22 temp tables |
| P9B ETL Orch | PASS | Daily TRUNCATE+INSERT; co-written with EXW_UserSettingsWalletAllowance in same SP run |
| P10 Atlassian | [-] | Skipped — no Atlassian MCP results |
| P10A Upstream | PASS | Dim_Customer.md read for T1 tiers; EXW_DimUser_Enriched.md and EXW_UserSettingsWalletAllowance.md cross-checked |
| P10B Lineage | PASS | .lineage.md written (53 cols, 8 T1, 45 T2) |
| P11 Generate | PASS | .md and .review-needed.md written |
