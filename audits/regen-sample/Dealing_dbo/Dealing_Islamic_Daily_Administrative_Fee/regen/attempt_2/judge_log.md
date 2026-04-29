## Adversarial Review: Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Random sample of 5 columns (PositionID, InstrumentTypeID, IsBuy, Bid, CountryID) — all correctly tiered. Dim-lookup passthroughs with upstream wikis correctly trace to the dim's production origin (e.g., Trade.PositionTbl via Dim_Position). Columns without upstream wikis (InstrumentTypeID, Exchange, ExchangeID) correctly marked Tier 2. Two non-sampled columns are arguably mis-tiered (see issues below) but didn't hit the random check.

**Dimension 2 — Upstream Fidelity: 9/10**
All 23 Tier 1 columns preserve the upstream description verbatim. The only differences are appended "Passthrough from X" annotations and added NULL semantics notes — both are additive, not lossy. ConvertRateIsBuy_1/0 dropped "Added 2023-02-26" metadata — trivial. No vendor names dropped, no FK targets removed, no semantic paraphrasing.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 42 elements match DDL exactly. Every element row has 5 cells with Tier tags. Property table complete. ETL pipeline diagram with real SP/table names. Footer has tier breakdown. Section 1 has row count (17.9M) and date range (2022-12-30 to present). Dictionary columns list inline values. Review-needed sidecar does not contain Section 4.

**Dimension 4 — Business Meaning: 10/10**
Section 1 is exceptional — names domain (Islamic swap-free accounts), specifies row grain (one position × one customer × one date), names ETL SP, describes DELETE+INSERT pattern, gives row count, date range, customer/instrument cardinality, Islamic account identification criteria, position eligibility rules, and references fee formula. A new analyst could immediately understand when and how to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count (17.9M), date range, cardinality stats (~1,078 customers, ~773 instruments), fee distribution (~54% charged), fee ranges ($0.10–$80.00) all present. No explicit Phase Gate Checklist with P2/P3 checkboxes, though footer says "Phases: 11/14". Data claims appear genuine but without the checklist, cannot confirm P2/P3 were executed vs. inferred.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown all present. Minor deviations: tier legend uses a simplified format (no Stars column), no explicit Phase Gate Checklist section.

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| PositionID | "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position." | "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer." | MINOR | Added passthrough note |
| GCID | "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction." | "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer." | MINOR | Added passthrough note |
| UserName | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer." | MINOR | Added passthrough note |
| OpenDateID | "ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default." | "ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| CloseDateID | "ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. **Partition column.** Always include in WHERE clause." | "ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. **Partition column.** Always include in WHERE clause. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| OpenOccurred | "When position was persisted (mapped from Occurred in production). Default getutcdate()." | "When position was persisted (mapped from Occurred in production). Default getutcdate(). Passthrough from Dim_Position." | MINOR | Added passthrough note |
| CloseOccurred | "When close was persisted." | "When close was persisted. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| InstrumentID | "FK to Trade.Instrument. Financial instrument being traded." | "FK to Trade.Instrument. Financial instrument being traded. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| InstrumentType_ID_InstrumentGroup | "Asset class: 1=Currencies, 2=Commodities, 4=Indices." | "Asset class: 1=Currencies, 2=Commodities, 4=Indices. NULL for Stocks/ETF/Crypto (not mapped in Dealing_Islamic_Instruments_Groups). Passthrough from Dealing_Islamic_Instruments_Groups.instrument_type_id." | MINOR | Added NULL semantics (additive) |
| InstrumentName_InstrumentGroup | "Instrument name (e.g., \"EUR/USD\", \"GBP/USD\"). From manual configuration." | "Instrument name (e.g., \"EUR/USD\", \"GBP/USD\"). From manual configuration. NULL for Stocks/ETF/Crypto. Passthrough from Dealing_Islamic_Instruments_Groups.name." | MINOR | Added NULL note |
| InstrumentGroup | "Fee tier group (1-4). Maps to `Dealing_Islamic_Admin_Fee_Per_Group.instrument_group` for fee rate lookup." | "Fee tier group (1-4). Maps to `Dealing_Islamic_Admin_Fee_Per_Group.instrument_group` for fee rate lookup. NULL for Stocks/ETF/Crypto. Passthrough from Dealing_Islamic_Instruments_Groups.instrument_group." | MINOR | Added NULL note |
| Units_per_Contract | "Number of instrument units in one standard contract. Used as divisor in commodity fee calculation. E.g., XTI=1000 barrels, XAG=5000 ounces." | "Number of instrument units in one standard contract. Used as divisor in commodity fee calculation. E.g., XTI=1000 barrels, XAG=5000 ounces. NULL for non-commodity instruments. Passthrough from Dealing_Islamic_Units_Per_Contract.units_per_contract." | MINOR | Added NULL note |
| IsBuy | "1 = Long/Buy (profit when price rises), 0 = Short/Sell." | "1 = Long/Buy (profit when price rises), 0 = Short/Sell. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| Leverage | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| Bid | "Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread." | "Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread. Passthrough from Fact_CurrencyPriceWithSplit." | MINOR | Added passthrough note |
| Ask | "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread." | "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. Passthrough from Fact_CurrencyPriceWithSplit." | MINOR | Added passthrough note |
| ConvertRateIsBuy_1 | "Pre-computed USD conversion rate for buy-side positions (IsBuy=1). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Bid; otherwise cross-rate. NULL where no cross-rate could be determined. Added 2023-02-26." | "Pre-computed USD conversion rate for buy-side positions (IsBuy=1). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Bid; otherwise cross-rate. NULL where no cross-rate could be determined. Passthrough from Fact_CurrencyPriceWithSplit." | MINOR | Dropped "Added 2023-02-26" metadata |
| ConvertRateIsBuy_0 | "Pre-computed USD conversion rate for sell-side positions (IsBuy=0). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Ask; otherwise cross-rate. NULL where no cross-rate could be determined. Added 2023-02-26." | "Pre-computed USD conversion rate for sell-side positions (IsBuy=0). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Ask; otherwise cross-rate. NULL where no cross-rate could be determined. Passthrough from Fact_CurrencyPriceWithSplit." | MINOR | Dropped "Added 2023-02-26" metadata |
| AmountInUnitsDecimal | "Position size in units/shares. Fractional lots." | "Position size in units/shares. Fractional lots. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| Admin_Fee_USD | "Administrative fee amount in USD. Applied per unit/contract/10K-USD-value depending on asset class. Ranges: $0.10 (Index group 3) to $80.00 (Currency group 4)." | "Administrative fee amount in USD. Applied per unit/contract/10K-USD-value depending on asset class. Ranges: $0.10 (Index group 3) to $80.00 (Currency group 4). NULL for Stocks/ETF/Crypto without group mapping. Passthrough from Dealing_Islamic_Admin_Fee_Per_Group." | MINOR | Added NULL note |
| GracePeriod | "Number of trading days before fee starts. Currently 7 for all groups." | "Number of trading days before fee starts. Currently 7 for all groups. Passthrough from Dealing_Islamic_Admin_Fee_Per_Group.grace_period." | MINOR | Added passthrough note |
| CountryID | "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0." | "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. Passthrough from Dim_Customer." | MINOR | Added passthrough note |

