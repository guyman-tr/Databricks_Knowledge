# Review Needed — eMoney_Customer_Risk_Assessment

**Generated**: 2026-04-21 | **Batch**: 9 | **Reviewer**: eMoney & Wallet Data Analytics Team

---

## Tier 4 Items (Uncertain — Needs Confirmation)

None. All 120 columns are Tier 1 or Tier 2 (fully confirmed from SP source code and upstream wikis).

---

## Open Questions

| # | Column(s) | Question | Priority |
|---|-----------|----------|----------|
| Q1 | P12_Response | SP logic references DocType 16/17 for Source of Income document — please confirm these are the correct document type IDs for SOI acceptance. | Medium |
| Q2 | P13_Response | DocType 15 and 18 used for Selfie verification — please confirm both remain active document type IDs. | Low |
| Q3 | Risk_Final_Result | What is the current numeric range for Risk_Final_Result? This would help consumers interpret the score without needing to look up the classification table. | Medium |
| Q4 | IsValidETM | 0.06% of rows have IsValidETM=0 (1,215 rows). What distinguishes IsValidETM=0 from IsValidETM=NULL? Is 0 an explicit invalid-account flag vs NULL being no-account? | Low |
| Q5 | P10_Response / P10_Risk | When was Q46 (Citizenship by Investment Program) cancelled, and is there any plan to re-enable it? The SP hardcodes NULL/weight=0 permanently with no conditional logic. | Low |
| Q6 | CountryTIN | The COALESCE priority for TIN country resolution (address-matching > HRC-different > non-HRC) is not documented in any Confluence page found. Please confirm this is the intended priority and add to team documentation. | Medium |

---

## Data Quality Flags (Observed in Phase 2/3)

| Flag | Detail | Severity |
|------|--------|----------|
| 'Error' class (2,043 rows) | 0.1% of customers have NULL Risk_Final_Result → ClientRisk='Error'. These customers are likely missing KYC data or have classification table coverage gaps. | Medium |
| P10 always NULL | 100% of P10_Response and P10_Risk are NULL — this is expected (cancelled parameter) but analysts may query these columns expecting data. Add a comment to any downstream reports that use P*_Response. | Low |
| STALE MaxDate | As of data sampling (2026-04-12), most recent ClientRiskDate is 2026-04-12. Verify daily refresh is still running after Group One completes. | Low |

---

## Reviewer Corrections Log

*Empty — no corrections received yet. Reviewers: add your corrections here with date and initials.*

---

## Phase 16 Adversarial Evaluation

**Evaluator**: Claude Sonnet 4.6 (independent review)
**Date**: 2026-04-21

### Dimension Scores

| Dimension | Weight | Score | Notes |
|-----------|--------|-------|-------|
| Tier Accuracy | 25% | 9.5 | All 5 Tier 1 cols have upstream wiki match; 115 Tier 2 cols are SP-code confirmed. T1 fidelity verification table present. P10 correctly flagged as CANCELLED. |
| Upstream Fidelity | 20% | 9.0 | Tier 1 descriptions copied verbatim with stats stripped per 10.5b protocol. DWH notes added for CAST transformations and NOT NULL constraint. Word count verification table included. |
| Completeness | 20% | 9.0 | All 120 columns documented. Parameter group table covers all 32 parameters. Business logic covers 5 scoring steps. 29 source objects listed in lineage file. |
| Business Meaning | 15% | 9.0 | AML scoring purpose is clearly explained. Override mechanisms documented (201 PEP, 1 manual). Dynamic threshold gotcha flagged prominently. 'Error' class semantics explained. History reversion history documented. |
| Data Evidence | 10% | 9.0 | Phase 2/3 data used throughout: 2,031,882 rows, date range, ClientRisk distribution percentages, IsValidETM split. Parameter response codes derived from live SP logic. |
| Shape Fidelity | 10% | 9.5 | 8-section structure, property table (11 rows), Elements table (120 rows all with Tier suffix), ASCII ETL diagram, sample queries, tier legend, T1 verification table. |

**Composite Score**: 9.1 / 10.0

**PASS** (threshold: 7.5)

### Evaluator Notes

- **Strength**: The 32-parameter scoring engine is comprehensively documented with parameter groups, ResponseID semantics, and the dynamic threshold mechanism. The P10 CANCELLED flag is prominent.
- **Strength**: The History table relationship (class-change-only, reverted 2025-03-12) is a non-obvious operational detail that is correctly captured.
- **Minor gap**: Document type IDs for P12/P13 (16/17 for SOI, 15/18 for selfie) should be confirmed with the team (see Q1/Q2 above).
- **Minor gap**: The exact numeric range of Risk_Final_Result would add value for consumers (see Q3 above).
