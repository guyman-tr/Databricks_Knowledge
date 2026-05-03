Let me verify the upstream wiki the writer claims to have found independently.
Now I have everything I need. Let me complete the review.

---

## Review Summary — EXW_Wallet.AmlProviderUsers

### Process Note: Upstream Bundle Gap

The harness-provided upstream bundle declared **"NO UPSTREAM WIKI was resolvable"**, yet the upstream wiki exists at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.AmlProviderUsers.md`. The writer independently discovered it (acknowledged in the review-needed sidecar). I verified the file — it is genuine and substantive. I will evaluate Tier 1 fidelity against this actual upstream wiki, not penalize the writer for the harness routing gap.

---

### Dimension 1 — Tier Accuracy: **10/10**

Five columns sampled: Id (Tier 1 ✓), AmlProviderId (Tier 1 ✓), etr_y (Tier 3 ✓), partition_date (Tier 3 ✓), ProviderUserId (Tier 1 ✓). Zero mismatches. All tier assignments are correct: 5 production passthroughs tagged Tier 1, 5 pipeline-infrastructure columns tagged Tier 3. No paraphrasing failures that lose information.

### Dimension 2 — Upstream Fidelity: **9/10**

Four of five Tier 1 columns are verbatim matches. AmlProviderId has one minor deviation: the upstream lists `1=Chainalysis, 4=ChainalysisCDN` while the wiki adds `2=BlackList, 3=Unsupported` from live data observation. This is an enrichment (no information lost), but not verbatim. The upstream glossary link `See [AML Provider](../../_glossary.md#aml-provider)` was dropped, which is appropriate since it references a production-side glossary path.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| Id | "Auto-incrementing surrogate primary key." | "Auto-incrementing surrogate primary key." | YES | — |
| AmlProviderId | "The AML screening provider this registration is for: 1=Chainalysis, 4=ChainalysisCDN. See [AML Provider](../../_glossary.md#aml-provider). FK to Dictionary.AmlProviders." | "The AML screening provider this registration is for: 1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN. FK to Dictionary.AmlProviders." | MINOR | Added 2=BlackList, 3=Unsupported from live data; dropped glossary link (production-context-specific) |
| Gcid | "Global Customer ID. The eToro customer this AML provider registration belongs to. Part of unique constraint with AmlProviderId." | "Global Customer ID. The eToro customer this AML provider registration belongs to. Part of unique constraint with AmlProviderId." | YES | — |
| ProviderUserId | "The customer's user identifier on the AML provider's system. Base64-encoded representation of the Gcid (e.g., Gcid 46870594 -> \"NDY4NzA1OTQ=\"). Used in all API calls to the provider." | "The customer's user identifier on the AML provider's system. Base64-encoded representation of the Gcid (e.g., Gcid 46870594 -> \"NDY4NzA1OTQ=\"). Used in all API calls to the provider." | YES | — |
| Occurred | "Timestamp when this customer was first registered with the AML provider." | "Timestamp when this customer was first registered with the AML provider." | YES | — |

### Dimension 3 — Completeness: **10/10**

All 10 checks pass:
- [x] All 8 sections present
- [x] Element count matches DDL (10/10)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (207,352) and date range (2020-05-27 to 2026-04-26)
- [x] AmlProviderId (≤15 values) lists inline key=value pairs
- [x] `.review-needed.md` does not contain `## 4. Elements`

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable: names the domain (AML screening), row grain (one customer-provider registration), production source, ETL pattern (Generic Pipeline Append), refresh (daily), row count, date range, and provider distribution with percentages. Explains downstream usage (SP_EXW_AMLProviderID → EXW_AMLProviderID). An analyst would immediately know what this table is for and when to use it.

### Dimension 5 — Data Evidence: **8/10**

Strong data evidence: row count (207,352), date range, provider distribution with exact counts and percentages, NULL patterns for etr_* and SynapseUpdateDate with specific affected row counts. Footer shows "Phases: 13/14". No explicit Phase Gate Checklist section in the wiki body, but the data claims are detailed and internally consistent enough to indicate live querying.

### Dimension 6 — Shape Fidelity: **9/10**

Numbered sections 1–8, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases-completed. Minor deviation: no standalone Phase Gate Checklist section (common in this wiki template). Otherwise matches the golden reference shape well.

---

### Top 5 Issues

1. **AmlProviderId description not verbatim** — Added `2=BlackList, 3=Unsupported` values not in upstream wiki. While this enriches the description, strict verbatim fidelity requires quoting the upstream as-is and noting the additional values separately. Severity: low.

2. **Harness upstream bundle gap** — The bundle declared no upstream wiki resolvable. The writer found one independently. The review-needed sidecar correctly flags this as a harness routing issue for EXW_Wallet → CryptoDBs/WalletDB path. Severity: low (process, not wiki quality).

3. **No explicit Phase Gate Checklist** — The footer references "Phases: 13/14" but there is no itemized checklist showing which phases were completed vs skipped. Severity: low.

4. **Gcid type narrowing not in Section 3.4 gotchas with urgency** — The int vs bigint risk is mentioned but could benefit from a specific threshold check (current max Gcid vs int max). Severity: low (already flagged in review-needed sidecar).

5. **No deduplication warning in Section 2.2** — The Append strategy with no uniqueness constraint could introduce duplicates. Mentioned in Section 3.4 gotchas but could be more prominent in the ETL logic section. Severity: low.

---

### Regeneration Feedback

No regeneration required — this wiki passes. Minor improvements for a future polish pass:
1. Quote AmlProviderId description verbatim from upstream, then add the additional provider values (2=BlackList, 3=Unsupported) as a separate data-observation note.
2. Add an explicit Phase Gate Checklist section itemizing completed vs skipped phases.

---

### Weighted Score Calculation

```
weighted = 0.25*10 + 0.20*9 + 0.20*10 + 0.15*9 + 0.10*8 + 0.10*9
         = 2.50 + 1.80 + 2.00 + 1.35 + 0.80 + 0.90
         = 9.35
```

**Verdict: PASS (9.35)**

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "AmlProviderUsers",
  "weighted_score": 9.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "Id",
      "upstream_quote": "Auto-incrementing surrogate primary key.",
      "wiki_quote": "Auto-incrementing surrogate primary key.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "AmlProviderId",
      "upstream_quote": "The AML screening provider this registration is for: 1=Chainalysis, 4=ChainalysisCDN. See [AML Provider](../../_glossary.md#aml-provider). FK to Dictionary.AmlProviders.",
      "wiki_quote": "The AML screening provider this registration is for: 1=Chainalysis, 2=BlackList, 3=Unsupported, 4=ChainalysisCDN. FK to Dictionary.AmlProviders.",
      "match": "MINOR",
      "loss": "Added 2=BlackList, 3=Unsupported from live data (enrichment, not loss); dropped production-context glossary link"
    },
    {
      "column": "Gcid",
      "upstream_quote": "Global Customer ID. The eToro customer this AML provider registration belongs to. Part of unique constraint with AmlProviderId.",
      "wiki_quote": "Global Customer ID. The eToro customer this AML provider registration belongs to. Part of unique constraint with AmlProviderId.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ProviderUserId",
      "upstream_quote": "The customer's user identifier on the AML provider's system. Base64-encoded representation of the Gcid (e.g., Gcid 46870594 -> \"NDY4NzA1OTQ=\"). Used in all API calls to the provider.",
      "wiki_quote": "The customer's user identifier on the AML provider's system. Base64-encoded representation of the Gcid (e.g., Gcid 46870594 -> \"NDY4NzA1OTQ=\"). Used in all API calls to the provider.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Occurred",
      "upstream_quote": "Timestamp when this customer was first registered with the AML provider.",
      "wiki_quote": "Timestamp when this customer was first registered with the AML provider.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "AmlProviderId",
      "problem": "Description adds 2=BlackList, 3=Unsupported values not present in upstream wiki (enrichment from live data). Upstream only lists 1=Chainalysis, 4=ChainalysisCDN. Strict verbatim fidelity requires quoting upstream as-is."
    },
    {
      "severity": "low",
      "column_or_section": "Upstream Bundle",
      "problem": "Harness bundle declared no upstream wiki resolvable, but Wallet.AmlProviderUsers wiki exists at knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/. Writer found it independently. Harness routing gap for EXW_Wallet → CryptoDBs/WalletDB path."
    },
    {
      "severity": "low",
      "column_or_section": "Phase Gate Checklist",
      "problem": "No explicit Phase Gate Checklist section itemizing completed vs skipped phases. Footer says 'Phases: 13/14' but individual phase status is not shown."
    },
    {
      "severity": "low",
      "column_or_section": "Gcid",
      "problem": "Type narrowing risk (production bigint vs Synapse int) mentioned in gotchas but no specific threshold check (current max Gcid vs int max 2,147,483,647) included in the wiki."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.2",
      "problem": "Append strategy with no uniqueness constraint could introduce duplicates. Mentioned in Section 3.4 gotchas but not in the ETL logic section where analysts look for data quality rules."
    }
  ],
  "regeneration_feedback": "No regeneration required. Minor polish: (1) Quote AmlProviderId verbatim from upstream, add extra provider values as a data-observation note. (2) Add explicit Phase Gate Checklist section.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 14 (unknown — 13/14 completed)"]
  }
}
</JUDGE_VERDICT>
