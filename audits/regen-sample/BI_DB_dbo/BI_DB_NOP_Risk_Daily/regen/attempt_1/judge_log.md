I'll now review this wiki systematically against the rubric. Let me verify the SP code and upstream bundle carefully.

---

## Per-Dimension Evaluation

### Dimension 1 — Tier Accuracy (weight 25%)

I sampled 5 columns:

| Column | Wiki Claims | Actual (from SP + upstream wikis) | Match? |
|--------|------------|-----------------------------------|--------|
| **DateID** | Tier 2 — BI_DB_PositionPnL | SP Step 04: `dp.DateID` — passthrough from BI_DB_PositionPnL, which HAS a wiki → should be **Tier 1** | **MISMATCH** |
| **InstrumentID** | Tier 1 — Trade.PositionTbl | SP Step 04: `dp.InstrumentID` — passthrough from BI_DB_PositionPnL (immediate upstream with wiki). Writer cited root origin 3 hops away. Tier correct, source relay. | Tier OK, source wrong |
| **IsSettled** | Tier 5 — Expert Review | SP Step 04: `dp.IsSettled` — passthrough from BI_DB_PositionPnL, which documents IsSettled → should be **Tier 1** | **MISMATCH** |
| **InstrumentDisplayName** | Tier 1 — Trade.InstrumentMetaData | SP Step 04: `di.InstrumentDisplayName` — dim-lookup passthrough from Dim_Instrument. Dim's root origin IS Trade.InstrumentMetaData. Correct per dim-lookup rule. | **MATCH** |
| **SellBuy** | Tier 2 — BI_DB_PositionPnL | SP Step 04: `CASE WHEN dp.IsBuy=1 THEN 'Buy' ELSE 'Sell'` — ETL-computed CASE. Tier 2 correct. | **MATCH** |

2 mismatches out of 5 → base score **5**. No paraphrasing failures on declared Tier 1 columns.

**Score: 5**

---

### Dimension 2 — Upstream Fidelity (weight 20%)

#### T1 Fidelity Table

The wiki declares 2 Tier 1 columns:

| Column | Upstream Quote (verbatim) | Wiki Quote (verbatim) | Match | Loss |
|--------|--------------------------|----------------------|-------|------|
| **InstrumentID** | BI_DB_PositionPnL: "Traded instrument." / Dim_Position: "FK to Trade.Instrument. Financial instrument being traded." | "FK to Trade.Instrument. Financial instrument being traded. Passthrough from BI_DB_PositionPnL." | MINOR | Added lineage context; core from Dim_Position verbatim, but immediate upstream is BI_DB_PositionPnL whose description is shorter. Source relay: cited Trade.PositionTbl (3 hops) instead of BI_DB_PositionPnL. |
| **InstrumentDisplayName** | Dim_Instrument: "Human-readable name shown in UI (e.g., 'Apple', 'EUR/USD'). Used in position displays, order forms, and APIs." | "Human-readable name shown in UI (e.g., 'Apple', 'EUR/USD'). Used in position displays, order forms, and APIs. Passthrough from Dim_Instrument." | MINOR | Core description verbatim from Dim_Instrument; added "Passthrough from Dim_Instrument" lineage suffix. Origin (Trade.InstrumentMetaData) correct per dim-lookup rule. |

The 2 declared Tier 1 columns are essentially verbatim (minor additions). Starting score: **9**.

