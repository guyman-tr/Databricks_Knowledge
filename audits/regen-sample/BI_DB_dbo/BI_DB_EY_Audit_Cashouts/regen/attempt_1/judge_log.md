## Judge Review: BI_DB_dbo.BI_DB_EY_Audit_Cashouts

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 7/10**
Sampled 5 columns: RealCID (Tier 1 ✓), PaymentMethod (Tier 1 ✓), Depot (Tier 1 ✓), CardType (Tier 1 ✓), IsCreditReportValidCB (claimed Tier 2, should be Tier 1 — passthrough from Fact_SnapshotCustomer which has an upstream wiki). 1 mismatch. Additionally, BaseExchangeRate and ExchangeFee are passthroughs from BI_DB_DepositWithdrawFee (which has a wiki) but tagged Tier 2 — these should be Tier 1.

**Dimension 2 — Upstream Fidelity: 5/10**
CardType description drops 9 card types (Laser, Switch, UK Local, Discover, Local Card, China Union Pay, Solo, Cirrus, GE Capital) and removes production context ("Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from Name in production."). Amount description completely rewritten from upstream "Position size in currency" to "Cashout/refund/chargeback amount in USD" with source changed from Trade.PositionTbl to History.Credit — contextually more accurate for cashouts but not verbatim. See full T1 fidelity table below.

**Dimension 3 — Completeness: 8/10**
9 of 10 checks pass. Missing: UC Target row in the property table. All 8 sections present, 19/19 elements match DDL, tier tags on all descriptions, ETL pipeline diagram present, footer has tier counts, review-needed sidecar does not contain Section 4.

**Dimension 4 — Business Meaning: 9/10**
Excellent. Section 1 is specific: names domain (EY audit), row grain (one withdrawal event), ETL SP, refresh pattern (DELETE+INSERT with auto-backfill), row count (~6.8M), date range (2023-01-01), ActionType distribution percentages, specific filter conditions (CashoutStatusID_Funding=3). Analyst would immediately know when and why to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count (~6.8M) and date range in Section 1. Specific ActionType distribution (95.3% Cashout, 4.5% Reverse). Footer says "Phases: 12/14" suggesting P2/P3 were executed. Data claims appear grounded.

**Dimension 6 — Shape Fidelity: 8/10**
All 8 numbered sections present, tier legend in Section 4, 3 real SQL queries in Section 7, footer with quality score and tier breakdown. Minor: tier legend only lists Tier 1 and Tier 2 (no Tier 3-5 even though the golden shape typically includes all).

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." (Dim_Customer) | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | YES | — |
| ExternalID | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format." (Dim_Customer) | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer." | MINOR | Added "Passthrough from Dim_Customer" — no semantic loss |
| WithdrawID | "Withdrawal request ID for cashout events. 0 for non-cashout events." (Fact_CustomerAction) | "Withdrawal request ID for cashout events. 0 for non-cashout events." | YES | — |
| WithdrawPaymentID | "Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL." (Fact_CustomerAction) | "Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL." | YES | — |
| Occurred | "UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded." (Fact_CustomerAction) | "UTC timestamp when the action occurred. For credits: when the credit was recorded." | MINOR | Removed position/login context irrelevant to cashout table — meaning preserved |
| Amount | "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). (Tier 1 — Trade.PositionTbl)" (Fact_CustomerAction) | "Cashout/refund/chargeback amount in USD. Passthrough from Fact_CustomerAction.Amount for cashout-related ActionTypeIDs. (Tier 1 — History.Credit)" | NO | Complete rewrite of description and source attribution. Upstream says "Position size in currency" (Trade.PositionTbl context) but writer changed to "Cashout/refund/chargeback amount in USD" (History.Credit context). Writer's adaptation is contextually more accurate for cashout events, but violates verbatim rule. |
| PaymentMethod | "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay)." (Dim_FundingType) | "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Resolved via Dim_BillingDepot.FundingTypeID → Dim_FundingType.Name. NULL when no matching billing withdraw row exists." | MINOR | Core verbatim, added join path and NULL semantics |
| Depot | "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports." (Dim_BillingDepot) | "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. Resolved from Fact_BillingWithdraw.DepotID. NULL when no matching billing withdraw row exists." | MINOR | Core verbatim, added join context |
| CardType | "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital." (Dim_CardType) | "Card brand name. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro. Resolved from Fact_BillingWithdraw.CardTypeIDAsInteger via Dim_CardType.CarTypeName. NULL for non-card payment methods." | NO | Dropped: "Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from Name in production." Truncated card type list from 18 values (0-17) to 9 values (0-8), dropping Laser, Switch, UK Local, Discover, Local Card, China Union Pay, Solo, Cirrus, GE Capital. |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." (Dim_Regulation) | "Short code for the customer's regulatory jurisdiction at the time of the event. Values: CySEC, FCA, FSA Seychelles, FinCEN+FINRA, ASIC & GAML, FSRA, BVI, ASIC, MAS, eToroUS, FinCEN. Resolved from Fact_SnapshotCustomer.RegulationID via Dim_Regulation.Name." | MINOR | Rewording adds context ("at the time of the event") and lists specific values — improvement, meaning preserved |
| VerificationCode | "Verification code supplied or received during withdrawal processing." (Fact_BillingWithdraw) | "Verification code supplied or received during withdrawal processing. Passthrough from Fact_BillingWithdraw." | MINOR | Core verbatim, added provenance note |

