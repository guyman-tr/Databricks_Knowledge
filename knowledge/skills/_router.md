---
name: dwh-domain-router
description: |
  Always-loaded routing index for the eToro DWH semantic layer. Lists every
  super-domain skill, its primary objects, and disambiguation tie-breakers.
  Read this FIRST on any analytical question about deposits, withdrawals, MIMO,
  trades, positions, customers, KYC, AML, fees, revenue, marketing, treasury,
  copy trading, eMoney, IBAN, crypto wallet, FTD, broker recon, audit trail
  (Tribe), or any DWH/BI_DB/EXW/Dealing/eMoney/Tribe table.
keywords: [router, dispatch, skills, deposits, withdrawals, MIMO, trades,
           positions, customers, KYC, AML, FTD, revenue, fees, treasury,
           copy trading, eMoney, IBAN, wallet, crypto, marketing]
priority: always_load
---

# DWH Domain Router

You have access to a tightly curated semantic skill library covering eToro's
DWH (Synapse), Unity Catalog mirrors, and production OLTP databases. **Load
the most specific skill first**; only load a second skill if the question
truly spans two domains (use a `bridges/*` skill in that case).

## Genie / Databricks SQL — read this first

The skills in this library reference objects by both **Synapse-style** names
(e.g. `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms`) and **Unity Catalog FQNs**
(e.g. `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`).
**On Databricks Genie, always emit the UC FQN.** The Synapse name is an alias
for cross-reference with Synapse wikis only.

- **Mapping reference**: [`_uc_object_map.md`](_uc_object_map.md) — every
  skill ref resolved to its UC FQN, with object type (TABLE / VIEW), status
  (deployed / not_migrated / synapse_only / deprecated), and source.
- **Per-skill action items**: [`_uc_object_map.action_required.md`](_uc_object_map.action_required.md)
  — the ~17 refs that cannot be queried in Databricks (Synapse-only / not
  migrated). Skills mark these in `synapse_only_objects:` front-matter.
- **Conventions** that hold across skills:
  - `BI_DB_dbo.<X>` → `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_<x_lower>` (TABLE).
  - `DWH_dbo.<X>` → `main.dwh.gold_sql_dp_prod_we_dwh_dbo_<x_lower>` (TABLE).
  - `eMoney_dbo.<X>` → `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_<x_lower>` for analyst-facing tables, `main.emoney.gold_*` for some operational ones (check the map).
  - `EXW_dbo.<X>` → `main.bi_db.gold_sql_dp_prod_we_exw_dbo_<x_lower>` *(when migrated; many `EXW_dbo` tables are `_Not_Migrated`)*.
  - `EXW_Wallet.<X>` / `EXW_Dictionary.<X>` → `main.wallet.bronze_walletdb_wallet_<x_lower>` / `main.wallet.bronze_walletdb_dictionary_<x_lower>` (these are the production-replicated bronze, NOT a DWH-curated mirror).
  - `eMoney_Tribe.<X>` → `main.emoney.bronze_fiatdwhdb_tribe_<x_lower>`.
  - `FiatDwhDB.dbo.<X>` → `main.emoney.bronze_fiatdwhdb_dbo_<x_lower>` (mostly).
  - **Per-platform MIMO objects are VIEWS, not tables**: Synapse `BI_DB_DDR_Fact_MIMO_<Platform>_Platform` → UC `main.etoro_kpi_prep.v_mimo_<platform>platform` (no underscore between platform-name and `platform` for `tradingplatform`/`emoneyplatform`; underscore present for `options_platform`).
- **When a skill references a Synapse object that is `_Not_Migrated` or only
  has a wiki**: do NOT translate it to a UC name. Tell the user the table is
  Synapse-only / QA-only and offer to either (a) reformulate the question
  using the UC-deployed equivalent, or (b) run the query against Synapse
  directly via the Synapse MCP / pyodbc.

## How to use this router

