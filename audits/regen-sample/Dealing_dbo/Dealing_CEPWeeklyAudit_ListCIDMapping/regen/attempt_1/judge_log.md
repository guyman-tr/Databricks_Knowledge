## Adversarial Review: Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping

### Dimension 1 — Tier Accuracy: 10/10

Sampled 5 columns: **NameListID**, **CID**, **TypeOfChange**, **ListName**, **UpdateDate**.

All upstream sources are unresolved `Dealing_staging` external tables with no wiki documentation. The SP code (`SP_W_CEPWeeklyAudit`) is the only traceable documentation source. Tier 2 is correct for all 8 SP-derived columns. `UpdateDate` as Tier 4 (`GETDATE()`) is correct. No mismatches. No paraphrasing failures possible since there are zero Tier 1 columns.

### Dimension 2 — Upstream Fidelity: 7/10 (neutral)

Zero Tier 1 columns exist. All upstream sources are `Dealing_staging.External_Etoro_*` tables — none have wiki documentation in the bundle. The sibling weekly audit tables (Rules, CP, Conditions, etc.) are **not** upstream column sources for this table; they are peer tables loaded by the same SP. Tier 2 attribution to SP logic is the correct ceiling.

**T1 Fidelity Table**: (empty — no Tier 1 columns)

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Dimension 3 — Completeness: 10/10

| Check | Result |
|-------|--------|
| All 8 sections present | YES |
| Element count matches DDL (9/9) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count (~1,057) and date range (2021-09-26 to 2026-04-25) | YES |
| Dictionary columns list values inline | YES — TypeOfChange values in element #6 |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

10/10 = score 10.

### Dimension 4 — Business Meaning: 10/10

Section 1 is excellent. It names the domain (CEP Named Lists, CID membership), defines row grain (per-CID membership change per audit week), identifies the ETL SP, states refresh pattern (weekly Sunday), gives row count (~1,057), date range, placeholder row semantics (113/1,057 = ~11%), LoginName sparsity (~92% NULL), composition breakdown (864 adds, 80 deletes), top lists by volume (CopyFunds, EU Real Stocks HBC, Portfolio Offerings), and historical context relative to the daily audit family. An analyst reading this would immediately know what this table is, when to use it, and what pitfalls to watch for.

### Dimension 5 — Data Evidence: 7/10

Strong live-data signals: exact row count (~1,057), date range, composition breakdown (864/80/113), 30 distinct lists, 629 distinct CIDs, specific list names with NameListIDs and event counts. LoginName ~92% NULL rate is specific. However, no explicit Phase Gate Checklist section exists — the footer says "Phases: 12/14" but doesn't enumerate which phases were completed or skipped. The data specificity is convincing but the phase documentation gap costs points.

### Dimension 6 — Shape Fidelity: 8/10

All 8 numbered sections present. Tier legend in Section 4. Real SQL in Section 7 (3 queries with proper table/column references). Footer has quality score, tier counts, and phase summary. Minor deviations: no explicit Phase Gate Checklist section, tier legend omits Tier 1/3 (acceptable since none exist). Overall shape is clean and close to golden reference.

### Top 5 Issues

1. **(low)** **Footer/Phase Gate** — "Phases: 12/14" stated but no Phase Gate Checklist section enumerates which 2 phases were skipped, making it impossible to verify whether P2/P3 (live data phases) were actually completed.

2. **(low)** **Section 6.2 "Referenced By"** — Lists 6 sibling tables as "Referenced By" but these are peer tables loaded by the same SP, not objects that reference this table via FK or JOIN in their own ETL. The relationship is "sibling in the same audit family," which is correctly labeled but could mislead analysts into thinking there are declared foreign key relationships.

3. **(low)** **NameListID rename not flagged** — Element #3 documents `NameListID` but the source column is `NamedListID` (with a 'd'). The lineage table catches this ("Passthrough (positional rename)") but the element description doesn't mention the rename, which could confuse someone reading the staging source.

4. **(low)** **ListName source precision** — Element #4 says "resolved via JOIN to `#NameLists_Log` on `NamedListID`" — this is a temp table reference. The actual source is `External_Etoro_CEP_NamedLists.Name` / `External_Etoro_History_NamedLists.Name`. The temp table is an implementation detail of the SP. Minor clarity issue.

5. **(info)** **No mention of the NameLists JOIN bug contrast** — The review-needed sidecar correctly notes that this table does NOT share the suspected `fdtd.ToDate = fdtd.ToDate` JOIN defect from the NameLists path (line ~878). The wiki's Section 3.4 Gotchas could have mentioned this for completeness, though the review-needed file does cover it.

### Regeneration Feedback

No regeneration needed — PASS. If refining:

1. Add an explicit Phase Gate Checklist section enumerating completed/skipped phases.
2. In element #3 (NameListID), note the source column rename from `NamedListID`.
3. Clarify Section 6.2 that sibling relationships are "same SP family" rather than FK/JOIN references.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPWeeklyAudit_ListCIDMapping",
  "weighted_score": 8.9,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "Footer states 'Phases: 12/14' but no Phase Gate Checklist section enumerates which phases were completed or skipped. Cannot verify P2/P3 completion."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Six sibling tables listed as 'Referenced By' are peer tables loaded by the same SP, not objects that reference this table via FK or JOIN in their own ETL. Relationship type is correctly labeled as 'Sibling' but placement under 'Referenced By' could mislead."
    },
    {
      "severity": "low",
      "column_or_section": "NameListID",
      "problem": "Source column is NamedListID (with 'd') but element description does not flag the positional rename. Lineage table catches it but element description omits it."
    },
    {
      "severity": "low",
      "column_or_section": "ListName",
      "problem": "Element description references temp table #NameLists_Log rather than the actual production source (External_Etoro_CEP_NamedLists.Name / External_Etoro_History_NamedLists.Name)."
    },
    {
      "severity": "info",
      "column_or_section": "Section 3.4 Gotchas",
      "problem": "Does not mention that this table's INSERT uses the correct JOIN pattern (unlike the NameLists path's suspected fdtd.ToDate = fdtd.ToDate bug). Review-needed sidecar covers this but the wiki's Gotchas section does not."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
