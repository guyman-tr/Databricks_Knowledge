## Human-Readable Summary

### Per-Dimension Scores

| Dimension | Score | Justification |
|---|---|---|
| **Tier Accuracy** | **8/10** | 0 tier mismatches in 5 random picks; −2 for `RegulationID` paraphrase (enum truncated to "etc.") |
| **Upstream Fidelity** | **3/10** | 2 T1 columns with semantic loss: `RegulationID` drops 8 specific authority names; `Regulation` drops usage context |
| **Completeness** | **10/10** | All 8 sections, 37/37 elements, tier tags throughout, ASCII diagram, row count + date range, footer tiers |
| **Business Meaning** | **9/10** | Excellent: names row grain, SP, ETL pattern, row count, date range, distribution by TransactionType and Regulation |
| **Data Evidence** | **8/10** | Live data confirmed: 7,979 rows, 2023-03-01–2025-09-10, % breakdowns by TransactionType and Regulation; P2 sampling explicitly cited in review-needed |
| **Shape Fidelity** | **9/10** | Numbered sections, tier legend, two real SQL samples, footer with quality score + phases, Section 5.2 ASCII diagram |

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|---|---|---|---|---|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Hash distribution key. Passthrough from..." | MINOR | Adds info; no loss |
| Customer | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format." | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer.ExternalID." | MINOR | Adds info; no loss |
| Currency | "Ticker symbol. 'USD', 'EUR' for forex; 'AAPL.US', 'TSLA.US' for US stocks (format: TICKER.EXCHANGE); 'BTC' for crypto. Unique across all instruments. Use this for human-readable instrument identification." | "Ticker symbol. 'USD', 'EUR' for forex; 'AAPL.US', 'TSLA.US' for US stocks (format: TICKER.EXCHANGE); 'BTC' for crypto. Unique across all instruments. Use this for human-readable instrument identification. Passthrough from Dim_Currency.Abbreviation via CurrencyID." | MINOR | Adds info; no loss |
| ExchangeRate | "Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production." | "Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production. Passthrough from Fact_BillingDeposit.ExchangeRate." | MINOR | Adds info; no loss |
| **RegulationID** | "Primary key identifying the regulatory authority. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored in CustomerStatic.RegulationID." | "Customer's regulatory jurisdiction from Fact_SnapshotCustomer at event date. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, etc. FK to Dim_Regulation." | **NO** | Drops 8 named authorities (FinCEN, FSA Seychelles, ASIC&GAML, FSRA, FINRAONLY, MAS, NYDFS+FINRA) via "etc."; loses "Stored in CustomerStatic.RegulationID" |
| **Regulation** | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Regulation short code resolved via Dim_Regulation.Name." | **NO** | Drops usage context ("Used in V_Dim_Customer and analytics dashboards") and production-match note |
| Label | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." (with NOTE prefix) | MINOR | Adds NOTE about SP quirk; verbatim intact |
| PlayerLevelID | "Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (excluded), 5=Silver, 6=Platinum Plus, 7=Diamond. 0=N/A (DWH ETL placeholder). IDs are NOT in rank order -- use Sort for ordering. FK from Dim_Customer. Excludes Internal in customer-facing queries: WHERE PlayerLevelID <> 4." | Same verbatim + "Passthrough from Fact_SnapshotCustomer." | MINOR | Adds routing info; "Sort column in Dim_PlayerLevel" adds specificity |
| BaseExchangeRate | "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Added by Adi (19/09/2019)." | "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Passthrough from Fact_BillingDeposit." | MINOR | Drops "Added by Adi (19/09/2019)" — historical metadata only |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel.Name." | MINOR | Adds info; no loss |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." | Same verbatim + "Passthrough from Dim_PlayerStatus.Name." | MINOR | Adds info; no loss |
| RegCountry | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | Same verbatim + "Passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID." | MINOR | Adds info; no loss |
| RegCountryByIP | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | Same verbatim + "Passthrough from Dim_Country.Name via Dim_Customer.CountryIDByIP." | MINOR | Adds info; no loss |
| CardType | "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners...17=GE Capital." | Same verbatim + "Passthrough from Dim_CardType.CarTypeName." | MINOR | Adds info; no loss |
| BinCountry | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | Same verbatim + "Passthrough from Dim_Country.Name via Fact_BillingDeposit.BinCountryIDAsInteger." | MINOR | Adds info; no loss |

---

### Top 5 Issues