1. Read the question. Identify the **primary noun** (e.g. "deposit", "trade",
   "customer", "balance", "FTD funnel").
2. Match against the **Anchor objects** column below. The first match wins.
3. If the question mentions two distinct nouns from different rows (e.g.
   "deposits that turned into trades within 7 days"), check the **Bridges**
   table for a dedicated cross-domain skill.
4. Read that skill's `SKILL.md` (and its sub-skill if there is one).
5. Only deep-read the wiki pages it links to if the skill itself isn't enough.

**Hard rule**: never load more than one anchor skill plus one bridge skill at
once. If you need a third, the question is asking for an executive summary —
answer with a short narrative and offer to drill into one domain at the user's
choice.

## Super-domains

| # | Skill | Primary anchor objects | When to load |
|---|-------|------------------------|--------------|
| C | [`payments/SKILL.md`](payments/SKILL.md) | `Fact_BillingDeposit`, `Fact_BillingWithdraw`, `Fact_Deposit_State`, `Fact_Cashout_State`, `BI_DB_DDR_Fact_MIMO_AllPlatforms`, `EXW_Wallet.CryptoTypes`, `eMoney_Dim_Account`, `EXW_FinanceReportsBalancesNew` | Question mentions money MOVEMENT (not fee revenue): deposit, withdrawal, cashout, FTD, reversal, chargeback, refund, funding type, depot, BIN, MID, recurring deposit, MIMO, IBAN, eMoney account, crypto wallet, EXW, finance recon, customer balance, fiat conversion. |
| H | [`revenue-and-fees/SKILL.md`](revenue-and-fees/SKILL.md) | `BI_DB_DDR_Fact_Revenue_Generating_Actions`, `etoro_kpi_prep.mv_revenue_trading`, `etoro_kpi_prep.v_revenue_*` (20+ views), `BI_DB_DepositWithdrawFee`, `BI_DB_DepositWithdrawFee_Reversals`, `Fact_Deposit_Fees`, `Fact_Withdraw_Fees`, `Staking.*`, `EXW_dbo.Staking_*`, `BI_DB_Finance_Staking_Report`, `etoro_kpi.v_spaceship_*`, `etoro_kpi_prep.v_moneyfarm_*`, `BI_DB_Index_Dividend_TaxReport*`, `Fact_AffiliateCommission`, `bi_dealing.bi_output_dealing_lp_fees_*` | Question mentions any FEE or REVENUE: commission, rollover, dividend, FX/conversion fee, exchange fee, spread, cashout fee, transfercoin/redeem fee, deposit/withdraw fee, share lending, dormant fee, ticket fee, admin fee, SDRT, spot adjustment, options fee, **staking, spaceship, moneyfarm, ISA, SIPP**, LP fees, broker pass-through, Apex fees, affiliate commission, dividend tax. |
| A | _(planned)_ trading & markets | `Dim_Instrument`, `Dim_Position`, `BI_DB_PositionPnL`, `Dim_Mirror`, `Trade.PositionTbl`, `Dealing_IGReconEODHolding`, `Dealing_DucoEODRec` | Question mentions: trade, position, instrument, asset, copy trade, mirror, P&L, leverage, dealing, broker recon, IG, Saxo, Duco, EOD position recon, treasury EOD. |
| B | _(planned)_ customer & identity | `Dim_Customer`, `Customer.CustomerStatic`, `Fact_SnapshotCustomer`, `BI_DB_CIDFirstDates`, `customer_snapshot_v` | Question mentions: customer, RealCID, GCID, KYC, verification, club, regulation jurisdiction, registration, CRM case, FTD funnel (registration side), customer attributes. |
| D | _(planned)_ compliance & AML | `BI_DB_AML_*`, `BI_DB_Tax_Compliance_TIN`, `bi_compliance_cmp_aml_risk_*`, `BI_DB_QMMF_Report`, `FiatDwhDB.Tribe`, `eMoney_Tribe.*` | Question mentions: AML, KYC, sanctions, PEP, watchlist, alert, risk classification, tax (TIN, FATCA, CRS), QMMF, regulatory report, SOC2, **eMoney audit trail, Tribe** (Tribe is the audit-trail proxy for eMoney/IBAN objects — when a Tribe question arrives, often cross-reference C.3 eMoney for join keys). |
| E | _(planned)_ finance & treasury | `finance_hubs_stg.*treasury*`, `Fact_History_Cost`, `Fact_BillingRedeem`, `History_CurrencyPrice` | Question mentions: GL, treasury, MMF, term deposit, bank concentration, FX history, cost amortization, internal redemption. (Fee REVENUE is H, not here.) |
| F | _(planned)_ marketing & acquisition | `BI_DB_Adwords_*`, `BI_DB_Bing_*`, `Dim_Campaign`, `Dim_Affiliate`, `BI_DB_AGGSilverpopCampaign` | Question mentions: campaign, channel, AppsFlyer, AdWords, Bing, affiliate, attribution, SilverPop, push notification, urban airship, marketing spend. |
| G | _(planned)_ internal & platform | `monitoring.app_genie_app_cost30d`, `github.cursor_usage`, `information_schema.*`, `billing.usage` | Question mentions: warehouse cost, Databricks compute billing, Genie usage, AI usage, system metadata, table sizes. |