**Missed inheritances** (columns that should have been Tier 1 but weren't):
- **DateID**: BI_DB_PositionPnL wiki exists and documents DateID. Writer tagged Tier 2. → -2
- **IsSettled**: BI_DB_PositionPnL wiki exists and documents IsSettled (Tier 5 there, but the wiki EXISTS). Writer tagged Tier 5 instead of inheriting. → -2

9 - 4 = **5**

**Score: 5**

---

### Dimension 3 — Completeness (weight 20%)

| Check | Status |
|-------|--------|
| All 8 sections present | YES |
| Element count matches DDL (8/8) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 contains row count and date range | YES (180,577 rows, 2023-12-16 to 2024-01-16) |
| Dictionary columns ≤15 values list inline pairs | YES — InstrumentType lists all 8 values in element #4, IsSettled lists 1/0 in #3, SellBuy lists Buy/Sell in #6 |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

10/10 → **Score: 10**

---

### Dimension 4 — Business Meaning (weight 15%)

Section 1 is excellent: names NOP/risk domain, specifies row grain (DateID, InstrumentID, IsSettled, SellBuy), identifies the ETL SP and step number, describes rolling 1-month retention, gives row count (180,577), date range (32 dates), instrument count (4,816), and refresh pattern. An analyst would immediately know when and how to query this table.

**Score: 9**

---

### Dimension 5 — Data Evidence (weight 10%)

- Row count and date range in Section 1: YES (180,577 rows, 32 dates)
- Specific enum distributions: YES (InstrumentType breakdown in Section 2.1 with row counts and percentages)
- NULL-rate claims: minimal but IsSettled, SellBuy distributions implied
- Phase Gate: Footer says "Phases: 11/14" but no explicit P2/P3 checkbox. Data claims are present and specific, suggesting live data was used.

**Score: 7**

---

### Dimension 6 — Shape Fidelity (weight 10%)

Numbered sections 1-8 present, tier legend in Section 4 (though abbreviated — only lists Tiers 1, 2, 5 used), real SQL samples in Section 7 with proper schema-qualified table names, footer has quality score and phases-completed. Minor: tier legend uses text-only format without star ratings.

**Score: 8**

---

## Weighted Total

```
weighted = 0.25×5 + 0.20×5 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8
         = 1.25 + 1.00 + 2.00 + 1.35 + 0.70 + 0.80
         = 7.10
```

**Verdict: FAIL** (7.10 < 7.5)

---

## T1 Fidelity Table (Markdown)

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| InstrumentID | "Traded instrument." (BI_DB_PositionPnL) / "FK to Trade.Instrument. Financial instrument being traded." (Dim_Position) | "FK to Trade.Instrument. Financial instrument being traded. Passthrough from BI_DB_PositionPnL." | MINOR | Used Dim_Position description (correct content) but cited Trade.PositionTbl origin instead of immediate upstream BI_DB_PositionPnL |
| InstrumentDisplayName | "Human-readable name shown in UI (e.g., 'Apple', 'EUR/USD'). Used in position displays, order forms, and APIs." (Dim_Instrument) | "Human-readable name shown in UI (e.g., 'Apple', 'EUR/USD'). Used in position displays, order forms, and APIs. Passthrough from Dim_Instrument." | MINOR | Core verbatim; added lineage suffix |

---

## Top 5 Issues

1. **HIGH — DateID: Wrong tier.** Tagged `(Tier 2 — BI_DB_PositionPnL)` but SP Step 04 does `dp.DateID` as a direct passthrough. BI_DB_PositionPnL wiki documents DateID. Should be Tier 1 with verbatim description from BI_DB_PositionPnL: "Snapshot date as YYYYMMDD; partition key."

2. **HIGH — IsSettled: Wrong tier.** Tagged `(Tier 5 — Expert Review)` but is a passthrough from BI_DB_PositionPnL, which has a wiki documenting IsSettled as "1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (ChangeTypeID = 13) when applicable." Should be Tier 1 from BI_DB_PositionPnL with that verbatim description.

3. **MEDIUM — InstrumentID: Source relay.** Cited `(Tier 1 — Trade.PositionTbl)` tracing 3 hops back (BI_DB_PositionPnL → Dim_Position → Trade.PositionTbl). The immediate upstream with a wiki is BI_DB_PositionPnL. Should be `(Tier 1 — BI_DB_PositionPnL)` with the BI_DB_PositionPnL description.

4. **MEDIUM — InstrumentDisplayName description type mismatch.** DDL has `varchar(200)` and the wiki correctly shows this. However, the upstream Dim_Instrument wiki declares the column as `varchar(100)`. The SP reads from Dim_Instrument, so the 200-char target column is wider than the source — this discrepancy should be called out.

5. **LOW — Tier legend incomplete.** Section 4 tier legend only lists Tiers 1, 2, and 5. The standard shape includes all tiers (1-5) with star ratings. Minor shape deviation.

---

## Regeneration Feedback

1. Re-tag **DateID** as `(Tier 1 — BI_DB_PositionPnL)` and use verbatim description from the BI_DB_PositionPnL wiki: "Snapshot date as YYYYMMDD; partition key."
2. Re-tag **IsSettled** as `(Tier 1 — BI_DB_PositionPnL)` and use verbatim description: "1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (ChangeTypeID = 13) when applicable."
3. Re-tag **InstrumentID** source from `Trade.PositionTbl` to `BI_DB_PositionPnL` (immediate upstream) and use its description: "Traded instrument."
4. Add full tier legend (Tiers 1–5 with star ratings) to Section 4 for shape compliance.
5. Add explicit Phase Gate Checklist marking which phases (P2/P3) were completed or skipped.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_NOP_Risk_Daily",
  "weighted_score": 7.10,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 5,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentID",
      "upstream_quote": "Traded instrument. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.InstrumentID)",
      "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded. Passthrough from BI_DB_PositionPnL. (Tier 1 — Trade.PositionTbl)",
      "match": "MINOR",
      "loss": "Used Dim_Position description instead of immediate upstream BI_DB_PositionPnL description. Cited root origin Trade.PositionTbl (3 hops away) instead of BI_DB_PositionPnL."
    },
    {
      "column": "InstrumentDisplayName",
      "upstream_quote": "Human-readable name shown in UI (e.g., \"Apple\", \"EUR/USD\"). Used in position displays, order forms, and APIs. (Tier 1 — Trade.InstrumentMetaData)",
      "wiki_quote": "Human-readable name shown in UI (e.g., \"Apple\", \"EUR/USD\"). Used in position displays, order forms, and APIs. Passthrough from Dim_Instrument. (Tier 1 — Trade.InstrumentMetaData)",
      "match": "MINOR",
      "loss": "Core description verbatim from Dim_Instrument wiki. Added 'Passthrough from Dim_Instrument' lineage suffix. No semantic loss."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "DateID",
      "problem": "Tagged Tier 2 (BI_DB_PositionPnL) but is a direct passthrough from BI_DB_PositionPnL which has a wiki documenting DateID. Should be Tier 1 with verbatim description from BI_DB_PositionPnL."
    },
    {
      "severity": "high",
      "column_or_section": "IsSettled",
      "problem": "Tagged Tier 5 (Expert Review) but is a passthrough from BI_DB_PositionPnL which has a wiki documenting IsSettled as '1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (ChangeTypeID = 13) when applicable.' Should be Tier 1 from BI_DB_PositionPnL."
    },
    {
      "severity": "medium",
      "column_or_section": "InstrumentID",
      "problem": "Source relay: cited (Tier 1 — Trade.PositionTbl) tracing 3 hops back through Dim_Position. Immediate upstream with wiki is BI_DB_PositionPnL. Should cite BI_DB_PositionPnL as the source."
    },
    {
      "severity": "medium",
      "column_or_section": "InstrumentDisplayName",
      "problem": "DDL declares varchar(200) but upstream Dim_Instrument wiki shows varchar(100). The wider target column is not called out as a discrepancy."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 — Tier Legend",
      "problem": "Tier legend only lists Tiers 1, 2, and 5. Standard shape requires full tier legend with star ratings for all tiers."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag DateID as (Tier 1 — BI_DB_PositionPnL) using verbatim text: 'Snapshot date as YYYYMMDD; partition key.' (2) Re-tag IsSettled as (Tier 1 — BI_DB_PositionPnL) using verbatim text: '1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (ChangeTypeID = 13) when applicable.' (3) Re-tag InstrumentID source from Trade.PositionTbl to BI_DB_PositionPnL (immediate upstream). (4) Add full tier legend with star ratings. (5) Add explicit Phase Gate Checklist.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
