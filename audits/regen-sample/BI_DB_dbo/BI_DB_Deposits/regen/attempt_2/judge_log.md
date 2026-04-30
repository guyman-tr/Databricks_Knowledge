## Human-Readable Summary — BI_DB_dbo.BI_DB_Deposits

---

### Per-Dimension Scores

| Dimension | Score | One-line justification |
|---|---|---|
| Tier Accuracy | 9 | 0/5 sampled columns have wrong tier; all dim-lookup passthroughs correctly tagged Tier 1 with root origin |
| Upstream Fidelity | 6 | Country + BINCountry truncate the upstream description; IsFTD drops distribution stats and type note; Registered drops rename provenance; PaymentStatus_PaymentStatusID inherits contradictory enum values from upstream |
| Completeness | 10 | All 8 sections present, 52/52 DDL columns documented, all rows have 5 cells, review-needed has no Elements section |
| Business Meaning | 9 | Row count, date range, ETL pattern, SP name, PI exclusion rule all present in Section 1 |
| Data Evidence | 8 | Live stats visible (580K rows, date range, NULL semantics); 11/14 phases; no explicit P2/P3 gate checklist in body but data is clearly real |
| Shape Fidelity | 9 | Footer present, tier legend present, real SQL in Section 7; only deviation is "Quality: pending/10" unfilled |

**Weighted score: 0.25×9 + 0.20×6 + 0.20×10 + 0.15×9 + 0.10×8 + 0.10×9 = 8.50 → PASS**

---

### T1 Fidelity Table

| Column | Upstream Quote (verbatim) | Wiki Quote (verbatim) | Match | Loss |
|---|---|---|---|---|
| DepositID | "Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH." | "Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY)." | MINOR | Dropped "Primary distribution key (HASH)" and "Clustered index key in DWH." |
| PaymentStatusID | "Current deposit status. Key values: 1=New, 2=Approved (73%), 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE (10.2%). Full 39-value enum in upstream wiki." | "Current deposit status. Key values: 1=New, 2=Approved, 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE." | MINOR | Dropped distribution percentages (73%, 10.2%) and "Full 39-value enum" reference |
| IsFTD | "First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. ~60.6% of deposits are FTD=1 in Billing.Deposit. Stored as int in DWH (vs. bit in production)." | "First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type." | NO | Dropped "~60.6% of deposits are FTD=1" and int/bit type divergence note |
| Amount | "Deposit amount in the deposit currency (CurrencyID). As of 2025-04-17, capped via CASE expression in ETL to prevent extreme outlier values from distorting aggregations." | "Deposit amount in the deposit currency (CurrencyID). Capped via CASE expression in upstream ETL to prevent extreme outlier values." | MINOR | Dropped "As of 2025-04-17" date and "from distorting aggregations" consequence clause |
| RiskManagementStatusID | "Result of the pre-processing risk management check. 69 distinct risk reason codes. NULL=no risk check recorded. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation." | (same) | YES | — |
| PaymentStatus_PaymentStatusID | "Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally." | (same) | YES | Note: inherited enum values contradict Section 1 of Dim_PaymentStatus (which shows 2=Approved, 3=Decline). Issue in upstream wiki, faithfully copied. |
| PaymentStatus_Name | "Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports." | (same) | YES | — |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Passthrough from Dim_Country via Dim_Customer.CountryID." | NO | Dropped "Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." |
| BINCountry | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Passthrough from Dim_Country via fbd.BinCountryIDAsInteger." | NO | Same truncation as Country |
| Registered | "Account registration date (renamed from Registered). Default=getdate()." | "Account registration date. Passthrough from Dim_Customer.RegisteredReal." | MINOR | Dropped "(renamed from Registered)" and "Default=getdate()" |
| SerialID | "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations." | "Affiliate (partner) ID under which the customer was acquired. Passthrough from Dim_Customer.AffiliateID (renamed from SerialID in Customer.CustomerStatic). NULL for direct/organic registrations." | MINOR | Dropped "FK to BackOffice.Affiliate"; rename note reworded |
| Funnel | "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration." | (verbatim + "Resolved from Dim_Funnel on fbd.FunnelID") | YES | Minor addition of context only |
| FunnelFrom | (same upstream Name description) | (same + "Resolved from Dim_Funnel on Dim_Customer.FunnelFromID") | YES | Three funnel columns share identical base description; differentiation only in trailing JOIN clause |
| AcquisitionFunnel | (same upstream Name description) | (same + "Resolved from Dim_Funnel on Dim_Customer.FunnelID") | YES | See FunnelFrom note |
| CreditCardType | "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa … 17=GE Capital." | (verbatim) | YES | — |
| DepoName | "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports." | (verbatim) | YES | — |
| FundingType | "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay)." | (verbatim) | YES | — |
| FunnelID | "Marketing funnel ID. FK to Dictionary.Funnel." | (verbatim) | YES | — |
| MatchStatusID | "PSP reconciliation match status. Default 0=Unmatched; 3=Matched. Used for provider reconciliation workflows." | (verbatim) | YES | — |

