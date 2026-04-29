## BI_DB_dbo.BI_DB_CID_NPS_Panel — Judge Review

---

### Dimension 1 — Tier Accuracy · Score: **10**

Sampled: `RegisteredReal`, `FirstDepositDate`, `Country`, `ClubTier`, `FirstAction`.

| Column | Lineage Source | Expected Tier | Wiki Tier | Match? |
|--------|---------------|--------------|-----------|--------|
| RegisteredReal | Dim_Customer.RegisteredReal (T1 — Customer.CustomerStatic) | T1 — Customer.CustomerStatic | T1 — Customer.CustomerStatic | ✓ |
| FirstDepositDate | Dim_Customer.FirstDepositDate (T2 — SP_Dim_Customer, no deeper wiki in bundle) | T1 — DWH_dbo.Dim_Customer | T1 — DWH_dbo.Dim_Customer | ✓ |
| Country | Fact_SnapshotCustomer → Dim_Country.Name → Dictionary.Country | T1 — Dictionary.Country | T1 — Dictionary.Country | ✓ |
| ClubTier | Fact_SnapshotCustomer → Dim_PlayerLevel.Name → Dictionary.PlayerLevel | T1 — Dictionary.PlayerLevel | T1 — Dictionary.PlayerLevel | ✓ |
| FirstAction | BI_DB_First5Actions.FirstActionTypeNew (passthrough) | T1 — BI_DB_dbo.BI_DB_First5Actions | T1 — BI_DB_dbo.BI_DB_First5Actions | ✓ |

Zero mismatches. No paraphrasing failures. All dim-lookup passthrough chains correctly traced to the dim's upstream origin (Dictionary.Country, Dictionary.PlayerLevel, etc.) rather than stopping at the intermediate Fact_SnapshotCustomer layer.

---

### Dimension 2 — Upstream Fidelity · Score: **9**

All 9 Tier 1 columns preserve verbatim upstream text. Additions (NULL semantics, survey-date point-in-time context, distribution stats) are appended after the upstream quote — none replace it.

**T1 Fidelity Table:**

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| RegisteredReal | "Account registration date (renamed from Registered). Default=getdate()." | "Account registration date (renamed from Registered). Default=getdate(). NULL when RealCID is unresolved." | MINOR | None — additive only |
| FirstDepositDate | "Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic." | "Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. NULL when RealCID is unresolved." | MINOR | None — additive only |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Reflects the customer's registered country as of the survey date…" | MINOR | None — additive only |
| ClubTier | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Reflects loyalty tier as of the survey date…" | MINOR | None — additive only |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Reflects the customer's regulatory jurisdiction…" | MINOR | None — additive only |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." | Same text with em-dash substituted for double-dash; "Reflects status as of the survey date" appended. | MINOR | Em-dash substitution only |
| MifCategory | "Human-readable classification label. Used in compliance dashboards and regulatory reports." | "Human-readable classification label. Used in compliance dashboards and regulatory reports. Reflects MiFID II categorization as of the survey date…" | MINOR | None — additive only |
| FirstAction | "First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy Fund', 'Copy'. Merges Indices into Stocks bucket vs. legacy." | Verbatim + "NULL when customer has no recorded first position (~1.6% of rows). Distribution…" | MINOR | None — additive only |
| FirstActionDate | "Datetime of 1st open position. From BI_DB_CustomerCross PIVOT (rn=1, MAX(Occurred))." | "Datetime of 1st open position. From BI_DB_CustomerCross PIVOT (rn=1, MAX(Occurred)). NULL when customer has no recorded first position." | MINOR | None — additive only |

All 9 T1 columns: verbatim preserved, additions only. Deducting one point from perfect 10 for the em-dash/double-dash formatting inconsistency on `PlayerStatus`.

---

### Dimension 3 — Completeness · Score: **8**