## Other domains (NOT super-domains)

These are regular-sized domains, not super-domains. They have their own skills (planned), but do not warrant the depth of a super-domain because the data is either narrow or scattered across other systems.

| # | Skill | Status | Anchors | When to load |
|---|-------|--------|---------|--------------|
| I | _(planned)_ **compensation** | regular domain — bonuses live here | _TBD — bonus tables_ | Question mentions: deposit bonus, refer-a-friend bonus, club bonus, marketing campaign bonus, club perk, customer pay-out, club status reward. **Sub-domain: bonuses.** Compensation is NOT a super-domain. |
| J | _(planned, deferred)_ **operations / back-office** | likely too sprawled to be a super-domain — DWH coverage is thin (data lives in `Trading.*`, `Billing.*`, `UserAPIDB.*`, `Settings.*`). For now treat as regular domain anchored on `Fact_CustomerAction` for the audit-trail piece. | `Fact_CustomerAction`, BackOffice operator-action tables | Question mentions: BackOffice manual operation, operator action, manual deposit, operator refund, customer action audit, ActionTypeID, SessionID. |

## Bridges

When a question crosses two super-domains, prefer a bridge skill over loading
both anchor skills.

| Bridge | Connects | When to load |
|--------|----------|--------------|
| [`bridges/crypto-to-fiat.md`](bridges/crypto-to-fiat.md) | C.4 Crypto Wallet ↔ C.3 eMoney IBAN | Question mentions C2F, fiat conversion, wallet-to-IBAN, `EXW_C2F_E2E`, off-ramp. **The bridge owns the E2E underbelly map** — C.4 stops at "crypto sent off-platform"; the full chain stitching lives here. |
| [`bridges/recurring-deposit-to-trade.md`](bridges/recurring-deposit-to-trade.md) | C.1 Deposits ↔ A. Trading | Question mentions deposit-to-trade conversion, FTD-to-first-position, recurring deposit driving trades, deposit cadence funnel. Canonical pre-stitched table: `de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`. |
| [`bridges/provider-reconciliation.md`](bridges/provider-reconciliation.md) | C.1/C.5 ↔ external providers | Question mentions Worldpay, SafeCharge, Nuvei, MID-level recon, provider settlement, `ExternalTransactionID` matching, provider statement vs DWH. |
| [`bridges/refund-chargeback-chain.md`](bridges/refund-chargeback-chain.md) | C.1 Deposits ↔ D. Compliance | Question mentions chargeback investigation, refund AML flag, dispute chain, `BI_DB_DepositWithdrawFee_Reversals` lifecycle. |
| [`bridges/tribe-emoney-audit.md`](bridges/tribe-emoney-audit.md) | D. Compliance ↔ C.3 eMoney | Question mentions Tribe, FiatDwhDB, Treezor audit envelopes, `eMoney_Tribe.*`, `bronze_fiatdwhdb_tribe_*`, SOC2 audit trail, "who authorized this", operator-action forensics on eMoney accounts/cards/IBAN. **Bridge supplies the audit-trail map**; C.3 supplies the join keys (`AccountID`, `GCID`, `CardID`, `TransactionID`). |

