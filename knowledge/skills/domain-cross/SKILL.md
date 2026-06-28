---
name: domain-cross
description: "Router for skills that bridge two or more super-domains. Load when a question explicitly crosses the Payments, Customer & Identity, Trading, Revenue & Fees, or Compliance domain boundaries. Five cross-domain skills: (1) crypto-to-fiat (C2F) — EXW crypto wallet to eMoney IBAN off-ramp anchored on EXW_C2F_E2E 103c + IsCryptoToFiat=1 MIMO marker; (2) provider-reconciliation — PSP settlement-statement matching vs BI_DB_DepositWithdrawFee, MID-routing joins (Synapse-only core), plus Apex SOD recon (UC); (3) tribe-emoney-audit — Treezor XML audit envelopes (emoney.bronze_fiatdwhdb_tribe_* family, ETL_AccountsActivities 105c) for SOC2-grade compliance investigation of eMoney accounts, cards, and IBAN transactions; (4) refund-chargeback-chain — forensic single-dispute chain from original deposit to reversal to AML overlay anchored on BI_DB_DepositWithdrawFee_Reversals 45c (pre-signed amounts); (5) recurring-deposits-and-investments — FTD-to-first-trade funnel (Dim_Customer.FTDDate + FirstTradeDate), recurring investment plan analysis (bronze_recurringinvestment_plans 26c + planinstances 33c), and the pre-stitched de_output_etoro_kpi_fact_customeraction_w_metrics. NOTE the 2026-06 deposit↔trade DECOUPLING: recurring positions can be funded from available USD balance with no deposit, so deposit-side (Fact_BillingDeposit/MIMO IsRecurring) counts recurring DEPOSITS while trade-side (BI_DB_RecurringInvestment_Positions / PlanInstances.PositionStatus) counts recurring TRADES — separate measures, not proxies; plan lifecycle = Plans.PlanStatusID vs DepositPlanStatusID. Includes an infra/ETL data-loss audit of the trade↔deposit bridge. Load this hub to be routed to the right cross-domain skill; do NOT load individual super-domain skills for questions that explicitly span two domains."
triggers:
  - C2F
  - crypto to fiat
  - crypto-to-fiat
  - off-ramp
  - wallet to IBAN
  - IsCryptoToFiat
  - EXW_C2F_E2E
  - FundingTypeID 27
  - TransactionTypeID 14
  - provider recon
  - settlement statement
  - settlement gap
  - MID
  - MIDName
  - ExternalTransactionID
  - Worldpay
  - SafeCharge
  - Nuvei
  - PayPal
  - Skrill
  - Tribe
  - FiatDwh
  - FiatDwhDB
  - Treezor
  - audit trail
  - SOC2
  - eMoney audit
  - AccountsActivities
  - ETL_AccountsActivities
  - chargeback
  - refund
  - reversal
  - dispute
  - BI_DB_DepositWithdrawFee_Reversals
  - PaymentStatusID 11
  - PaymentStatusID 12
  - ReversedDeposit
  - deposit to trade
  - FTD to FT
  - FTD-to-FT
  - recurring deposit
  - IsRecurring
  - recurring investment
  - recurring position open
  - balance-funded recurring
  - PlanStatusID
  - DepositPlanStatusID
  - bronze_recurringinvestment
  - First5Actions
  - time-to-first-trade
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals
  - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities
  - main.emoney.bronze_fiatdwhdb_tribe_accountsactivities_accountactivity_833937
  - main.emoney.bronze_fiatdwhdb_tribe_settlementstransactions_settlementtransaction_637239
  - main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
sample_questions:
  - "Crypto wallet converted to EUR on IBAN — what happened?"
  - "Match a Worldpay settlement row to our internal deposit record"
  - "Who authorized this eMoney account-activity event on GCID X?"
  - "Investigate this chargeback end-to-end — deposit to AML flag to resolution"
  - "How long after FTD does the average customer open their first trade?"
  - "Show recurring-deposit customers who opened a position within 7 days"
domain_tags:
  - cross-domain
  - c2f
  - provider-recon
  - tribe
  - chargeback
  - recurring
  - ftd-funnel
sub_skills:
  - crypto-to-fiat.md
  - provider-reconciliation.md
  - recurring-deposits-and-investments.md
  - refund-chargeback-chain.md
  - tribe-emoney-audit.md
version: 2
owner: "dataplatform"
last_validated_at: "2026-06-25"
---

# Cross-Domain Skills Hub

Questions that cross super-domain boundaries fail when answered with a single-domain skill — they need the bridging context, join keys, and data-quality warnings that live in cross-domain skills. This hub routes to the right bridge.

## When to Use

Load when the user's question explicitly spans **two or more** of these super-domains:

