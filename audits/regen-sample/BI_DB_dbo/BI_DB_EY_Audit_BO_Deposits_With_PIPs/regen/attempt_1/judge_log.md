## Judge Review: BI_DB_dbo.BI_DB_EY_Audit_BO_Deposits_With_PIPs

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 8/10**
Sampled ExternalID (T1 ✓), PaymentDate (T1 ✓), TotalRollbackAmount (T2 ✓), ExchangeRate (T1 ✓), CardType (T1 ✓). One debatable assignment: HCAmountUSD is a direct passthrough (`hc.TotalCashChange`), not ETL-computed, yet tagged Tier 2. Without an upstream wiki it can't be T1, but it's not computed either — T3 would be more accurate. Dim-lookup passthroughs (Currency, Regulation, WhiteLabel, FundingType, CardType, etc.) all correctly trace to the dim's root origin, not the intermediate dim table.

**Dimension 2 — Upstream Fidelity: 3/10**
Three Tier 1 columns are paraphrased with semantic loss: **Funnel** (upstream: "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration." → wiki: "Acquisition funnel name for the deposit."), **WhiteLabel** (dropped "Multiple LabelIDs can share the same Name" deduplication warning), **MIDName** (upstream: "Short code for the regulation" → wiki: "Regulation name associated with the ProtocolMIDSettings record"). Per rubric: 2+ paraphrased → 3.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 39 elements match 39 DDL columns exactly. All element rows have 5 cells with tier tags. Property table complete. ETL pipeline diagram uses real object names. Footer has tier breakdown. Section 1 has row count and date range. Review-needed sidecar does not contain Section 4.

