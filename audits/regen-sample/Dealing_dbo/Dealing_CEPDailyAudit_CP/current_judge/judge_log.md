## Judge Review — Dealing_dbo.Dealing_CEPDailyAudit_CP

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 7/10**
Sampled 5 columns: Date (T2 ✓), CompoundPropertyID (T2 ✓), TypeOfChange (T2 ✓), Comments (T2 ✓), UpdateDate (T4 ✗). UpdateDate is clearly `GETDATE()` in the SP's INSERT statement — this is visible SP code, not inferred. Should be Tier 2. One mismatch out of 5.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
The wiki claims 0 Tier 1 columns. The upstream bundle contains only sibling CEPDailyAudit tables (Rules, Conditions, etc.), which are NOT upstream sources — they are co-written by the same SP from independent staging tables. The actual upstream sources (Dealing_staging.External_Etoro_CEP_CompoundProperties, etc.) are all unresolved with no wikis. Zero Tier 1 columns is correct. Neutral score applies.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count (11) matches DDL column count (11). All element rows have 5 cells with tier tags. Property table has all required fields. Section 5.2 has ASCII ETL diagram with real object names. Footer has tier breakdown. Section 1 has row count (314) and date range (Dec 2023 – 2026-03-09). TypeOfChange lists its 3 discrete values inline. Review-needed sidecar does not contain `## 4. Elements`. 10/10 checks pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (CEP hedging rule engine), the entity (Compound Properties), the row grain (one CP lifecycle event per business date), the ETL SP, refresh pattern (daily Priority 0), row count (314), date range, and why it matters (compliance, incident investigation, governance). An analyst reading this would immediately know when to query it.

**Dimension 5 — Data Evidence: 5/10**
Row count (314) and date range (Dec 2023 – 2026-03-09) are present. TypeOfChange enum values are listed. NULL semantics for sentinel rows are documented. However, there is no Phase Gate Checklist section — P2/P3 completion is not attested. Data claims appear plausible but unverifiable without phase gate evidence.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1–8, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown. Minor deviation: no explicit "phases-completed" list in footer (only `Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10` sub-scores, which is close but not the phase-gate format).

### T1 Fidelity Table

No Tier 1 columns exist — all columns are ETL-computed by SP_CEPDailyAudit from unresolved staging sources. The upstream bundle contains only sibling tables, not actual upstream sources.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **UpdateDate tier misclassification** (medium) — Tagged `[UNVERIFIED] (Tier 4 — inferred)` but the SP INSERT clearly shows `GETDATE()` as the 11th column. This is Tier 2, not Tier 4. The description text is accurate ("GETDATE() at SP execution time") but contradicts its own tier tag.

2. **No Phase Gate Checklist** (medium) — The wiki contains data claims (314 rows, date range, max date) but provides no P2/P3 attestation that live data was actually queried. This undercuts confidence in the specifics.

3. **LoginName column alias discrepancy** (low) — The SP inserts `PreviousAppLoginName AS AppLoginName` (which is actually the COALESCE result assigned to a variable named PreviousAppLoginName earlier). The wiki correctly describes the COALESCE behavior but the column naming in the SP is confusing — the wiki could note that the SP alias `AppLoginName` in the INSERT is actually the COALESCE result, not the raw AppLoginName field.

4. **Sentinel row pattern incomplete** (low) — Section 2.2 documents sentinel rows with NULL TypeOfChange, but the SP code for the CP table doesn't show an explicit sentinel-row INSERT (unlike the `#FromDateToDate` table which only creates a date reference). The sentinel pattern may be inherited from the DELETE+INSERT for `@Date` with no matching changes, but the wiki doesn't clarify this mechanism. Worth verifying.

5. **IsActive column not in this table** (info) — The wiki correctly excludes IsActive (which exists in Rules but not CP), confirming column coverage is accurate. No action needed.

### Regeneration Feedback

1. Re-tag `UpdateDate` as `(Tier 2 — SP_CEPDailyAudit)` — the source (`GETDATE()`) is explicitly visible in SP code, not inferred.
2. Add a Phase Gate Checklist section (or mark P2/P3 status in footer) to attest whether row count and date range come from live queries.
3. Clarify the sentinel row mechanism in Section 2.2 — does the SP explicitly insert a sentinel, or does the DELETE-only pattern for no-change dates produce zero rows?

### Weighted Score

```
weighted = 0.25×7 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×5 + 0.10×8
         = 1.75 + 1.40 + 2.00 + 1.35 + 0.50 + 0.80
         = 7.80
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_CP",
  "weighted_score": 7.80,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "UpdateDate",
      "problem": "Tagged [UNVERIFIED] (Tier 4 — inferred) but SP INSERT clearly shows GETDATE() as the 11th column. Should be Tier 2 — SP_CEPDailyAudit. Description text is correct but contradicts its own tier tag."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 8 / Footer",
      "problem": "No Phase Gate Checklist section. Data claims (314 rows, date range Dec 2023 – 2026-03-09) are present but P2/P3 attestation is missing, so live-data provenance is unverifiable."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.2 (Sentinel Row Pattern)",
      "problem": "Wiki documents sentinel rows with NULL TypeOfChange but the SP code for the CP INSERT does not show an explicit sentinel-row INSERT path. The DELETE for @Date with no matching #CPChangesFinal rows would produce zero rows, not a sentinel. Verify whether sentinel pattern actually applies to this table."
    },
    {
      "severity": "low",
      "column_or_section": "LoginName",
      "problem": "SP inserts PreviousAppLoginName AS AppLoginName where PreviousAppLoginName is already the COALESCE result. Wiki correctly describes COALESCE behavior but could note the SP alias indirection for traceability."
    },
    {
      "severity": "info",
      "column_or_section": "Footer",
      "problem": "Footer tier count says '0 T1, 10 T2, 0 T3, 1 T4' — UpdateDate fix would make it '0 T1, 11 T2, 0 T3, 0 T4'."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag UpdateDate as (Tier 2 — SP_CEPDailyAudit) — GETDATE() is visible in SP code. (2) Add Phase Gate Checklist or P2/P3 attestation in footer. (3) Verify sentinel row pattern — SP code shows DELETE+INSERT with no explicit sentinel INSERT for CP table; if no changes occur, zero rows may be written rather than a sentinel row. Clarify or remove Section 2.2 if sentinel pattern does not apply.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
