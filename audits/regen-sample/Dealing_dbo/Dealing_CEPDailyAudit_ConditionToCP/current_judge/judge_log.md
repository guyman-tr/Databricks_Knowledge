## Judge Review — `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP`

### Dimension 1 — Tier Accuracy: **7/10**

Sampled 5 columns against SP code (`SP_CEPDailyAudit`, lines around the `--condition to cp` INSERT block):

| Column | SP Source | Expected Tier | Wiki Tier | Match? |
|--------|-----------|---------------|-----------|--------|
| Date | `@Date` parameter | Tier 2 | Tier 2 | YES |
| RuleID | `#Dim_CPtoRule` (derived) | Tier 2 | Tier 2 | YES |
| CP_Name | `#CPLog` via `#ConditionToCP_Log` | Tier 2 | Tier 2 | YES |
| TypeOfChange | Literal string in SP | Tier 2 | Tier 2 | YES |
| UpdateDate | `GETDATE()` — clearly visible in SP INSERT | **Tier 2** | **Tier 4** | **NO** |

**UpdateDate** is explicitly `GETDATE()` in the SP's INSERT statement — the last column in the SELECT. This is not "inferred from name"; it is directly verifiable from SP code. Tagging it Tier 4 is a conservative error. 1 mismatch → base score 7. No paraphrasing failures (0 Tier 1 columns).

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

The wiki claims **0 Tier 1 columns**, which is correct. All 11 columns are SP-derived or SP-computed. The actual upstream sources (staging tables like `External_Etoro_CEP_ConditionToCompoundProperty`) are unresolved — no wikis exist for them. The 6 upstream wikis in the bundle are **sibling audit tables**, not column-level sources for this table. No Tier 1 inheritance is possible or expected.

### T1 Fidelity Table

*No Tier 1 columns — table empty.*

### Dimension 3 — Completeness: **10/10**

| Check | Status |
|-------|--------|
| All 8 sections present | YES |
| Element count = DDL column count (11 = 11) | YES |
| Every element row has 5 cells | YES |
| Every description ends with tier tag | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count (~1,219) and date range (2023-12-12 – 2026-03-09) | YES |
| TypeOfChange (2 values) listed inline in element description | YES |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

10/10 → **10**.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names the domain (CEP condition-to-CP membership changes), defines row grain (one condition add/remove per CP per rule context per date), includes the CEP hierarchy diagram, explains fan-out from multi-rule CPs, names the ETL SP, states DELETE+INSERT pattern, gives row count and date range, and explains why the table matters for governance. A new analyst would know exactly when to query this table.

### Dimension 5 — Data Evidence: **5/10**

Row count (~1,219) and date range are present and labeled "(sampled)," suggesting live data access. TypeOfChange exact values are documented. However, there is **no explicit Phase Gate Checklist** with P2/P3 checkboxes anywhere in the wiki. Without confirmed P2+P3, data claims cannot be fully trusted. The specific numbers feel grounded but lack formal attestation.

### Dimension 6 — Shape Fidelity: **7/10**

Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown — all present. Minor deviations: no Phase Gate Checklist section, no explicit "phases-completed" list in the footer. Otherwise structurally sound.

### Weighted Total

```
weighted = 0.25×7 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×5 + 0.10×7
         = 1.75  + 1.40  + 2.00   + 1.35  + 0.50  + 0.70
         = 7.70
```

**Verdict: PASS**

### Top 5 Issues

1. **`UpdateDate` (high)** — Tagged Tier 4 (inferred) but SP code line `GETDATE()` in the INSERT clearly confirms it. Should be Tier 2.
2. **Missing Phase Gate Checklist (medium)** — No P2/P3 attestation section. Data claims (row count, date range) appear but lack formal phase completion evidence.
3. **No phases-completed in footer (low)** — Footer omits the `Phases: P1 [x] P2 [x] P3 [x]` format expected by the golden shape.
4. **LoginName SP alias (low)** — The SP inserts `PreviousAppLoginName AS AppLoginName` (which is actually the `COALESCE` result aliased). The wiki's description is accurate about the COALESCE but could note the alias rename more precisely.
5. **Relationship section missing `Dealing_CEPDailyAudit_ConditionToCP` ↔ `Dealing_CEPDailyAudit_Rules` (low)** — Rules is a sibling reachable via `RuleID`; only indirect references via CPToRule are listed.

### Regeneration Feedback

1. Re-tag `UpdateDate` as `(Tier 2 — SP_CEPDailyAudit)` — remove `[UNVERIFIED]`. The SP INSERT explicitly uses `GETDATE()` as the 11th column.
2. Add a Phase Gate Checklist section with P1/P2/P3 status indicators.
3. Add a `Phases: ...` entry to the footer line.
4. Consider adding `Dealing_CEPDailyAudit_Rules` to Section 6 Relationships (joinable on `RuleID + Date`).

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_ConditionToCP",
  "weighted_score": 7.70,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "UpdateDate",
      "problem": "Tagged Tier 4 (inferred) but SP_CEPDailyAudit INSERT statement clearly uses GETDATE() as the 11th column. This is verifiable from SP code and should be Tier 2."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 8 / Footer",
      "problem": "No Phase Gate Checklist (P1/P2/P3) section present. Data claims (row count ~1,219, date range 2023-12-12 to 2026-03-09) appear without formal phase completion attestation."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer omits phases-completed list (e.g. 'Phases: P1 [x] P2 [x] P3 [x]') expected by the golden reference shape."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6 — Relationships",
      "problem": "Missing direct relationship entry for Dealing_CEPDailyAudit_Rules, which is joinable on RuleID + Date and is a sibling audit table in the same SP."
    },
    {
      "severity": "low",
      "column_or_section": "LoginName",
      "problem": "SP inserts PreviousAppLoginName (which is the COALESCE result) aliased as AppLoginName. Wiki description is functionally correct but could note the SP alias chain more precisely."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag UpdateDate as (Tier 2 — SP_CEPDailyAudit) and remove [UNVERIFIED] — GETDATE() is explicit in the SP INSERT. (2) Add a Phase Gate Checklist section with P1/P2/P3 status. (3) Add phases-completed entry to the footer. (4) Add Dealing_CEPDailyAudit_Rules to Section 6 Relationships (joinable on RuleID + Date).",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