**Dimension 4 — Business Meaning: 10/10**
Section 1 is exemplary: names domain (EY audit), row grain (daily approved deposits for CB-valid customers), ETL SP, refresh pattern (DELETE+INSERT), row count (15.1M), date range (2023-01-01 to 2025-10-27), and top regulation distribution. An analyst can immediately understand when and why to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count (15.1M), date range, regulation distribution (CySEC 53.5%, FCA 28.5%), status distribution (99.998% Approved), funding type distribution (CreditCard 53.9%) all present. No explicit Phase Gate P2/P3 checkboxes in footer, but data claims appear genuine and specific.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend, real SQL samples, footer with quality score and tier breakdown. Minor: tier legend only shows Tier 1 and Tier 2 (no Tier 3+ rows, but none were needed).

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| ExternalID | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format." (Dim_Customer) | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer." | YES | — |
| CID | "Customer ID. Identifies the eToro customer who made this deposit. References DWH_dbo.Dim_Customer." (Fact_BillingDeposit) | "Customer ID. Identifies the eToro customer who made this deposit." | MINOR | Dropped FK reference |
| DepositID | "Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH." (Fact_BillingDeposit) | "Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY)." | MINOR | Dropped DWH-specific storage note |
| Amount | "Deposit amount in the deposit currency (CurrencyID). As of 2025-04-17, capped via CASE expression..." (Fact_BillingDeposit) | "Deposit amount in the deposit currency (CurrencyID). CAST to DECIMAL(16,2) in SP." | MINOR | Different supplementary context |
| Currency | "Ticker symbol. 'USD', 'EUR' for forex; 'AAPL.US', 'TSLA.US' for US stocks..." (Dim_Currency) | "Ticker symbol for the deposit currency. 'USD', 'EUR', 'GBP', etc." | MINOR | Simplified examples for deposit context |
| Status | "Human-readable status label. UNIQUE constraint prevents duplicates in production." (Dim_PaymentStatus) | "Human-readable deposit status label. 99.998% = 'Approved'." | MINOR | Dropped UNIQUE constraint, added distribution |
| PaymentDate | "UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time." (Fact_BillingDeposit) | "UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time." | YES | — |
| ModificationDate | "UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection." (Fact_BillingDeposit) | "UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection." | YES | — |
| ProcessorValueDate | "Value date from the payment processor. Mandatory for offline/wire deposits. NULL for instant payment methods." (Fact_BillingDeposit) | "Value date from the payment processor. Mandatory for offline/wire deposits. NULL for instant payment methods." | YES | — |
| PaymentStatusID | "Current deposit status. Key values: 1=New, 2=Approved (73%)..." (Fact_BillingDeposit) | "Current deposit status ID. 1=New, 2=Approved, 3=Decline..." | MINOR | Dropped percentages |
| CurrencyID | "Currency of the deposit amount. References DWH_dbo.Dim_Currency. 1=USD, 2=EUR, 3=GBP, etc." (Fact_BillingDeposit) | "Currency of the deposit amount. 1=USD, 2=EUR, 5=AUD, 6=CHF, etc. FK to Dim_Currency." | MINOR | Different example IDs |
| Funnel | "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration." (Dim_Funnel) | "Acquisition funnel name for the deposit. Resolved from Dim_Funnel.Name via FunnelID JOIN." | NO | Dropped "Unique", usage contexts (marketing reports, BackOffice views), and purpose description |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards." (Dim_Regulation) | "Short code for the regulatory entity governing the customer. Resolved from Dim_Regulation.Name via Dim_Customer.RegulationID. Top values: CySEC (53.5%), FCA (28.5%)." | MINOR | Added data distribution, added context |
| WhiteLabel | "Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro')." (Dim_Label) | "Brand name of the white-label broker the customer was acquired under. Resolved from Dim_Label.Name via Dim_Customer.LabelID." | NO | Dropped deduplication warning (multiple LabelIDs share same Name) and BackOffice usage context |
| CountyByRegIP | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." (Dim_Country) | "Full country name based on the customer's registration IP address. Resolved from Dim_Country.Name via Dim_Customer.CountryIDByIP." | MINOR | Added IP context, dropped "Unique per row" and usage list |
| MIDName | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." (Dim_Regulation) | "Regulation name associated with the ProtocolMIDSettings record used for routing this deposit. Resolved from Dim_Regulation.Name via ProtocolMIDSettings.RegulationID. NULL when no MID settings exist." | NO | Rewording from "Short code" to "Regulation name"; dropped V_Dim_Customer usage |
| TransactionID | (no upstream wiki in bundle — Fact_BillingDeposit wiki truncated) | "Internal transaction identifier from Billing.Deposit." | MINOR | Cannot verify — upstream truncated |
| ExTransactionID | "External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution." (Fact_BillingDeposit) | "External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution." | YES | — |
| ExchangeRate | "Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production." (Fact_BillingDeposit) | "Exchange rate from deposit currency to USD at processing time. 1.0 for USD deposits." | MINOR | Dropped "Cannot be 0" constraint, added USD note |
| BaseExchangeRate | "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate." (Fact_BillingDeposit) | "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate." | YES | — |
| ExchangeFee | "Exchange fee in provider-specific integer encoding (basis points)." (Fact_BillingDeposit) | "Exchange fee in provider-specific integer encoding (basis points). 0 for USD deposits." | YES | — (added USD note) |
| IsCreditReportValidCB | "1 if customer is eligible for CreditBureau credit report validation. ETL-computed." (Fact_SnapshotCustomer) | "DWH-computed flag indicating credit-report-valid customer. Always 1 in this table (SP filters to CB-valid only)." | MINOR | Rephrased but added important "always 1" context |
| CountryID | "Customer's registered country. DEFAULT 0. FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded)." (Fact_SnapshotCustomer) | "Customer's registered country at the time of the deposit. Point-in-time value from Fact_SnapshotCustomer via Dim_Range. FK to Dim_Country." | MINOR | Added point-in-time context, dropped DEFAULT detail |
| FundingType | "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay)." (Dim_FundingType) | "Payment method name (e.g., CreditCard, PayPal, eToroMoney, WireTransfer). Top values: CreditCard (53.9%), eToroMoney (29.7%), PayPal (12.1%)." | MINOR | Different example values, added distribution |
| CardType | "Card brand name. Unique constraint prevents duplicates in production. Renamed from Name in production." (Dim_CardType) | "Card network brand name. Resolved from Dim_CardType.CarTypeName via Fact_BillingDeposit.CardTypeIDAsInteger. Values: Visa, Master Card, Diners, Maestro, etc. NULL for non-card payment methods." | MINOR | Minor rewording, dropped UNIQUE constraint, added NULL semantics |

### Top 5 Issues

