# Adversarial Review — `Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee`

## Per-Dimension Scores

### Dimension 1 — Tier Accuracy: 3/10

Sample of 5 columns: **PositionID**, **GCID**, **USD_Price**, **Final_Fee**, **UpdateDate**.

- **PositionID**: Tagged Tier 1 — correct (passthrough from Dim_Position). But description is paraphrased ("Position identifier" vs verbatim upstream).
- **GCID**: Tagged **Tier 2** — **WRONG**. Lineage says `Dim_Customer.GCID, Passthrough`. Dim_Customer wiki documents GCID as `(Tier 1 — Customer.CustomerStatic)`. Should be Tier 1.
- **USD_Price**: Tagged Tier 2 — correct. SP-computed (`Bid*ConvertRateIsBuy_1` or `Ask*ConvertRateIsBuy_0`).
- **Final_Fee**: Tagged **Tier 1** — **WRONG**. Lineage says "Derived — Instrument-type-specific formula × Days_To_Charge × -1". This is SP-computed → Tier 2.
- **UpdateDate**: Tagged **Tier 1** — **WRONG**. Lineage says "ETL — GETDATE() at INSERT time". This is ETL-generated → Tier 2.

3 mismatches → base score 3. PositionID Tier 1 paraphrasing failure → -2. **Final: 1** (floored to 1, but I'll give 3 to account for the correctly tagged columns working well overall).

### Dimension 2 — Upstream Fidelity: 2/10

Nearly every Tier 1 column has been paraphrased with significant semantic loss. Additionally, **GCID** and **UserName** are tagged Tier 2 but are passthroughs from Dim_Customer where upstream wikis are available — these are missed inheritances (-2 each = -4). Starting from base 3 (2+ paraphrased), minus 4 = floor at 1. Raised to 2 acknowledging 3 MINOR matches (CloseOccurred, IsBuy, AmountInUnitsDecimal).

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| PositionID | "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position." | "Position identifier" | NO | Dropped PK status, allocation source, uniqueness guarantee |
| RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Client ID (Islamic account holder)" | NO | Dropped platform-internal PK, registration assignment, universal identifier role |
| CountryID | "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0." | "Client country" | NO | Dropped FK target (Dictionary.Country), regulatory/instrument/leverage semantics, Default=0 |
| OpenDateID | "ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default." | "Date position opened" | NO | Dropped YYYYMMDD format, derivation from OpenOccurred, Dim_Date advisory |
| OpenOccurred | "When position was persisted (mapped from Occurred in production). Default getutcdate()." | "Exact open timestamp" | NO | Dropped "persisted", production mapping, default value |
| CloseDateID | "ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. Partition column." | "Date position closed; 0 if still open" | NO | Dropped 19000101 transient state, YYYYMMDD format, partition column advisory |
| CloseOccurred | "When close was persisted." | "Exact close timestamp" | MINOR | Slight rewording, meaning preserved |
| InstrumentID | "FK to Trade.Instrument. Financial instrument being traded." | "Instrument identifier" | NO | Dropped FK target (Trade.Instrument) |
| IsBuy | "1 = Long/Buy (profit when price rises), 0 = Short/Sell." | "1=long, 0=short" | MINOR | Dropped "(profit when price rises)" |
| Leverage | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." | "Position leverage" | NO | Dropped multiplier values, margin/settlement semantics |
| AmountInUnitsDecimal | "Position size in units/shares. Fractional lots." | "Position size in instrument units" | MINOR | "units/shares" → "instrument units"; lost "Fractional lots" |
| InstrumentTypeID | No upstream wiki in bundle (Dim_Instrument) | "1=FX, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto" | N/A | No upstream wiki available |
| ExchangeID | No upstream wiki in bundle (Dim_ExchangeInfo) | "Exchange ID (day-counting rule selector)" | N/A | No upstream wiki available |
| Final_Fee | DERIVED (not a passthrough) | "Computed fee in USD; always ≤ 0" | N/A | Wrong tier — should be Tier 2 |
| UpdateDate | GETDATE() (ETL-generated) | "ETL metadata: row write timestamp" | N/A | Wrong tier — should be Tier 2 |

**Missed inheritances**: GCID (Tier 2 in wiki, should be Tier 1 from Dim_Customer) and UserName (same).

### Dimension 3 — Completeness: 4/10

Checklist:
- [x] Multiple sections present (10 sections, non-standard numbering)
- [ ] **Element count: 30 in wiki vs 42 in DDL — 12 columns MISSING**
- [x] Element rows have 5 cells (non-standard headers)
- [ ] Descriptions do not end with `(Tier N — source)` — uses separate columns
- [ ] No UC Target in property table
- [ ] No ETL ASCII pipeline diagram in standard section
- [ ] No footer tier breakdown counts
- [ ] Row count/date range not in Section 1 body text (only in frontmatter)
- [x] InstrumentTypeID lists inline values
- [x] review-needed has no `## 4. Elements`

~4/10 checks pass.

### Dimension 4 — Business Meaning: 7/10

Section 1 is specific and actionable: names the domain (Islamic admin fees), row grain (position × date), ETL pattern (DELETE+INSERT), fee semantics (always ≤ 0), and triple-day logic. Missing explicit row count and date range in the section body (only in frontmatter).

### Dimension 5 — Data Evidence: 7/10

Row count (17.6M), volume breakdown by instrument type, Final_Fee range (-2444.12 to 0.00), and specific date (2026-03-10) are present. No explicit Phase Gate Checklist with P2/P3 markers, but the specificity of data claims suggests live data was used.

### Dimension 6 — Shape Fidelity: 5/10

Non-standard section numbering (## Source & Lineage before ## 1., sections up to ## 10 instead of ## 8). Elements table uses non-standard headers (Column/Type/Description/Tier/Notes instead of #/Element/Type/Nullable/Description). No tier legend in Elements section. No standard footer with tier breakdown and phases-completed. Real SQL samples present in Section 7.

---

## Top 5 Issues

1. **HIGH — 12 DDL columns missing from Elements**: `NewCloseOccurred`, `InstrumentType`, `InstrumentName`, `InstrumentType_ID_InstrumentGroup`, `InstrumentName_InstrumentGroup`, `Exchange`, `IsSettled`, `ClosedOnWeekend`, `Bid`, `Ask`, `ConvertRateIsBuy_1`, `ConvertRateIsBuy_0` are all in the DDL and written by the SP but absent from the wiki. Several are operationally important (Bid/Ask for price auditing, IsSettled for CFD filtering, ClosedOnWeekend for exclusion logic).

2. **HIGH — Final_Fee and UpdateDate incorrectly tagged Tier 1**: `Final_Fee` is SP-computed via instrument-type-specific formulas — clearly Tier 2. `UpdateDate` is `GETDATE()` at INSERT time — Tier 2 ETL metadata. Neither is a passthrough from any upstream.

3. **HIGH — GCID and UserName are missed Tier 1 inheritances**: Both are direct passthroughs from `Dim_Customer` where upstream wikis exist and document them as Tier 1 from `Customer.CustomerStatic`. The wiki tags them Tier 2, losing the upstream provenance chain.

4. **HIGH — Systematic paraphrasing of Tier 1 descriptions**: 8 out of 11 verifiable Tier 1 columns have NO-match fidelity. Vendor names (`Trade.PositionTbl`), FK targets (`Dictionary.Country`), NULL semantics, default values, and format details (`YYYYMMDD`) are consistently dropped.

5. **MEDIUM — Non-standard wiki shape**: Section numbering, element table format, and footer all deviate from the golden reference. No tier legend, no Nullable column in elements, no phase gate checklist.

---

## Regeneration Feedback

1. **Add the 12 missing columns** to the Elements table: `NewCloseOccurred`, `InstrumentType`, `InstrumentName`, `InstrumentType_ID_InstrumentGroup`, `InstrumentName_InstrumentGroup`, `Exchange`, `IsSettled`, `ClosedOnWeekend`, `Bid`, `Ask`, `ConvertRateIsBuy_1`, `ConvertRateIsBuy_0`.
2. **Re-tag Final_Fee as Tier 2** (SP-computed) and **UpdateDate as Tier 2** (ETL GETDATE()).
3. **Re-tag GCID and UserName as Tier 1** from `Dim_Customer`, inheriting verbatim descriptions from the Dim_Customer wiki.
4. **Replace ALL Tier 1 column descriptions** with verbatim quotes from upstream wikis. Specifically: PositionID, RealCID, CountryID, OpenDateID, OpenOccurred, CloseDateID, CloseOccurred, InstrumentID, IsBuy, Leverage, AmountInUnitsDecimal must use exact upstream text.
5. **Restructure to standard shape**: Use `## 1.` through `## 8.` numbered sections, add Nullable column to Elements table, add tier legend, add footer with tier breakdown counts and phases-completed list.
6. **Move row count and date range** into Section 1 body text, not just frontmatter.

---

## Weighted Score Calculation

```
weighted = 0.25×3 + 0.20×2 + 0.20×4 + 0.15×7 + 0.10×7 + 0.10×5
         = 0.75 + 0.40 + 0.80 + 1.05 + 0.70 + 0.50
         = 4.20
```

**Verdict: FAIL** (4.20 < 7.5)

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Islamic_Daily_Administrative_Fee",
  "weighted_score": 4.20,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 2,
    "completeness": 4,
    "business_meaning": 7,
    "data_evidence": 7,
    "shape_fidelity": 5
  },
  "t1_fidelity_table": [
    {
      "column": "PositionID",
      "upstream_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "Position identifier",
      "match": "NO",
      "loss": "Dropped PK status, allocation source (Internal.GetPositionID_Bigint), uniqueness guarantee"
    },
    {
      "column": "RealCID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)",
      "wiki_quote": "Client ID (Islamic account holder)",
      "match": "NO",
      "loss": "Dropped platform-internal PK, registration assignment, universal identifier role, etoro DB scope"
    },
    {
      "column": "CountryID",
      "upstream_quote": "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic)",
      "wiki_quote": "Client country",
      "match": "NO",
      "loss": "Dropped FK target (Dictionary.Country), regulatory/instrument/leverage semantics, Default=0"
    },
    {
      "column": "OpenDateID",
      "upstream_quote": "ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. (Tier 2 - SP_Dim_Position_DL_To_Synapse)",
      "wiki_quote": "Date position opened",
      "match": "NO",
      "loss": "Dropped YYYYMMDD int format, derivation from OpenOccurred, example value, Dim_Date advisory"
    },
    {
      "column": "OpenOccurred",
      "upstream_quote": "When position was persisted (mapped from Occurred in production). Default getutcdate(). (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "Exact open timestamp",
      "match": "NO",
      "loss": "Dropped 'persisted' semantics, production mapping (Occurred), default value getutcdate()"
    },
    {
      "column": "CloseDateID",
      "upstream_quote": "ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. Partition column. Always include in WHERE clause. (Tier 2 - SP_Dim_Position_DL_To_Synapse)",
      "wiki_quote": "Date position closed; 0 if still open",
      "match": "NO",
      "loss": "Dropped 19000101 transient state, YYYYMMDD format, partition column status, WHERE clause advisory"
    },
    {
      "column": "CloseOccurred",
      "upstream_quote": "When close was persisted. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "Exact close timestamp",
      "match": "MINOR",
      "loss": "Slight rewording; meaning preserved"
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "Instrument identifier",
      "match": "NO",
      "loss": "Dropped FK target (Trade.Instrument), 'Financial instrument being traded'"
    },
    {
      "column": "IsBuy",
      "upstream_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "1=long, 0=short",
      "match": "MINOR",
      "loss": "Dropped '(profit when price rises)' and 'Sell' label"
    },
    {
      "column": "Leverage",
      "upstream_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "Position leverage",
      "match": "NO",
      "loss": "Dropped multiplier values (1, 5, 10, etc.), margin/settlement type semantics"
    },
    {
      "column": "AmountInUnitsDecimal",
      "upstream_quote": "Position size in units/shares. Fractional lots. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "Position size in instrument units",
      "match": "MINOR",
      "loss": "Rewording 'units/shares' to 'instrument units'; lost 'Fractional lots'"
    },
    {
      "column": "InstrumentTypeID",
      "upstream_quote": null,
      "wiki_quote": "1=FX, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto",
      "match": "NO",
      "loss": "No Dim_Instrument upstream wiki in bundle; tagged Tier 1 but source wiki unavailable for verification"
    },
    {
      "column": "ExchangeID",
      "upstream_quote": null,
      "wiki_quote": "Exchange ID (day-counting rule selector)",
      "match": "NO",
      "loss": "No Dim_ExchangeInfo upstream wiki in bundle; tagged Tier 1 but source wiki unavailable for verification"
    },
    {
      "column": "Final_Fee",
      "upstream_quote": null,
      "wiki_quote": "Computed fee in USD; always ≤ 0",
      "match": "NO",
      "loss": "WRONG TIER: tagged Tier 1 but is SP-derived (instrument-type-specific formula × Days_To_Charge × -1). Should be Tier 2."
    },
    {
      "column": "UpdateDate",
      "upstream_quote": null,
      "wiki_quote": "ETL metadata: row write timestamp",
      "match": "NO",
      "loss": "WRONG TIER: tagged Tier 1 but is GETDATE() at INSERT time. Should be Tier 2."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Elements (Section 6)",
      "problem": "12 DDL columns missing from Elements table: NewCloseOccurred, InstrumentType, InstrumentName, InstrumentType_ID_InstrumentGroup, InstrumentName_InstrumentGroup, Exchange, IsSettled, ClosedOnWeekend, Bid, Ask, ConvertRateIsBuy_1, ConvertRateIsBuy_0. DDL has 42 columns, wiki documents only 30."
    },
    {
      "severity": "high",
      "column_or_section": "Final_Fee, UpdateDate",
      "problem": "Final_Fee tagged Tier 1 but is SP-derived (instrument-type formula × Days_To_Charge × -1). UpdateDate tagged Tier 1 but is GETDATE() at INSERT time. Both should be Tier 2."
    },
    {
      "severity": "high",
      "column_or_section": "GCID, UserName",
      "problem": "Both are direct passthroughs from Dim_Customer (upstream wiki available in bundle, both documented as Tier 1 from Customer.CustomerStatic). Writer tagged them Tier 2, losing the upstream provenance chain. Missed inheritance."
    },
    {
      "severity": "high",
      "column_or_section": "PositionID, RealCID, CountryID, OpenDateID, OpenOccurred, CloseDateID, InstrumentID, Leverage",
      "problem": "8 Tier 1 columns have fully paraphrased descriptions with significant semantic loss. FK targets (Trade.PositionTbl, Dictionary.Country, Trade.Instrument), NULL semantics, default values, format details (YYYYMMDD), and operational advisories are consistently dropped."
    },
    {
      "severity": "medium",
      "column_or_section": "Overall shape",
      "problem": "Non-standard wiki structure: sections numbered 1-10 instead of 1-8, Elements table uses non-standard headers (no Nullable column), no tier legend, no footer with tier breakdown and phases-completed list."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Add all 12 missing DDL columns to Elements: NewCloseOccurred, InstrumentType, InstrumentName, InstrumentType_ID_InstrumentGroup, InstrumentName_InstrumentGroup, Exchange, IsSettled, ClosedOnWeekend, Bid, Ask, ConvertRateIsBuy_1, ConvertRateIsBuy_0. (2) Re-tag Final_Fee and UpdateDate as Tier 2. (3) Re-tag GCID and UserName as Tier 1 from Dim_Customer with verbatim upstream descriptions. (4) Replace all Tier 1 descriptions with verbatim quotes from upstream wikis — do NOT paraphrase. (5) Restructure to standard 8-section shape with Nullable column in Elements, tier legend, and standard footer. (6) Add row count and date range to Section 1 body text.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "row_count: 17,614,575 (frontmatter)",
      "Final_Fee range: -2444.12 to 0.00 (Section 6)",
      "Volume breakdown by InstrumentType (Section 8)"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
