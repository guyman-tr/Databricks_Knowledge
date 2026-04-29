## Adversarial Review: Dealing_dbo.Dealing_Boundary_Cost

### Dimension 1 — Tier Accuracy: **3/10**

**Sample of 5 columns:**

| Column | Wiki Tier | Correct Tier | Match? |
|--------|-----------|--------------|--------|
| InstrumentID (#5) | Tier 1 — Dim_Instrument | Tier 1 — Dim_Instrument | YES (but paraphrased) |
| InstrumentType (#7) | Tier 1 — Dim_Instrument | Tier 1 — Dim_Instrument | YES (but paraphrased) |
| InstrumentTypeID (#27) | Tier 1 — Dim_Instrument | Tier 1 — Dim_Instrument | YES (but paraphrased) |
| InstrumentName (#6) | Tier 2 — SP_Boundary_Cost, via Dim_Instrument | Tier 1 — DWH_dbo.Dim_Instrument (rename of InstrumentDisplayName) | **NO** |
| IsSettled (#29) | Tier 5 — Expert Review | Tier 1 — DWH_dbo.Dim_Position (passthrough) | **NO** |

2 tier mismatches → base score 5. InstrumentID description dropped sentinel value info ("Ranges from 0 (system placeholder) to ~21 million IDs allocated"); InstrumentType dropped "else=Other" catch-all. Two paraphrasing failures on Tier 1 columns: 5 - 4 = **3**.

### Dimension 2 — Upstream Fidelity: **3/10**

All 3 declared Tier 1 columns are paraphrased, not verbatim. Additionally, 2 columns (InstrumentName, IsSettled) represent missed inheritances — upstream wikis existed and the columns are passthroughs/renames, but the writer tagged them Tier 2 or Tier 5 instead of Tier 1.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| InstrumentID | "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables." | "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Referenced by virtually every trading fact table. FK to DWH_dbo.Dim_Instrument." | NO | Dropped sentinel range info (ID=0 placeholder, ~21M allocated), dropped Dim_Currency/Dim_HistorySplitRatio references |
| InstrumentType | "Text label for InstrumentTypeID -- DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display." | "Text label for the instrument category: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. DWH-computed via CASE on InstrumentTypeID. Use InstrumentTypeID for filtering; InstrumentType for display." | NO | Dropped "else=Other" catch-all; rephrased "for InstrumentTypeID" → "for the instrument category" |
| InstrumentTypeID | "Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Distribution: Stocks 82%, ETF 8%, Crypto 4%, Commodities 3%, Indices 2%, Currencies 1%." | "Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Used for boundary default logic (Stocks/ETFs get defaults when no boundary configured)." | NO | Dropped distribution percentages; added non-upstream context |
| InstrumentName (MISSED — tagged Tier 2) | "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries." (Dim_Instrument #18) | "User-facing instrument display name from `Dim_Instrument.InstrumentDisplayName`. More descriptive than the internal Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries." | NO | Missed inheritance: should be Tier 1, tagged Tier 2. Paraphrased source reference. |
| IsSettled (MISSED — tagged Tier 5) | "1 = real asset, 0 = CFD asset." (Dim_Position #93) | "1 = real asset, 0 = CFD asset." | MINOR | Missed inheritance: should be Tier 1 from Dim_Position, tagged Tier 5. Description verbatim but tier wrong. |

### Dimension 3 — Completeness: **4/10**

| Check | Pass? |
|-------|-------|
| All 8 sections present | ❌ Only 7 sections (no Section 8) |
| Element count = DDL column count | ❌ Property table says 33, DDL has 31 |
| Every element row has 5 cells | ✓ |
| Every description ends with tier tag | ✓ |
| Property table has Production Source, Refresh, Distribution, UC Target | ❌ Missing UC Target |
| Section 5.2 ETL pipeline ASCII diagram | ❌ No pipeline diagram in wiki (only in lineage file) |
| Footer has tier breakdown counts | ❌ Footer only has "Generated: 2026-03-21 \| Batch 4 \| Schema: Dealing_dbo" |
| Section 1 has row count + date range | ❌ Has date (2024-03-17) but no row count |
| Dictionary columns list inline values | ✓ InstrumentTypeID, IsSettled have values listed |
| .review-needed.md has no `## 4. Elements` | ✓ |

4/10 checks pass → score **4**.

### Dimension 4 — Business Meaning: **8/10**

Section 1 is genuinely strong. It names the domain (dealing/hedging NOP), specifies the row grain (one-minute window per instrument × HedgeServer × IsSettled), names the ETL SP (SP_Boundary_Cost), and describes the refresh pattern (daily delete+insert per date). The IsSettled distinction is well explained. Missing row count (query timed out). Good but not perfect.

### Dimension 5 — Data Evidence: **4/10**

- Row count: Missing (query timed out per Quality Score)
- Date range: Partial ("latest available date is 2024-03-17")
- Enum values: InstrumentTypeID values listed inline
- Phase Gate Checklist: No formal P2/P3 checklist present
- NULL-rate claims: Not backed by sampled data

No Phase Gate Checklist means data claims cannot be verified as grounded. The Quality Score section acknowledges "row count query timed out" which is honest but means key data evidence is absent.

### Dimension 6 — Shape Fidelity: **5/10**

- Numbered sections: Yes but only 7 of 8
- Tier legend in Section 4: Present ✓
- SQL samples in Section 7: Section 7 is "Quality Score" — no SQL examples ❌
- Footer format: Missing tier breakdown counts, missing phases-completed list
- Property table structure: Present and well-formed

---

### Top 5 Issues

1. **HIGH — Property table column count wrong**: Property table claims 33 columns; DDL has 31. The Elements table correctly lists 31. This contradicts the DDL and confuses consumers.

2. **HIGH — InstrumentName (#6) tagged Tier 2 instead of Tier 1**: This is a rename of `Dim_Instrument.InstrumentDisplayName` (passthrough from upstream wiki). The upstream wiki for Dim_Instrument documents InstrumentDisplayName. The writer should have tagged this Tier 1 and quoted the upstream description verbatim.

3. **HIGH — IsSettled (#29) tagged Tier 5 instead of Tier 1**: This is a passthrough from `Dim_Position.IsSettled`. The upstream Dim_Position wiki documents IsSettled as Tier 5, but from Dealing_Boundary_Cost's perspective, it's a passthrough with upstream wiki available → Tier 1 citing Dim_Position. The writer just copied the upstream's tier classification instead of applying the inheritance rule.

4. **MEDIUM — All Tier 1 descriptions paraphrased**: InstrumentID dropped sentinel range and FK targets. InstrumentType dropped "else=Other". InstrumentTypeID dropped distribution percentages and added non-upstream context. None are verbatim as required.

5. **MEDIUM — Missing structural elements**: No Section 8, no ETL pipeline diagram in wiki body, no SQL sample queries, no tier breakdown in footer, no row count in Section 1.

---

### Regeneration Feedback

1. Fix property table column count from 33 to 31.
2. Re-tag InstrumentName (#6) as `(Tier 1 — DWH_dbo.Dim_Instrument)` and use verbatim text from Dim_Instrument wiki for InstrumentDisplayName (#18).
3. Re-tag IsSettled (#29) as `(Tier 1 — DWH_dbo.Dim_Position)` using verbatim text from Dim_Position wiki (#93).
4. Replace all Tier 1 column descriptions with character-for-character copies from upstream wikis: InstrumentID from Dim_Instrument #1, InstrumentType from Dim_Instrument #3, InstrumentTypeID from Dim_Instrument #2.
5. Add Section 8 (Sample Queries) with real SQL examples, add ETL pipeline ASCII diagram in Section 5, add tier breakdown counts to footer.
6. Add row count to Section 1 (retry query or estimate from known parameters).

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Boundary_Cost",
  "weighted_score": 4.25,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 3,
    "completeness": 4,
    "business_meaning": 8,
    "data_evidence": 4,
    "shape_fidelity": 5
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentID",
      "upstream_quote": "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables.",
      "wiki_quote": "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Referenced by virtually every trading fact table. FK to DWH_dbo.Dim_Instrument.",
      "match": "NO",
      "loss": "Dropped sentinel range info (ID=0 placeholder, ~21M allocated), dropped Dim_Currency/Dim_HistorySplitRatio references, added non-upstream FK note"
    },
    {
      "column": "InstrumentType",
      "upstream_quote": "Text label for InstrumentTypeID -- DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display.",
      "wiki_quote": "Text label for the instrument category: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. DWH-computed via CASE on InstrumentTypeID. Use InstrumentTypeID for filtering; InstrumentType for display.",
      "match": "NO",
      "loss": "Dropped 'else=Other' catch-all; rephrased 'for InstrumentTypeID' to 'for the instrument category'; reordered sentences"
    },
    {
      "column": "InstrumentTypeID",
      "upstream_quote": "Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Distribution: Stocks 82%, ETF 8%, Crypto 4%, Commodities 3%, Indices 2%, Currencies 1%.",
      "wiki_quote": "Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Used for boundary default logic (Stocks/ETFs get defaults when no boundary configured).",
      "match": "NO",
      "loss": "Dropped distribution percentages (Stocks 82%, ETF 8%, etc.); added non-upstream boundary context"
    },
    {
      "column": "InstrumentName (MISSED INHERITANCE)",
      "upstream_quote": "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries.",
      "wiki_quote": "User-facing instrument display name from Dim_Instrument.InstrumentDisplayName. More descriptive than the internal Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries.",
      "match": "NO",
      "loss": "Missed inheritance: rename of Dim_Instrument.InstrumentDisplayName tagged Tier 2 instead of Tier 1. Paraphrased source reference ('Trade.InstrumentMetaData' → 'Dim_Instrument.InstrumentDisplayName')."
    },
    {
      "column": "IsSettled (MISSED INHERITANCE)",
      "upstream_quote": "1 = real asset, 0 = CFD asset.",
      "wiki_quote": "1 = real asset, 0 = CFD asset.",
      "match": "MINOR",
      "loss": "Missed inheritance: passthrough from Dim_Position.IsSettled tagged Tier 5 instead of Tier 1. Description is verbatim but tier classification is wrong."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Property table",
      "problem": "Column count listed as 33 but DDL has 31 columns. Elements table correctly lists 31."
    },
    {
      "severity": "high",
      "column_or_section": "InstrumentName (#6)",
      "problem": "Tagged Tier 2 (SP_Boundary_Cost, via Dim_Instrument) but this is a rename of Dim_Instrument.InstrumentDisplayName with upstream wiki available. Should be Tier 1 — DWH_dbo.Dim_Instrument with verbatim upstream text."
    },
    {
      "severity": "high",
      "column_or_section": "IsSettled (#29)",
      "problem": "Tagged Tier 5 (Expert Review) but this is a passthrough from Dim_Position.IsSettled with upstream wiki available. Should be Tier 1 — DWH_dbo.Dim_Position. Writer copied the upstream's own tier classification instead of applying inheritance rules."
    },
    {
      "severity": "medium",
      "column_or_section": "InstrumentID (#5), InstrumentType (#7), InstrumentTypeID (#27)",
      "problem": "All 3 declared Tier 1 columns have paraphrased descriptions instead of verbatim quotes from DWH_dbo.Dim_Instrument upstream wiki. InstrumentID dropped sentinel range info, InstrumentType dropped 'else=Other', InstrumentTypeID dropped distribution percentages."
    },
    {
      "severity": "medium",
      "column_or_section": "Sections 5/7/8, Footer",
      "problem": "Missing Section 8 (Sample Queries), no ETL pipeline ASCII diagram in wiki body, Section 7 is Quality Score instead of SQL samples, footer lacks tier breakdown counts and phases-completed list."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix property table column count from 33 to 31. (2) Re-tag InstrumentName as Tier 1 — DWH_dbo.Dim_Instrument and use verbatim text from Dim_Instrument wiki InstrumentDisplayName entry. (3) Re-tag IsSettled as Tier 1 — DWH_dbo.Dim_Position and use verbatim text from Dim_Position wiki. (4) Replace all Tier 1 descriptions with character-for-character copies from upstream wikis (InstrumentID from Dim_Instrument #1, InstrumentType from #3, InstrumentTypeID from #2). (5) Add Section 8 with SQL samples, add ETL pipeline diagram to Section 5, add tier breakdown to footer. (6) Retry row count query for Section 1.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2 (row count query timed out)", "P3 (no Phase Gate Checklist present)"]
  }
}
</JUDGE_VERDICT>