---

### Top 5 Issues

1. **Country / BINCountry (medium)** — Both descriptions truncate the Dim_Country.Name verbatim to remove "Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." An analyst won't know these names are unique (query implication) or where they surface in the product.

2. **PaymentStatus_PaymentStatusID — contradictory enum values (medium)** — The enum list inherited from Dim_PaymentStatus.PaymentStatusID elements ("1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally") contradicts the actual Dim_PaymentStatus business content (where 2=Approved, 3=Decline, 35=DeclineByRRE per Section 1 and Section 2 of that same upstream wiki). The writer faithfully copied a bad description from the upstream wiki without cross-checking against the dim's Section 1 data. An analyst querying `WHERE PaymentStatus_PaymentStatusID = 2` would see "2=InProcess" in the description but actually get Approved rows.

3. **IsFTD — dropped distribution and type divergence note (low)** — "~60.6% of deposits are FTD=1" and "Stored as int in DWH (vs. bit in production)" were both dropped. The type note is relevant for joins and CAST compatibility.

4. **Registered — dropped rename provenance (low)** — The note "(renamed from Registered)" and "Default=getdate()" from the Dim_Customer.RegisteredReal entry were dropped. The rename context helps analysts understand the column's production history.

5. **Funnel / FunnelFrom / AcquisitionFunnel — indistinguishable descriptions (low)** — All three share an identical base description; the only differentiation is the trailing "Resolved from Dim_Funnel on X" clause. An analyst can't easily tell from the body text which funnel dimension is the deposit's own funnel vs. the customer's registration funnel variants.

---

### Regeneration Feedback

