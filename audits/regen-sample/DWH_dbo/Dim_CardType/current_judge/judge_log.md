I'll review this wiki systematically against the rubric. Let me first verify the upstream wiki to do character-by-character comparison of Tier 1 columns.

## Per-Dimension Analysis

### Dimension 1 — Tier Accuracy (25%)

All 4 columns checked (only 4 exist):

| Column | Lineage | Expected Tier | Wiki Tier | Match? |
|--------|---------|---------------|-----------|--------|
| CardTypeID | passthrough from Dictionary.CardType, upstream wiki exists | Tier 1 | Tier 1 | YES |
| CarTypeName | rename from Dictionary.CardType.Name, upstream wiki exists | Tier 1 | Tier 1 | YES |
| IsActive | cast (bit→int) from Dictionary.CardType, upstream wiki exists | Tier 1 | Tier 1 | YES |
| UpdateDate | ETL-computed migration timestamp | Tier 2 | Tier 2 | YES |

Tier assignments are all correct (0 mismatches → base 10). However, all 3 Tier 1 columns are **paraphrased**, not verbatim. Deduct 2 per paraphrasing failure: 10 - 6 = **4**.

### Dimension 2 — Upstream Fidelity (20%)

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CardTypeID | "Card network identifier. Active brands: 1=Visa, 2=MasterCard, 3=Diners, 8=Maestro. Inactive: 0=None, 4=Amex, 5=FirePay, 6=JCB, 7=American Express, 9=Laser, 10=Switch, 11=UK Local, 12=Discover, 13=Local Card, 14=China UnionPay, 15=Solo, 16=Cirrus, 17=GE Capital, 18=Unknown, 19-31=various regional/legacy brands." | "Card network identifier. Active brands (IsActive=1 as of 2019): 0=None (unknown/fallback), 1=Visa, 2=Master Card, 3=Diners. Inactive: 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro (active in production today)..." | **NO** | Active set rewritten to DWH snapshot state (Maestro moved from active→inactive, None moved to active). Brand names reformatted: "MasterCard"→"Master Card", "FirePay"→"Fire Pay", "China UnionPay"→"China Union Pay", "UK Local"→"UK Local Credit Card". IDs 18-31 dropped entirely. |
| CarTypeName | "Card brand name. Unique constraint prevents duplicates. Used in payment UI, transaction records, and fraud reporting." | "Card brand name. DDL note: column has a typo ("Car" instead of "Card") — historical artifact from legacy DWH SQL Server migration. Key values: Visa, Master Card..." | **NO** | Dropped: unique constraint, usage context (payment UI, transaction records, fraud reporting). Replaced with DWH-specific notes. |
| IsActive | "Whether this card brand is currently accepted for deposits: 1=accepted, 0=rejected. DEFAULT 1 (new card types are active by default). Only 4 of 32 are currently active." | "Whether this card brand was accepted for deposits as of the 2019 migration snapshot: 1=active, 0=inactive. DWH note: production uses bit type; DWH uses int..." | **NO** | Changed temporality ("currently"→"as of 2019"). Dropped DEFAULT 1 semantics. Dropped "Only 4 of 32 are currently active." Added DWH-specific cast notes not in upstream. |

All 3 Tier 1 columns paraphrased → **Score: 3**

### Dimension 3 — Completeness (20%)

- [x] All 8 sections present
- [x] Element count matches DDL (4 DDL columns, 4 elements)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (18) and date range (2019-06-30)
- [x] Dictionary columns list inline key=value pairs (CardTypeID lists all 18, IsActive lists 1/0)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

10/10 → **Score: 10**

### Dimension 4 — Business Meaning (15%)

Section 1 is excellent: names the domain (payment card network brands), row grain (each row = a card type), production source (etoro.Dictionary.CardType), refresh pattern (frozen 2019 migration), row count (18 of 32), and even flags the CarTypeName typo. An analyst would know exactly when to use this table and its limitations.

**Score: 9**

### Dimension 5 — Data Evidence (10%)