---

### Top 5 Issues

1. **HIGH — CardType: Truncated upstream value list.** Dropped 9 of 18 card types (IDs 9-17: Laser, Switch, UK Local Credit Card, Discover, Local Card, China Union Pay, Solo, Cirrus, GE Capital) and removed production context about uniqueness constraint and naming history. An analyst reading this wiki would not know these card types exist.

2. **HIGH — IsCreditReportValidCB, BaseExchangeRate, ExchangeFee: Mistagged as Tier 2 when they should be Tier 1.** IsCreditReportValidCB is a passthrough from Fact_SnapshotCustomer (which has an upstream wiki). BaseExchangeRate and ExchangeFee are passthroughs from BI_DB_DepositWithdrawFee (which has an upstream wiki). All three should be Tier 1 with verbatim upstream descriptions.

3. **MEDIUM — Amount: Source attribution changed from Trade.PositionTbl to History.Credit.** The upstream Fact_CustomerAction wiki tags Amount as "(Tier 1 — Trade.PositionTbl)" with description "Position size in currency." The writer changed this to "Cashout/refund/chargeback amount in USD (Tier 1 — History.Credit)." While contextually more accurate for cashout events, this is not verbatim inheritance. The review-needed sidecar correctly flagged this for verification.

4. **MEDIUM — Missing UC Target in property table.** The completeness checklist requires UC Target in the property table. This is absent, reducing the table's utility for Databricks-side analysts.

5. **LOW — Occurred description trimmed.** Upstream includes context for position opens and logins ("For position opens: when position was opened. For logins: login time.") which was dropped. While irrelevant to cashouts, the verbatim rule says to preserve the upstream text.

---

### Regeneration Feedback

1. **CardType**: Restore the full upstream description verbatim from Dim_CardType wiki, including all 18 card types (0-17), the uniqueness constraint note, and the rename note.
2. **IsCreditReportValidCB**: Re-tag as `(Tier 1 — Fact_SnapshotCustomer)` and use the upstream description: "1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3."
3. **BaseExchangeRate and ExchangeFee**: Re-tag as `(Tier 1 — BI_DB_DepositWithdrawFee)` and use the upstream descriptions verbatim: "Base FX rate from state" and "Exchange fee from state" respectively, with the Tier 2 attribution from the upstream wiki.
4. **Amount**: Either preserve the upstream verbatim text with an added note about cashout-specific semantics, or clearly document in the review-needed sidecar that the description was intentionally adapted and why.
5. **Property table**: Add UC Target row.

---

### Weighted Score

```
weighted = 0.25×7 + 0.20×5 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8
         = 1.75 + 1.00 + 1.60 + 1.35 + 0.70 + 0.80
         = 7.20
```

