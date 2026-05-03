## Judge Review: BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns sampled: `Campaign` (#16), `Region` (#48), `DateID` (#82), `IDFA` (#61), `Contributor2TouchTime` (#42). All tagged Tier 3 with source "AppsFlyer API, no upstream wiki" or "ETL process, no upstream wiki." The upstream bundle explicitly confirms: "NO UPSTREAM WIKI was resolvable for any source." No Synapse-resident upstream exists — data lands from an external API. Tier 3 is the correct classification for every column. Zero mismatches.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

No Tier 1 columns exist because no upstream wiki was available in the bundle. This is the correct outcome — the writer did not fabricate Tier 1 claims. Neutral score per rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|---|---|---|---|---|
| *(none)* | — | — | — | No Tier 1 columns; no upstream wiki available |

### Dimension 3 — Completeness: **10/10**

| Check | Result |
|---|---|
| All 8 sections present | YES (## 1 through ## 8) |
| Element count matches DDL | YES (86/86) |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES (AppsFlyer API → _Ext → SP_AppFlyer_Reports → BI_DB_AppFlyer_Reports) |
| Footer has tier breakdown counts | YES (0 T1, 0 T2, 86 T3, 0 T4, 0 T5) |
| Section 1 contains row count and date range | YES (130.3M rows, 2020 to present) |
| Dictionary columns with ≤15 values list inline values | YES (Platform, EtoroReport, EtoroAppName, AttributedTouchType all list values) |
| .review-needed.md does NOT contain `## 4. Elements` | YES (Section 4 is "ETL Load Mechanism Unknown") |

### Dimension 4 — Business Meaning: **9/10**

Section 1 is strong: names the domain (AppsFlyer mobile attribution), specifies row grain (raw attribution events per install/in-app event), row count (130.3M), date range (2020–present), the two apps covered (OneApp Android/iOS), the downstream consumer SP (SP_AppFlyer_Reports with specific transforms), and the "all varchar" landing design. An analyst knows exactly what this table is and when to use it vs. the downstream cleansed table. Minor gap: no explicit refresh time/schedule (just "daily").

### Dimension 5 — Data Evidence: **7/10**

Row count (130.3M) and date range (2020–2025) present in Section 1. Specific distribution percentages cited for Region (EU 71%, AS 8%), AttributedTouchType (click 53%, impression 14%), and top CountryCodes (DE, UK, FR, IT, AE). These suggest live data was queried. Footer says "Phases: 12/14" but there is no explicit Phase Gate Checklist section with `[x]` marks showing which phases were completed/skipped, making it impossible to verify P2/P3 status independently. The data claims appear grounded but the audit trail is incomplete.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown all present. Minor deviations: no explicit Phase Gate Checklist section (just the footer summary), and the footer format uses a slightly non-standard layout ("Quality: 7.0/10 | Phases: 12/14" rather than a structured phases-completed list).

---

### Top 5 Issues

1. **Medium — Footer/Phase Gate ambiguity**: Footer claims "Phases: 12/14" but no Phase Gate Checklist section exists to show which 2 phases were skipped. Cannot independently verify P2 (sample data) and P3 (distribution analysis) were completed, though the data claims in descriptions strongly suggest they were.

2. **Low — No refresh time specificity**: Section 1 and the property table say "Daily by DateID partition — externally loaded" but don't specify when (time of day) or provide SLA context. An analyst can't judge data freshness.

3. **Low — SubParam1–5 repetitive descriptions**: Elements 25–29 have nearly identical descriptions ("Custom sub-parameter N passed via the attribution link for additional tracking dimensions"). While accurate for a raw landing table with no upstream docs, if any sub-parameters have known eToro-specific conventions, those are missing.

4. **Low — Section 3.3 Common JOINs sparse**: Only one join listed (to BI_DB_AppFlyer_Reports). For a marketing attribution table, potential joins to user/account tables via CustomerUserID could be mentioned.

5. **Low — DateID type inconsistency note**: Element 82 correctly notes DateID is `int` in DDL, but the Gotchas section adds a confusing note about "loaded as string context" that could mislead analysts — the DDL is authoritative and DateID is int.

### Regeneration Feedback

1. Add an explicit Phase Gate Checklist section showing which phases were completed with `[x]` marks
2. Clarify refresh timing beyond "daily" — document known load window or SLA if available
3. Differentiate SubParam1–5 if any have known eToro conventions; otherwise the current descriptions are acceptable for a raw landing table
4. Remove or clarify the confusing DateID "string context" gotcha — the DDL defines it as `int`, full stop

---

### Weighted Score Calculation

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80
         = 8.75
```

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AppFlyer_Reports_Ext",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Footer / Phase Gate",
      "problem": "Footer claims 'Phases: 12/14' but no Phase Gate Checklist section exists with [x] marks. Cannot verify which 2 phases were skipped or confirm P2/P3 completion independently."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1 / Property Table",
      "problem": "Refresh described as 'Daily by DateID partition — externally loaded' with no time-of-day or SLA context. Analysts cannot judge data freshness."
    },
    {
      "severity": "low",
      "column_or_section": "SubParam1–SubParam5 (Elements 25–29)",
      "problem": "All five sub-parameter descriptions are nearly identical boilerplate. Acceptable for raw landing table with no upstream docs, but any known eToro-specific conventions for these fields are missing."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.3 Common JOINs",
      "problem": "Only one join listed (BI_DB_AppFlyer_Reports). Potential join to user/account tables via CustomerUserID not mentioned."
    },
    {
      "severity": "low",
      "column_or_section": "DateID (Element 82) / Section 3.4 Gotchas",
      "problem": "Gotcha about DateID 'loaded as string context' is confusing — DDL defines DateID as int, which is authoritative. The note may mislead analysts."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Section 1: 130.3M rows, 2020 to present",
      "Region: EU (71%), AS (8%), AU (3%), SA (2%), AF (2%), NA (<1%), None (12%), empty (3%)",
      "AttributedTouchType: click (53%), impression (14%), NULL/empty (33%)",
      "CountryCode: top countries DE, UK, FR, IT, AE"
    ],
    "skipped_phases": ["Unknown — no Phase Gate Checklist section present, footer says 12/14"]
  }
}
</JUDGE_VERDICT>
