# BI_DB_dbo.BI_DB_DDR_Fact_AUM — Review Needed

Sidecar checklist for domain experts — **does not substitute** `.md`.

---

## PHASE 16 — Adversarial Scorecard (experiment)

| Dimension | Score (1–10) | Evidence / Issue |
|-----------|----------------|-------------------|
| Tier Accuracy | 8.5 | 14 VL/FSE surrogates tagged Tier **1**, remainder Tier **2** — spot-check aligns with GATE contract; ambiguity only on VL relay vs deepest origin wording. |
| Lineage Evidence | 9.0 | **Phase 9 verbatim** SP blocks anchored in `.lineage.md`; no guessed transforms. |
| Business Clarity | 7.8 | **`TotalEquityTP` naming** vs `#ClientBalance` sum of (`TotalLiability`+`ActualNWA`) flagged — risks analyst misread versus balance docs. |
| Cross-Object Consistency | 8.0 | `RealCID` matches `Dim_Customer`; VL formulas copied from `V_Liabilities.md` — OK. |
| Operability | 8.2 | Query advisory + duplication warning present; OPTIONS lag risk highlighted. |

**Weighted composite (manual blend per rubric priorities): ~8.1 / 10** — clears internal **7.5** bar with residual naming debt.

---

## Soft Fails / Pipeline Signals

| # | Checkpoint | Severity | Detail |
|---|--------------|----------|--------|
| S1 | Phase 3 DMV row count | SOFT | Dedicated pool DMV path (`sys.dm_pdw_*`) unreachable from MCP ODBC profile — substituted date-bounded `MIN/MAX` + single-day cardinality sample. |
| S2 | Atlassian MCP | SOFT | Scoped Confluence scrape **not rerun** beyond inherited pointer in `V_Liabilities`; no DDR-specific slug confirmed. |

---

## Parity Assertion

**DDL (`BI_DB_dbo.BI_DB_DDR_Fact_AUM.sql`) column count ↔ Elements table rows = **43 / 43** ✓**.

---

## PII Checkpoint

Numeric fact only; surrogate **`RealCID`** needs alignment with Org GDPR taxonomy when tagging UC columns (customer identifier class).

---

## Reviewer Corrections

| Column / Topic | Current | Correction | Scope | Reviewer | Date |
|----------------|---------|-----------|-------|----------|------|
| _(none)_ | | | | | |

---

## Tier 4 (UNVERIFIED)

None flagged — every column cites SP verbatim block or VL/Client Balance lineage.

---

## Open Questions

1. Should **`TotalEquityTP`** be renamed in a future DDL migration to **`TotalCombinedLiabilityNWA_TP`** or similar to avoid lexical clash with treasury “equity”?
2. What **customer archetypes** land exclusively in UNION supplement beyond IBAN-/Options-first shells?
3. Validate **whether `OptionsCashEquity` belongs in `CreditGlobal` regulatory interpretation** versus marketing credit semantics.
4. Confirm **Approx FX** stewardship for **`IBANBalance`** vs treasury rates used in statutory filings.