- "Crypto came into wallet → converted to EUR on IBAN" → [`crypto-to-fiat.md`](crypto-to-fiat.md)
- "Match our deposit record against the Worldpay settlement file" → [`provider-reconciliation.md`](provider-reconciliation.md)
- "Who authorized this eMoney account action?" / "SOC2 audit trail for this IBAN" → [`tribe-emoney-audit.md`](tribe-emoney-audit.md)
- "Investigate this chargeback / refund end-to-end" → [`refund-chargeback-chain.md`](refund-chargeback-chain.md)
- "Customer deposited then opened first trade — funnel metrics / cohort" → [`recurring-deposits-and-investments.md`](recurring-deposits-and-investments.md)

Do **not** load this hub for questions that stay within a single super-domain — route directly to that domain instead.

## Scope

In scope: the five cross-domain bridging skills listed below; their join keys, anchor tables, and data-quality warnings for cross-domain joins only.
Out of scope: single-domain questions (route to `domain-payments`, `domain-customer-and-identity`, `domain-trading`, `domain-revenue-and-fees` directly); AML risk classification logic (Compliance super-domain when built); GL / treasury reporting.
Last verified: 2026-05-17

## Critical Warnings

1. **Tier 1 — Each cross-domain skill owns EXACTLY its stitching layer — do not extend it into a full super-domain query.** These skills carry only the join keys and bridge tables needed to cross the boundary. The sub-domain SQL lives in the parent super-domain skills; the cross-domain skill supplies the linking context only.
2. **Tier 1 — Synapse-only objects in provider-reconciliation and refund-chargeback-chain.** `Fact_Deposit_State`, `Fact_Cashout_State`, `Dim_BillingProtocolMIDSettingsID`, `EXW_PaymentReconciliation`, and `Fact_Cashout_Rollback` are `_Not_Migrated` — they CANNOT be queried from Databricks. The aggregate / reversal-signed-amount portions (BI_DB_DepositWithdrawFee_Reversals, Apex SOD recon tables) ARE in UC. Route Synapse-specific joins to the `synapse_*` MCP servers.
3. **Tier 2 — Raw Tribe envelopes should NOT be queried directly.** Go through `ETL_AccountsActivities` (105c, in `main.bi_db`, not `main.emoney`) for analyst-grade output. Raw Tribe envelope tables (parent + child, with XML-numeric suffixes like `_833937`) are for forensic drill-down only, after confirming the ETL recon output is insufficient.

## Sub-skill routing

| Sub-skill | Connects | Anchor (UC FQN) | When to load |
|---|---|---|---|
| [`crypto-to-fiat.md`](crypto-to-fiat.md) | Payments C.4 (Crypto Wallet) ↔ C.3 (eMoney IBAN) | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` (103c) | "Crypto came in → converted to EUR/USD on IBAN." The already-stitched E2E view is the default; manual stitch via `CorrelationId` only for failed/partial C2F forensics. |
| [`provider-reconciliation.md`](provider-reconciliation.md) | Payments C.1 / C.5 ↔ external PSPs | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` + Apex SOD tables | Settlement-statement gap analysis. Core MID-routing join is Synapse-only; Apex SOD is in UC. |
| [`tribe-emoney-audit.md`](tribe-emoney-audit.md) | Compliance ↔ Payments C.3 (eMoney) | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities` (105c) + `main.emoney.bronze_fiatdwhdb_tribe_*` | Treezor XML audit-envelope investigation of eMoney accounts, cards, and IBAN transactions. Operator / system action trail; SOC2 forensics. |
| [`refund-chargeback-chain.md`](refund-chargeback-chain.md) | Payments C.1 ↔ Revenue & Fees ↔ Compliance | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals` (45c) | Single-dispute forensics: original deposit → chargeback/refund → AML overlay. Amounts are PRE-SIGNED (refunds/chargebacks negative). State-table provenance is Synapse-only. |
| [`recurring-deposits-and-investments.md`](recurring-deposits-and-investments.md) | Payments C.1 ↔ Trading | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` + `Dim_Customer.FTDDate/FirstTradeDate` + `bronze_recurringinvestment_recurringinvestment_plans` | FTD-to-first-trade cohort funnel, recurring investment plan analysis. Use `FTDDate + FirstTradeDate` on `Dim_Customer` (already computed); reach for the RecurringInvestment `plans`/`planinstances` tables for plan-level recurring analysis. **2026-06 decoupling:** recurring trade ≠ recurring deposit (balance-funded positions have no deposit row) — deposit-side `IsRecurring` counts recurring *deposits*, trade-side bridge counts recurring *trades* (separate measures); plan lifecycle via `Plans.PlanStatusID` vs `DepositPlanStatusID`. Includes infra/ETL data-loss audit. |
