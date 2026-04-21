# Review Needed — eMoney_dbo.eMoney_Dim_Country_Rollout

**Generated**: 2026-04-21 | **Batch**: 12 | **Quality**: 8.5/10

---

## Tier 4 Items (Low-Confidence — Need Verification)

| Column | Issue | Action |
|--------|-------|--------|
| CountryID | Sourced from DWH_dbo.Dim_Country which has no wiki yet | Once Dim_Country is documented, verify CountryID semantics match |
| CountryName | Renamed from Dim_Country.Name — description inferred | Confirm no other Name variants exist in Dim_Country |
| Region | Values observed: UK, French, Spanish, Italian, Eastern Europe, North Europe, German, ROE, Australia — but sourced from undocumented Dim_Country | Verify complete Region enum from Dim_Country |
| Desk | Values observed: UK, French, Spanish, Italian, Other EU, German, Australia — sourced from undocumented Dim_Country | Verify complete Desk enum from Dim_Country |

---

## Open Questions

1. **Is there a planned deactivation process?** If eToro Money exits a market, how is the row removed? The SP does DELETE+INSERT but rollout dates are hardcoded — would a country be removed by deleting its CASE entry?
2. **CountryID=12 (Australia)** — the SP header says rollout date 2025-10-15, added 2025-10-12 by Shachar Rubin. Is this correct? The date is very recent.
3. **No IsActive flag** — if a rollout is reversed (e.g., regulatory withdrawal), the row would persist unless the SP is modified. Is there a separate process for deactivations?
4. **DWH_dbo.Dim_Country wiki** — once created, Tier 4 columns should be updated to Tier 1 (if wiki confirms descriptions) or Tier 2.

---

## No Reviewer Corrections Required

All column descriptions are consistent with SP code analysis. Quality is constrained by the absence of a DWH_dbo.Dim_Country wiki (Tier 4 for passthrough columns).