**Verdict: FAIL** (7.20 < 7.5)

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_EY_Audit_Cashouts",
  "weighted_score": 7.2,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 5,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "RealCID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "ExternalID",
      "upstream_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format.",
      "wiki_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Added 'Passthrough from Dim_Customer' — no semantic loss"
    },
    {
      "column": "WithdrawID",
      "upstream_quote": "Withdrawal request ID for cashout events. 0 for non-cashout events.",
      "wiki_quote": "Withdrawal request ID for cashout events. 0 for non-cashout events.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "WithdrawPaymentID",
      "upstream_quote": "Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL.",
      "wiki_quote": "Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Occurred",
      "upstream_quote": "UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded.",
      "wiki_quote": "UTC timestamp when the action occurred. For credits: when the credit was recorded.",
      "match": "MINOR",
      "loss": "Removed position/login context irrelevant to cashout table"
    },
    {
      "column": "Amount",
      "upstream_quote": "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "Cashout/refund/chargeback amount in USD. Passthrough from Fact_CustomerAction.Amount for cashout-related ActionTypeIDs. (Tier 1 — History.Credit)",
      "match": "NO",
      "loss": "Complete rewrite: 'Position size in currency' → 'Cashout/refund/chargeback amount in USD'. Source changed from Trade.PositionTbl to History.Credit. Contextually more accurate for cashouts but not verbatim."
    },
    {
      "column": "PaymentMethod",
      "upstream_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay).",
      "wiki_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Resolved via Dim_BillingDepot.FundingTypeID → Dim_FundingType.Name. NULL when no matching billing withdraw row exists.",
      "match": "MINOR",
      "loss": "Core verbatim, added join path and NULL semantics"
    },
    {
      "column": "Depot",
      "upstream_quote": "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports.",
      "wiki_quote": "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. Resolved from Fact_BillingWithdraw.DepotID. NULL when no matching billing withdraw row exists.",
      "match": "MINOR",
      "loss": "Core verbatim, added join context and NULL semantics"
    },
    {
      "column": "CardType",
      "upstream_quote": "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from Name in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital.",
      "wiki_quote": "Card brand name. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro. Resolved from Fact_BillingWithdraw.CardTypeIDAsInteger via Dim_CardType.CarTypeName. NULL for non-card payment methods.",
      "match": "NO",
      "loss": "Dropped: uniqueness constraint, payment UI usage note, rename note. Truncated card type list from 18 values (0-17) to 9 values (0-8), losing Laser, Switch, UK Local Credit Card, Discover, Local Card, China Union Pay, Solo, Cirrus, GE Capital."
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the customer's regulatory jurisdiction at the time of the event. Values: CySEC, FCA, FSA Seychelles, FinCEN+FINRA, ASIC & GAML, FSRA, BVI, ASIC, MAS, eToroUS, FinCEN. Resolved from Fact_SnapshotCustomer.RegulationID via Dim_Regulation.Name.",
      "match": "MINOR",
      "loss": "Minor rewording adds point-in-time context and lists specific values — improvement, meaning preserved"
    },
    {
      "column": "VerificationCode",
      "upstream_quote": "Verification code supplied or received during withdrawal processing.",
      "wiki_quote": "Verification code supplied or received during withdrawal processing. Passthrough from Fact_BillingWithdraw.",
      "match": "MINOR",
      "loss": "Core verbatim, added provenance note"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "CardType",
      "problem": "Upstream Dim_CardType.CarTypeName description lists 18 card types (0-17) with production context (unique constraint, payment UI usage, rename from Name). Wiki truncates to 9 values (0-8), dropping Laser, Switch, UK Local Credit Card, Discover, Local Card, China Union Pay, Solo, Cirrus, GE Capital and all production context."
    },
    {
      "severity": "high",
      "column_or_section": "IsCreditReportValidCB, BaseExchangeRate, ExchangeFee",
      "problem": "All three are passthroughs from upstream tables that have wikis (Fact_SnapshotCustomer, BI_DB_DepositWithdrawFee) but are tagged Tier 2 instead of Tier 1. IsCreditReportValidCB should be (Tier 1 — Fact_SnapshotCustomer). BaseExchangeRate and ExchangeFee should be (Tier 1 — BI_DB_DepositWithdrawFee)."
    },
    {
      "severity": "medium",
      "column_or_section": "Amount",
      "problem": "Upstream Fact_CustomerAction tags Amount as '(Tier 1 — Trade.PositionTbl)' with description 'Position size in currency.' Wiki rewrites to 'Cashout/refund/chargeback amount in USD (Tier 1 — History.Credit)'. Contextually more accurate for cashout ActionTypeIDs but not verbatim. Source attribution changed."
    },
    {
      "severity": "medium",
      "column_or_section": "Property table",
      "problem": "Missing UC Target row. Completeness checklist requires Production Source, Refresh, Distribution, and UC Target in the property table."
    },
    {
      "severity": "low",
      "column_or_section": "Occurred",
      "problem": "Upstream description includes 'For position opens: when position was opened. For logins: login time.' which was trimmed. While irrelevant to cashouts, verbatim inheritance requires preserving the full text."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Restore CardType description verbatim from Dim_CardType wiki including all 18 card types (0-17), uniqueness constraint note, and rename note. (2) Re-tag IsCreditReportValidCB as (Tier 1 — Fact_SnapshotCustomer) using upstream description. (3) Re-tag BaseExchangeRate and ExchangeFee as (Tier 1 — BI_DB_DepositWithdrawFee) using upstream descriptions. (4) For Amount, either preserve upstream verbatim with a contextual note, or document the adaptation rationale in review-needed. (5) Add UC Target row to the property table.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
