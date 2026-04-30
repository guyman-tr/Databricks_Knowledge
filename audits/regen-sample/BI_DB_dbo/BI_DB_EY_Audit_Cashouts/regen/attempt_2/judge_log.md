## Judge Review: BI_DB_dbo.BI_DB_EY_Audit_Cashouts

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (Regulation, DateID, CardType, IsCreditReportValidCB, Amount). All tier assignments are correct. Dim-lookup passthroughs correctly trace to the dim's root origin (e.g., CardType → Dictionary.CardType, PaymentMethod → Dictionary.FundingType). ETL-computed columns (DateID, Date, BankNameAsString, ActionType, UpdateDate) are correctly tagged Tier 2. No mismatches.

**Dimension 2 — Upstream Fidelity: 6/10**
One clear paraphrase: Regulation. The upstream (Dim_Regulation.Name) says *"Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name."* The wiki rewrote this to *"Short code for the customer's regulatory jurisdiction at the time of the event. Values: CySEC, FCA, ..."* — dropping the V_Dim_Customer reference and the production provenance note. Seven other Tier 1 columns have MINOR additions (appending resolution paths, NULL notes) but preserve the upstream core verbatim, which is acceptable.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count = 19 matches DDL exactly. Every element row has 5 cells with tier annotation. Property table complete. Section 5.2 has detailed ASCII pipeline. Footer has tier breakdown. Section 1 has row count and date range. Review-needed sidecar has no Section 4.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent — names domain (EY audit), row grain (one withdrawal event), ETL SP, refresh pattern (DELETE+INSERT with auto-backfill), row count (~6.8M), date range (2023-01-01), and ActionType distribution. Actionable and specific.

**Dimension 5 — Data Evidence: 8/10**
Row count (~6.8M), date range, and ActionType distribution percentages (95.3% Cashout, 4.5% Reverse cashout, etc.) are specific and appear data-backed. NULL semantics documented for PaymentMethod, BaseExchangeRate, ExchangeFee. Footer claims 12/14 phases.

**Dimension 6 — Shape Fidelity: 9/10**
All structural elements present: numbered sections, tier legend, real SQL in Section 7, footer with quality score and phases. Minor: no explicit Phase Gate Checklist section with checkboxes.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | YES | — |
| ExternalID | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format." | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer." | MINOR | Added resolution note |
| WithdrawID | "Withdrawal request ID for cashout events. 0 for non-cashout events." | "Withdrawal request ID for cashout events. 0 for non-cashout events." | YES | — |
| WithdrawPaymentID | "Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL." | "Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL." | YES | — |
| Occurred | "UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded." | "UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded." | YES | — |
| Amount | "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents)." | "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). DWH note: ..." | MINOR | Added DWH context note |
| PaymentMethod | "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay)." | "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Resolved via Dim_BillingDepot.FundingTypeID → Dim_FundingType.Name. NULL when no matching billing withdraw row exists." | MINOR | Added resolution path and NULL note |
| Depot | "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports." | "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. Resolved from Fact_BillingWithdraw.DepotID. NULL when no matching billing withdraw row exists." | MINOR | Added resolution path |
| CardType | "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from Name in production. 0=None, 1=Visa, 2=Master Card, ..." | "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from Name in production. 0=None, 1=Visa, 2=Master Card, ... Resolved from Fact_BillingWithdraw.CardTypeIDAsInteger via Dim_CardType.CarTypeName. NULL for non-card payment methods." | MINOR | Added resolution path |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the customer's regulatory jurisdiction at the time of the event. Values: CySEC, FCA, FSA Seychelles, FinCEN+FINRA, ASIC & GAML, FSRA, BVI, ASIC, MAS, eToroUS, FinCEN. Resolved from Fact_SnapshotCustomer.RegulationID via Dim_Regulation.Name." | NO | Rewrote entirely. Dropped "Used in V_Dim_Customer and analytics dashboards" and "Values match production Dictionary.Regulation.Name" |
| IsCreditReportValidCB | "1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3." | "1 if customer is eligible for CreditBureau credit report validation. ETL-computed in Fact_SnapshotCustomer from PlayerLevelID, AccountTypeID, LabelID, CountryID. Passthrough from point-in-time snapshot." | MINOR | Expanded computation details, dropped §2.3 ref |
| BaseExchangeRate | "Base FX rate from state." | "Base FX rate from state. Passthrough from BI_DB_DepositWithdrawFee, originally sourced from Fact_Cashout_State.BaseExchangeRate. Stored as varchar despite numeric origin. NULL when no matching DepositWithdrawFee row exists." | MINOR | Added provenance and NULL note |
| ExchangeFee | "Exchange fee from state." | "Exchange fee from state. Passthrough from BI_DB_DepositWithdrawFee, originally sourced from Fact_Cashout_State.ExchangeFee. Stored as varchar despite numeric origin. NULL when no matching DepositWithdrawFee row exists." | MINOR | Added provenance and NULL note |
| VerificationCode | "Verification code supplied or received during withdrawal processing." | "Verification code supplied or received during withdrawal processing. Passthrough from Fact_BillingWithdraw." | MINOR | Added source note |