## Tie-breakers (disambiguation)

| If the question mentions… | …route to… | Reason |
|---------------------------|------------|--------|
| "money in" or "money out" or "MIMO" or "FTD" across platforms | [`payments/mimo-panel-and-ddr.md`](payments/mimo-panel-and-ddr.md) (C.2) | Pre-aggregated cross-platform panel. Default "how much flowed" answer. |
| "FTD" + acquisition funnel ("registration → KYC → FTD") | B. Customer & Identity | FTD timing/conversion belongs to acquisition; FTD VOLUMES go to C.2. |
| "deposit" / "withdrawal" + trading platform | [`payments/deposits-and-withdrawals.md`](payments/deposits-and-withdrawals.md) (C.1) | Trading-platform fiat deposits live in `Fact_BillingDeposit/Withdraw`. |
| "deposit" + "eMoney" or "IBAN" or "card" | [`payments/emoney-accounts-and-cards.md`](payments/emoney-accounts-and-cards.md) (C.3) | eMoney deposits use `eMoney_Dim_Transaction`, NOT `Fact_BillingDeposit`. |
| "deposit" + "crypto" or "wallet" or "on-chain" | [`payments/crypto-wallet.md`](payments/crypto-wallet.md) (C.4) | Crypto deposits live in EXW_Wallet, not fiat billing tables. |
| "recurring deposit" → trade | [`bridges/recurring-deposit-to-trade.md`](bridges/recurring-deposit-to-trade.md) | Bridge across C.1 and A. |
| "balance" of a customer alone | [`payments/finance-recon-and-balances.md`](payments/finance-recon-and-balances.md) (C.5) | Authoritative customer balances live in `EXW_FinanceReportsBalancesNew`. |
| "balance" + "open positions equity" or "realizable equity" | A. Trading (`V_Liabilities`) | Realizable equity from positions is a trading view. |
| **ANY fee question** (deposit fee / withdraw fee / cashout / transfercoin / FX / exchange / commission / rollover / dividend / staking / spaceship / moneyfarm / SDRT / share lending / dormant / ticket / admin / spot adjust / interest / Apex / LP / affiliate) | [`revenue-and-fees/SKILL.md`](revenue-and-fees/SKILL.md) (H) | All fee revenue lives in H, not Payments. |
| "MID routing" / "which MID handled this deposit" / "pipscalculation" | [`payments/deposits-and-withdrawals.md`](payments/deposits-and-withdrawals.md) (C.1) | MID routing and production pipscalculation enrichment live in `Fact_Deposit_State` / `Fact_Cashout_State`. |
| "true historical state" / "every state transition this deposit went through" | bronze `history.billing.deposit` / `history.billing.withdraw` | Note in C.1: rarely needed for analytical work. |
| "chargeback" investigation / "AML refund" | [`bridges/refund-chargeback-chain.md`](bridges/refund-chargeback-chain.md) | Crosses C.1 + H + Compliance. |
| "C2F" or "fiat conversion" or "wallet → IBAN" | [`bridges/crypto-to-fiat.md`](bridges/crypto-to-fiat.md) | Crosses C.4 + C.3. |
| "broker recon" / "IG EOD" / "Saxo holdings" / "Duco" | A. Trading & Markets (`dealing_dbo`) | Broker recon is position-truth, NOT payment-truth. Lives in `Dealing_*` / `dealing_dbo`. |
| **"which broker" / "LP identity" / "hedge mapping" / "which liquidity provider"** | A. Trading & Markets (`dealing_dbo`) | Broker / LP master lives in `dealing_dbo` (hedge server + LP IDs), NOT in any payments-side table. Payment-side `BankName` / `MID` / `PaymentProviderName` are PSP identities, not broker identities — do not conflate. |
| **"Apex" or "Gatsby" or "Options"** | H. Revenue & Fees (`v_revenue_optionsplatform`) for fees / **C.5 finance-recon-and-balances** for Apex SOD recon / **A. Trading** for US-resident equity trading | **Gatsby = product brand (acquired); Apex = the broker (= USABroker).** Lake only has Apex SFTP reports. Apex also clears US-resident customer equities, but those land in REGULAR trading tables — there is no "Apex silo" for US equities. Three roles, one broker; route by what's actually being asked. |
| **"Spaceship" / "MoneyFarm" / "WealthFrance" / regional acquired product** | H. Revenue & Fees + the relevant `_domain_card.md` | **Spaceship = Australian** (Voyager/Nova/Super product lines); **MoneyFarm = UK**; **WealthFrance = French (not yet ingested)**. Always read the `knowledge/uc_domains/<product>/_domain_card.md` first — heavy lifting is done there. **Do not pattern-match on table names or assume geography.** |
| "Tribe" / "SOC2 audit trail" / "eMoney audit log" / "who-did-what-when on eMoney" / "FiatDwhDB" / "Treezor" | [`bridges/tribe-emoney-audit.md`](bridges/tribe-emoney-audit.md) | Tribe is Treezor's XML audit envelope feed; FiatDwhDB is Treezor's operational fiat mirror. **Bridge owns the map**; C.3 supplies the join keys. Compliance super-domain (D) owns the interpretation rules when built. |
| "bonus" / "deposit bonus" / "refer-a-friend" / "club perk" | I. Compensation _(planned)_ | Bonuses are pay-OUT, not payments. Different domain. |
| "BackOffice manual deposit" / "operator action" / "manual refund by ops" | J. Operations _(planned)_ | `Fact_CustomerAction` — operator audit trail, not payment movement. |
| "MIMO" + per-MID / per-provider drill-down | [`bridges/provider-reconciliation.md`](bridges/provider-reconciliation.md) | C.2 doesn't carry MID; need C.1 raw + provider statement. |