- Row count (18) in Section 1: present
- Date range (2019-06-30): present
- Specific enum values: full list of all 18 card types with active/inactive status
- Phase gate: footer says "Phases: 11/14" but no explicit P2/P3 checkboxes. Data claims appear grounded (card type names match upstream wiki).

**Score: 7**

### Dimension 6 — Shape Fidelity (10%)

Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases. Minor: "3.1b" numbering is slightly non-standard. Otherwise conforms well.

**Score: 8**

---

## Weighted Total

```
weighted = 0.25×4 + 0.20×3 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8
         = 1.00 + 0.60 + 2.00 + 1.35 + 0.70 + 0.80
         = 6.45
```

**Verdict: FAIL** (6.45 < 7.5)

---

## Top 5 Issues

1. **HIGH — CardTypeID**: Upstream active set is {1=Visa, 2=MasterCard, 3=Diners, 8=Maestro}; wiki rewrites it to DWH snapshot state {0=None, 1=Visa, 2=Master Card, 3=Diners}, moving Maestro to inactive and None to active. Brand names reformatted ("MasterCard"→"Master Card", "FirePay"→"Fire Pay", "China UnionPay"→"China Union Pay"). IDs 18-31 dropped. This is wholesale rewriting, not verbatim inheritance.

2. **HIGH — CarTypeName**: Upstream says "Unique constraint prevents duplicates. Used in payment UI, transaction records, and fraud reporting." Wiki drops all of this and replaces with DWH-specific typo notes. The upstream description must appear verbatim first, with DWH notes appended.

3. **HIGH — IsActive**: Upstream says "currently accepted" with DEFAULT 1 semantics and "Only 4 of 32 are currently active." Wiki changes temporality and drops both the default and the count. Tier 1 means quote-then-annotate, not rewrite.

4. **MEDIUM — Upstream description structure**: The writer treated Tier 1 as "adapt upstream meaning to DWH context" rather than "quote upstream verbatim, then add DWH-specific notes as a separate annotation." The correct pattern is: upstream quote first, then `DWH note: ...` addendum.

5. **LOW — CardTypeID element description**: Wiki says `CardTypeID` is `NULL` and `IsActive=1` for ID=0 (None), but upstream says ID=0 has `IsActive=0`. The wiki correctly flags this discrepancy in Section 3.4, but the element description presents the DWH values as if they were the canonical truth rather than quoting upstream first.

---

## Regeneration Feedback

