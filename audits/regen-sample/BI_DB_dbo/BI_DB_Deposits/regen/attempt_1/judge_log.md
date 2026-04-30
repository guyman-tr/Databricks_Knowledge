## Judge Review: BI_DB_dbo.BI_DB_Deposits

---

### Per-Dimension Scores

| Dim | Score | One-line justification |
|-----|-------|------------------------|
| D1 Tier Accuracy (25%) | **6** | 0/5 tier mismatches (base 10), but 2 sampled T1 columns have paraphrasing failures (Funnel, CreditCardType) → −4 |
| D2 Upstream Fidelity (20%) | **3** | 7 confirmed paraphrasing failures: Funnel/FunnelFrom/AcquisitionFunnel (all replace upstream text with routing statements), CreditCardType (drops 18-item enum), PaymentStatus_PaymentStatusID (no verbatim), DepoName (fabricated examples), RiskManagementStatusID (drops key codes) |
| D3 Completeness (20%) | **8** | All 8 sections, 52/52 elements, correct footer; minor: some dictionary columns (FundingType, Channel) don't enumerate all values |
| D4 Business Meaning (15%) | **9** | Row count, date range, ETL pattern (incremental UPDATE+INSERT), SP name, PI exclusion rule all present |
| D5 Data Evidence (10%) | **8** | Row count and date range corroborated; status enums cited; phases 11/14 suggests data sampling ran |
| D6 Shape Fidelity (10%) | **8** | Correct structure throughout; minor: quality score shows "pending/10" rather than a numeric value |

**Weighted Score: 0.25×6 + 0.20×3 + 0.20×8 + 0.15×9 + 0.10×8 + 0.10×8 = 1.50 + 0.60 + 1.60 + 1.35 + 0.80 + 0.80 = 6.65 → FAIL**

---

### T1 Fidelity Table

| Column | Upstream Quote (verbatim) | Wiki Quote (verbatim) | Match | Loss |
|--------|--------------------------|----------------------|-------|------|
| DepositID | "Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH." | "Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY)." | MINOR | Drops DWH-specific distribution/index notes |
| RiskManagementStatusID | "Result of the pre-processing risk management check. 69 distinct risk reason codes. NULL=no risk check recorded. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation." | "Result of the pre-processing risk management check. NULL=no risk check recorded." | NO | Drops 69-code count and all key code enumerations |
| PaymentStatus_PaymentStatusID | "Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally." | "Denormalized payment status ID from Dim_PaymentStatus. Passthrough from Dim_PaymentStatus." | NO | Entirely replaced upstream text with generic passthrough statement; drops all enum values |
| PaymentStatus_Name | "Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports." | "Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports. Passthrough from Dim_PaymentStatus." | MINOR | Adds editorial note; otherwise preserved |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Passthrough from Dim_Country via Dim_Customer.CountryID." | MINOR | Drops "Unique per row." and usage contexts |
| Funnel | "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration." | "Funnel name at deposit time, resolved from Dim_Funnel on fbd.FunnelID. Passthrough from Dim_Funnel.Name." | NO | Entire upstream description replaced with routing statement |
| FunnelFrom | "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration." | "Source funnel variant name for the customer, resolved from Dim_Funnel on Dim_Customer.FunnelFromID. Passthrough from Dim_Funnel.Name." | NO | Same failure as Funnel |
| AcquisitionFunnel | "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration." | "Registration funnel name for the customer, resolved from Dim_Funnel on Dim_Customer.FunnelID. Passthrough from Dim_Funnel.Name." | NO | Same failure as Funnel |
| CreditCardType | "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital." | "Card brand name (e.g., Visa, Master Card, Diners, Maestro). Passthrough from Dim_CardType.CarTypeName." | NO | Drops full 18-item enum, uniqueness constraint, usage context, and rename note |
| BINCountry | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English for the card-issuing country. Passthrough from Dim_Country.Name via fbd.BinCountryIDAsInteger." | MINOR | Drops "Unique per row." and usage context; adds routing note |
| DepoName | "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports." | "Human-readable depot name (e.g., Checkout, PayPal, Wire, Tribe). Passthrough from Dim_BillingDepot.Name." | NO | Fabricated examples (Checkout, PayPal, Tribe not in upstream); drops "Unique across all depots." and usage context |
| Registered | "Account registration date (renamed from Registered). Default=getdate()." | "Account registration date. Passthrough from Dim_Customer.RegisteredReal." | MINOR | Drops rename provenance and Default=getdate() |
| SerialID | "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations." | "Affiliate (partner) ID under which the customer was acquired. Passthrough from Dim_Customer.AffiliateID (renamed from SerialID in Customer.CustomerStatic). NULL for direct/organic registrations." | MINOR | Drops "FK to BackOffice.Affiliate." |
| IsFTD | "First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. ~60.6% of deposits are FTD=1 in Billing.Deposit. Stored as int in DWH (vs. bit in production)." | "First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type." | MINOR | Drops ~60.6% prevalence stat and bit→int type note |