## What this router is NOT

- It does **not** contain any data, SQL, or business definitions. Those live
  in the per-skill files.
- It does **not** list every table — only anchors. To find which skill owns
  a non-anchor table, read [`_node_summary.csv`](_node_summary.csv) for the
  cluster id, then look up that cluster's anchor skill in the table above.
- Counts of objects, deep lineage, and SQL examples live in the **wikis**
  (`knowledge/synapse/Wiki/<schema>/Tables/<obj>.md`). Skills point at them.

## Provenance

- Domains were derived from a fused join graph of:
  - 1,142 wiki files (DWH_dbo + BI_DB_dbo + EXW + eMoney + Dealing + Tribe)
  - 143 Genie spaces (table cliques + explicit join_specs)
  - 95 KPI views from `etoro_kpi[_prep[_stg]]` (FROM/JOIN parsed from DDL)
  - 4 Tableau custom-SQL workbooks
- Louvain community detection on the merged 1,839-node graph yielded 62
  raw clusters at modularity 0.600. They were collapsed into the 7 super-
  domains above by hub-table similarity and Genie-space ownership.
- Full audit trail: [`_CHECKPOINT_A.md`](_CHECKPOINT_A.md),
  [`_join_graph.json`](_join_graph.json),
  [`_domain_candidates.md`](_domain_candidates.md).