---

### Top 5 Issues

1. **NewCloseOccurred (#12) mis-tiered as Tier 2** — SP code shows `dp.CloseOccurred AS NewCloseOccurred`, a literal alias/passthrough from Dim_Position. With the Dim_Position wiki available, this should be Tier 1 — Trade.PositionTbl, not Tier 2. The description even acknowledges "Currently identical to CloseOccurred (no transformation applied)."

2. **IsSettled (#26) mis-tiered as Tier 2** — SP code shows `dp.IsSettled`, a direct passthrough from Dim_Position. The upstream wiki exists and documents it (as Tier 5 — Expert Review). Per rules, passthrough with upstream wiki present → Tier 1. The writer correctly notes "Always 0 in this table" but should still tag it Tier 1 with the upstream origin.

3. **OpenDateID (#7) and CloseDateID (#8) origin attribution** — Tagged "Tier 1 — Dim_Position" but the rules state dim-lookup passthroughs should NOT use "Tier 1 via Dim_X". These columns are ETL-computed within Dim_Position (Tier 2 in the upstream wiki), so the origin should reference the dim's own computation source rather than just "Dim_Position".

4. **No explicit Phase Gate Checklist** — The footer mentions "Phases: 11/14" but there's no dedicated Phase Gate Checklist section with P2/P3 checkboxes. Data claims appear genuine but cannot be formally verified against phase completion.

5. **InstrumentTypeID (#14) placed in "Group C: Fee Timing"** — InstrumentTypeID is an instrument attribute, not a fee timing column. It would fit better in "Group D: Instrument Details" alongside InstrumentType, InstrumentName, etc. This is a grouping/organizational issue, not a correctness issue.

---

### Regeneration Feedback

1. Re-tag **NewCloseOccurred** as `(Tier 1 — Trade.PositionTbl)` — it's a passthrough alias of Dim_Position.CloseOccurred with no transformation.
2. Re-tag **IsSettled** as `(Tier 1 — Trade.PositionTbl)` or note the upstream's Tier 5 uncertainty — it's a direct passthrough from Dim_Position with upstream wiki available.
3. Change **OpenDateID** and **CloseDateID** origin from `Tier 1 — Dim_Position` to `Tier 1 — SP_Dim_Position_DL_To_Synapse` (or accept them as Tier 2 since they're ETL-computed in the dim itself, not production-sourced).
4. Add an explicit Phase Gate Checklist section showing which phases (P1–P3) were completed.
5. Move **InstrumentTypeID** from "Group C: Fee Timing" to "Group D: Instrument Details" for logical grouping consistency.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Islamic_Daily_Administrative_Fee",
  "weighted_score": 9.3,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {"column": "PositionID", "upstream_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position.", "wiki_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position.", "match": "MINOR", "loss": "Added passthrough note (additive, no loss)"},
    {"column": "RealCID", "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.", "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "GCID", "upstream_quote": "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction.", "wiki_quote": "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "UserName", "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).", "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "OpenDateID", "upstream_quote": "ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default.", "wiki_quote": "ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. Passthrough from Dim_Position.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "CloseDateID", "upstream_quote": "ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. **Partition column.** Always include in WHERE clause.", "wiki_quote": "ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. **Partition column.** Always include in WHERE clause. Passthrough from Dim_Position.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "OpenOccurred", "upstream_quote": "When position was persisted (mapped from Occurred in production). Default getutcdate().", "wiki_quote": "When position was persisted (mapped from Occurred in production). Default getutcdate(). Passthrough from Dim_Position.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "CloseOccurred", "upstream_quote": "When close was persisted.", "wiki_quote": "When close was persisted. Passthrough from Dim_Position.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "InstrumentID", "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded.", "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded. Passthrough from Dim_Position.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "InstrumentType_ID_InstrumentGroup", "upstream_quote": "Asset class: 1=Currencies, 2=Commodities, 4=Indices.", "wiki_quote": "Asset class: 1=Currencies, 2=Commodities, 4=Indices. NULL for Stocks/ETF/Crypto (not mapped in Dealing_Islamic_Instruments_Groups). Passthrough from Dealing_Islamic_Instruments_Groups.instrument_type_id.", "match": "MINOR", "loss": "Added NULL semantics (additive)"},
    {"column": "InstrumentName_InstrumentGroup", "upstream_quote": "Instrument name (e.g., \"EUR/USD\", \"GBP/USD\"). From manual configuration.", "wiki_quote": "Instrument name (e.g., \"EUR/USD\", \"GBP/USD\"). From manual configuration. NULL for Stocks/ETF/Crypto. Passthrough from Dealing_Islamic_Instruments_Groups.name.", "match": "MINOR", "loss": "Added NULL note"},
    {"column": "InstrumentGroup", "upstream_quote": "Fee tier group (1-4). Maps to Dealing_Islamic_Admin_Fee_Per_Group.instrument_group for fee rate lookup.", "wiki_quote": "Fee tier group (1-4). Maps to Dealing_Islamic_Admin_Fee_Per_Group.instrument_group for fee rate lookup. NULL for Stocks/ETF/Crypto. Passthrough from Dealing_Islamic_Instruments_Groups.instrument_group.", "match": "MINOR", "loss": "Added NULL note"},
    {"column": "Units_per_Contract", "upstream_quote": "Number of instrument units in one standard contract. Used as divisor in commodity fee calculation. E.g., XTI=1000 barrels, XAG=5000 ounces.", "wiki_quote": "Number of instrument units in one standard contract. Used as divisor in commodity fee calculation. E.g., XTI=1000 barrels, XAG=5000 ounces. NULL for non-commodity instruments. Passthrough from Dealing_Islamic_Units_Per_Contract.units_per_contract.", "match": "MINOR", "loss": "Added NULL note"},
    {"column": "IsBuy", "upstream_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell.", "wiki_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell. Passthrough from Dim_Position.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "Leverage", "upstream_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.", "wiki_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "Bid", "upstream_quote": "Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread.", "wiki_quote": "Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread. Passthrough from Fact_CurrencyPriceWithSplit.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "Ask", "upstream_quote": "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread.", "wiki_quote": "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. Passthrough from Fact_CurrencyPriceWithSplit.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "ConvertRateIsBuy_1", "upstream_quote": "Pre-computed USD conversion rate for buy-side positions (IsBuy=1). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Bid; otherwise cross-rate. NULL where no cross-rate could be determined. Added 2023-02-26.", "wiki_quote": "Pre-computed USD conversion rate for buy-side positions (IsBuy=1). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Bid; otherwise cross-rate. NULL where no cross-rate could be determined. Passthrough from Fact_CurrencyPriceWithSplit.", "match": "MINOR", "loss": "Dropped 'Added 2023-02-26' metadata"},
    {"column": "ConvertRateIsBuy_0", "upstream_quote": "Pre-computed USD conversion rate for sell-side positions (IsBuy=0). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Ask; otherwise cross-rate. NULL where no cross-rate could be determined. Added 2023-02-26.", "wiki_quote": "Pre-computed USD conversion rate for sell-side positions (IsBuy=0). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Ask; otherwise cross-rate. NULL where no cross-rate could be determined. Passthrough from Fact_CurrencyPriceWithSplit.", "match": "MINOR", "loss": "Dropped 'Added 2023-02-26' metadata"},
    {"column": "AmountInUnitsDecimal", "upstream_quote": "Position size in units/shares. Fractional lots.", "wiki_quote": "Position size in units/shares. Fractional lots. Passthrough from Dim_Position.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "Admin_Fee_USD", "upstream_quote": "Administrative fee amount in USD. Applied per unit/contract/10K-USD-value depending on asset class. Ranges: $0.10 (Index group 3) to $80.00 (Currency group 4).", "wiki_quote": "Administrative fee amount in USD. Applied per unit/contract/10K-USD-value depending on asset class. Ranges: $0.10 (Index group 3) to $80.00 (Currency group 4). NULL for Stocks/ETF/Crypto without group mapping. Passthrough from Dealing_Islamic_Admin_Fee_Per_Group.", "match": "MINOR", "loss": "Added NULL note"},
    {"column": "GracePeriod", "upstream_quote": "Number of trading days before fee starts. Currently 7 for all groups.", "wiki_quote": "Number of trading days before fee starts. Currently 7 for all groups. Passthrough from Dealing_Islamic_Admin_Fee_Per_Group.grace_period.", "match": "MINOR", "loss": "Added passthrough note"},
    {"column": "CountryID", "upstream_quote": "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0.", "wiki_quote": "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. Passthrough from Dim_Customer.", "match": "MINOR", "loss": "Added passthrough note"}
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "NewCloseOccurred (#12)",
      "problem": "Tagged Tier 2 (SP_Islamic_Administrative_Fee) but SP code shows `dp.CloseOccurred AS NewCloseOccurred` — a literal alias passthrough from Dim_Position. With Dim_Position wiki available, this should be Tier 1 — Trade.PositionTbl. The description itself acknowledges 'Currently identical to CloseOccurred (no transformation applied).'"
    },
    {
      "severity": "medium",
      "column_or_section": "IsSettled (#26)",
      "problem": "Tagged Tier 2 (SP_Islamic_Administrative_Fee) but SP code shows `dp.IsSettled` — direct passthrough from Dim_Position. Upstream wiki exists and documents this column (as Tier 5 — Expert Review). Per tier rules, passthrough with upstream wiki present should be Tier 1, not Tier 2."
    },
    {
      "severity": "low",
      "column_or_section": "OpenDateID (#7), CloseDateID (#8)",
      "problem": "Tagged 'Tier 1 — Dim_Position' but the dim-lookup passthrough rule says NOT to use 'Tier 1 via Dim_X'. These are ETL-computed in Dim_Position (Tier 2 in the upstream wiki). The origin attribution is inconsistent with other columns that correctly trace to production origins (e.g., Trade.PositionTbl)."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / Footer",
      "problem": "No explicit Phase Gate Checklist with P2/P3 checkboxes. Footer shows 'Phases: 11/14' but there is no way to verify which phases were completed or skipped. Data claims appear genuine but lack formal verification."
    },
    {
      "severity": "low",
      "column_or_section": "InstrumentTypeID (#14) — Group C",
      "problem": "Placed in 'Group C: Fee Timing' but InstrumentTypeID is an instrument attribute (asset class identifier), not a fee timing column. Should logically be in 'Group D: Instrument Details' alongside InstrumentType, InstrumentName, etc."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Re-tag NewCloseOccurred as Tier 1 — Trade.PositionTbl (it is a literal alias passthrough). (2) Re-tag IsSettled as Tier 1 with appropriate upstream origin or note the Tier 5 uncertainty from Dim_Position. (3) Resolve OpenDateID/CloseDateID origin attribution — either use the dim's computation source or accept as Tier 2. (4) Add explicit Phase Gate Checklist section. (5) Move InstrumentTypeID from Group C to Group D.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase Gate Checklist not present — cannot verify P2/P3 status"]
  }
}
</JUDGE_VERDICT>
