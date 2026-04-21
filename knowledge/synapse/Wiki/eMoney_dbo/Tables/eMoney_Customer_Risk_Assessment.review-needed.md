# eMoney_Customer_Risk_Assessment — Review Needed

> Sidecar checklist for wiki reviewer. All wiki content is in `eMoney_Customer_Risk_Assessment.md`.

## Open Questions

| # | Column / Topic | Question | Priority |
|---|---------------|----------|---------|
| 1 | P10 | Confirm P10 (KYC Q46 Citizenship By Investment Program) is permanently cancelled and not planned for reinstatement. If reinstated, P10_Response and P10_Risk would populate and P10_Weight would contribute to Risk_Final_Result. | High |
| 2 | @RiskLowerCut / @RiskUpperCut | What are the current numeric threshold values for Low/Medium and Medium/High boundaries? (ParameterID 98/99 in Fivetran classification table — ParameterWeight × 100). Required to interpret Risk_Final_Result values meaningfully. | High |
| 3 | History anomaly (2025-02-25 → 2025-03-12) | During this period, History used score-change trigger (Risk_Final_Result <>) instead of class-change trigger. Does any downstream system or analysis rely on History row counts? If so, the inflated rows during this window may skew retention/class-stability metrics. | Medium |
| 4 | CountryByIP | CountryIDByIP was computed in #dim_customer but commented out (`/*,dc.CountryIDByIP*/`). Was this intentionally removed, and is there a plan to re-add it? | Low |
| 5 | RiskStatus | RiskStatusID is joined in Step 04 (LEFT JOIN Dim_RiskStatus) but not stored in the CRA table. Was it considered for a column and deliberately excluded? | Low |
| 6 | VerificationLevelID near-100% at level 3 | Virtually all CRA rows show VerificationLevelID=3 (fully verified). Is this expected for the active eTM population, or is there a filtering issue upstream? | Low |
| 7 | IsValidETM NULL (~20.9%) | ~424K customers have NULL for IsValidETM, indicating a LEFT JOIN miss from eMoney_Dim_Account. Are these customers with only a GCID_Unique_Count>1 account (excluded by the filter), or a data gap? | Medium |
| 8 | eTM_FMI / eTM_FMO | eMoney_Panel_FirstDates is INNER JOINed in Step 05 (not LEFT JOIN). Customers without a matching Panel_FirstDates record would be excluded from the population entirely. Confirm this is correct and that eMoney_Panel_FirstDates covers all active accounts. | Medium |
| 9 | Manual Override source freshness | The manual override Google Sheet is synced via Fivetran. Confirm Fivetran sync frequency — if the sheet is updated intra-day, it will not take effect until the next Fivetran cycle. | Low |
| 10 | BusinessDuration encoding | BusinessDuration=1 means "less than 1 year since FTD" (DATEDIFF YEAR=0 → bucket 1). This is a non-intuitive encoding. Confirm that downstream users understand this is a bucket (1/2/3), not year count. | Medium |
| 11 | P32 grouping order | In the wiki Elements section, P32 appears in section 4.13 (IBAN MIMO) with DDL ordinals #118-119, while P27-P31 in section 4.14 use ordinals #108-117. The grouping is thematically correct (P32 is an IBAN metric) but the ordinal numbering reads non-sequentially across sections. No content error — cosmetic only. | Low |

## Tier 1 Copy Verification

| Column | Upstream Source | Stripped Items | Status |
|--------|----------------|----------------|--------|
| CID | Dim_Customer.md row (RealCID) — Customer.CustomerStatic | None stripped; DWH rename note appended | IDENTICAL |
| GCID | Dim_Customer.md row (GCID) — Customer.CustomerStatic | None stripped | IDENTICAL |
| VerificationLevelID | Dim_Customer.md row — BackOffice.Customer | Stats stripped: "(34.2%)", "(12.4%)", "(6.2%)", "(47.1%)" | IDENTICAL (stats stripped) |
| DateOfBirth | Dim_Customer.md row (BirthDate) — Customer.CustomerStatic | None stripped; DWH CAST+rename note appended | IDENTICAL |
| DateOfReg | Dim_Customer.md row (RegisteredReal) — Customer.CustomerStatic | None stripped; DWH CAST+rename note appended | IDENTICAL |

**T1 Coverage**: 5 Tier 1 columns out of 120 total. Upstream Dim_Customer.md has ~87 documented columns, but only 5 pass through to CRA without ETL transformation (rename or CAST-only is permitted per 10.5b). Remaining 115 columns are Tier 2 (SP-computed, lookup-joined, or Fivetran-derived). Phase 10.5b HARD FAIL check: upstream_wiki_columns > 20 AND tier1_count > 0 → condition satisfied, no fail.

## Items Confirmed by Reviewer

- [ ] P10 permanently cancelled (no reinstatement planned)
- [ ] @RiskLowerCut and @RiskUpperCut current values confirmed
- [ ] History anomaly rows (2025-02-25 → 2025-03-12) impact on downstream systems assessed
- [ ] IsValidETM NULL (~20.9%) — LEFT JOIN miss reason confirmed
- [ ] eTM_FMI/FMO INNER JOIN on Panel_FirstDates confirmed as intentional
- [ ] BusinessDuration=1 encoding understood by downstream users
- [ ] CountryByIP exclusion confirmed as permanent

## Phase 16 Adversarial Evaluation

| Dimension | Score | Notes |
|-----------|-------|-------|
| Business Meaning | 9.0 | Risk engine purpose, override hierarchy, 32-param structure, observed distributions all documented |
| Grain & Lifecycle | 9.5 | Customer grain explicit, TRUNCATE+INSERT described, History class-change rule documented, 2025 anomaly noted |
| Technical Accuracy | 9.0 | SP step summary matches all 32 steps; formula explicit; dynamic thresholds; P10 cancellation; 99999 sentinel; all override paths |
| Column Completeness | 8.5 | All 120 columns documented; P32 grouping order cosmetic issue noted; no missing columns |
| Tier Accuracy | 9.0 | 5 Tier 1 verified verbatim from upstream; 115 Tier 2 correct; P10 marked cancelled; no false Tier 1 assignments |
| Gotchas & Flags | 9.0 | P10 always NULL, dynamic thresholds, PEP vs algorithm score discrepancy, history anomaly, ClientRiskDate semantics, UpdateDate not a business date |
| **Average** | **9.0** | **PASS (≥7.5 threshold)** |