1. **HIGH — RegulationID**: Enum truncated with "etc." after ID=5 (BVI), silently dropping 8 named regulatory authorities: eToroUS (6), FinCEN (7), FinCEN+FINRA (8), FSA Seychelles (9), ASIC&GAML (10), FSRA (11), FINRAONLY (12), MAS (13), NYDFS+FINRA (14). These are exactly the authorities that appear in Section 1's distribution (FinCEN+FINRA 41%, FSA Seychelles 21%, ASIC&GAML 17%), creating a contradiction between Section 1 and the column description.

2. **HIGH — Regulation**: Column description rewritten to "Regulation short code resolved via Dim_Regulation.Name" — drops verbatim content "Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." An analyst cannot determine the column's systemic role from the abbreviated description.

3. **MEDIUM — DepositWithdrawID**: Tagged `(Tier 2 — SP_Deposit_Reversals_PIPs)` but lineage confirms it is a rename passthrough of `Fact_BillingDeposit.DepositID`, which has an upstream wiki entry (Billing.Deposit). Per tier rules, a rename with upstream wiki present must be Tier 1. Should be `(Tier 1 — Billing.Deposit)` with verbatim description: "Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY)."

4. **MEDIUM — BaseExchangeRate**: Drops "Added by Adi (19/09/2019)" from the upstream Fact_BillingDeposit wiki. While this is historical metadata rather than a semantic loss, it represents a departure from verbatim inheritance.

5. **LOW — IsValidCustomer**: Source citation is `(Tier 2 — SP_Fact_SnapshotCustomer)` — referencing an upstream SP rather than this table's writer SP. All other ETL-computed columns cite `SP_Deposit_Reversals_PIPs`. This inconsistency could mislead a maintainer about which SP controls this column's value in *this* table (it is a passthrough, so the source SP is valid, but the citation style diverges from the rest of the wiki).

---

### Regeneration Feedback

