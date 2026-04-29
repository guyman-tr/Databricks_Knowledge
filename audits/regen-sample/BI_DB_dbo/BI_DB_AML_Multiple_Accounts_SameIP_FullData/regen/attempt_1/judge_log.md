# Judge Review — BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP_FullData

## Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
All 3 columns checked (table only has 3). CID correctly tagged Tier 1 — Customer.CustomerStatic, tracing through Dim_Customer.RealCID to the root origin. HashIP correctly tagged Tier 2 (CHECKSUM transformation). UpdateDate correctly tagged Tier 2 (GETDATE()). Zero mismatches.

**Dimension 2 — Upstream Fidelity: 10/10**
One Tier 1 column (CID). The upstream description from Dim_Customer.RealCID is preserved verbatim, with additional filter-context appended (not paraphrased). No semantic loss.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. DDL has 3 columns, wiki has 3 elements — exact match. Every element has 5 cells with tier tags. Property table complete. ETL pipeline diagram present with real SP names and step numbers. Footer has tier breakdown. Row count in Section 1. Review-needed sidecar does not contain `## 4. Elements`.

**Dimension 4 — Business Meaning: 9/10**
Excellent. Names domain (AML same-IP detection), row grain (per-customer detail), ETL SP (SP_AML_Multiple_Accounts), refresh pattern (daily TRUNCATE+INSERT), row count (1,102,688), and describes sibling tables. The ETL walkthrough with temp table progression is particularly useful. Missing only a formal date range (though a snapshot table doesn't have one — "as of 2025-03-13" is appropriate).

**Dimension 5 — Data Evidence: 8/10**
Row count (1,102,688), distinct HashIP count (353,336), average cluster size (~3.1), and UpdateDate staleness (2025-03-13) are all cited. Phase list includes P2+P3. No formal Phase Gate Checklist with `[x]` marks, but data claims appear grounded.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1-8, tier legend in Section 4, 3 real SQL samples in Section 7, footer with quality score and phases list. Minor: no explicit Phase Gate Checklist table. Otherwise matches the golden reference shape well.

## T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." (Dim_Customer.RealCID) | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer.RealCID. Only includes customers where IsValidCustomer=1, IsDepositor=1, and VerificationLevelID=3 whose registration IP is shared by at least one other qualifying customer." | YES | None — upstream text preserved verbatim, additional filter context appended |

## Top 5 Issues

1. **Severity: low | Section 1** — Data staleness (UpdateDate = 2025-03-13, over a year stale). The wiki correctly flags this in Gotchas and review-needed, but Section 1 could more prominently warn that the table may be abandoned.

2. **Severity: low | Section 3.3** — The JOIN advisory for `BI_DB_AML_Multiple_Accounts_SameIP` says "ON HashIP = IP (note: parent table stores raw IP, not hash)" — this join would not actually work since one side is a CHECKSUM int-as-string and the other is a raw IP string. The note acknowledges this but could be clearer that this is NOT a viable join pattern.

3. **Severity: low | Section 4** — No formal Phase Gate Checklist table with `[x]` checkboxes. The phases are listed in the footer but the structured checklist format is missing.

4. **Severity: low | Section 5.2** — The pipeline diagram shows `HashIP=CHECKSUM(ss.IP)` but the actual SP code in Step 8 sources from `#SameIP ss` which got IP from `Dim_Customer dc`. The diagram correctly shows this lineage chain — this is a cosmetic note only.

5. **Severity: low | Section 1** — The SP comment header says "14/10/2023" for device ID script changes but the create date is "2023-11-13". The wiki correctly cites the create date. No issue with the wiki itself.

## Regeneration Feedback

No regeneration needed. This is a clean, accurate wiki for a simple 3-column table. If iterating:
1. Add a formal Phase Gate Checklist table with `[x]` marks for P1-P3.
2. Strengthen the Section 3.3 warning about the SameIP parent table join — make it explicit that HashIP cannot be directly joined to the raw IP column.
3. Consider adding a more prominent "STALE DATA WARNING" banner given the >1 year gap.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AML_Multiple_Accounts_SameIP_FullData",
  "weighted_score": 9.55,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 10,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer.RealCID. Only includes customers where IsValidCustomer=1, IsDepositor=1, and VerificationLevelID=3 whose registration IP is shared by at least one other qualifying customer.",
      "match": "YES",
      "loss": "None — upstream text preserved verbatim, additional filter context appended"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Data staleness (UpdateDate = 2025-03-13, over a year stale) is noted in Gotchas and review-needed but could be more prominently flagged in Section 1 as the table may be abandoned."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.3",
      "problem": "JOIN advisory for BI_DB_AML_Multiple_Accounts_SameIP says 'ON HashIP = IP' but this join cannot work — one is CHECKSUM int-as-string, the other is raw IP string. The note acknowledges it but should say explicitly this is NOT a viable join."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4",
      "problem": "No formal Phase Gate Checklist table with [x] checkboxes. Phases listed in footer but structured checklist format missing."
    }
  ],
  "regeneration_feedback": "No regeneration needed. Minor improvements: (1) Add formal Phase Gate Checklist. (2) Strengthen Section 3.3 SameIP join warning. (3) Add prominent stale-data banner.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
