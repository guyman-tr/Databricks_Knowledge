# BI_DB_AML_Periodic_Review_HR — Review Notes

**Generated**: 2026-04-22
**Batch**: 49
**Reviewer action required**: Yes — SP bug may affect this table

---

## Phase 16 Adversarial Evaluation

| Dimension | Score | Notes |
|---|---|---|
| Tier fidelity | 8.5/10 | 9 T1 (same as AR), 23 T2 (AR's 22 + Final_Decision), 13 T3, 1 Propagation. Final_Decision correctly placed as T2 (SP-derived computation). All tier assignments consistent with upstream wikis and AR table. |
| Upstream fidelity | 9/10 | T1 columns for KYC_Panel and AML_KYC_SOF sources copied verbatim from upstream wikis. Final_Decision logic documented with exact SP CASE logic. |
| Completeness | 9.5/10 | All 46 DDL columns documented. Final_Decision distribution (Green 43.3%/Orange 43.1%/Red 13.5%) captured. Top signal combinations documented. FTD range confirms 1-year population gate. |
| Business meaning | 9/10 | HR vs AR vs MR distinction clear. Orange > Red priority rule documented and verified with data (Orange customers with screening flag = Orange not Red). SOF mitigation mechanism (Has_Proof_Of_Income_FromLastYear) documented. |
| Data evidence | 9/10 | Live sampling: row count, Final_Decision distribution, Regulation breakdown, Age_Group, signal combinations all confirmed. The 461 Green rows with Is_High_Risk_SOF=1 confirm the income-proof mitigation logic. |
| Shape fidelity | 9/10 | ROUND_ROBIN HEAP, TRUNCATE+INSERT confirmed. Column 44 position of Final_Decision verified against sys.columns. |

**Overall**: 9.0/10 — PASS (threshold: 7.5)

---

## Open Issues

**ISSUE 1 (Medium priority — SP BUG, affects HR population gate)**: In `SP_AML_Periodic_Review`, `@3YearsAgo_DateID` is computed using `@YearAgo_Date` instead of `@3YearsAgo_Date`. The HR table uses `@YearAgo_Date` (FTD filter: 1 year ago), NOT the buggy date variable. However, the MR table uses `@3YearsAgo_DateID` which IS computed with the wrong date. **Confirmed: HR is not affected by this bug.** The FTD range (oldest 2008, newest 2025-04-11 = 1 year before 2026-04-12) matches the `@YearAgo_Date` correctly.

**ISSUE 2 (Low priority — undocumented dependency)**: `BI_DB_SF_Cases_Panel` has no wiki entry. Same as AR table.

**ISSUE 3 (Low priority — type inconsistencies vs AR)**: Several columns have different data types in HR vs AR for the same semantic meaning:
- `Regulation`: AR=varchar(250), HR=nvarchar(8000)
- `aml_compliance_POB`: AR=varchar(250), HR=nvarchar(8000)
- `aml_compliance`: AR=nvarchar(500), HR=varchar(250) ← reversed
- `ScreeningStatus`: AR=varchar(250), HR=nvarchar(8000)
- `ReasonType`: AR=nvarchar(1000), HR=nvarchar(8000)

These are cosmetic (no data loss for current values) but indicate the SP was written at different times or uses different source column types for each output. Flag for DDL standardization.

---

## Confirmed Behaviors

- TRUNCATE + INSERT daily — no history retained
- 100% of rows have RiskScoreName='High' — safe to query without that filter
- PlayerStatus limited to 'Normal' (99.5%) and 'Warning' (0.5%) — population gate enforced
- FTD newest = 2025-04-11 ≈ 1 year before run date — confirms `@YearAgo_Date` filter working correctly
- Orange takes PRIORITY over Red in Final_Decision (doc expiry supersedes risk flags)
- Is_High_Risk_SOF=1 does NOT guarantee Red — Has_Proof_Of_Income_FromLastYear=1 mitigates to Green (461 confirmed rows)
- All rows have UpdateDate = 2026-04-12 05:56:27 (uniform per daily run)
