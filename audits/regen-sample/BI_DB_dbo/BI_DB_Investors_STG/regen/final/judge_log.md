## Judge Review: BI_DB_dbo.BI_DB_Investors_STG

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (AccountManagerID, CountryID, AssetType, CID, RegulationID). All tier assignments are correct. The three passthrough columns from Fact_SnapshotCustomer (AccountManagerID, CountryID, RegulationID) are correctly tagged Tier 1. CID (multi-source per stream) and AssetType (CASE expression) are correctly Tier 2. No mismatches.

**Dimension 2 — Upstream Fidelity: 9/10**
All three Tier 1 columns have near-verbatim descriptions from the Fact_SnapshotCustomer wiki. One trivial formatting diff: RegulationID dropped the internal cross-reference "See §2.4." — no semantic loss. No vendor names dropped, no NULL semantics removed, no FK targets omitted.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 13/13 elements match DDL. All element rows have 5 cells with tier tags. Property table complete. Section 5.2 has detailed ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count (~9.5M) with stream breakdown. SourceTable/ActionType/AssetType/InstrumentType all list their domain values inline. Review-needed sidecar does not contain Section 4.

**Dimension 4 — Business Meaning: 10/10**
Section 1 is exemplary: names the domain (investor activity reporting), row grain (per CID per activity dimension), ETL SP (SP_InvestorReport), refresh pattern (daily truncate-and-reload), all three source streams with specific source tables, and actual row counts with stream percentage breakdowns (Balance 61.9%, Manual 34.8%, Copy 3.4%).

**Dimension 5 — Data Evidence: 7/10**
Strong live-data signals: exact row count (~9.5M), precise stream breakdown (5,875,751 / 3,299,576 / 319,121), 161 NULL AUA rows identified. No explicit Phase Gate Checklist with P2/P3 checkboxes, but the specificity of the numbers strongly suggests real queries were run. Footer says "Phases: 12/14".

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1-8, tier legend in Section 4, three real SQL samples in Section 7, footer with quality score and tier breakdown. Minor deviation: tier legend only lists Tier 1 and Tier 2 (acceptable since no other tiers used). Footer format close to golden reference.

### T1 Fidelity Table

| Column | Upstream Quote (FSC wiki) | Wiki Quote | Match | Loss |
|--------|--------------------------|------------|-------|------|
| AccountManagerID | "Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager." | "Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager." | YES | — |
| CountryID | "Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded)." | "Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded)." | YES | — |
| RegulationID | "Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation." | "Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. FK to Dim_Regulation." | MINOR | Dropped internal cross-reference "See §2.4." — no semantic loss |

### Top 5 Issues

1. **Severity: low | RegulationID description** — Dropped "See §2.4." from the upstream Fact_SnapshotCustomer description. Trivial formatting-only loss; the §2.4 reference was to the FSC wiki's own section, not meaningful in the STG context.

2. **Severity: low | No explicit Phase Gate Checklist** — Footer says "Phases: 12/14" but there is no P2/P3 checkbox section. Data claims appear genuine based on specificity but cannot be formally verified from the wiki alone.

3. **Severity: low | CID source simplification** — Element #4 says "Manual stream: Fact_CustomerAction.RealCID" but in the SP, the Manual stream CID can also come from BI_DB_PositionPnL.CID via the FULL OUTER JOIN (`COALESCE(a.CID, nmi.CID)`). This is a minor simplification, not an error.

4. **Severity: info | Section 8 empty** — Atlassian sources skipped (regen harness mode). Expected for regen runs but worth noting.

5. **Severity: info | BI_DB_Investors_Unclustered downstream wiki notes AccountManagerID FK target as Dim_AccountManager** — The STG wiki correctly references Dim_Manager. The inconsistency is in the downstream wiki, not this one, but worth flagging for pipeline coherence.

### Regeneration Feedback

No regeneration needed — wiki passes with a strong score. If a polish pass is desired:
1. Add "See §2.4 of FSC wiki" or retain the upstream cross-reference in RegulationID for full verbatim compliance.
2. Add an explicit Phase Gate Checklist section with P2/P3 status.
3. Refine CID description to mention BI_DB_PositionPnL.CID as an alternative source in the Manual stream via FULL OUTER JOIN.

---

**Weighted Score: 9.40**

```
0.25×10 + 0.20×9 + 0.20×10 + 0.15×10 + 0.10×7 + 0.10×9
= 2.50 + 1.80 + 2.00 + 1.50 + 0.70 + 0.90 = 9.40
```

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Investors_STG",
  "weighted_score": 9.40,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "AccountManagerID",
      "upstream_quote": "Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager.",
      "wiki_quote": "Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CountryID",
      "upstream_quote": "Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded).",
      "wiki_quote": "Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "RegulationID",
      "upstream_quote": "Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation.",
      "wiki_quote": "Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. FK to Dim_Regulation.",
      "match": "MINOR",
      "loss": "Dropped internal cross-reference 'See §2.4.' — no semantic loss, reference was to FSC wiki's own section"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "RegulationID",
      "problem": "Dropped 'See §2.4.' from upstream Fact_SnapshotCustomer description. Trivial formatting-only loss; the cross-reference was to FSC wiki's own section and is not meaningful in STG context."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No explicit Phase Gate Checklist with P2/P3 checkboxes. Footer says 'Phases: 12/14' but phases completed are not enumerated. Data claims appear genuine based on specificity."
    },
    {
      "severity": "low",
      "column_or_section": "CID",
      "problem": "Element description says 'Manual stream: Fact_CustomerAction.RealCID' but SP code shows CID can also come from BI_DB_PositionPnL.CID via FULL OUTER JOIN COALESCE. Minor simplification."
    },
    {
      "severity": "info",
      "column_or_section": "Section 8",
      "problem": "Atlassian sources skipped (regen harness mode). Expected but worth noting for completeness."
    },
    {
      "severity": "info",
      "column_or_section": "Section 6.1",
      "problem": "Downstream BI_DB_Investors_Unclustered wiki references 'Dim_AccountManager' as FK target for AccountManagerID, while this STG wiki correctly uses Dim_Manager. Cross-wiki inconsistency in the pipeline."
    }
  ],
  "regeneration_feedback": "No regeneration needed. If polishing: (1) Retain 'See §2.4' cross-reference in RegulationID for full verbatim compliance. (2) Add explicit Phase Gate Checklist section. (3) Refine CID description to mention BI_DB_PositionPnL.CID as alternative source in Manual stream via FULL OUTER JOIN.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