1. **HIGH — Funnel T1 description paraphrased** (`Funnel`): Upstream Dim_Funnel.Name description ("Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.") replaced with generic "Acquisition funnel name for the deposit." All usage context and specificity lost.

2. **HIGH — WhiteLabel T1 description paraphrased** (`WhiteLabel`): Upstream Dim_Label.Name description dropped critical deduplication warning: "Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro')." An analyst unaware of this will write incorrect GROUP BYs.

3. **HIGH — MIDName T1 description paraphrased** (`MIDName`): Upstream "Short code for the regulation" rewrote to "Regulation name associated with the ProtocolMIDSettings record." While the added context is useful, the upstream text must be preserved verbatim.

4. **MEDIUM — ExternalID type mismatch in description** (`ExternalID`): Wiki says "Decimal(38,0)" matching the Dim_Customer upstream, but the actual DDL column in this table is `varchar(100)`. The description should note the type difference since the BI_DB column stores it as string.

5. **MEDIUM — HCAmountUSD mistagged Tier 2** (`HCAmountUSD`): This is `hc.TotalCashChange` — a direct passthrough from External_etoro_History_Credit_Yesterday, not an ETL computation. Without an upstream wiki it cannot be Tier 1, but it is not "ETL-computed" either. Should be Tier 3 (source traceable, no wiki).

### Regeneration Feedback