---

### Top 5 Issues

1. **HIGH — Funnel / FunnelFrom / AcquisitionFunnel**: Three Tier 1 columns from Dim_Funnel.Name have their upstream descriptions ("Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.") entirely replaced with routing passthrough statements. This is a 3-column mass paraphrasing failure — an analyst gets zero information about what the funnel name means.

2. **HIGH — CreditCardType**: Upstream Dim_CardType.CarTypeName verbatim includes 18-item full enum (0=None through 17=GE Capital), uniqueness constraint, usage context ("Used in payment UI, transaction records, and fraud reporting"), and rename provenance ("Renamed from `Name` in production"). Writer condensed to just 4 examples and a passthrough note, dropping the complete reference data.

3. **HIGH — PaymentStatus_PaymentStatusID**: Upstream text ("Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally.") was entirely discarded and replaced with "Denormalized payment status ID from Dim_PaymentStatus. Passthrough from Dim_PaymentStatus." — not a single word of upstream text carried through.

4. **HIGH — DepoName**: Writer produced fabricated examples ("Checkout, PayPal, Wire, Tribe") that do not appear in Dim_BillingDepot's upstream description ("MoneyBookers USD", "Neteller", "Wire"). "Checkout" and "Tribe" are not real depot names documented in the upstream wiki. Also drops "Unique across all depots." and "Used in admin dashboards, routing logs, and discrepancy reports."

5. **MEDIUM — RiskManagementStatusID**: The upstream Fact_BillingDeposit description includes "69 distinct risk reason codes" and "Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation." — all dropped. An analyst querying this column has no diagnostic vocabulary for interpreting values.

---

### Regeneration Feedback

1. **Funnel, FunnelFrom, AcquisitionFunnel**: Replace each description with verbatim from Dim_Funnel.Name upstream: *"Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration."* Then append the contextual routing note (which join) as a supplement, NOT as replacement.

2. **CreditCardType**: Use verbatim Dim_CardType.CarTypeName upstream including the complete 18-item enum list. Quote: *"Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital."*

3. **PaymentStatus_PaymentStatusID**: Copy verbatim from Dim_PaymentStatus Element 1: *"Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally."*

4. **DepoName**: Use verbatim Dim_BillingDepot.Name upstream: *"Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports."* Remove fabricated examples.

