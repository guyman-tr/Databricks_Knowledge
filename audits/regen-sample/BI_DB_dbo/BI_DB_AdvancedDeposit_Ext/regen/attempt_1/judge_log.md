# Adversarial Review: BI_DB_dbo.BI_DB_AdvancedDeposit_Ext

## Critical Finding

The upstream bundle states unambiguously: **"NO UPSTREAM WIKI was resolvable for any source listed in the lineage."** Yet the writer tagged **34 of 47 columns as Tier 1** — claiming verbatim inheritance from upstream wikis that do not exist. Every single Tier 1 assignment is fabricated. The descriptions read convincingly (specific enum values, NULL semantics, vendor names), but they cannot be "verbatim from upstream wiki" when no upstream wiki was provided. This is exactly the pathological optimism this review process exists to catch.

---

## Per-Dimension Scores

### Dimension 1 — Tier Accuracy: **3/10**

Sampled 5 columns: Amount (#9), Country (#34), Funnel (#39), Approved (#14), DepoName (#46). All tagged Tier 1. All wrong — no upstream wiki exists for any source, so Tier 1 is impossible. All should be Tier 2 (lineage traceable from SP code but no wiki to quote). 5/5 mismatches → base score 3. PaymentStatusID (#6) even references "Full 39-value enum in upstream wiki" — an upstream wiki the bundle says doesn't exist.

### Dimension 2 — Upstream Fidelity: **3/10**

The neutral score of 7 applies when the writer *correctly identifies* that no upstream wiki exists and adjusts tiers accordingly. This writer did the opposite: fabricated 34 Tier 1 assignments with descriptions styled as verbatim quotes from nonexistent wikis. This is "wrong tier origin" across the board → score 3.

### Dimension 3 — Completeness: **8/10**

Structurally solid. All 8 sections present. 47/47 elements match DDL. All element rows have 5 cells with tier tags. Property table complete. ETL diagram present with real names. Footer has tier breakdown. Date range is legitimately N/A for an empty table. The review-needed sidecar correctly omits `## 4. Elements`. ~9/10 checks pass → score 8.

### Dimension 4 — Business Meaning: **8/10**

Section 1 is genuinely good for a dormant table. It explains: the table's purpose (extended deposit denormalization), that it's empty, the decommission timeline (~Nov 2024), the relationship to SP_H_Deposits and BI_DB_Deposits, the 6 source groupings, and a cleanup recommendation. Missing an explicit row-grain statement, but the context makes "one row per deposit attempt" clear.

### Dimension 5 — Data Evidence: **5/10**

Row count (0) confirmed via live query per the review-needed sidecar. But there is no visible Phase Gate Checklist section with P2/P3 checkboxes. The footer claims "Phases: 13/14" without showing which phases. The specific enum values cited (e.g., PaymentStatusID key values, CreditCardType brands) appear authoritative but cannot have come from live data on this empty table — they're either from SP code reading or fabricated.

### Dimension 6 — Shape Fidelity: **8/10**

Good adherence to the golden shape: numbered sections, tier legend in Section 4, SQL samples in Section 7 (redirecting appropriately to BI_DB_Deposits), footer with quality score and tier breakdown. Missing a formal Phase Gate Checklist section. Minor: Section 8 is "Atlassian Knowledge Sources" rather than the expected heading.

---

## T1 Fidelity Table

Every Tier 1 column fails because no upstream wiki exists. Representative sample:

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| DepositID | **NO UPSTREAM WIKI EXISTS** | "Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Passthrough from Fact_BillingDeposit." | NO | Entire description is fabricated — no upstream wiki to quote from |
| Amount | **NO UPSTREAM WIKI EXISTS** | "Deposit amount in the deposit currency (CurrencyID). DWH note: as of 2025-04-17, capped via CASE expression..." | NO | Description invented; no source wiki available |
| PaymentStatusID | **NO UPSTREAM WIKI EXISTS** | "Current deposit status. Key values: 1=New, 2=Approved... Full 39-value enum in upstream wiki." | NO | Explicitly references "upstream wiki" that doesn't exist — fabrication |
| Country | **NO UPSTREAM WIKI EXISTS** | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | NO | Description fabricated; tagged Tier 1 — Dictionary.Country with no wiki |
| Funnel | **NO UPSTREAM WIKI EXISTS** | "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views..." | NO | Fabricated; same description copy-pasted for Funnel, FunnelFrom, AcquisitionFunnel |
| CreditCardType | **NO UPSTREAM WIKI EXISTS** | "Card brand name. DDL note: source column has a typo..." | NO | Description fabricated; specific card brand list not from any wiki |
| DepoName | **NO UPSTREAM WIKI EXISTS** | "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire')..." | NO | Vendor names fabricated — no upstream wiki to inherit from |
| BINCountry | **NO UPSTREAM WIKI EXISTS** | "Full country name in English. Unique per row..." | NO | Copy of Country description; no wiki source |
| PaymentStatus_Name | **NO UPSTREAM WIKI EXISTS** | "Human-readable status label. UNIQUE constraint..." | NO | Fabricated Tier 1 claim for Dictionary.PaymentStatus |
| Registered | **NO UPSTREAM WIKI EXISTS** | "Account registration date (renamed from Registered). Default=getdate()." | NO | Fabricated Tier 1 claim for Customer.CustomerStatic |

All 34 claimed Tier 1 columns fail upstream fidelity because no upstream wiki was available.

---

## Top 5 Issues

1. **HIGH — All 34 Tier 1 columns (entire Elements table)**: No upstream wiki exists in the bundle. Every Tier 1 tag is invalid. All should be Tier 2 (SP code-traced) with descriptions clearly marked as inferred from code, not inherited from documentation.

2. **HIGH — PaymentStatusID (#6)**: Description explicitly states "Full 39-value enum in upstream wiki" — this upstream wiki does not exist. This is not paraphrasing; it's fabricating a source reference.

3. **HIGH — Funnel (#39), FunnelFrom (#40), AcquisitionFunnel (#41)**: All three share an identical description copy-pasted verbatim ("Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.") Despite being three different join paths with different business meanings (deposit funnel vs. source funnel vs. customer funnel).

4. **MEDIUM — Country (#34) and BINCountry (#45)**: Share nearly identical descriptions ("Full country name in English. Unique per row...") — both tagged Tier 1 from Dictionary.Country with no wiki to support. The descriptions should differentiate: Country is the customer's registration country, BINCountry is the card-issuing bank's country.

5. **MEDIUM — Missing Phase Gate Checklist**: Footer claims "Phases: 13/14" but no Phase Gate Checklist section exists in the document. There is no way to verify which phases were completed or skipped.

---

## Regeneration Feedback

1. **Re-tag all 34 Tier 1 columns to Tier 2.** No upstream wiki was available in the bundle. Every column description should end with `(Tier 2 — SP_H_Deposits code analysis)` or the appropriate Tier 2 source. Remove all claims of verbatim inheritance.
2. **Remove the fabricated "upstream wiki" reference** in PaymentStatusID (#6). Replace with `(Tier 2 — SP_H_Deposits, enum values inferred from Fact_BillingDeposit column domain)`.
3. **Differentiate the three Funnel columns** (#39, #40, #41). Each resolves a different FK: Funnel = deposit-level funnel (fbd.FunnelID), FunnelFrom = customer's original acquisition funnel (Dim_Customer.FunnelFromID), AcquisitionFunnel = customer's current funnel (Dim_Customer.FunnelID). Do not copy-paste the same description.
4. **Differentiate Country (#34) vs BINCountry (#45).** Country = customer's registration country. BINCountry = card-issuing bank's country. The wiki already notes the fraud-detection significance in BINCountry but the core description is a copy-paste.
5. **Add a formal Phase Gate Checklist section** or remove the "Phases: 13/14" claim from the footer. Show which phases were completed and which were skipped.
6. **Update the footer tier breakdown** to reflect the corrected tiers: 0 T1, 47 T2 (or similar after proper reclassification).

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AdvancedDeposit_Ext",
  "weighted_score": 5.15,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 3,
    "completeness": 8,
    "business_meaning": 8,
    "data_evidence": 5,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "DepositID",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Passthrough from Fact_BillingDeposit.",
      "match": "NO",
      "loss": "Entire Tier 1 claim fabricated — no upstream wiki was available to quote from"
    },
    {
      "column": "Amount",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Deposit amount in the deposit currency (CurrencyID). DWH note: as of 2025-04-17, capped via CASE expression in upstream ETL to prevent extreme outlier values from distorting aggregations. Passthrough from Fact_BillingDeposit.",
      "match": "NO",
      "loss": "Description invented without wiki source; specific DWH note may be from code but not from a documented wiki"
    },
    {
      "column": "PaymentStatusID",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Current deposit status. Key values: 1=New, 2=Approved, 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE. Full 39-value enum in upstream wiki. Passthrough from Fact_BillingDeposit.",
      "match": "NO",
      "loss": "Fabricated reference to 'upstream wiki' that does not exist; enum values not verifiable from any provided wiki"
    },
    {
      "column": "Country",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Dim_Customer.CountryID.",
      "match": "NO",
      "loss": "Fabricated Tier 1 claim from Dictionary.Country; description invented"
    },
    {
      "column": "Funnel",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Dim-lookup passthrough from Dim_Funnel.Name via fbd.FunnelID.",
      "match": "NO",
      "loss": "Fabricated Tier 1 claim from Dictionary.Funnel; identical description copy-pasted across 3 funnel columns"
    },
    {
      "column": "FunnelFrom",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Dim-lookup passthrough from Dim_Funnel.Name via Dim_Customer.FunnelFromID.",
      "match": "NO",
      "loss": "Identical copy-paste from Funnel column; fabricated Tier 1"
    },
    {
      "column": "AcquisitionFunnel",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Dim-lookup passthrough from Dim_Funnel.Name via Dim_Customer.FunnelID.",
      "match": "NO",
      "loss": "Identical copy-paste from Funnel column; fabricated Tier 1"
    },
    {
      "column": "CreditCardType",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Card brand name. DDL note: source column has a typo ('CarTypeName' instead of 'CardTypeName') — historical artifact from legacy DWH SQL Server migration. Key values: Visa, Master Card, MasterCard, Diners, Amex, American Express, Maestro, Discover, China Union Pay. Dim-lookup passthrough from Dim_CardType.CarTypeName via fbd.CardTypeIDAsInteger.",
      "match": "NO",
      "loss": "Fabricated Tier 1 from Dictionary.CardType; card brand list not sourced from any wiki"
    },
    {
      "column": "DepoName",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. Dim-lookup passthrough from Dim_BillingDepot.Name via fbd.DepotID.",
      "match": "NO",
      "loss": "Fabricated Tier 1 from Billing.Depot; vendor names (MoneyBookers, Neteller) not sourced from any wiki"
    },
    {
      "column": "BINCountry",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via fbd.BinCountryIDAsInteger. May differ from customer's registration country (Country column) — useful for fraud detection.",
      "match": "NO",
      "loss": "Copy-paste of Country description with fraud note appended; fabricated Tier 1"
    },
    {
      "column": "Registered",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Account registration date (renamed from Registered). Default=getdate(). Dim-lookup passthrough from Dim_Customer.RegisteredReal.",
      "match": "NO",
      "loss": "Fabricated Tier 1 from Customer.CustomerStatic; no wiki exists"
    },
    {
      "column": "SerialID",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. Dim-lookup passthrough from Dim_Customer.AffiliateID (renamed from Customer.CustomerStatic.SerialID).",
      "match": "NO",
      "loss": "Fabricated Tier 1 from Customer.CustomerStatic; NULL semantics not verifiable"
    },
    {
      "column": "PaymentStatus_PaymentStatusID",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally. Denormalized dim-lookup passthrough from Dim_PaymentStatus.PaymentStatusID on fbd.PaymentStatusID.",
      "match": "NO",
      "loss": "Fabricated Tier 1 from Dictionary.PaymentStatus; enum values not from any wiki"
    },
    {
      "column": "PaymentStatus_Name",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports. Denormalized dim-lookup passthrough from Dim_PaymentStatus.Name on fbd.PaymentStatusID.",
      "match": "NO",
      "loss": "Fabricated Tier 1 from Dictionary.PaymentStatus"
    },
    {
      "column": "FundingType",
      "upstream_quote": "NO UPSTREAM WIKI EXISTS IN BUNDLE",
      "wiki_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Dim-lookup passthrough from Dim_FundingType.Name via External_etoro_Billing_Funding_Datafactory.FundingTypeID.",
      "match": "NO",
      "loss": "Fabricated Tier 1 from Dictionary.FundingType; payment method examples not from any wiki"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "All 34 claimed Tier 1 columns",
      "problem": "The upstream bundle explicitly states 'NO UPSTREAM WIKI was resolvable for any source listed in the lineage.' Every Tier 1 tag is invalid — no wiki existed to quote verbatim from. All 34 should be Tier 2 (SP code-traced) or Tier 3."
    },
    {
      "severity": "high",
      "column_or_section": "PaymentStatusID (#6)",
      "problem": "Description states 'Full 39-value enum in upstream wiki' — this upstream wiki does not exist per the bundle. This is a fabricated source reference."
    },
    {
      "severity": "high",
      "column_or_section": "Funnel (#39), FunnelFrom (#40), AcquisitionFunnel (#41)",
      "problem": "All three columns share an identical copy-pasted description despite representing three different join paths with different business semantics (deposit funnel vs. source funnel vs. current funnel)."
    },
    {
      "severity": "medium",
      "column_or_section": "Country (#34), BINCountry (#45)",
      "problem": "Near-identical descriptions copy-pasted. Country is customer registration country; BINCountry is card-issuing bank country. Core description should differentiate these."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer / Phase Gate",
      "problem": "Footer claims 'Phases: 13/14' but no Phase Gate Checklist section exists in the document. Cannot verify which phases were completed or skipped."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag ALL 34 Tier 1 columns to Tier 2 — no upstream wiki was available in the bundle, so Tier 1 inheritance is impossible. Use '(Tier 2 — SP_H_Deposits code analysis)' or equivalent. (2) Remove fabricated 'upstream wiki' reference in PaymentStatusID. (3) Write distinct descriptions for Funnel, FunnelFrom, and AcquisitionFunnel explaining the different join paths and business meanings. (4) Differentiate Country (customer registration) vs BINCountry (card issuer) descriptions. (5) Add a Phase Gate Checklist section or remove the 'Phases: 13/14' footer claim. (6) Update footer tier breakdown to 0 T1, ~47 T2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "PaymentStatusID: claims '39-value enum in upstream wiki' — upstream wiki does not exist",
      "PaymentStatus_PaymentStatusID: lists 7 enum values without wiki source",
      "CreditCardType: lists 9 card brand values without wiki source",
      "FundingType: lists 7 payment method examples without wiki source"
    ],
    "skipped_phases": [
      "Phase Gate Checklist section entirely absent — cannot determine which phases were skipped"
    ]
  }
}
</JUDGE_VERDICT>