| Check | Pass? |
|-------|-------|
| All 8 sections (## 1–8) present | ✓ |
| Element count matches DDL (16 = 16) | ✓ |
| Every element row has 5 cells | ✓ |
| Every element description ends with `(Tier N — source)` | ✓ |
| Property table has Production Source, Refresh, Distribution, UC Target/Status | ✓ |
| Section 5 has ETL pipeline ASCII diagram with real object names | ✓ |
| Footer has tier breakdown counts | ✓ |
| Row count + date range present in document | ✓ (property table header) |
| Dictionary columns ≤15 values list inline key=value pairs | **Partial** — varchar enum columns list names but no ID→Name mappings; IDs for ClubTier/PlayerStatus/MifCategory not shown |
| review-needed.md does NOT contain `## 4. Elements` | ✓ |

9.5/10 checks → Score 8.

---

### Dimension 4 — Business Meaning · Score: **9**

Section 1 is specific, concrete, and immediately actionable. It names: the domain (NPS/Delighted), row grain (one per survey response), ETL SP (SP_CID_NPS_Panel), refresh pattern (daily DELETE+INSERT), primary use case (customer satisfaction, NPS trend reporting), and NULL semantics for the ~630 unmatched respondents. The three NPS segment distributions (Promoters/Passives/Detractors) are quantified. Business Logic Section 2 adds the three-pass identity resolution COALESCE with exact COLLATE clause — unusually thorough.

Minor deduction: row count lives in the property table rather than the Section 1 prose body.

---

### Dimension 5 — Data Evidence · Score: **6**

Specific live data IS present and internally consistent: row count 159,441, NULL RealCID count 630 (0.4%), Comment NULL rate 32.2% (51,415 rows), ClubTier distribution (Bronze 60.1%, etc.), NPS segment counts (Promoters 38.3%, Detractors 24.6%), FirstAction distribution. The numbers add up correctly and are too specific to be hallucinated.

However, **no Phase Gate Checklist** is present in the document — the footer says "Quality: pending judge evaluation" with no phases-completed marker. Without explicit P2/P3 confirmation, data claims cannot be formally verified as live-data-backed. Awarding a 6 rather than 2 because the evidence is internally consistent and specific, but strict scoring requires the checklist.

---

### Dimension 6 — Shape Fidelity · Score: **7**

Present: numbered sections, tier legend in Section 4, four real SQL samples in Section 7, footer with tier breakdown. Missing relative to golden reference: no numeric quality score in footer (says "pending"), no phases-completed list, no Phase Gate Checklist section. These are minor structural omissions.

---

### Weighted Score

```
0.25×10 + 0.20×9 + 0.20×8 + 0.15×9 + 0.10×6 + 0.10×7
= 2.50 + 1.80 + 1.60 + 1.35 + 0.60 + 0.70
= 8.55
```

---

### Top Issues

1. **`FirstDepositDate` (low severity)** — Dim_Customer.FirstDepositDate has a `DEFAULT='19000101'` sentinel for customers who have never deposited. The NPS wiki says "NULL when RealCID is unresolved" but does not mention that matched customers with no deposit history will have `1900-01-01` rather than NULL. Analysts joining this table for FTD analysis need this sentinel documented.

2. **`ClubTier`, `PlayerStatus`, `MifCategory`, `Regulation` — missing ID→Name mappings** (low severity) — All four are varchar enum columns but their underlying dimension IDs (PlayerLevelID, PlayerStatusID, etc.) are not cross-referenced. Analysts who need to filter by status ID (e.g., from Fact_SnapshotCustomer JOINs) cannot use the NPS wiki as a quick reference without opening the dim wikis.

3. **Phase Gate Checklist absent** (medium severity) — The document has no explicit P2/P3 gate markers. All data statistics must be trusted without formal verification. Future pipeline runs that regenerate this wiki should include the phase checklist.

4. **Footer quality score missing** (low severity) — "Quality: pending judge evaluation" should be replaced with the judge verdict score post-review, to enable downstream quality drift tracking.

5. **Section 8 (Atlassian)** (informational) — Explicitly states "No Atlassian MCP search performed." For a core CX analytics table used in NPS trend reporting, Confluence pages almost certainly exist. This is a known gap, not a flaw in what was written.

---

### Regeneration Feedback

1. Add `'1900-01-01'` sentinel note to `FirstDepositDate`: "Customers matched by RealCID who have never deposited will show `1900-01-01`, not NULL."
2. Add Phase Gate Checklist (P1–P3) and replace footer "pending" with judge score once reviewed.
3. For `ClubTier`, `PlayerStatus`, `MifCategory`: optionally add the numeric ID→Name mapping inline (e.g., `1=Normal, 2=Blocked…`) so the NPS wiki is self-contained for enum lookups.
4. These are all minor; the core wiki is high quality and does not require regeneration.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_CID_NPS_Panel",
  "weighted_score": 8.55,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [
    {
      "column": "RegisteredReal",
      "upstream_quote": "Account registration date (renamed from Registered). Default=getdate().",
      "wiki_quote": "Account registration date (renamed from Registered). Default=getdate(). NULL when RealCID is unresolved.",
      "match": "MINOR",
      "loss": "None — additive context only"
    },
    {
      "column": "FirstDepositDate",
      "upstream_quote": "Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic.",
      "wiki_quote": "Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. NULL when RealCID is unresolved.",
      "match": "MINOR",
      "loss": "None — additive context only; 1900-01-01 sentinel for non-depositor matches not mentioned"
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Reflects the customer's registered country as of the survey date (sourced from Fact_SnapshotCustomer → Dim_Country).",
      "match": "MINOR",
      "loss": "None — additive context only"
    },
    {
      "column": "ClubTier",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Reflects loyalty tier as of the survey date. Distribution: Bronze 60.1%, Gold 13.8%, Silver 13.4%, Platinum 6.7%, Platinum Plus 5.2%, Diamond 0.5%. NULL when unresolved.",
      "match": "MINOR",
      "loss": "None — additive context only"
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Reflects the customer's regulatory jurisdiction as of the survey date. Top values: CySEC (55.5%), FCA (30.0%), ASIC & GAML (8.4%). NULL when unresolved.",
      "match": "MINOR",
      "loss": "None — additive context only"
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. Reflects status as of the survey date. 97.0% of matched rows are Normal.",
      "match": "MINOR",
      "loss": "Em-dash substituted for double-dash; additive context only"
    },
    {
      "column": "MifCategory",
      "upstream_quote": "Human-readable classification label. Used in compliance dashboards and regulatory reports.",
      "wiki_quote": "Human-readable classification label. Used in compliance dashboards and regulatory reports. Reflects MiFID II categorization as of the survey date. Distribution: Retail 51.1%, Retail Pending 46.1%, Pending 2.2%, Elective Professional 0.2%. NULL when unresolved.",
      "match": "MINOR",
      "loss": "None — additive context only"
    },
    {
      "column": "FirstAction",
      "upstream_quote": "First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy Fund', 'Copy'. Merges Indices into Stocks bucket vs. legacy.",
      "wiki_quote": "First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy Fund', 'Copy'. Merges Indices into Stocks bucket vs. legacy. NULL when customer has no recorded first position (~1.6% of rows). Distribution: Stocks/ETFs/Indices 37.9%, Crypto 36.9%, Copy 15.8%, FX/Commodities 6.8%, Copy Fund 1.2%.",
      "match": "MINOR",
      "loss": "None — additive context only"
    },
    {
      "column": "FirstActionDate",
      "upstream_quote": "Datetime of 1st open position. From BI_DB_CustomerCross PIVOT (rn=1, MAX(Occurred)).",
      "wiki_quote": "Datetime of 1st open position. From BI_DB_CustomerCross PIVOT (rn=1, MAX(Occurred)). NULL when customer has no recorded first position.",
      "match": "MINOR",
      "loss": "None — additive context only"
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Phase Gate Checklist / Footer",
      "problem": "No Phase Gate Checklist present in the document. Footer reads 'Quality: pending judge evaluation' with no phases-completed list. All data claims (row counts, distributions, NULL rates) are internally consistent and specific but cannot be formally verified as live-data-backed without the P2/P3 checklist."
    },
    {
      "severity": "low",
      "column_or_section": "FirstDepositDate",
      "problem": "Description says 'NULL when RealCID is unresolved' but does not mention that matched customers who have never deposited will have '1900-01-01' sentinel value (the Dim_Customer DEFAULT). Analysts filtering for real deposit dates need: WHERE FirstDepositDate > '1900-01-01'."
    },
    {
      "severity": "low",
      "column_or_section": "ClubTier, PlayerStatus, MifCategory, Regulation",
      "problem": "Dictionary/enum varchar columns list names in descriptions but omit the numeric ID→Name mappings from the underlying dimension tables (e.g., PlayerLevelID 1=Bronze, 2=Platinum, 3=Gold; PlayerStatusID 1=Normal, 2=Blocked, etc.). Analysts cannot resolve status IDs to names without opening separate dim wikis."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 — Atlassian",
      "problem": "States 'No Atlassian MCP search performed.' For a core NPS analytics table likely referenced in CX/Product Confluence pages, this is a known gap that future regenerations should address."
    },
    {
      "severity": "low",
      "column_or_section": "Footer quality score",
      "problem": "Footer says 'Quality: pending judge evaluation' — should be updated post-review to enable quality drift tracking across regeneration attempts."
    }
  ],
  "regeneration_feedback": "Wiki PASSES at 8.55. Optional improvements for next pass: (1) Add '1900-01-01' sentinel note to FirstDepositDate description for matched non-depositors. (2) Add Phase Gate Checklist section (P1–P3) with checkboxes and replace footer 'pending' with judge score. (3) For ClubTier/PlayerStatus/MifCategory, add numeric ID→Name mappings inline for analyst self-service. (4) Run Atlassian MCP search for NPS-related Confluence pages.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count ~159,441 (property table header)",
      "Date range 2021-01-01 to 2025-07-10 (property table header)",
      "NULL RealCID: ~630 rows (~0.4%) (Section 1 + col 3)",
      "Comment NULL: ~51,415 rows (32.2%) (Section 3.4 + col 16)",
      "NPS Promoters 38.3%, Passives 37.1%, Detractors 24.6% (Section 2.4)",
      "ClubTier distribution: Bronze 60.1%, Gold 13.8%, Silver 13.4%… (col 9)",
      "FirstAction distribution: Stocks/ETFs/Indices 37.9%, Crypto 36.9%… (col 13)",
      "Country top values: UK 26,857, Germany 15,658, Italy 15,038 (col 8)"
    ],
    "skipped_phases": ["Phase Gate Checklist not present — phases unknown"]
  }
}
</JUDGE_VERDICT>
