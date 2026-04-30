I'll review this wiki systematically against the rubric dimensions.

## Per-Dimension Evaluation

### Dimension 1 — Tier Accuracy (25%) — Score: 10

Five random columns sampled: CID, LastVisit, AssetAmount, DateID, InstrumentName.

| Column | Claimed | Expected | Match? |
|--------|---------|----------|--------|
| CID | Tier 1 — Customer.CustomerStatic | Tier 1 (passthrough rename from Fact_MarketPageViews.RealCID, root origin Customer.CustomerStatic via Dim_Customer) | YES |
| LastVisit | Tier 2 — Fact_MarketPageViews | Tier 2 (MAX aggregation on Occurred) | YES |
| AssetAmount | Tier 2 — Dim_Position | Tier 2 (SUM aggregation by InstrumentTypeID) | YES |
| DateID | Tier 2 — SP | Tier 2 (defensible — filtered passthrough from parameter-derived value) | YES |
| InstrumentName | Tier 1 — Trade.InstrumentMetaData | Tier 1 (rename of Dim_Instrument.SymbolFull, upstream wiki available) | YES |

0 mismatches → 10. No paraphrasing penalties applied here (those are in D2).

### Dimension 2 — Upstream Fidelity (20%) — Score: 3

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." (Dim_Customer.RealCID) | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Fact_MarketPageViews.RealCID (renamed)." | MINOR | Added ETL context; core verbatim |
| AccountId | "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced." (Dim_Customer.SalesForceAccountID) | "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Post-load UPDATE from Dim_Customer.SalesForceAccountID via JOIN on CID=RealCID." | MINOR | Added ETL context; core verbatim |
| InstrumentID | "Primary key from Trade.Instrument. Identifies the tradeable instrument pair." (Dim_Instrument.InstrumentID) | "FK to Dim_Instrument. Financial instrument being traded. Passthrough from Fact_MarketPageViews." | NO | Dropped "Primary key from Trade.Instrument"; replaced "Identifies the tradeable instrument pair" with "Financial instrument being traded" (likely copied from Dim_Position wiki instead) |
| InstrumentTypeID | "From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType." (Dim_Instrument.InstrumentTypeID) | "Asset class identifier from Dim_Instrument. 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto. FK to Dictionary.CurrencyType. Passthrough from Dim_Instrument via JOIN on InstrumentID." | NO | Dropped "From IMD (InstrumentMetaData)"; dropped enum values 3=CFD, 7=Bonds, 8=TrustFunds, 9=Options; changed labels (Forex→Currencies, Commodity→Commodities) |
| InstrumentName | "Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API." (Dim_Instrument.SymbolFull) | "Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API. Passthrough from Dim_Instrument.SymbolFull (renamed to InstrumentName)." | MINOR | Added ETL context; core verbatim |

2 paraphrased with semantic loss → **3**.

### Dimension 3 — Completeness (20%) — Score: 8

| Check | Pass? |
|-------|-------|
| All 8 sections present | YES |
| Element count = DDL (16/16) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Prod Source, Refresh, Distribution, UC Target | NO — missing UC Target |
| Section 5.2 ETL pipeline diagram | YES |
| Footer tier breakdown | YES |
| Section 1 row count + date range | YES |
| Dictionary columns list key=value pairs | YES (InstrumentTypeID) |
| .review-needed.md lacks ## 4. Elements | YES |

9/10 → **8**.

### Dimension 4 — Business Meaning (15%) — Score: 9

Section 1 is excellent: names the domain (Marketing Cloud SFTP export), row grain (CID, InstrumentID per DateID), ETL SP (SP_MarketingCloudUserBehavior), refresh pattern (daily rolling 1-month), row count (3.55M), date range (May 2024), and a detailed 6-step SP walkthrough. An analyst reading this would immediately know what the table is for and when to query it.

### Dimension 5 — Data Evidence (10%) — Score: 8

Strong data evidence: 3,551,713 row count, 722,211 distinct customers, 5,644 instruments, DateID range 20240502–20240531, 167 NULL AccountId rows. Footer says "Phases: 11/14" — no explicit Phase Gate Checklist section, but the specificity of claims (exact row counts, distinct counts, NULL counts) indicates real data access. Minor deduction for no explicit P2/P3 checklist.

### Dimension 6 — Shape Fidelity (10%) — Score: 9

All structural elements present: numbered sections 1–8, tier legend in Section 4, real SQL samples in Section 7, footer with quality score and phases-completed. Tier legend only lists Tier 1/2 (appropriate since no T3–T5 used). Minor: no Phase Gate Checklist section explicitly.

---

## Weighted Total

```
weighted = 0.25*10 + 0.20*3 + 0.20*8 + 0.15*9 + 0.10*8 + 0.10*9
         = 2.50 + 0.60 + 1.60 + 1.35 + 0.80 + 0.90
         = 7.75
```

**Verdict: PASS** (7.75 ≥ 7.5)

---

## Top 5 Issues