1. **RegulationID**: Replace "0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, etc." with the full enum verbatim from Dim_Regulation wiki: "0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored in CustomerStatic.RegulationID."
2. **Regulation**: Replace with verbatim from Dim_Regulation.Name wiki: "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name."
3. **DepositWithdrawID**: Re-tag as `(Tier 1 — Billing.Deposit)` and use verbatim Fact_BillingDeposit.DepositID description: "Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Renamed to DepositWithdrawID for schema compatibility with BI_DB_DepositWithdrawFee."
4. **BaseExchangeRate**: Append "Added by Adi (19/09/2019)." from the upstream wiki to avoid divergence.
5. **IsValidCustomer**: Change source citation from `SP_Fact_SnapshotCustomer` to `SP_Deposit_Reversals_PIPs` to match this table's ETL context, or keep `SP_Fact_SnapshotCustomer` with an explicit note that the value is passed through unchanged.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Deposit_Reversals_PIPs",
  "weighted_score": 7.65,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Hash distribution key. Passthrough from Fact_BillingDeposit / Fact_SnapshotCustomer.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "Customer",
      "upstream_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format.",
      "wiki_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer.ExternalID.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "Currency",
      "upstream_quote": "Ticker symbol. \"USD\", \"EUR\" for forex; \"AAPL.US\", \"TSLA.US\" for US stocks (format: TICKER.EXCHANGE); \"BTC\" for crypto. Unique across all instruments. Use this for human-readable instrument identification.",
      "wiki_quote": "Ticker symbol. \"USD\", \"EUR\" for forex; \"AAPL.US\", \"TSLA.US\" for US stocks (format: TICKER.EXCHANGE); \"BTC\" for crypto. Unique across all instruments. Use this for human-readable instrument identification. Passthrough from Dim_Currency.Abbreviation via CurrencyID.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "ExchangeRate",
      "upstream_quote": "Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production.",
      "wiki_quote": "Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production. Passthrough from Fact_BillingDeposit.ExchangeRate.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "RegulationID",
      "upstream_quote": "Primary key identifying the regulatory authority. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored in CustomerStatic.RegulationID.",
      "wiki_quote": "Customer's regulatory jurisdiction from Fact_SnapshotCustomer at event date. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, etc. FK to Dim_Regulation.",
      "match": "NO",
      "loss": "Drops 8 named regulatory authorities via 'etc.' (eToroUS, FinCEN, FinCEN+FINRA, FSA Seychelles, ASIC&GAML, FSRA, FINRAONLY, MAS, NYDFS+FINRA); loses 'Stored in CustomerStatic.RegulationID'"
    },
    {
      "column": "PlayerLevelID",
      "upstream_quote": "Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (excluded), 5=Silver, 6=Platinum Plus, 7=Diamond. 0=N/A (DWH ETL placeholder). IDs are NOT in rank order -- use Sort for ordering. FK from Dim_Customer. Excludes Internal in customer-facing queries: WHERE PlayerLevelID <> 4.",
      "wiki_quote": "Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (excluded), 5=Silver, 6=Platinum Plus, 7=Diamond. 0=N/A (DWH ETL placeholder). IDs are NOT in rank order -- use Sort column in Dim_PlayerLevel for ordering. FK from Dim_Customer. Excludes Internal in customer-facing queries: WHERE PlayerLevelID <> 4. Passthrough from Fact_SnapshotCustomer.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Regulation short code resolved via Dim_Regulation.Name.",
      "match": "NO",
      "loss": "Drops 'Used in V_Dim_Customer and analytics dashboards' and 'Values match production Dictionary.Regulation.Name'"
    },
    {
      "column": "Label",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "**NOTE: maps to Dim_PlayerLevel.Name, NOT Dim_Label.Name** — SP quirk. Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "BaseExchangeRate",
      "upstream_quote": "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Added by Adi (19/09/2019).",
      "wiki_quote": "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Passthrough from Fact_BillingDeposit.",
      "match": "MINOR",
      "loss": "Drops 'Added by Adi (19/09/2019)' — historical metadata"
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel.Name.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Passthrough from Dim_PlayerStatus.Name.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "RegCountry",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "RegCountryByIP",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name via Dim_Customer.CountryIDByIP.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "CardType",
      "upstream_quote": "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital.",
      "wiki_quote": "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. Passthrough from Dim_CardType.CarTypeName.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "BinCountry",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name via Fact_BillingDeposit.BinCountryIDAsInteger.",
      "match": "MINOR",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "RegulationID",
      "problem": "Description truncates the upstream enum after ID=5 (BVI) using 'etc.', silently dropping 8 specific authority names: 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. These are exactly the authorities cited in Section 1 data (FinCEN+FINRA 41%, FSA Seychelles 21%, ASIC&GAML 17%), creating a contradiction between the column description and the business summary."
    },
    {
      "severity": "high",
      "column_or_section": "Regulation",
      "problem": "Description paraphrased to 'Regulation short code resolved via Dim_Regulation.Name.' Drops verbatim upstream content: 'Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.' An analyst cannot determine the column's systemic role or confirm production provenance."
    },
    {
      "severity": "medium",
      "column_or_section": "DepositWithdrawID",
      "problem": "Tagged (Tier 2 — SP_Deposit_Reversals_PIPs) but lineage confirms this is a rename passthrough of Fact_BillingDeposit.DepositID, which has a documented upstream wiki (Billing.Deposit). Per tier rules, a passthrough rename with upstream wiki present must be Tier 1. Should be (Tier 1 — Billing.Deposit) with verbatim: 'Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Renamed to DepositWithdrawID for schema compatibility.'"
    },
    {
      "severity": "medium",
      "column_or_section": "BaseExchangeRate",
      "problem": "Drops 'Added by Adi (19/09/2019)' from the upstream Fact_BillingDeposit wiki entry. While historical metadata, verbatim inheritance requires this to be preserved."
    },
    {
      "severity": "low",
      "column_or_section": "IsValidCustomer",
      "problem": "Source citation is '(Tier 2 — SP_Fact_SnapshotCustomer)' — referencing an upstream SP rather than this table's own ETL SP. All other passthrough columns from Fact_SnapshotCustomer cite SP_Deposit_Reversals_PIPs. Inconsistent citation style may mislead a maintainer about which SP controls this value in this table."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) RegulationID — replace 'etc.' with full enum verbatim from Dim_Regulation wiki: '6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored in CustomerStatic.RegulationID.' (2) Regulation — replace paraphrase with verbatim from Dim_Regulation.Name: 'Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.' (3) DepositWithdrawID — re-tag as Tier 1 — Billing.Deposit using verbatim Fact_BillingDeposit.DepositID description. (4) BaseExchangeRate — append 'Added by Adi (19/09/2019).' from upstream. (5) IsValidCustomer — standardize source citation to SP_Deposit_Reversals_PIPs.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["3 phases of 14 skipped (11/14 completed per footer)"]
  }
}
</JUDGE_VERDICT>
