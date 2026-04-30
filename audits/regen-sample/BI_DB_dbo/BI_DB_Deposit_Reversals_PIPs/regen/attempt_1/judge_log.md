## Human-Readable Summary

### Per-Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Tier Accuracy (25%) | 5 | 1 clear tier mismatch: `Label` is tagged Tier 2 but is a dim-lookup passthrough (`dpl.Name AS [Label]` from `Dim_PlayerLevel`) — must be Tier 1 — Dictionary.PlayerLevel. Two paraphrase failures deduct 4 additional points: `Currency` introduces factually wrong terminology ("ISO currency abbreviation"), `PlayerStatus` drops critical RTRIM gotcha. |
| Upstream Fidelity (20%) | 3 | 9 of 14 Tier 1 columns are paraphrased rather than quoted verbatim from upstream wikis. Most serious: `Currency` adds "ISO currency abbreviation" (wrong — tickers like AAPL.US are NOT ISO currency codes); `ExchangeRate` adds "rollback tracking" as a source but SP code shows ONLY `BDEP.ExchangeRate` (Fact_BillingDeposit); `PlayerStatus` drops the operational RTRIM gotcha. |
| Completeness (20%) | 8 | All 8 sections present, 37/37 elements, every row has 5 cells + tier tag, ETL diagram present, data claims in Section 1. One failure: footer says "12 T1, 25 T2" but the actual Elements table has 14 Tier 1 and 23 Tier 2 (review-needed sidecar also lists 14 names but says "12 columns"). |
| Business Meaning (15%) | 9 | Excellent — names the row grain, the temporary BO replication rationale, source tables, PIPs ratio logic, row count, and date range in Section 1. |
| Data Evidence (10%) | 8 | Specific row count (8,817), date range, TransactionType distribution (60%/30%), sentinel values documented. Phases 11/14 completed with real data sampling evident. |
| Shape Fidelity (10%) | 8 | Well-structured; real SQL samples; footer present. Minor: footer tier counts are wrong; tier legend omits Tier 3–5 rows (acceptable since none are used). |

### Weighted Score

```
0.25×5 + 0.20×3 + 0.20×8 + 0.15×9 + 0.10×8 + 0.10×8 = 1.25 + 0.60 + 1.60 + 1.35 + 0.80 + 0.80 = 6.40
```

**Verdict: FAIL**

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID (RealCID). Hash distribution key. References Dim_Customer." | NO | Drops platform-primary-key context, registration origin, universal-identifier role; adds DWH-specific distribution note |
| Customer | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format." | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format." | YES | — |
| Currency | "Ticker symbol. 'USD', 'EUR' for forex; 'AAPL.US', 'TSLA.US' for US stocks (format: TICKER.EXCHANGE); 'BTC' for crypto. Unique across all instruments. Use this for human-readable instrument identification." | "Ticker symbol / ISO currency abbreviation. Resolved via Dim_Currency.Abbreviation on CurrencyID." | NO | Introduces factually wrong term "ISO currency abbreviation" — eToro tickers are NOT ISO codes for stocks (AAPL.US is a ticker, not an ISO currency code). Drops examples, exchange-format info, uniqueness note. |
| ExchangeRate | "Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production." (Fact_BillingDeposit.ExchangeRate) | "Exchange rate from rollback tracking or Fact_BillingDeposit. Cannot be 0 in production." | NO | Incorrectly adds "rollback tracking" — SP source code shows ONLY `BDEP.ExchangeRate` (Fact_BillingDeposit). Also drops "from deposit currency to USD at processing time." |
| RegulationID | "Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. FK to Dim_Regulation." | "Customer's regulatory jurisdiction from Fact_SnapshotCustomer at event date. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, etc. FK to Dim_Regulation." | MINOR | Drops end-of-day change semantics; truncates enum (9 regulation IDs missing) |
| PlayerLevelID | "Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (excluded), 5=Silver, 6=Platinum Plus, 7=Diamond. 0=N/A (DWH ETL placeholder). IDs are NOT in rank order -- use Sort for ordering." | "eToro Club loyalty tier from Fact_SnapshotCustomer. 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond, 4=Internal (excluded). FK to Dim_PlayerLevel." | MINOR | Drops "IDs are NOT in rank order -- use Sort for ordering" (important sort gotcha); drops "0=N/A (DWH ETL placeholder)" |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Regulation short code resolved via Dim_Regulation.Name." | MINOR | Drops usage context and production-match guarantee |
| BaseExchangeRate | "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Added by Adi (19/09/2019)." | "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate." | MINOR | Drops attribution metadata only |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | "eToro Club tier name. Resolved via Dim_PlayerLevel.Name on PlayerLevelID. 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond." | NO | Mixes in ID-to-name mapping from the PlayerLevelID element (not the Name element); drops "Internal, N/A" values; drops usage context |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." | "Account restriction state name. Resolved via Dim_PlayerStatus.Name on PlayerStatusID from Fact_SnapshotCustomer." | NO | Drops critical operational gotcha about trailing spaces (RTRIM); drops "Unique per status"; drops BackOffice usage context |
| RegCountry | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Registration country name resolved via Dim_Country.Name on Fact_SnapshotCustomer.CountryID." | NO | "Full country name in English" → "Registration country name"; drops uniqueness and usage context |
| RegCountryByIP | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Country detected from customer IP at registration. Resolved via Dim_Country.Name on Dim_Customer.CountryIDByIP." | NO | Same as RegCountry pattern; drops "Full country name in English" and uniqueness note |
| CardType | "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, ..., 17=GE Capital." | "Card network brand name. Resolved via Dim_CardType.CarTypeName on Fact_BillingDeposit.CardTypeIDAsInteger. Active: 1=Visa, 2=Master Card, 3=Diners, 8=Maestro." | NO | "Card brand name" → "Card network brand name"; drops full 18-value enum, unique-constraint warning, "Renamed from Name in production" |
| BinCountry | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Country of the card BIN resolved via Dim_Country.Name on Fact_BillingDeposit.BinCountryIDAsInteger." | NO | Same Dim_Country.Name pattern; drops "Full country name in English" and uniqueness note |