1. **HIGH — InstrumentTypeID paraphrased**: Dropped 4 enum values (3=CFD, 7=Bonds, 8=TrustFunds, 9=Options), changed labels (Forex→Currencies, Commodity→Commodities), dropped "From IMD (InstrumentMetaData)" source attribution.

2. **HIGH — InstrumentID paraphrased**: "Primary key from Trade.Instrument. Identifies the tradeable instrument pair." replaced with "FK to Dim_Instrument. Financial instrument being traded." — writer appears to have copied from the Dim_Position wiki instead of the Dim_Instrument wiki.

3. **MEDIUM — Missing UC Target**: Property table omits the UC Target line, which is a standard completeness item.

4. **LOW — No Phase Gate Checklist**: The wiki has no explicit Phase Gate section showing which validation phases were completed (P1–P5). Footer implies 11/14 phases but doesn't itemize.

5. **LOW — "LastMonth" column naming caveat could be stronger**: The writer correctly documents the misnomer but it's buried in business logic and gotchas rather than surfaced prominently in the element description with a warning prefix.

---

## Regeneration Feedback

1. Replace `InstrumentID` description with verbatim from Dim_Instrument wiki: `"Primary key from Trade.Instrument. Identifies the tradeable instrument pair."` then append passthrough context.
2. Replace `InstrumentTypeID` description with verbatim from Dim_Instrument wiki: `"From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType."` then append passthrough context.
3. Add UC Target to the property table (or note if none exists).
4. Add explicit Phase Gate Checklist section showing P1–P5 completion status.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_MarketingCloudUserBehaviorInstrument",
  "weighted_score": 7.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 3,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Fact_MarketPageViews.RealCID (renamed).",
      "match": "MINOR",
      "loss": "Added ETL context; core description verbatim"
    },
    {
      "column": "AccountId",
      "upstream_quote": "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced.",
      "wiki_quote": "Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Post-load UPDATE from Dim_Customer.SalesForceAccountID via JOIN on CID=RealCID.",
      "match": "MINOR",
      "loss": "Added ETL context; core description verbatim"
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "Primary key from Trade.Instrument. Identifies the tradeable instrument pair.",
      "wiki_quote": "FK to Dim_Instrument. Financial instrument being traded. Passthrough from Fact_MarketPageViews.",
      "match": "NO",
      "loss": "Dropped 'Primary key from Trade.Instrument'; replaced 'Identifies the tradeable instrument pair' with 'Financial instrument being traded' (likely copied from Dim_Position wiki instead of Dim_Instrument wiki)"
    },
    {
      "column": "InstrumentTypeID",
      "upstream_quote": "From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType.",
      "wiki_quote": "Asset class identifier from Dim_Instrument. 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto. FK to Dictionary.CurrencyType. Passthrough from Dim_Instrument via JOIN on InstrumentID.",
      "match": "NO",
      "loss": "Dropped 'From IMD (InstrumentMetaData)' source; dropped 4 enum values (3=CFD, 7=Bonds, 8=TrustFunds, 9=Options); changed labels (Forex→Currencies, Commodity→Commodities)"
    },
    {
      "column": "InstrumentName",
      "upstream_quote": "Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API.",
      "wiki_quote": "Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API. Passthrough from Dim_Instrument.SymbolFull (renamed to InstrumentName).",
      "match": "MINOR",
      "loss": "Added ETL context; core description verbatim"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "InstrumentTypeID",
      "problem": "Paraphrased Tier 1 description: dropped 4 enum values (3=CFD, 7=Bonds, 8=TrustFunds, 9=Options), changed labels (Forex→Currencies, Commodity→Commodities), dropped 'From IMD (InstrumentMetaData)' source attribution. Must use Dim_Instrument wiki verbatim."
    },
    {
      "severity": "high",
      "column_or_section": "InstrumentID",
      "problem": "Paraphrased Tier 1 description: 'Primary key from Trade.Instrument. Identifies the tradeable instrument pair.' replaced with 'FK to Dim_Instrument. Financial instrument being traded.' Writer appears to have sourced from Dim_Position wiki instead of Dim_Instrument wiki."
    },
    {
      "severity": "medium",
      "column_or_section": "Property Table",
      "problem": "Missing UC Target row in property table — standard completeness item."
    },
    {
      "severity": "low",
      "column_or_section": "Shape",
      "problem": "No explicit Phase Gate Checklist section (P1–P5). Footer says 11/14 phases but doesn't itemize which were completed."
    },
    {
      "severity": "low",
      "column_or_section": "LastMonthAmountInvest",
      "problem": "The 'current month not previous month' caveat is documented in business logic and gotchas but could be more prominent in the element description with a warning prefix."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Replace InstrumentID description with verbatim from Dim_Instrument wiki: 'Primary key from Trade.Instrument. Identifies the tradeable instrument pair.' then append passthrough context. (2) Replace InstrumentTypeID description with verbatim from Dim_Instrument wiki: 'From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType.' then append passthrough context. (3) Add UC Target to property table. (4) Add explicit Phase Gate Checklist section.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase Gate Checklist not present as explicit section"]
  }
}
</JUDGE_VERDICT>