1. **Country and BINCountry**: Restore full verbatim from Dim_Country.Name: add "Unique per row. Used in UI dropdowns, compliance documents, and analytical reports."
2. **PaymentStatus_PaymentStatusID**: Do not blindly copy the Dim_PaymentStatus Elements entry. Cross-check against Dim_PaymentStatus Section 1 and Section 2 to get the correct value mapping (2=Approved, 3=Decline, 35=DeclineByRRE, etc.). The current inherited text ("1=Pending, 2=InProcess…") is wrong relative to what the column actually contains.
3. **IsFTD**: Add "~60.6% of deposits are FTD=1 in Billing.Deposit. Note: stored as bit in BI_DB_Deposits."
4. **Registered**: Add "(renamed from Dim_Customer.RegisteredReal, sourced as Registered in Customer.CustomerStatic). Default=getdate() at registration time."
5. **Funnel/FunnelFrom/AcquisitionFunnel**: Differentiate the lead sentence: e.g., Funnel = "Funnel at deposit time (Fact_BillingDeposit.FunnelID)"; FunnelFrom = "Customer's 'from' funnel variant (Dim_Customer.FunnelFromID)"; AcquisitionFunnel = "Customer's acquisition funnel at registration (Dim_Customer.FunnelID)."

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Deposits",
  "weighted_score": 8.50,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 9,
    "upstream_fidelity": 6,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "DepositID",
      "upstream_quote": "Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH.",
      "wiki_quote": "Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY).",
      "match": "MINOR",
      "loss": "Dropped 'Primary distribution key (HASH)' and 'Clustered index key in DWH.'"
    },
    {
      "column": "PaymentStatusID",
      "upstream_quote": "Current deposit status. Key values: 1=New, 2=Approved (73%), 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE (10.2%). Full 39-value enum in upstream wiki.",
      "wiki_quote": "Current deposit status. Key values: 1=New, 2=Approved, 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE.",
      "match": "MINOR",
      "loss": "Dropped distribution percentages (73%, 10.2%) and 'Full 39-value enum in upstream wiki' reference"
    },
    {
      "column": "IsFTD",
      "upstream_quote": "First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. ~60.6% of deposits are FTD=1 in Billing.Deposit. Stored as int in DWH (vs. bit in production).",
      "wiki_quote": "First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type.",
      "match": "NO",
      "loss": "Dropped '~60.6% of deposits are FTD=1 in Billing.Deposit' and int/bit type divergence note"
    },
    {
      "column": "Amount",
      "upstream_quote": "Deposit amount in the deposit currency (CurrencyID). As of 2025-04-17, capped via CASE expression in ETL to prevent extreme outlier values from distorting aggregations.",
      "wiki_quote": "Deposit amount in the deposit currency (CurrencyID). Capped via CASE expression in upstream ETL to prevent extreme outlier values.",
      "match": "MINOR",
      "loss": "Dropped 'As of 2025-04-17' date anchor and 'from distorting aggregations' consequence clause"
    },
    {
      "column": "RiskManagementStatusID",
      "upstream_quote": "Result of the pre-processing risk management check. 69 distinct risk reason codes. NULL=no risk check recorded. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation.",
      "wiki_quote": "Result of the pre-processing risk management check. 69 distinct risk reason codes. NULL=no risk check recorded. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PaymentStatus_PaymentStatusID",
      "upstream_quote": "Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally. (Tier 1 — Dictionary.PaymentStatus)",
      "wiki_quote": "Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally.",
      "match": "YES",
      "loss": "Verbatim copy is faithful but the inherited enum values contradict Dim_PaymentStatus Section 1 (2=Approved, 3=Decline in actual data). Issue originated in upstream wiki element table conflicting with upstream Section 1."
    },
    {
      "column": "PaymentStatus_Name",
      "upstream_quote": "Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports.",
      "wiki_quote": "Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Passthrough from Dim_Country via Dim_Customer.CountryID.",
      "match": "NO",
      "loss": "Dropped 'Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.'"
    },
    {
      "column": "BINCountry",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Passthrough from Dim_Country via fbd.BinCountryIDAsInteger.",
      "match": "NO",
      "loss": "Same truncation as Country: dropped 'Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.'"
    },
    {
      "column": "Registered",
      "upstream_quote": "Account registration date (renamed from Registered). Default=getdate().",
      "wiki_quote": "Account registration date. Passthrough from Dim_Customer.RegisteredReal.",
      "match": "MINOR",
      "loss": "Dropped '(renamed from Registered)' rename provenance and 'Default=getdate()' default value note"
    },
    {
      "column": "SerialID",
      "upstream_quote": "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations.",
      "wiki_quote": "Affiliate (partner) ID under which the customer was acquired. Passthrough from Dim_Customer.AffiliateID (renamed from SerialID in Customer.CustomerStatic). NULL for direct/organic registrations.",
      "match": "MINOR",
      "loss": "Dropped 'FK to BackOffice.Affiliate'; rename clause reworded"
    },
    {
      "column": "Funnel",
      "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.",
      "wiki_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Resolved from Dim_Funnel on fbd.FunnelID.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FunnelFrom",
      "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.",
      "wiki_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Resolved from Dim_Funnel on Dim_Customer.FunnelFromID.",
      "match": "YES",
      "loss": "Shares identical base description with Funnel and AcquisitionFunnel; business distinction only in trailing JOIN clause — could confuse analysts"
    },
    {
      "column": "AcquisitionFunnel",
      "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.",
      "wiki_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Resolved from Dim_Funnel on Dim_Customer.FunnelID.",
      "match": "YES",
      "loss": "Same as FunnelFrom — three funnel columns indistinguishable from lead sentence alone"
    },
    {
      "column": "CreditCardType",
      "upstream_quote": "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital.",
      "wiki_quote": "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "DepoName",
      "upstream_quote": "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports.",
      "wiki_quote": "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "FundingType",
      "upstream_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay).",
      "wiki_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "MatchStatusID",
      "upstream_quote": "PSP reconciliation match status. Default 0=Unmatched; 3=Matched. Used for provider reconciliation workflows.",
      "wiki_quote": "PSP reconciliation match status. Default 0=Unmatched; 3=Matched. Used for provider reconciliation workflows.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Country / BINCountry",
      "problem": "Both descriptions truncate Dim_Country.Name verbatim: dropped 'Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.' Analyst cannot tell the values are unique (join safety implication) or how the field surfaces in product."
    },
    {
      "severity": "medium",
      "column_or_section": "PaymentStatus_PaymentStatusID",
      "problem": "Inherited enum values from Dim_PaymentStatus element table ('1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally') contradict Dim_PaymentStatus Section 1 (2=Approved, 3=Decline, 35=DeclineByRRE). An analyst reading the description will have the wrong value map. Writer should have cross-checked the dim's Section 1 against the element table and written the correct values."
    },
    {
      "severity": "low",
      "column_or_section": "IsFTD",
      "problem": "Dropped '~60.6% of deposits are FTD=1 in Billing.Deposit' (distribution context) and 'Stored as int in DWH (vs. bit in production)' (type divergence). The type note matters for CAST compatibility in downstream joins."
    },
    {
      "severity": "low",
      "column_or_section": "Registered",
      "problem": "Dropped '(renamed from Registered). Default=getdate()' from Dim_Customer.RegisteredReal upstream description. The rename provenance and default are useful lineage context."
    },
    {
      "severity": "low",
      "column_or_section": "Funnel / FunnelFrom / AcquisitionFunnel",
      "problem": "All three columns have identical lead descriptions. The distinction (deposit-time funnel vs. customer FunnelFromID vs. customer FunnelID) is buried in a trailing 'Resolved from...' clause. An analyst skimming the table cannot distinguish these three columns from the description alone."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Country + BINCountry: restore full Dim_Country.Name verbatim — add 'Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.' (2) PaymentStatus_PaymentStatusID: do NOT copy the Dim_PaymentStatus element entry blindly; cross-check against Section 1 of that wiki and rewrite enum as: 1=New, 2=Approved, 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE — consistent with BI_DB_Deposits.PaymentStatusID usage. (3) IsFTD: add '~60.6% of deposits are FTD=1 in Billing.Deposit. Note: stored as bit in BI_DB_Deposits (vs. int in Fact_BillingDeposit).' (4) Registered: add '(renamed from Dim_Customer.RegisteredReal, which is Registered in Customer.CustomerStatic). Default=getdate() at registration time.' (5) Funnel/FunnelFrom/AcquisitionFunnel: lead each with a distinct sentence — e.g., Funnel='Funnel context at deposit time (from Fact_BillingDeposit.FunnelID)', FunnelFrom='Customer's from-funnel variant at registration (Dim_Customer.FunnelFromID)', AcquisitionFunnel='Customer's primary acquisition funnel (Dim_Customer.FunnelID)'.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