---

### Top 5 Issues

1. **[HIGH] Currency — Factually wrong description**: Wiki says "Ticker symbol / ISO currency abbreviation" but `Dim_Currency.Abbreviation` contains instrument tickers including stock tickers like `AAPL.US`, `TSLA.US` — these are NOT ISO currency abbreviations. An analyst expecting ISO codes would fail to join correctly against currency lookup tables.

2. **[HIGH] PlayerStatus — Critical RTRIM gotcha dropped**: `Dim_PlayerStatus.Name` upstream wiki explicitly warns: "some values have trailing spaces in live data -- apply RTRIM() for string comparisons." Wiki drops this entirely. Analysts filtering on PlayerStatus string values would silently get wrong results.

3. **[HIGH] ExchangeRate — Wrong source attribution**: Wiki says "Exchange rate from rollback tracking or Fact_BillingDeposit." SP source code (line `BDEP.ExchangeRate`) shows `ExchangeRate` comes ONLY from `Fact_BillingDeposit`. The rollback tracking table (`#depositRollbacks`) is used only for `ExchangeFee`, `Amount`, and `RollbackAmountInUSD` — NOT for `ExchangeRate`. The lineage file has the same error.

4. **[MEDIUM] Label — Tier 2 mismatch**: `Label` is tagged `(Tier 2 — SP_Deposit_Reversals_PIPs)` but the SP does `dpl.Name AS [Label]` with an explicit `JOIN DWH_dbo.Dim_PlayerLevel dpl ON f1.PlayerLevelID = dpl.PlayerLevelID`. This is a dim-lookup passthrough and must be `(Tier 1 — Dictionary.PlayerLevel)` per the tier rules, citing the quirk in the description.

5. **[MEDIUM] Footer tier counts wrong**: Footer says "12 T1, 25 T2" but the Elements table has 14 Tier 1 columns (CID, Customer, Currency, ExchangeRate, RegulationID, PlayerLevelID, Regulation, BaseExchangeRate, Club, PlayerStatus, RegCountry, RegCountryByIP, CardType, BinCountry) and 23 Tier 2 columns. The review-needed sidecar lists 14 names after "12 columns" — an internal inconsistency in both files.

---

### Regeneration Feedback (Numbered)

1. **Fix Currency (row 12)**: Replace "Ticker symbol / ISO currency abbreviation" with the verbatim upstream quote from `Dim_Currency.Abbreviation`: "Ticker symbol. 'USD', 'EUR' for forex; 'AAPL.US', 'TSLA.US' for US stocks (format: TICKER.EXCHANGE); 'BTC' for crypto. Unique across all instruments." Remove any reference to "ISO currency abbreviation" — this is wrong for equities.

2. **Fix PlayerStatus (row 28)**: Re-quote verbatim from `Dim_PlayerStatus.Name`: add "Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." This is an operational gotcha that must not be dropped.

3. **Fix ExchangeRate (row 13) source claim**: Remove "or rollback tracking" — per SP source code, `ExchangeRate` is exclusively `BDEP.ExchangeRate` from `Fact_BillingDeposit`. Update the lineage file row for `ExchangeRate` to remove `External_etoro_Billing_DepositRollbackTracking` from the source column.

