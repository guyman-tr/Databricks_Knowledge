## Judge Review: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
All 3 columns checked (entire table). NumOfClientsSameIP correctly tagged Tier 2 (COUNT DISTINCT aggregation). IP correctly tagged Tier 1 — Customer.CustomerStatic (passthrough through Dim_Customer, which documents it as Tier 1 from Customer.CustomerStatic). UpdateDate correctly tagged Tier 2 (GETDATE()). Zero mismatches, zero paraphrasing failures.

**Dimension 2 — Upstream Fidelity: 10/10**
One Tier 1 column (IP). Character-by-character comparison confirms verbatim match with the Dim_Customer upstream wiki.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count 3/3 matches DDL exactly. Every element row has 5 cells. Every description ends with tier tag. Property table has all required fields. Section 5.2 has a detailed ETL pipeline diagram with real SP names and step numbers. Footer has tier breakdown. Section 1 has row count (370,638) and data date. Review-needed sidecar does not contain a `## 4. Elements` section.

**Dimension 4 — Business Meaning: 10/10**
Section 1 is specific, concrete, and actionable. Names the domain (AML multi-account fraud detection via shared IP), specifies row grain (one IP address shared by 2+ verified depositing customers), names the ETL SP (SP_AML_Multiple_Accounts, Step 07/16), refresh pattern (daily TRUNCATE+INSERT), row count, distribution stats (66.1% have exactly 2 clients, max 374), filter criteria, and companion table relationship.

**Dimension 5 — Data Evidence: 9/10**
Row count (370,638), data date (2025-03-13), value distribution (66.1% at 2, max 374), range documented in element description. Footer indicates 11/14 phases completed; P2/P3 are not listed as skipped, and the data claims are consistent and specific. Minor deduction: no explicit Phase Gate Checklist section with P2/P3 checkboxes visible.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1-8, tier legend in Section 4, real SQL samples in Section 7 (3 queries), footer with quality score and phases-completed list. Minor: no explicit tier legend table with example tags in Section 4 header (the legend shows only 2 tiers which is correct for this table but slightly abbreviated).

### T1 Fidelity Table

| Column | Upstream Quote (Dim_Customer wiki) | Wiki Quote | Match | Loss |
|--------|-----------------------------------|------------|-------|------|
| IP | Registration IP address. (Tier 1 — Customer.CustomerStatic) | Registration IP address. (Tier 1 — Customer.CustomerStatic) | YES | — |

### Top 5 Issues

1. **Severity: low | Section 1** — UpdateDate is "2025-03-13" suggesting the table hasn't been refreshed in over a year. The review-needed sidecar correctly flags this, but the wiki Section 1 presents the 370,638 row count without noting it may be stale.

2. **Severity: low | Section 3.3** — The JOIN to BI_DB_AML_Multiple_Accounts_SameIP_FullData says "IP-based correlation" but the actual join mechanism is unclear since FullData stores CHECKSUM(IP) as HashIP, not raw IP. The Gotchas section does explain this, but the JOIN table could be more precise.

3. **Severity: low | Section 5** — Phase Gate Checklist is not shown as an explicit section. The footer mentions "Phases: 11/14" but doesn't enumerate which data-validation phases (P2/P3) were completed.

4. **Severity: low | Element IP** — The description is minimal ("Registration IP address") which is verbatim from upstream and correct, but the element description could note the GROUP BY key role and the varchar(15)→nvarchar(250) widening that the review-needed sidecar flags.

5. **Severity: low | Section 2.2** — Says "Step 16" for the TRUNCATE+INSERT which is correct, but the SP comment block labels it as a second "Step 14" (duplicate step numbering in the SP source). This is a source-code oddity, not a wiki error.

### Regeneration Feedback

No regeneration needed. This is a high-quality wiki for a simple 3-column table. If further polish were desired:
1. Add explicit Phase Gate Checklist showing P2/P3 completion status
2. Note the varchar(15)→nvarchar(250) type widening in the IP element description
3. Clarify the FullData JOIN mechanism in Section 3.3 (requires recomputing CHECKSUM or joining through Dim_Customer)

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AML_Multiple_Accounts_SameIP",
  "weighted_score": 9.8,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 10,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 9,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "IP",
      "upstream_quote": "Registration IP address. (Tier 1 — Customer.CustomerStatic)",
      "wiki_quote": "Registration IP address. (Tier 1 — Customer.CustomerStatic)",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "UpdateDate is 2025-03-13, suggesting over a year of staleness. Row count 370,638 may be outdated but is presented without staleness caveat in the main body."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.3 Common JOINs",
      "problem": "JOIN to FullData table described as 'IP-based correlation' but FullData uses CHECKSUM(IP) as HashIP — direct join is not possible without recomputing checksum or going through Dim_Customer."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No explicit Phase Gate Checklist section showing P2/P3 completion. Footer says 11/14 phases but doesn't enumerate data-validation phase status."
    },
    {
      "severity": "low",
      "column_or_section": "Element: IP",
      "problem": "Description is correct and verbatim but could note the varchar(15) to nvarchar(250) type widening flagged in the review-needed sidecar."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.2",
      "problem": "References 'Step 16' which is correct in the SP but the SP source has duplicate step numbering (two Step 14s, then Step 16/17). Minor source-code oddity, not a wiki error."
    }
  ],
  "regeneration_feedback": "No regeneration needed. Wiki scores 9.8 weighted. Optional polish: (1) Add explicit Phase Gate Checklist section. (2) Note varchar(15)->nvarchar(250) widening in IP element. (3) Clarify FullData JOIN mechanism in Section 3.3.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["NumOfClientsSameIP: range 2-374, 66.1% at value 2", "row count 370,638"],
    "skipped_phases": ["P7 — no views", "P10 — no Atlassian"]
  }
}
</JUDGE_VERDICT>
