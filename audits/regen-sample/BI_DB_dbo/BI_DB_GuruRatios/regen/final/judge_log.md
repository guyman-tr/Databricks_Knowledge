## Judge Review: BI_DB_dbo.BI_DB_GuruRatios

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 9/10**
All 4 columns checked (table only has 4). RealCID, UserName = Tier 1; Ratio, UpdateDate = Tier 2. All tiers are defensible. One concern: RealCID is attributed to `Customer.CustomerStatic` but the immediate ETL source is `etoroGeneral_History_GuruCopiers.ParentCID`. The value IS a CID and the description correctly characterizes it, but the source attribution in the tier tag could more precisely say the copier table. No paraphrasing failures — upstream text is preserved verbatim with additive context only.

**Dimension 2 — Upstream Fidelity: 9/10**
Both Tier 1 columns (RealCID, UserName) preserve the upstream Dim_Customer description character-for-character. Each appends a context sentence ("In this table, identifies the Popular Investor..." and "Passthrough from Dim_Customer."). These are additions, not rewording — no vendor names, NULL semantics, or FK targets were dropped. Two MINOR diffs, no NO matches.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 4/4 elements match DDL. Every element row has 5 cells with tier tags. Property table has all required fields. ETL pipeline diagram uses real SP names. Footer has tier breakdown. Row count stated in Section 1 and summary. No dictionary columns to enumerate. Review-needed sidecar has no `## 4. Elements` section.

**Dimension 4 — Business Meaning: 10/10**
Section 1 is excellent — names the domain (copy-trading amplification ratios), row grain (one PI), ETL SPs by name, refresh pattern (TRUNCATE + repopulate, currently disabled), row count (50), and the 10-day lag. The quoted SP comment adds authoritative context. A new analyst would immediately know what this table is and when to use it.

**Dimension 5 — Data Evidence: 7/10**
Row count (50) is stated. Last UpdateDate (2024-06-06) is cited. The disabled-SP observation is grounded in the `-- Disabled for investigation` comment from the source code. However, there is no formal Phase Gate Checklist section with `[x]` checkboxes — the footer says "Phases: 1-11 (excl. 10 Jira)" but doesn't show P2/P3 explicitly. No NULL-rate distribution analysis (acceptable for a 4-column, 50-row table).

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1-8, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases list. Minor: no explicit Phase Gate Checklist subsection with checkboxes. Otherwise matches the golden reference shape well.

---

### T1 Fidelity Table

| Column | Upstream Quote (Dim_Customer) | Wiki Quote | Match | Loss |
|--------|-------------------------------|------------|-------|------|
| RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. In this table, identifies the Popular Investor whose copier-tree ratio is computed." | MINOR | Added context sentence; no upstream text lost |
| UserName | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer." | MINOR | Added provenance note; no upstream text lost |

---

### Top Issues

1. **(Low) RealCID source attribution** — Tagged `(Tier 1 — Customer.CustomerStatic)` but the ETL pulls `ParentCID` from `etoroGeneral_History_GuruCopiers`, not from Customer.CustomerStatic directly. The value is semantically correct (it IS a CID) and the description is correct, but the tier source tag is one hop removed from the actual ETL source.

2. **(Low) No Phase Gate Checklist** — The footer lists phases but there is no explicit checklist subsection with `[x]` / `[ ]` checkboxes for P2 (row count verification) and P3 (distribution analysis).

3. **(Info) Additive text on T1 columns** — Both T1 descriptions append context beyond the upstream verbatim text. This is additions, not paraphrasing, so no semantic loss occurs, but strict verbatim compliance would omit these.

---

### Weighted Total

```
weighted = 0.25*9 + 0.20*9 + 0.20*10 + 0.15*10 + 0.10*7 + 0.10*9
         = 2.25 + 1.80 + 2.00 + 1.50 + 0.70 + 0.90
         = 9.15
```

**Verdict: PASS**

This is a strong wiki for a small utility table. The writer correctly traced the recursive SP logic, quoted the SP author's comment, flagged the disabled state, and preserved upstream descriptions with only minor additive modifications. The business meaning section is particularly well done — an analyst reading it for the first time would immediately understand the table's purpose, limitations, and staleness.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_GuruRatios",
  "weighted_score": 9.15,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 9,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "RealCID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. In this table, identifies the Popular Investor whose copier-tree ratio is computed.",
      "match": "MINOR",
      "loss": "Added context sentence about PI identification; no upstream text removed"
    },
    {
      "column": "UserName",
      "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).",
      "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Added provenance note 'Passthrough from Dim_Customer'; no upstream text removed"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "RealCID",
      "problem": "Tier source attributed to Customer.CustomerStatic but ETL pulls ParentCID from etoroGeneral_History_GuruCopiers. Semantically correct (value IS a CID) but source tag is one hop removed from actual ETL source."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Section 4",
      "problem": "No explicit Phase Gate Checklist subsection with [x]/[ ] checkboxes for P2 (row count verification) and P3 (distribution analysis). Footer lists phases but lacks formal checklist."
    },
    {
      "severity": "low",
      "column_or_section": "RealCID, UserName",
      "problem": "Both T1 descriptions append context sentences beyond the upstream verbatim text. Additions, not paraphrasing — no semantic loss — but strict verbatim compliance would omit these."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