### Top 5 Issues

1. **HIGH — Regulation (Element #14)**: Description paraphrased. Upstream says "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." Wiki rewrote to "Short code for the customer's regulatory jurisdiction at the time of the event" and substituted inline enum values. Must quote upstream verbatim.

2. **LOW — Multiple Tier 1 columns have appended text**: ExternalID, PaymentMethod, Depot, CardType, BaseExchangeRate, ExchangeFee, VerificationCode all append resolution paths and NULL semantics after the verbatim upstream quote. While the upstream text is preserved, strictly speaking additions beyond verbatim are a deviation. Acceptable practice but noted.

3. **LOW — Amount (Element #9) contextual mismatch**: The upstream Tier 1 source is "Trade.PositionTbl" but in this cashout table, Amount comes from History.Credit (cashout amounts, not position sizes). The writer correctly flagged this in the review-needed sidecar and added a DWH note, but the Tier 1 tag of "Trade.PositionTbl" is technically the upstream origin as documented in Fact_CustomerAction — it's accurate per inheritance rules but semantically misleading for cashout analysts.

4. **LOW — Auto-backfill gap detection quirk**: Well-documented in Section 2.5 and Section 3.4 that gap detection checks BI_DB_EY_Audit_Deposits (not Cashouts). This is a genuine SP behavior and is appropriately flagged.

5. **LOW — BaseExchangeRate/ExchangeFee type mismatch**: Well-documented as varchar(50) despite numeric origin. Correctly flagged in Section 3.4 gotchas and review-needed sidecar.

### Regeneration Feedback

1. Replace the Regulation description with the verbatim upstream quote from Dim_Regulation.Name: *"Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name."* Add the inline enum values and resolution path as a separate sentence after the verbatim quote.

### Weighted Score

```
weighted = 0.25×10 + 0.20×6 + 0.20×10 + 0.15×9 + 0.10×8 + 0.10×9
         = 2.50 + 1.20 + 2.00 + 1.35 + 0.80 + 0.90
         = 8.75
```

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_EY_Audit_Cashouts",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 6,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
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
      "loss": "Added resolution note; upstream core preserved"
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
      "wiki_quote": "UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Amount",
      "upstream_quote": "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents).",
      "wiki_quote": "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). DWH note: in this cashout-specific table, Amount represents the cashout/refund/chargeback amount for ActionTypeIDs 8, 11, 12, 13, 37 sourced from History.Credit via Fact_CustomerAction.",
      "match": "MINOR",
      "loss": "Added DWH context note; upstream core preserved verbatim"
    },
    {
      "column": "PaymentMethod",
      "upstream_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay).",
      "wiki_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Resolved via Dim_BillingDepot.FundingTypeID → Dim_FundingType.Name. NULL when no matching billing withdraw row exists.",
      "match": "MINOR",
      "loss": "Added resolution path and NULL semantics"
    },
    {
      "column": "Depot",
      "upstream_quote": "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports.",
      "wiki_quote": "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. Resolved from Fact_BillingWithdraw.DepotID. NULL when no matching billing withdraw row exists.",
      "match": "MINOR",
      "loss": "Added resolution path and NULL note"
    },
    {
      "column": "CardType",
      "upstream_quote": "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from Name in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital.",
      "wiki_quote": "Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from Name in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. Resolved from Fact_BillingWithdraw.CardTypeIDAsInteger via Dim_CardType.CarTypeName. NULL for non-card payment methods.",
      "match": "MINOR",
      "loss": "Added resolution path and NULL note"
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the customer's regulatory jurisdiction at the time of the event. Values: CySEC, FCA, FSA Seychelles, FinCEN+FINRA, ASIC & GAML, FSRA, BVI, ASIC, MAS, eToroUS, FinCEN. Resolved from Fact_SnapshotCustomer.RegulationID via Dim_Regulation.Name.",
      "match": "NO",
      "loss": "Rewrote description entirely. Dropped 'Used in V_Dim_Customer and analytics dashboards' and 'Values match production Dictionary.Regulation.Name'"
    },
    {
      "column": "IsCreditReportValidCB",
      "upstream_quote": "1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3.",
      "wiki_quote": "1 if customer is eligible for CreditBureau credit report validation. ETL-computed in Fact_SnapshotCustomer from PlayerLevelID, AccountTypeID, LabelID, CountryID. Passthrough from point-in-time snapshot.",
      "match": "MINOR",
      "loss": "Expanded computation details, dropped section reference"
    },
    {
      "column": "BaseExchangeRate",
      "upstream_quote": "Base FX rate from state.",
      "wiki_quote": "Base FX rate from state. Passthrough from BI_DB_DepositWithdrawFee, originally sourced from Fact_Cashout_State.BaseExchangeRate. Stored as varchar despite numeric origin. NULL when no matching DepositWithdrawFee row exists.",
      "match": "MINOR",
      "loss": "Added provenance and NULL note"
    },
    {
      "column": "ExchangeFee",
      "upstream_quote": "Exchange fee from state.",
      "wiki_quote": "Exchange fee from state. Passthrough from BI_DB_DepositWithdrawFee, originally sourced from Fact_Cashout_State.ExchangeFee. Stored as varchar despite numeric origin. NULL when no matching DepositWithdrawFee row exists.",
      "match": "MINOR",
      "loss": "Added provenance and NULL note"
    },
    {
      "column": "VerificationCode",
      "upstream_quote": "Verification code supplied or received during withdrawal processing.",
      "wiki_quote": "Verification code supplied or received during withdrawal processing. Passthrough from Fact_BillingWithdraw.",
      "match": "MINOR",
      "loss": "Added source note"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Regulation (Element #14)",
      "problem": "Description paraphrased. Upstream Dim_Regulation.Name says 'Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.' Wiki rewrote to 'Short code for the customer's regulatory jurisdiction at the time of the event' and substituted inline enum values, dropping the V_Dim_Customer reference and production provenance note."
    },
    {
      "severity": "low",
      "column_or_section": "Multiple Tier 1 columns",
      "problem": "Seven Tier 1 columns (ExternalID, PaymentMethod, Depot, CardType, BaseExchangeRate, ExchangeFee, VerificationCode) append resolution paths and NULL semantics after the upstream verbatim text. Upstream core is preserved but additions go beyond strict verbatim quoting."
    },
    {
      "severity": "low",
      "column_or_section": "Amount (Element #9)",
      "problem": "Tier 1 source tagged as Trade.PositionTbl (inherited from Fact_CustomerAction wiki) but in this cashout context Amount represents cashout/refund amounts from History.Credit. Writer flagged this in review-needed sidecar. The DWH note is appropriate but the origin tag is semantically misleading for cashout analysts."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.5 / Section 3.4",
      "problem": "Auto-backfill gap detection checks BI_DB_EY_Audit_Deposits (not Cashouts) — correctly documented as a quirk. No action needed but confirms the SP has a potential gap-detection blind spot."
    },
    {
      "severity": "low",
      "column_or_section": "BaseExchangeRate / ExchangeFee (Elements #16, #17)",
      "problem": "Type mismatch: varchar(50) in this table vs numeric(38,8) in BI_DB_DepositWithdrawFee. Well-documented in Section 3.4 gotchas. No fix needed in wiki — this is a design issue in the SP."
    }
  ],
  "regeneration_feedback": "Replace the Regulation (Element #14) description with the verbatim upstream quote from Dim_Regulation.Name: 'Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.' Append the inline enum values and resolution path as additional context after the verbatim core.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
