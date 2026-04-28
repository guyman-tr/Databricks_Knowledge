I'll review this wiki systematically against the upstream bundle and SP source code.

## Per-Dimension Evaluation

### Dimension 1 — Tier Accuracy: **5/10**

Random 5 columns sampled:

| Column | Wiki Tier | Correct Tier | Verdict |
|--------|-----------|-------------|---------|
| InstrumentTypeID (#14) | Tier 2 — SP | Tier 2 (no Dim_Instrument wiki in bundle) | OK |
| CountryID (#42) | Tier 1 — Customer.CustomerStatic | Tier 1 | OK |
| Bid (#28) | Tier 2 — SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | Tier 1 — Fact_CurrencyPriceWithSplit wiki IS in bundle, column is passthrough (`f.Bid`) | WRONG |
| IsBuy (#24) | Tier 1 — Trade.PositionTbl | Tier 1 | OK |
| ConvertRateIsBuy_1 (#30) | Tier 2 — SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | Tier 1 — upstream wiki present, direct passthrough | WRONG |

2 mismatches → base score 5. The systematic error: all 4 `Fact_CurrencyPriceWithSplit` passthrough columns (Bid, Ask, ConvertRateIsBuy_1, ConvertRateIsBuy_0) are tagged Tier 2 when the upstream wiki exists in the bundle and the SP does `SELECT f.Bid, f.Ask, f.ConvertRateIsBuy_1, f.ConvertRateIsBuy_0` — pure passthroughs.

Additionally, `OpenDateID` and `CloseDateID` pass through from Dim_Position (upstream wiki present) but are tagged Tier 2.

### Dimension 2 — Upstream Fidelity: **3/10**

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| PositionID | "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position." | "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position." | YES | — |
| RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer." | YES | — |
| GCID | "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction." | "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer." | YES | — |
| UserName | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer." | YES | — |
| OpenOccurred | "When position was persisted (mapped from Occurred in production). Default getutcdate()." | "When position was persisted (mapped from Occurred in production). Default getutcdate(). Passthrough from Dim_Position." | YES | — |
| CloseOccurred | "When close was persisted." | "When close was persisted. Passthrough from Dim_Position. 1900-01-01 for open positions." | MINOR | Added "1900-01-01 for open positions" not in upstream |
| InstrumentID | "FK to Trade.Instrument. Financial instrument being traded." | "FK to Trade.Instrument. Financial instrument being traded. Passthrough from Dim_Position." | YES | — |
| IsBuy | "1 = Long/Buy (profit when price rises), 0 = Short/Sell." | "1 = Long/Buy (profit when price rises), 0 = Short/Sell. Passthrough from Dim_Position." | YES | — |
| Leverage | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position." | YES | — |
| AmountInUnitsDecimal | "Position size in units/shares. Fractional lots." | "Position size in instrument units (e.g., shares, crypto coins). Fractional lots. Passthrough from Dim_Position." | NO | "units/shares" paraphrased to "instrument units (e.g., shares, crypto coins)" — added crypto coins not in upstream |
| CountryID | "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0." | "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. Passthrough from Dim_Customer." | YES | — |

Base score: 5 (1 paraphrased — AmountInUnitsDecimal).

**Missed inheritances**: 4 Fact_CurrencyPriceWithSplit columns (Bid, Ask, ConvertRateIsBuy_1, ConvertRateIsBuy_0) have upstream wikis in the bundle and are direct passthroughs but tagged Tier 2 instead of Tier 1. Additionally, config table columns from Dealing_Islamic_Admin_Fee_Per_Group (admin_fee_usd, grace_period), Dealing_Islamic_Instruments_Groups (instrument_group, name, instrument_type_id), and Dealing_Islamic_Units_Per_Contract (units_per_contract) — all have upstream wikis in the bundle. Counting the 4 most impactful (Fact_CurrencyPriceWithSplit): -8 → clamped to 3.

### Dimension 3 — Completeness: **10/10**

| Check | Status |
|-------|--------|
| All 8 sections present | YES |
| Element count matches DDL (42=42) | YES |
| Every element has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram | YES |
| Footer has tier breakdown counts | YES (counts are wrong: claims 8 T1 but actually 11 T1) |
| Section 1 has row count + date range | YES |
| Dictionary columns list key=value pairs | YES (InstrumentTypeID, IsBuy, etc.) |
| .review-needed.md has no ## 4. Elements | YES |

All 10 checks pass structurally → 10. Note: the footer tier counts are arithmetically wrong (see issues).

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent — names the domain (Islamic/swap-free accounts), specifies row grain (one position per customer per date), names the ETL SP, states refresh pattern (daily DELETE+INSERT per @Date), provides row count (17.9M), date range (2022-12-30 to present), customer/instrument counts, Islamic account identification criteria, position eligibility rules, and fee formula overview. A new analyst would know exactly when to query this table.

### Dimension 5 — Data Evidence: **7/10**

Row count (17.9M), date range (2022-12-30 to present), customer counts (~1,078), instrument counts (~773), fee distribution percentages (54% charged, 46% zero) all appear and look like live data. Phase Gate is not explicitly shown as P2/P3 checkboxes, but data claims are consistent with live sampling. Footer says "Phases: 11/14".

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1-8 present, tier legend in Section 4, real SQL samples in Section 7, footer format with quality score and phases-completed list. Minor deviations: no explicit Phase Gate Checklist section, tier counts in footer are wrong.

---

## Weighted Total

```
weighted = 0.25*5 + 0.20*3 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*8
         = 1.25 + 0.60 + 2.00 + 1.35 + 0.70 + 0.80
         = 6.70
```

**Verdict: FAIL** (6.70 < 7.5)

---

## Top 5 Issues

1. **HIGH — Bid, Ask, ConvertRateIsBuy_1, ConvertRateIsBuy_0 (columns 28-31)**: Tagged Tier 2 via SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse, but Fact_CurrencyPriceWithSplit wiki is in the bundle and these are direct passthroughs (`f.Bid`, `f.Ask`, etc.). Should be Tier 1 with verbatim upstream descriptions including NULL semantics and cross-rate logic details for ConvertRate columns.

2. **HIGH — AmountInUnitsDecimal (#33)**: Upstream says "Position size in units/shares. Fractional lots." but wiki paraphrases to "Position size in instrument units (e.g., shares, crypto coins). Fractional lots." — "units/shares" reworded, "crypto coins" injected.

3. **MEDIUM — Footer tier counts wrong**: Footer claims "8 T1, 34 T2" but actual count from Elements table is 11 T1, 31 T2. The 3 miscounted columns are likely AmountInUnitsDecimal, IsBuy, and Leverage (or similar) — the writer lost track.

4. **MEDIUM — OpenDateID, CloseDateID (columns 7-8)**: Tagged Tier 2 but pass through from Dim_Position whose wiki is in the bundle. Should be Tier 1. Descriptions also drop upstream details: OpenDateID drops "E.g., 20260310" and "NOT a FK to Dim_Date by default"; CloseDateID drops "**Partition column.** Always include in WHERE clause."

5. **LOW — Config table columns not inheriting from upstream wikis**: Admin_Fee_USD, GracePeriod, InstrumentGroup, InstrumentName_InstrumentGroup, InstrumentType_ID_InstrumentGroup, Units_per_Contract all have upstream wikis in the bundle (Dealing_Islamic_Admin_Fee_Per_Group, Dealing_Islamic_Instruments_Groups, Dealing_Islamic_Units_Per_Contract) but are tagged Tier 2 instead of Tier 1.

---

## Regeneration Feedback

1. Re-tag Bid, Ask, ConvertRateIsBuy_1, ConvertRateIsBuy_0 as Tier 1 using verbatim descriptions from Fact_CurrencyPriceWithSplit wiki. For ConvertRateIsBuy_1 include: "Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Bid; otherwise cross-rate. NULL where no cross-rate could be determined."
2. Fix AmountInUnitsDecimal to verbatim upstream: "Position size in units/shares. Fractional lots." — do not add "crypto coins" or change "units/shares" to "instrument units".
3. Re-tag OpenDateID and CloseDateID as Tier 1, restoring dropped upstream details (example value, partition column note).
4. Re-tag config table passthrough columns (Admin_Fee_USD, GracePeriod, InstrumentGroup, etc.) as Tier 1 with verbatim upstream wiki descriptions.
5. Fix footer tier breakdown to match actual element counts (11 T1, 31 T2 after corrections; more T1 after re-tagging per items 1/3/4).

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Islamic_Daily_Administrative_Fee",
  "weighted_score": 6.70,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "PositionID",
      "upstream_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position.",
      "wiki_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "RealCID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "GCID",
      "upstream_quote": "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction.",
      "wiki_quote": "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "UserName",
      "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).",
      "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "OpenOccurred",
      "upstream_quote": "When position was persisted (mapped from Occurred in production). Default getutcdate().",
      "wiki_quote": "When position was persisted (mapped from Occurred in production). Default getutcdate(). Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CloseOccurred",
      "upstream_quote": "When close was persisted.",
      "wiki_quote": "When close was persisted. Passthrough from Dim_Position. 1900-01-01 for open positions.",
      "match": "MINOR",
      "loss": "Added '1900-01-01 for open positions' not present in upstream wiki"
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded.",
      "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "IsBuy",
      "upstream_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell.",
      "wiki_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Leverage",
      "upstream_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.",
      "wiki_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "AmountInUnitsDecimal",
      "upstream_quote": "Position size in units/shares. Fractional lots.",
      "wiki_quote": "Position size in instrument units (e.g., shares, crypto coins). Fractional lots. Passthrough from Dim_Position.",
      "match": "NO",
      "loss": "Paraphrased 'units/shares' to 'instrument units (e.g., shares, crypto coins)' — injected 'crypto coins' not in upstream, changed wording"
    },
    {
      "column": "CountryID",
      "upstream_quote": "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0.",
      "wiki_quote": "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. Passthrough from Dim_Customer.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Bid, Ask, ConvertRateIsBuy_1, ConvertRateIsBuy_0 (columns 28-31)",
      "problem": "Tagged Tier 2 via SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse but Fact_CurrencyPriceWithSplit wiki IS in the bundle and these are direct passthroughs (SELECT f.Bid, f.Ask, etc.). Should be Tier 1 with verbatim upstream descriptions. ConvertRateIsBuy_1 drops NULL semantics and cross-rate logic details."
    },
    {
      "severity": "high",
      "column_or_section": "AmountInUnitsDecimal (#33)",
      "problem": "Upstream says 'Position size in units/shares. Fractional lots.' but wiki paraphrases to 'Position size in instrument units (e.g., shares, crypto coins). Fractional lots.' — rewording and injection of 'crypto coins' not in upstream."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Footer claims '8 T1, 34 T2' but actual element count is 11 T1, 31 T2. Three Tier 1 columns are miscounted."
    },
    {
      "severity": "medium",
      "column_or_section": "OpenDateID, CloseDateID (columns 7-8)",
      "problem": "Tagged Tier 2 but pass through from Dim_Position whose wiki is in the bundle. Should be Tier 1. OpenDateID drops 'E.g., 20260310' and 'NOT a FK to Dim_Date by default'. CloseDateID drops 'Partition column. Always include in WHERE clause.'"
    },
    {
      "severity": "low",
      "column_or_section": "Admin_Fee_USD, GracePeriod, InstrumentGroup, InstrumentName_InstrumentGroup, InstrumentType_ID_InstrumentGroup, Units_per_Contract",
      "problem": "Config table passthrough columns have upstream wikis in the bundle (Dealing_Islamic_Admin_Fee_Per_Group, Dealing_Islamic_Instruments_Groups, Dealing_Islamic_Units_Per_Contract) but are tagged Tier 2 instead of Tier 1."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag Bid, Ask, ConvertRateIsBuy_1, ConvertRateIsBuy_0 as Tier 1 using verbatim Fact_CurrencyPriceWithSplit wiki descriptions — include NULL semantics and cross-rate logic for ConvertRate columns. (2) Fix AmountInUnitsDecimal to verbatim upstream: 'Position size in units/shares. Fractional lots.' (3) Re-tag OpenDateID and CloseDateID as Tier 1 with full upstream descriptions including example value and partition column note. (4) Re-tag config table passthrough columns (Admin_Fee_USD, GracePeriod, InstrumentGroup, InstrumentName_InstrumentGroup, InstrumentType_ID_InstrumentGroup, Units_per_Contract) as Tier 1 with verbatim upstream wiki descriptions. (5) Fix footer tier breakdown to match actual element counts after re-tagging.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