5. **RiskManagementStatusID**: Restore from Fact_BillingDeposit upstream: add "69 distinct risk reason codes." and "Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation."

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Deposits",
  "weighted_score": 6.65,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 6,
    "upstream_fidelity": 3,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "DepositID",
      "upstream_quote": "Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH.",
      "wiki_quote": "Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY).",
      "match": "MINOR",
      "loss": "Drops DWH-specific distribution and index notes"
    },
    {
      "column": "RiskManagementStatusID",
      "upstream_quote": "Result of the pre-processing risk management check. 69 distinct risk reason codes. NULL=no risk check recorded. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation.",
      "wiki_quote": "Result of the pre-processing risk management check. NULL=no risk check recorded.",
      "match": "NO",
      "loss": "Drops 69-code count and all key code enumerations (1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation)"
    },
    {
      "column": "PaymentStatus_PaymentStatusID",
      "upstream_quote": "Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally.",
      "wiki_quote": "Denormalized payment status ID from Dim_PaymentStatus. Passthrough from Dim_PaymentStatus.",
      "match": "NO",
      "loss": "Entire upstream text replaced with generic passthrough statement; all enum values dropped"
    },
    {
      "column": "PaymentStatus_Name",
      "upstream_quote": "Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports.",
      "wiki_quote": "Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports. Passthrough from Dim_PaymentStatus.",
      "match": "MINOR",
      "loss": "Added editorial passthrough note; core content preserved"
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Passthrough from Dim_Country via Dim_Customer.CountryID.",
      "match": "MINOR",
      "loss": "Drops 'Unique per row.' and usage context"
    },
    {
      "column": "Funnel",
      "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.",
      "wiki_quote": "Funnel name at deposit time, resolved from Dim_Funnel on fbd.FunnelID. Passthrough from Dim_Funnel.Name.",
      "match": "NO",
      "loss": "Entire upstream description replaced with routing statement; all meaning and usage context lost"
    },
    {
      "column": "FunnelFrom",
      "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.",
      "wiki_quote": "Source funnel variant name for the customer, resolved from Dim_Funnel on Dim_Customer.FunnelFromID. Passthrough from Dim_Funnel.Name.",
      "match": "NO",
      "loss": "Same failure as Funnel — upstream description replaced with routing statement"
    },
    {
      "column": "AcquisitionFunnel",
      "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.",
      "wiki_quote": "Registration funnel name for the customer, resolved from Dim_Funnel on Dim_Customer.FunnelID. Passthrough from Dim_Funnel.Name.",
      "match": "NO",
      "loss": "Same failure as Funnel — upstream description replaced with routing statement"
    },
    {
      "column": "CreditCardType",
      "upstream_quote": "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital.",
      "wiki_quote": "Card brand name (e.g., Visa, Master Card, Diners, Maestro). Passthrough from Dim_CardType.CarTypeName.",
      "match": "NO",
      "loss": "Drops full 18-item enum list, uniqueness constraint, usage context, and rename provenance"
    },
    {
      "column": "BINCountry",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English for the card-issuing country. Passthrough from Dim_Country.Name via fbd.BinCountryIDAsInteger.",
      "match": "MINOR",
      "loss": "Drops 'Unique per row.' and usage context; adds routing context"
    },
    {
      "column": "DepoName",
      "upstream_quote": "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports.",
      "wiki_quote": "Human-readable depot name (e.g., Checkout, PayPal, Wire, Tribe). Passthrough from Dim_BillingDepot.Name.",
      "match": "NO",
      "loss": "Fabricated examples (Checkout, Tribe) not in upstream; drops 'Unique across all depots.' and usage context"
    },
    {
      "column": "Registered",
      "upstream_quote": "Account registration date (renamed from Registered). Default=getdate().",
      "wiki_quote": "Account registration date. Passthrough from Dim_Customer.RegisteredReal.",
      "match": "MINOR",
      "loss": "Drops rename provenance and Default=getdate()"
    },
    {
      "column": "SerialID",
      "upstream_quote": "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations.",
      "wiki_quote": "Affiliate (partner) ID under which the customer was acquired. Passthrough from Dim_Customer.AffiliateID (renamed from SerialID in Customer.CustomerStatic). NULL for direct/organic registrations.",
      "match": "MINOR",
      "loss": "Drops 'FK to BackOffice.Affiliate.'"
    },
    {
      "column": "IsFTD",
      "upstream_quote": "First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. ~60.6% of deposits are FTD=1 in Billing.Deposit. Stored as int in DWH (vs. bit in production).",
      "wiki_quote": "First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type.",
      "match": "MINOR",
      "loss": "Drops ~60.6% prevalence stat and int vs. bit type note"
    },
    {
      "column": "FundingType",
      "upstream_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay).",
      "wiki_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Passthrough from Dim_FundingType.",
      "match": "MINOR",
      "loss": "Added editorial routing note; core content preserved"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Funnel, FunnelFrom, AcquisitionFunnel",
      "problem": "Three Tier 1 columns from Dim_Funnel.Name have their upstream description ('Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.') entirely replaced with routing passthrough statements. Analyst gets no information about what the funnel name means."
    },
    {
      "severity": "high",
      "column_or_section": "CreditCardType",
      "problem": "Upstream Dim_CardType.CarTypeName verbatim includes full 18-item enum (0=None through 17=GE Capital), uniqueness constraint, usage context, and rename note. Writer condensed to 4 examples and a passthrough note, dropping the complete reference data."
    },
    {
      "severity": "high",
      "column_or_section": "PaymentStatus_PaymentStatusID",
      "problem": "Upstream text ('Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally.') was discarded entirely and replaced with 'Denormalized payment status ID from Dim_PaymentStatus. Passthrough from Dim_PaymentStatus.' Not a single word of upstream text carried through."
    },
    {
      "severity": "high",
      "column_or_section": "DepoName",
      "problem": "Writer used fabricated examples ('Checkout, PayPal, Wire, Tribe') not appearing in Dim_BillingDepot upstream ('MoneyBookers USD', 'Neteller', 'Wire'). 'Checkout' and 'Tribe' are invented. Also drops 'Unique across all depots.' and usage context ('admin dashboards, routing logs, and discrepancy reports')."
    },
    {
      "severity": "medium",
      "column_or_section": "RiskManagementStatusID",
      "problem": "Upstream Fact_BillingDeposit description includes '69 distinct risk reason codes.' and 'Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation.' — all dropped. Analyst has no diagnostic vocabulary for interpreting risk management status values."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Funnel/FunnelFrom/AcquisitionFunnel: replace routing statements with verbatim Dim_Funnel.Name upstream text: 'Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.' (2) CreditCardType: use full verbatim Dim_CardType.CarTypeName text including complete 18-item enum (0=None through 17=GE Capital), uniqueness constraint, usage context, and rename note. (3) PaymentStatus_PaymentStatusID: copy verbatim from Dim_PaymentStatus Element 1 text including all enum values. (4) DepoName: use upstream examples from Dim_BillingDepot.Name ('MoneyBookers USD', 'Neteller', 'Wire') not fabricated ones; restore 'Unique across all depots.' and usage context. (5) RiskManagementStatusID: restore '69 distinct risk reason codes.' and 'Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation.' from Fact_BillingDeposit upstream.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