1. For **Funnel**, **WhiteLabel**, and **MIDName**: replace wiki descriptions with the verbatim text from the upstream dimension wikis (Dim_Funnel.Name, Dim_Label.Name, Dim_Regulation.Name), then append any table-specific context AFTER the upstream quote.
2. For **ExternalID**: note that while Dim_Customer stores this as `decimal(38,0)`, this table's DDL uses `varchar(100)` — add a note about the type difference.
3. Re-tag **HCAmountUSD** as `(Tier 3 — External_etoro_History_Credit_Yesterday)` since it is a passthrough from an undocumented external table, not an ETL computation.
4. Apply the same Tier 3 treatment to **DepositType** and **Depot** — these are simple lookups from undocumented external tables, not ETL-computed values.
5. For **WhiteLabel** specifically, add the deduplication warning from upstream: "Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro')."

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_EY_Audit_BO_Deposits_With_PIPs",
  "weighted_score": 7.7,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {"column": "ExternalID", "upstream_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format.", "wiki_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer.", "match": "YES", "loss": null},
    {"column": "CID", "upstream_quote": "Customer ID. Identifies the eToro customer who made this deposit. References DWH_dbo.Dim_Customer.", "wiki_quote": "Customer ID. Identifies the eToro customer who made this deposit.", "match": "MINOR", "loss": "Dropped FK reference to Dim_Customer"},
    {"column": "DepositID", "upstream_quote": "Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH.", "wiki_quote": "Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY).", "match": "MINOR", "loss": "Dropped DWH storage details (HASH distribution key, clustered index)"},
    {"column": "Amount", "upstream_quote": "Deposit amount in the deposit currency (CurrencyID). As of 2025-04-17, capped via CASE expression in ETL to prevent extreme outlier values from distorting aggregations.", "wiki_quote": "Deposit amount in the deposit currency (CurrencyID). CAST to DECIMAL(16,2) in SP.", "match": "MINOR", "loss": "Different supplementary context (SP CAST vs upstream amount cap)"},
    {"column": "Currency", "upstream_quote": "Ticker symbol. 'USD', 'EUR' for forex; 'AAPL.US', 'TSLA.US' for US stocks (format: TICKER.EXCHANGE); 'BTC' for crypto. Unique across all instruments.", "wiki_quote": "Ticker symbol for the deposit currency. 'USD', 'EUR', 'GBP', etc. Resolved from Dim_Currency.Abbreviation via CurrencyID JOIN.", "match": "MINOR", "loss": "Simplified examples for deposit-currency context; dropped stock/crypto ticker formats"},
    {"column": "Status", "upstream_quote": "Human-readable status label. UNIQUE constraint prevents duplicates in production. Used in back-office payment management UI and reconciliation reports.", "wiki_quote": "Human-readable deposit status label. Resolved from Dim_PaymentStatus.Name via PaymentStatusID JOIN. 99.998% = 'Approved'.", "match": "MINOR", "loss": "Dropped UNIQUE constraint and UI usage context"},
    {"column": "PaymentDate", "upstream_quote": "UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time.", "wiki_quote": "UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time.", "match": "YES", "loss": null},
    {"column": "ModificationDate", "upstream_quote": "UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection.", "wiki_quote": "UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection.", "match": "YES", "loss": null},
    {"column": "ProcessorValueDate", "upstream_quote": "Value date from the payment processor. Mandatory for offline/wire deposits. NULL for instant payment methods.", "wiki_quote": "Value date from the payment processor. Mandatory for offline/wire deposits. NULL for instant payment methods.", "match": "YES", "loss": null},
    {"column": "PaymentStatusID", "upstream_quote": "Current deposit status. Key values: 1=New, 2=Approved (73%), 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE (10.2%). Full 39-value enum in upstream wiki. NC index key.", "wiki_quote": "Current deposit status ID. 1=New, 2=Approved, 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE. FK to Dim_PaymentStatus.", "match": "MINOR", "loss": "Dropped percentage distributions and NC index key note"},
    {"column": "CurrencyID", "upstream_quote": "Currency of the deposit amount. References DWH_dbo.Dim_Currency. 1=USD, 2=EUR, 3=GBP, etc.", "wiki_quote": "Currency of the deposit amount. 1=USD, 2=EUR, 5=AUD, 6=CHF, etc. FK to Dim_Currency.", "match": "MINOR", "loss": "Different example IDs (3=GBP vs 5=AUD)"},
    {"column": "Funnel", "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.", "wiki_quote": "Acquisition funnel name for the deposit. Resolved from Dim_Funnel.Name via FunnelID JOIN.", "match": "NO", "loss": "Dropped 'Unique', all usage context (marketing reports, BackOffice views, attribution analytics), and purpose description"},
    {"column": "Regulation", "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.", "wiki_quote": "Short code for the regulatory entity governing the customer. Resolved from Dim_Regulation.Name via Dim_Customer.RegulationID. Top values: CySEC (53.5%), FCA (28.5%), ASIC & GAML (6.9%).", "match": "MINOR", "loss": "Dropped V_Dim_Customer reference; added data distribution"},
    {"column": "WhiteLabel", "upstream_quote": "Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro').", "wiki_quote": "Brand name of the white-label broker the customer was acquired under. Resolved from Dim_Label.Name via Dim_Customer.LabelID.", "match": "NO", "loss": "Dropped deduplication warning (multiple LabelIDs share same Name), BackOffice UI context"},
    {"column": "CountyByRegIP", "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.", "wiki_quote": "Full country name based on the customer's registration IP address. Resolved from Dim_Country.Name via Dim_Customer.CountryIDByIP. Note: column name has typo ('County' instead of 'Country').", "match": "MINOR", "loss": "Dropped 'Unique per row' and usage list; added IP-based context and typo note"},
    {"column": "MIDName", "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.", "wiki_quote": "Regulation name associated with the ProtocolMIDSettings record used for routing this deposit. Resolved from Dim_Regulation.Name via ProtocolMIDSettings.RegulationID. NULL when no MID settings exist.", "match": "NO", "loss": "Rewrote 'Short code for the regulation' as 'Regulation name associated with the ProtocolMIDSettings record'; dropped V_Dim_Customer reference"},
    {"column": "TransactionID", "upstream_quote": "(upstream wiki truncated — cannot verify)", "wiki_quote": "Internal transaction identifier from Billing.Deposit.", "match": "MINOR", "loss": "Cannot verify — Fact_BillingDeposit wiki truncated at 30KB"},
    {"column": "ExTransactionID", "upstream_quote": "External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution.", "wiki_quote": "External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution.", "match": "YES", "loss": null},
    {"column": "ExchangeRate", "upstream_quote": "Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production.", "wiki_quote": "Exchange rate from deposit currency to USD at processing time. 1.0 for USD deposits.", "match": "MINOR", "loss": "Dropped 'Cannot be 0' constraint; added USD note"},
    {"column": "BaseExchangeRate", "upstream_quote": "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate.", "wiki_quote": "Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate.", "match": "YES", "loss": null},
    {"column": "ExchangeFee", "upstream_quote": "Exchange fee in provider-specific integer encoding (basis points).", "wiki_quote": "Exchange fee in provider-specific integer encoding (basis points). 0 for USD deposits.", "match": "YES", "loss": null},
    {"column": "IsCreditReportValidCB", "upstream_quote": "1 if customer is eligible for CreditBureau credit report validation. ETL-computed.", "wiki_quote": "DWH-computed flag indicating credit-report-valid customer. Always 1 in this table (SP filters to CB-valid only). Point-in-time value from Fact_SnapshotCustomer via Dim_Range.", "match": "MINOR", "loss": "Rephrased; added 'always 1' context"},
    {"column": "CountryID", "upstream_quote": "Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded).", "wiki_quote": "Customer's registered country at the time of the deposit. Point-in-time value from Fact_SnapshotCustomer via Dim_Range. FK to Dim_Country.", "match": "MINOR", "loss": "Dropped DEFAULT and CountryID=250 exclusion detail; added point-in-time context"},
    {"column": "FundingType", "upstream_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay).", "wiki_quote": "Payment method name (e.g., CreditCard, PayPal, eToroMoney, WireTransfer). Resolved from Dim_FundingType.Name via Fact_BillingDeposit.FundingTypeID. Top values: CreditCard (53.9%), eToroMoney (29.7%), PayPal (12.1%).", "match": "MINOR", "loss": "Different example values; added distribution"},
    {"column": "CardType", "upstream_quote": "Card brand name. Unique constraint prevents duplicates in production. Renamed from Name in production.", "wiki_quote": "Card network brand name. Resolved from Dim_CardType.CarTypeName via Fact_BillingDeposit.CardTypeIDAsInteger. Values: Visa, Master Card, Diners, Maestro, etc. NULL for non-card payment methods.", "match": "MINOR", "loss": "Minor rewording ('brand' to 'network brand'); dropped UNIQUE constraint and rename note; added NULL semantics"}
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Funnel",
      "problem": "Tier 1 description paraphrased. Upstream Dim_Funnel.Name says 'Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.' Wiki replaces with generic 'Acquisition funnel name for the deposit.' All specificity lost."
    },
    {
      "severity": "high",
      "column_or_section": "WhiteLabel",
      "problem": "Tier 1 description paraphrased. Upstream Dim_Label.Name warns 'Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = eToro).' Wiki drops this deduplication warning entirely, risking incorrect GROUP BY queries by analysts."
    },
    {
      "severity": "high",
      "column_or_section": "MIDName",
      "problem": "Tier 1 description paraphrased. Upstream Dim_Regulation.Name says 'Short code for the regulation.' Wiki rewrote to 'Regulation name associated with the ProtocolMIDSettings record.' While the added context is useful, the upstream description must be quoted verbatim first."
    },
    {
      "severity": "medium",
      "column_or_section": "ExternalID",
      "problem": "Wiki says 'Decimal(38,0)' matching Dim_Customer upstream, but this table's DDL column is varchar(100). The type difference should be noted — a consumer expecting decimal behavior will be surprised by string storage."
    },
    {
      "severity": "medium",
      "column_or_section": "HCAmountUSD",
      "problem": "Tagged Tier 2 — External_etoro_History_Credit_Yesterday but is a direct passthrough (hc.TotalCashChange), not ETL-computed. Should be Tier 3 (source traceable but no upstream wiki). Same issue applies to DepositType and Depot."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Replace Funnel description with verbatim Dim_Funnel.Name text, then append deposit-specific context. (2) Replace WhiteLabel description with verbatim Dim_Label.Name text including the deduplication warning about multiple LabelIDs sharing the same Name. (3) Replace MIDName description with verbatim Dim_Regulation.Name text, then append the ProtocolMIDSettings routing context. (4) Add type-difference note for ExternalID (upstream decimal(38,0), this table varchar(100)). (5) Re-tag HCAmountUSD, DepositType, and Depot as Tier 3 (passthrough from undocumented external tables, not ETL-computed).",
  "stats_check": {
    "table_level_stats_in_descriptions": ["Section 1: 15.1M rows, 99.998% Approved, date range 2023-01-01 to 2025-10-27, regulation distribution", "Regulation: CySEC 53.5%, FCA 28.5%, ASIC & GAML 6.9%", "FundingType: CreditCard 53.9%, eToroMoney 29.7%, PayPal 12.1%"],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