4. **Re-tag Label (row 19) as Tier 1**: Change to `(Tier 1 — Dictionary.PlayerLevel)` and use the verbatim description from `Dim_PlayerLevel.Name`: "Tier display name." Retain the SP-quirk note (maps to PlayerLevel.Name, not Dim_Label.Name) in the description alongside the Tier 1 tag.

5. **Fix footer tier counts**: Change "12 T1, 25 T2" to "14 T1, 23 T2" in both the wiki footer and the review-needed sidecar.

6. **Re-quote all Dim_Country.Name passthrough columns verbatim**: RegCountry (row 30), RegCountryByIP (row 31), BinCountry (row 34) all resolve `Dim_Country.Name`. Prepend "Full country name in English. Unique per row." to each description before the "Resolved via..." clause.

7. **Re-quote PlayerLevelID (row 17) to include sort-order warning**: Add from `Dim_PlayerLevel.PlayerLevelID`: "IDs are NOT in rank order -- use Sort for ordering. FK from Dim_Customer." Currently this critical gotcha is absent.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Deposit_Reversals_PIPs",
  "weighted_score": 6.40,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 3,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID (RealCID). Hash distribution key. References Dim_Customer.",
      "match": "NO",
      "loss": "Drops 'platform-internal primary key', 'Assigned at registration', 'Unique within etoro DB', 'universal customer identifier' context; adds DWH-specific distribution note not from upstream"
    },
    {
      "column": "Customer",
      "upstream_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format.",
      "wiki_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Currency",
      "upstream_quote": "Ticker symbol. 'USD', 'EUR' for forex; 'AAPL.US', 'TSLA.US' for US stocks (format: TICKER.EXCHANGE); 'BTC' for crypto. Unique across all instruments. Use this for human-readable instrument identification.",
      "wiki_quote": "Ticker symbol / ISO currency abbreviation. Resolved via Dim_Currency.Abbreviation on CurrencyID.",
      "match": "NO",
      "loss": "Introduces factually wrong term 'ISO currency abbreviation' — eToro tickers for stocks (e.g. AAPL.US) are NOT ISO currency codes; drops specific examples, exchange-format notation, and uniqueness claim"
    },
    {
      "column": "ExchangeRate",
      "upstream_quote": "Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production.",
      "wiki_quote": "Exchange rate from rollback tracking or Fact_BillingDeposit. Cannot be 0 in production.",
      "match": "NO",
      "loss": "Incorrectly claims source includes rollback tracking; SP source code shows ONLY BDEP.ExchangeRate (Fact_BillingDeposit). Also drops 'from deposit currency to USD at processing time.'"
    },
    {
      "column": "RegulationID",
      "upstream_quote": "Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation.",
      "wiki_quote": "Customer's regulatory jurisdiction from Fact_SnapshotCustomer at event date. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, etc. FK to Dim_Regulation.",
      "match": "MINOR",
      "loss": "Drops end-of-day change semantics from RegulationChangeLog; truncates enum (9 of 15 IDs missing: eToroUS, FinCEN, FinCEN+FINRA, FSA Seychelles, ASIC&GAML, FSRA, FINRAONLY, MAS, NYDFS+FINRA)"
    },
    {
      "column": "PlayerLevelID",
      "upstream_quote": "Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (excluded), 5=Silver, 6=Platinum Plus, 7=Diamond. 0=N/A (DWH ETL placeholder). IDs are NOT in rank order -- use Sort for ordering. FK from Dim_Customer. Excludes Internal in customer-facing queries: WHERE PlayerLevelID <> 4.",
      "wiki_quote": "eToro Club loyalty tier from Fact_SnapshotCustomer. 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond, 4=Internal (excluded). FK to Dim_PlayerLevel.",
      "match": "MINOR",
      "loss": "Drops 'IDs are NOT in rank order -- use Sort for ordering' (important sort gotcha); drops 0=N/A placeholder; drops 'WHERE PlayerLevelID <> 4' filter guidance"
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Regulation short code resolved via Dim_Regulation.Name.",
      "match": "MINOR",
      "loss": "Drops usage context ('Used in V_Dim_Customer') and production-match guarantee"
    },
    {
      "column": "BaseExchangeRate",
      "upstream_quote": "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Added by Adi (19/09/2019).",
      "wiki_quote": "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate.",
      "match": "MINOR",
      "loss": "Drops attribution metadata only; semantic meaning preserved"
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "eToro Club tier name. Resolved via Dim_PlayerLevel.Name on PlayerLevelID. 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond.",
      "match": "NO",
      "loss": "Mixes in ID-to-name mapping from PlayerLevelID element (not from Name element); drops 'Internal, N/A' values; drops usage context; upstream Name element does not contain ID mappings"
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Account restriction state name. Resolved via Dim_PlayerStatus.Name on PlayerStatusID from Fact_SnapshotCustomer.",
      "match": "NO",
      "loss": "Drops critical operational gotcha about trailing spaces (RTRIM required for string comparisons); drops 'Unique per status'; drops BackOffice usage context"
    },
    {
      "column": "RegCountry",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Registration country name resolved via Dim_Country.Name on Fact_SnapshotCustomer.CountryID.",
      "match": "NO",
      "loss": "'Full country name in English' dropped; 'Unique per row' dropped; usage context dropped"
    },
    {
      "column": "RegCountryByIP",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Country detected from customer IP at registration. Resolved via Dim_Country.Name on Dim_Customer.CountryIDByIP.",
      "match": "NO",
      "loss": "Same Dim_Country.Name pattern as RegCountry; 'Full country name in English' and 'Unique per row' dropped"
    },
    {
      "column": "CardType",
      "upstream_quote": "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital.",
      "wiki_quote": "Card network brand name. Resolved via Dim_CardType.CarTypeName on Fact_BillingDeposit.CardTypeIDAsInteger. Active: 1=Visa, 2=Master Card, 3=Diners, 8=Maestro.",
      "match": "NO",
      "loss": "Drops full 18-value enum (only 4 shown); drops unique-constraint warning; drops 'Renamed from Name in production'; 'Card brand name' → 'Card network brand name'"
    },
    {
      "column": "BinCountry",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Country of the card BIN resolved via Dim_Country.Name on Fact_BillingDeposit.BinCountryIDAsInteger.",
      "match": "NO",
      "loss": "Same Dim_Country.Name pattern; 'Full country name in English' and 'Unique per row' dropped"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Currency",
      "problem": "Wiki description says 'Ticker symbol / ISO currency abbreviation' but Dim_Currency.Abbreviation contains stock tickers like 'AAPL.US' and 'TSLA.US' — these are NOT ISO currency abbreviations. An analyst would incorrectly assume ISO codes and fail joins against currency lookup tables. Upstream wiki is explicit: 'Ticker symbol. AAPL.US, TSLA.US for US stocks (format: TICKER.EXCHANGE)'. The term 'ISO currency abbreviation' is factually wrong."
    },
    {
      "severity": "high",
      "column_or_section": "PlayerStatus",
      "problem": "Drops the operational gotcha from Dim_PlayerStatus.Name: 'Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.' An analyst filtering or joining on PlayerStatus string values without RTRIM would silently get wrong results."
    },
    {
      "severity": "high",
      "column_or_section": "ExchangeRate",
      "problem": "Wiki says 'Exchange rate from rollback tracking or Fact_BillingDeposit.' SP source code shows ONLY BDEP.ExchangeRate (Fact_BillingDeposit) is used for ExchangeRate — rollback tracking table is used for ExchangeFee and rollback amounts but NOT for ExchangeRate. The lineage file has the same error. Misleads analysts about the source."
    },
    {
      "severity": "medium",
      "column_or_section": "Label",
      "problem": "Tagged (Tier 2 — SP_Deposit_Reversals_PIPs) but SP does `dpl.Name AS [Label]` with explicit JOIN to Dim_PlayerLevel on PlayerLevelID. This is a dim-lookup passthrough — per tier rules must be (Tier 1 — Dictionary.PlayerLevel). The SP quirk (Label column contains PlayerLevel names, not Label names) should be documented in the description, not used to demote the tier."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer / Section 4",
      "problem": "Footer states '12 T1, 25 T2' (12+25=37) but actual Element table count is 14 Tier 1 and 23 Tier 2 (also 37). Review-needed sidecar lists 14 column names under 'Tier 1 (12 columns)' — an internal inconsistency in both files."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix Currency (row 12) — replace 'ISO currency abbreviation' with verbatim Dim_Currency.Abbreviation upstream: 'Ticker symbol. AAPL.US, TSLA.US for US stocks (format: TICKER.EXCHANGE); BTC for crypto. Unique across all instruments.' (2) Fix PlayerStatus (row 28) — append verbatim from Dim_PlayerStatus.Name: 'Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.' (3) Fix ExchangeRate (row 13) — remove 'rollback tracking' as a source; per SP code ExchangeRate is ONLY from Fact_BillingDeposit.ExchangeRate (BDEP.ExchangeRate). Also fix lineage file. (4) Re-tag Label (row 19) as (Tier 1 — Dictionary.PlayerLevel); keep the SP-quirk note in the description. (5) Fix footer to 14 T1, 23 T2. (6) Re-quote RegCountry, RegCountryByIP, BinCountry from Dim_Country.Name verbatim: 'Full country name in English. Unique per row.' prefix each. (7) Add PlayerLevelID sort gotcha: 'IDs are NOT in rank order -- use Sort for ordering.' (8) Re-quote Club from Dim_PlayerLevel.Name (not from PlayerLevelID element): 'Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A.'",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