1. For all 3 Tier 1 columns (CardTypeID, CarTypeName, IsActive), **quote the upstream Dictionary.CardType description verbatim first**, then append DWH-specific notes as a clearly separated addendum (e.g., `DWH note: ...`).
2. For CardTypeID, use the upstream's active set verbatim (1=Visa, 2=MasterCard, 3=Diners, 8=Maestro) and the upstream brand name spellings (MasterCard not "Master Card", FirePay not "Fire Pay", China UnionPay not "China Union Pay"). Append DWH snapshot differences as a note.
3. For CarTypeName, restore "Unique constraint prevents duplicates. Used in payment UI, transaction records, and fraud reporting." from upstream, then add the typo note.
4. For IsActive, restore "Whether this card brand is currently accepted for deposits: 1=accepted, 0=rejected. DEFAULT 1 (new card types are active by default). Only 4 of 32 are currently active." verbatim, then add the DWH cast and snapshot notes.
5. Include IDs 18-31 in CardTypeID description (from upstream: "18=Unknown, 19-31=various regional/legacy brands") with a note that only 0-17 exist in the DWH snapshot.

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_CardType",
  "weighted_score": 6.45,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 4,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "CardTypeID",
      "upstream_quote": "Card network identifier. Active brands: 1=Visa, 2=MasterCard, 3=Diners, 8=Maestro. Inactive: 0=None, 4=Amex, 5=FirePay, 6=JCB, 7=American Express, 9=Laser, 10=Switch, 11=UK Local, 12=Discover, 13=Local Card, 14=China UnionPay, 15=Solo, 16=Cirrus, 17=GE Capital, 18=Unknown, 19-31=various regional/legacy brands.",
      "wiki_quote": "Card network identifier. Active brands (IsActive=1 as of 2019): 0=None (unknown/fallback), 1=Visa, 2=Master Card, 3=Diners. Inactive: 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro (active in production today), 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital.",
      "match": "NO",
      "loss": "Active set rewritten to DWH snapshot state (Maestro moved active→inactive, None moved inactive→active). Brand names reformatted: MasterCard→Master Card, FirePay→Fire Pay, China UnionPay→China Union Pay, UK Local→UK Local Credit Card. IDs 18-31 dropped entirely."
    },
    {
      "column": "CarTypeName",
      "upstream_quote": "Card brand name. Unique constraint prevents duplicates. Used in payment UI, transaction records, and fraud reporting.",
      "wiki_quote": "Card brand name. DDL note: column has a typo (\"Car\" instead of \"Card\") — historical artifact from legacy DWH SQL Server migration. Key values: Visa, Master Card, MasterCard, Diners, Amex, American Express, Maestro, Discover, China Union Pay.",
      "match": "NO",
      "loss": "Dropped unique constraint reference, dropped usage context (payment UI, transaction records, fraud reporting). Replaced with DWH-specific typo notes and value list not in upstream."
    },
    {
      "column": "IsActive",
      "upstream_quote": "Whether this card brand is currently accepted for deposits: 1=accepted, 0=rejected. DEFAULT 1 (new card types are active by default). Only 4 of 32 are currently active.",
      "wiki_quote": "Whether this card brand was accepted for deposits as of the 2019 migration snapshot: 1=active, 0=inactive. DWH note: production uses bit type; DWH uses int. This snapshot may not reflect current production acceptance (e.g., Maestro/ID=8 is active in production but shows 0 here).",
      "match": "NO",
      "loss": "Changed temporality (currently→as of 2019). Dropped DEFAULT 1 semantics. Dropped 'Only 4 of 32 are currently active.' Added DWH-specific cast and snapshot notes not in upstream."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "CardTypeID",
      "problem": "Upstream active set {1=Visa, 2=MasterCard, 3=Diners, 8=Maestro} rewritten to DWH snapshot state {0=None, 1=Visa, 2=Master Card, 3=Diners}. Brand names reformatted (MasterCard→Master Card, FirePay→Fire Pay, China UnionPay→China Union Pay). IDs 18-31 dropped. Must quote upstream verbatim then add DWH notes."
    },
    {
      "severity": "high",
      "column_or_section": "CarTypeName",
      "problem": "Upstream description ('Unique constraint prevents duplicates. Used in payment UI, transaction records, and fraud reporting.') entirely replaced with DWH-specific typo notes. Must quote upstream verbatim first."
    },
    {
      "severity": "high",
      "column_or_section": "IsActive",
      "problem": "Upstream description rewritten: 'currently accepted' changed to 'as of 2019 migration snapshot', DEFAULT 1 semantics dropped, '4 of 32' count dropped. Must quote upstream verbatim then add DWH snapshot notes."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 4 (all Tier 1 columns)",
      "problem": "Writer treated Tier 1 as 'adapt upstream meaning to DWH context' instead of 'quote verbatim, then annotate'. All 3 Tier 1 descriptions are contextual rewrites, not inheritance."
    },
    {
      "severity": "low",
      "column_or_section": "CardTypeID element",
      "problem": "Element description presents DWH snapshot values (None=active, Maestro=inactive) as canonical truth rather than quoting upstream active set first and noting DWH divergence as an addendum."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Quote upstream Dictionary.CardType descriptions VERBATIM for CardTypeID, CarTypeName, and IsActive — do not adapt temporality, active sets, or brand name spellings. (2) Append DWH-specific notes (frozen snapshot, type cast, typo) as clearly separated 'DWH note:' addenda AFTER the upstream quote. (3) Restore upstream brand name spellings: MasterCard (not Master Card), FirePay (not Fire Pay), China UnionPay (not China Union Pay), UK Local (not UK Local Credit Card). (4) Restore upstream active set in CardTypeID description: 1=Visa, 2=MasterCard, 3=Diners, 8=Maestro. (5) Include IDs 18-31 from upstream ('18=Unknown, 19-31=various regional/legacy brands') with note that only 0-17 exist in DWH snapshot.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
