---
name: domain-exw-wallet
description: |
  EXW (eToro Wallet) super-domain. EXW is the non-custodial crypto wallet
  product — customers can withdraw their eToro-traded crypto from the platform
  into self-custodied on-chain wallets provisioned by BitGo (97.5%, multi-sig)
  or CUG (2.5%, MPC-based). Once on chain, the assets live under blockchain
  addresses the customer controls; eToro provides custody orchestration,
  pricing, AML screening, and a set of E2E facts that reconcile the wallet
  side back to the trading platform and to eMoney IBAN.

  This is a real super-domain (not thin) with five distinct flows, each owned
  by a different team and each with its own E2E reconciliation fact:

    1. HOLD          — daily snapshot of every customer's wallet balance.
                       UC fact: EXW_FinanceReportsBalancesNew (40c, daily T-1,
                       AUM source). Sub-skill: balance-and-aum.md.
    2. INBOUND       — external→wallet receives. UC: wallet.bronze_walletdb_
                       wallet_receivedtransactions (19c). Plus the on-chain
                       deposit hash join. Sub-skill: on-chain-ledger.md.
    3. REDEEM        — TP position→wallet (the canonical "withdraw crypto to
                       my wallet" flow). 1.13M lifetime rows. Owned by MIMO
                       Group per Confluence. UC fact: EXW_FactTransactions
                       (filtered IsRedeem=1) + the EXW_V_RedeemReconciliation
                       view (51c). Sub-skill: redemptions.md.
    4. C2F           — wallet→IBAN fiat conversion (the off-ramp). UC fact:
                       EXW_C2F_E2E (103c, 17,702 rows, 9 production Tableau
                       dashboards depend on it). Owned by ETM/Finance.
                       Sub-skill: conversions-c2f.md.
    5. C2P           — wallet→TP open position (subset of C2F where the
                       converted USD funds an open trading position rather
                       than IBAN). Launched 2025-12-11. UC fact: EXW_C2P_E2E
                       (90c, 5,978 rows). Sub-skill: conversions-c2p.md.

  Plus two cross-cutting sub-skills:
    A. transactions.md   — EXW_FactTransactions (45c, 4.7M rows, daily T-1,
                           the unified Sent+Received+Conv+Redeem fact). The
                           DEFAULT analytical entry for any "show me crypto
                           activity for customer X" question.
    B. price-and-fx.md   — EXW_PriceDaily (10c, 1 row/day) and EXW_Price
                           (17c, 24 rows/day per instrument). The USD-
                           normalisation backbone for every other sub-skill.

  Custody providers: BitGo (97.5% — multi-sig, the legacy default), CUG
  (2.5% — MPC-based, newer blockchains like SOL). Tangany was retired.
  Simplex was the fiat→crypto on-ramp, decommissioned 2022-09. Crypto-to-
  crypto in-wallet swaps (EXW_FactConversions) frozen since 2023-06; the
  feature is no longer offered.

  This super-domain DOES NOT own:
    - Crypto CFD positions or P&L on trading platform → domain-trading.
    - Real-crypto custodied within TP (Fact_AUM.TotalRealCrypto) → domain-trading.
      EXW only starts at the moment a customer redeems out of TP.
    - Daily fiat balance / IBAN balance → domain-payments.
    - Cross-platform aggregate AUM rollup → domain-aum-and-aua.
    - Staking and gas-fee REVENUE recognition → domain-revenue-and-fees.
      (The transaction fact is here; the revenue line lives there.)
    - AML risk classification logic → domain-compliance-and-aml.
      (We provide the WalletId/address evidence; risk logic lives there.)

  The single most important cross-table primitive in EXW is CorrelationId.
  It is the only reliable way to glue customer INTENT (Conversion, Redemption,
  Request) to on-chain EXECUTION (SentTransactions). Joining on amount or
  timestamp is wrong and silently double-counts. Three pre-enriched Synapse
  facts (EXW_FactRedeemTransactions, EXW_FactConversions,
  EXW_PaymentReconciliation) are NOT migrated to UC and must be rebuilt
  manually using CorrelationId stitches in Databricks.

  Crypto is OFF the MIMO graph. Verified: there is NO BI_DB_DDR_Fact_MIMO_
  Crypto_Platform. MIMO sees crypto only post-C2F as eMoney rows tagged
  IsCryptoToFiat=1. Inbound on-chain deposits to wallet are invisible to
  MIMO until the customer converts. This is a real cross-platform reporting
  gap — surface it explicitly when answering "how much customer money
  flowed in/out?" questions.

triggers:
  - EXW
  - eToro Wallet
  - eToro wallet
  - etoro wallet
  - non-custodial wallet
  - non-custodial crypto
  - non custodial wallet
  - self-custody
  - self custody
  - on-chain wallet
  - on chain wallet
  - on-chain
  - on chain
  - blockchain wallet
  - crypto wallet
  - BitGo
  - bitgo
  - CUG
  - Tangany
  - GoodWallet
  - good wallet
  - exw_dbo
  - EXW_FactTransactions
  - EXW_FactBalance
  - EXW_FinanceReportsBalancesNew
  - EXW_FactRedeemTransactions
  - EXW_V_RedeemReconciliation
  - EXW_DimUser
  - EXW_DimUser_Enriched
  - EXW_WalletInventory
  - SP_EXW_FinanceReportsBalancesNew
  - SP_EXW_Fact_Transactions
  - SP_EXW_C2F_E2E
  - SP_EXW_FactRedeemTransactions
  - SentTransactions
  - SentTransactionOutputs
  - ReceivedTransactions
  - Conversions
  - ConversionTransactions
  - Redemptions
  - SendRequestCorrelationId
  - CorrelationId
  - BlockchainTransactionId
  - BlockchainCryptoId
  - WalletId
  - WalletPool
  - WalletBalances
  - CustomerWalletsView
  - public address
  - blockchain hash
  - AmlValidations
  - AML wallet
  - travel rule
  - TransactionTravelRule
  - bronze_walletdb_wallet
  - bronze_walletconversiondb_c2f
  - crypto-to-position
  - crypto to position
  - on-ramp
  - redeem crypto
  - redemption
  - withdraw to wallet
  - transfer to wallet
  - transfer coin
  - swap crypto
  - crypto swap
  - gas fee
  - ETH gas fee
  - EXW_EthFeeSent_Blockchain
  - wallet AUM
  - crypto AUM
  - on-chain AUM

required_tables:
  # Snapshot / AUM
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew
  # Unified transaction fact
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions
  # E2E reconciliation facts
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e
  - main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation
  # Customer / wallet hubs
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory
  - main.wallet.bronze_walletdb_wallet_customerwalletsview
  # On-chain ledger (the bronze layer the SP-built facts derive from)
  - main.wallet.bronze_walletdb_wallet_senttransactions
  - main.wallet.bronze_walletdb_wallet_senttransactionoutputs
  - main.wallet.bronze_walletdb_wallet_senttransactionstatuses
  - main.wallet.bronze_walletdb_wallet_receivedtransactions
  - main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses
  - main.wallet.bronze_walletdb_wallet_conversions
  - main.wallet.bronze_walletdb_wallet_conversiontransactions
  - main.wallet.bronze_walletdb_wallet_redemptions
  - main.wallet.bronze_walletdb_wallet_requests
  - main.wallet.bronze_walletdb_wallet_amlvalidations
  - main.wallet.bronze_walletdb_wallet_walletpool
  - main.wallet.bronze_walletdb_wallet_cryptotypes
  # Pricing
  - main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily
  # Travel-rule (Tier 3)
  - main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation
  - main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses

intersects_with:
  - domain-aum-and-aua/SKILL.md                       # EXW = line 4 of the AUM rollup contract
  - domain-trading/SKILL.md                           # TP-side real crypto, position lifecycle, position open (C2P sink)
  - domain-payments/SKILL.md                          # eMoney IBAN settlement (C2F sink), MIMO panel (crypto invisible until C2F)
  - domain-payments/mimo-panel-and-ddr.md             # IsCryptoToFiat=1 filter — the only place crypto touches MIMO
  - domain-revenue-and-fees/SKILL.md                  # C2F fee revenue, gas-fee revenue, staking-fee revenue
  - domain-compliance-and-aml/SKILL.md                # AML risk classification (uses our WalletId/address)
  - domain-customer-and-identity/SKILL.md             # GCID/RealCID identity bridge
  - cross-cutting/valid-users-filter-contract.md      # IsTestAccount/IsValidCustomer filter pattern
  - cross-cutting/data-latency-and-rollforward.md     # snapshot roll-forward (applies to balance-and-aum only)

out_of_scope:
  - Crypto CFD positions / P&L → domain-trading
  - Real-crypto on TP (Fact_AUM.TotalRealCrypto) → domain-trading
  - Fiat balance / IBAN balance → domain-payments
  - Cross-platform AUM rollup → domain-aum-and-aua
  - Fee revenue recognition (we provide the transaction; revenue lives in domain-revenue-and-fees)
  - AML risk classification (we provide WalletId/address; logic lives in domain-compliance-and-aml)
  - Synapse EXW_FactBalance (older fact, NOT in UC, do NOT use)
  - Synapse EXW_FactRedeemTransactions / EXW_FactConversions / EXW_PaymentReconciliation
    (NOT migrated to UC — must rebuild via CorrelationId stitch in UC; see redemptions.md, on-chain-ledger.md)

sub_skills:
  - balance-and-aum.md       # snapshot AUM (HOLD flow)
  - transactions.md          # EXW_FactTransactions unified fact (default analytical entry)
  - redemptions.md           # REDEEM flow (TP → wallet)
  - conversions-c2f.md       # C2F flow (wallet → IBAN fiat)
  - conversions-c2p.md       # C2P flow (wallet → TP open position)
  - on-chain-ledger.md       # bronze layer: sent/received/conversions/redemptions/AML/statuses
  - price-and-fx.md          # daily and hourly crypto prices (USD normalisation backbone)

version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-06-09"
---

# EXW (eToro Wallet) Super-Domain

> **Tier 0 — Cross-cutting contracts.**
> - **Snapshot facts** (the HOLD/balance-and-aum sub-skill — `EXW_FinanceReportsBalancesNew`) MUST follow [`../cross-cutting/data-latency-and-rollforward.md`](../cross-cutting/data-latency-and-rollforward.md): silent 3-day roll-forward to latest clean partition (T-1 cadence, partition `etr_ymd` STRING `'YYYY-MM-DD'`).
> - **Flow facts** (transactions / redemptions / C2F / C2P / on-chain ledger) are NOT subject to roll-forward — absence of activity = no activity, not staleness. Don't fabricate.
> - **Valid-customer filter** for any AUM-side rollup follows [`../cross-cutting/valid-users-filter-contract.md`](../cross-cutting/valid-users-filter-contract.md). On EXW, the canonical triplet is `IsTestAccount = 0 AND IsValidCustomer = 1 AND AMLClosureEvent = 0` (98.5% of dollar value).

## When to Use

Load this skill when the user asks about:
- "eToro Wallet" / "EXW" / "non-custodial crypto" / "self-custody crypto" / "GoodWallet" / "on-chain crypto"
- Any of the five EXW verbs: HOLD (snapshot balances), INBOUND (external receives), REDEEM (TP→wallet withdraw), C2F (wallet→IBAN fiat conversion), C2P (wallet→TP open position)
- Specific E2E facts: `EXW_FinanceReportsBalancesNew`, `EXW_FactTransactions`, `EXW_C2F_E2E`, `EXW_C2P_E2E`, `EXW_V_RedeemReconciliation`, `EXW_PriceDaily`
- Custody providers: BitGo, CUG, the retired Tangany; the decommissioned Simplex on-ramp; the frozen 2023-06 in-wallet swap (`EXW_FactConversions`)
- The bronze layer: `main.wallet.bronze_walletdb_wallet_*` tables and the CorrelationId master pattern
- Cross-domain bridges: how REDEEM stitches to TP `Dim_Position` (close → AdminPositionLog), how C2F bridges to eMoney, how C2P bridges to TP `IsAirDrop=1`
- AML semantics on a transaction: `AmlValidations`, `IsBlocked`, the pre-send screening flow
- Why EXW is additive to TP `TotalRealCrypto` (not double-counted) in cross-platform AUM
- Travel-rule data, blockchain hash joins, three-way reconciliation (eToro ledger ↔ BitGo API ↔ Blox tracker)

## Scope
**In scope:** the five EXW flows (HOLD / INBOUND / REDEEM / C2F / C2P) routed via 7 sub-skills (`balance-and-aum.md`, `transactions.md`, `redemptions.md`, `conversions-c2f.md`, `conversions-c2p.md`, `on-chain-ledger.md`, `price-and-fx.md`); the canonical AUM source `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew`; the unified transaction fact `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions`; the E2E reconciliation facts (C2F_E2E, C2P_E2E, V_RedeemReconciliation); the bronze layer's 14-table catalog under `main.wallet.bronze_walletdb_wallet_*`; pricing tables (`EXW_PriceDaily`, `EXW_Price`); custody provider routing (BitGo / CUG); AML pre-send pattern; travel-rule data.

**Out of scope:**
- TP-side trading positions and PnL → `domain-trading`
- IBAN balances and eMoney transactions on the fiat side of C2F → `domain-payments` (`crypto-wallet.md` is the legacy skill; this hub supersedes it)
- Customer master / GCID semantics → `domain-customer-and-identity`
- Cross-platform AUM rollup → `domain-aum-and-aua` (this hub provides the EXW line item only)
- Cross-platform MIMO panel → `domain-payments` (EXW is invisible to MIMO; redemptions move TP→wallet, not in/out of platform)
- Fee revenue from C2F slippage / spread → `domain-revenue-and-fees`
- Frozen products: in-wallet crypto-to-crypto swap (`EXW_FactConversions`, frozen 2023-06); fiat-to-crypto on-ramp (Simplex, decommissioned 2022-09)

Last verified: 2026-06-09

## Critical Warnings

### Tier 1 — Silent wrong numbers

1. **EXW AUM filtering — the valid-cohort triplet is mandatory** — `IsTestAccount = 0 AND IsValidCustomer = 1 AND AMLClosureEvent = 0` covers ~98.5% of dollar value; without these filters EXW totals are inflated by test wallets and AML-flagged shells. The cohort definition is EXW-side, not the cross-cutting `valid-users-filter-contract.md` SCD-2 walk — they coincide on `IsValidCustomer = 1` but EXW adds the two extra flags that are EXW-table-local.
2. **`etr_ymd` partition is a STRING, not INT** — landmine. On `EXW_FinanceReportsBalancesNew`, `EXW_FactTransactions`, and the bronze layer, `etr_ymd` is `'YYYY-MM-DD'` STRING; predicates using `etr_ymd = 20260608` (INT) silently filter to zero rows. Always use string literals: `etr_ymd = '2026-06-08'`.
3. **EXW is ADDITIVE to TP `TotalRealCrypto`, not a substitute** — the trading-side balance reflects in-platform crypto; EXW reflects withdrawn-to-chain crypto. Cross-platform AUM sums BOTH. Subtracting one from the other is wrong; double-counting is also wrong (a redemption moves the same coins from one column to the other across the redemption date — see `redemptions.md` for the bridge).
4. **CorrelationId is the universal stitch key across the EXW bronze layer** — the same CorrelationId appears across 14 bronze tables (`SentTransactions`, `ReceivedTransactions`, `WalletConversions`, `RedeemTransactions`, `AmlValidations`, status logs, fee tables). Joining on `WalletId` alone is wrong for transaction-level lineage. See `on-chain-ledger.md` § "CorrelationId master pattern".
5. **`EtoroFees` on `EXW_FactTransactions` is pre-multiplied with sign** — already includes the appropriate +/- direction; do NOT multiply by ActionType-derived sign. Doing so flips the sign and produces silently wrong fee totals. See `transactions.md` § cardinal rules.

### Tier 2 — Aggregate / interpretation

6. **MIMO panel does NOT see EXW activity** — redemptions are TP→wallet, not in/out of platform; in/out is what MIMO measures. This is intentional (the customer's money never leaves eToro's universe via redeem; only on C2F does the value exit eToro books). Don't expect EXW redemptions to appear in `BI_DB_DDR_Fact_MIMO_AllPlatforms`.
7. **C2F is a 5-stage lifecycle, not an atomic event** — `EXW_C2F_E2E` exposes timestamps for: `RequestedAt`, `LockedAt`, `ConfirmedAt`, `BroadcastAt`, `SettledAt`. Querying "C2F volume on date X" without picking a stage timestamp produces ambiguous numbers. The conventional choice is `SettledAt` for realised volume; `RequestedAt` for funnel analysis. See `conversions-c2f.md`.
8. **C2P launched 2025-12-11; pre-launch C2P questions are anachronisms** — `EXW_C2P_E2E` only has rows from 2025-12-11 onward. Cross-period comparisons (e.g., "C2P share of redemptions YoY") are meaningless before that date. See `conversions-c2p.md`.
9. **`EXW_EthFeeSent_Blockchain` is known-stale** — last refresh significantly behind T-1; do not use for live ETH fee analysis. The bronze `bronze_walletdb_wallet_sentethereumfees` table is the freshest path for ETH fee per send.

### Tier 3 — Operational / dependencies

10. **In-wallet crypto-to-crypto swap (`EXW_FactConversions`) is FROZEN since 2023-06** — the feature was removed; rows beyond 2023-06 do not exist. Don't quote conversion volume from this table; if asked, surface the freeze date and route to C2F (the only conversion product that survived).
11. **`bronze_walletdb_wallet_sentaddresses` fans out 1:N from a SentTransaction** — multi-output sends (one transaction broadcast to N receiver addresses) produce N rows here. Aggregate with care; the canonical "send count" is on the `SentTransactions` parent.
12. **Three independent reconciliation systems must agree** — eToro internal ledger, BitGo provider API, Blox tracker. Production runbooks (Confluence) describe how to investigate when one of the three diverges; this is operational rather than analytical, but cross-system divergence is a real cause of "phantom" wallet balances.

## What EXW is — one paragraph

EXW (eToro Wallet, branded externally as **eToro GoodWallet** in some Customer Service docs) is eToro's non-custodial crypto wallet product. Unlike every other balance in eToro (TP equity, IBAN, Options, Spaceship, MoneyFarm — all custodied within eToro's books), EXW assets live on public blockchains under wallet IDs provisioned by **BitGo (97.5%, multi-sig)** or **CUG (2.5%, MPC, newer chains like SOL)**. The customer holds the keys. eToro's role is custody orchestration (BitGo/CUG API), AML pre-screening (`AmlValidations` runs before broadcast), pricing (the daily and hourly price tables), travel-rule enforcement, and reconciliation across three independent systems (eToro internal ledger, BitGo provider API, Blox tracker).

The platform launched April 2018. As of 2026-06-09 it carries ~$105M in valid-cohort customer AUM across 717K wallets, with BTC ~60%, XRP ~22%, ETH ~12% of dollar value. ~80% of wallets carry `Balance = 0` (empty shells provisioned at activation but never used), ~21% have a positive USD value. Daily transaction throughput is ~5K redeems out of TP plus ~80K small inbound receives.

## The five flows (verbs of the platform)

This is the mental model — every EXW question maps to one of these five verbs plus two cross-cutting facts (transactions + price). The hub's job is to route to the right sub-skill.

```
                   ┌──────────────────────────────────────────────────────┐
                   │              EXW (eToro Wallet)                       │
                   │   Custody: BitGo (97.5%) / CUG (2.5%)                 │
                   │   Brand: also "eToro GoodWallet" in customer comms    │
                   └──────────────────────────────────────────────────────┘
                                          │
   ┌────────────┬────────────┬────────────┼────────────┬────────────┐
   │            │            │            │            │            │
   ▼            ▼            ▼            ▼            ▼            ▼
┌──────┐   ┌──────────┐   ┌──────────┐   ┌──────┐   ┌──────────┐   ┌─────────┐
│ HOLD │   │  REDEEM  │   │   C2F    │   │ C2P  │   │ INBOUND  │   │  SWAP   │
│balanc│   │TP→wallet │   │wallet→   │   │wlt→TP│   │external→ │   │crypto→  │
│snapsht│  │(withdraw │   │  IBAN    │   │positn│   │  wallet  │   │ crypto  │
│       │  │ to chain)│   │ fiat     │   │      │   │ (deposit)│   │ FROZEN  │
└──┬───┘   └────┬─────┘   └─────┬────┘   └──┬───┘   └─────┬────┘   └────┬────┘
   │            │               │           │             │             │
   ▼            ▼               ▼           ▼             ▼             ▼
EXW_Finance   EXW_Fact     EXW_C2F_E2E  EXW_C2P_E2E  Received      EXW_Fact
ReportsBala-  RedeemTrans  (UC, 103c,   (UC, 90c,    Transactions  Conversions
ncesNew       (Synapse-    17,702 rows) 5,978 rows)  (UC, 19c)     (Synapse-
(UC, 40c)     only, 1.13M  9 prod       launched     2.5M rows     only, 50K,
1.83M/day     rows; UC     Tableau      2025-12-11   blockchain    frozen
balance-and-  rebuild via  dashboards   trading       hash join     2023-06)
aum.md        Correlation  conversions- bridge        on-chain-     conversions
              Id stitch)   c2f.md       conversions-  ledger.md     -c2f.md §
              redemptions  ETM/Finance  c2p.md                      historical
              .md          owner        Trading
              MIMO Group                  bridge
              owner

   │            │               │           │             │             │
   ▼            ▼               ▼           ▼             ▼             ▼
   │       UNDERLYING:                    UNDERLYING:                   │
   └──── main.wallet.bronze_walletdb_wallet_* (the single OLTP mirror) ─┘
            • Wallets / WalletPool / WalletAssets
            • SentTransactions(11) + Outputs(14) + Statuses(7)
            • ReceivedTransactions(19) + Statuses(8)
            • Conversions(16) + ConversionTransactions(17)
            • Redemptions(20) + Requests(11) + RequestStatuses
            • AmlValidations(17) — PRE-send, blocking
            • CryptoTypes / BlockchainCryptos / FiatTypes
            • Travel rule: information / statuses / addresses
                    (on-chain-ledger.md owns this layer)
```

## Sub-skill routing

Default reading order if you have NO context: hub → `transactions.md` (EXW_FactTransactions is the most general-purpose entry).

| Question shape | Load |
|---|---|
| "What's our EXW AUM?" / "wallet balance for GCID X" / "BTC on wallet" / per-customer holdings | [`balance-and-aum.md`](balance-and-aum.md) |
| "Show me crypto activity for GCID X over a window" / "redeem volume per asset" / general transaction analytics | [`transactions.md`](transactions.md) |
| "Customer redeemed crypto from TP — when did it confirm?" / "off-platform redemption volume" / "bypass backoffice approval flow" | [`redemptions.md`](redemptions.md) |
| "Crypto came in → converted to EUR/USD on IBAN" / "C2F slippage" / "C2F failed cycle investigation" / Tableau C2F dashboards | [`conversions-c2f.md`](conversions-c2f.md) |
| "Customer used crypto to fund a position" / "what triggered this AdminPositionLog Crypto Transfer?" / IsAirDrop=1 + CompensationReasonID=134 | [`conversions-c2p.md`](conversions-c2p.md) |
| "On-chain hash forensics" / "was this send AML-blocked?" / "BitGo replacement (RBF)" / "real-time wallet balance via WalletBalances" / "Wallet→Customer GCID resolution" / public address lookup | [`on-chain-ledger.md`](on-chain-ledger.md) |
| "USD value of X BTC on date Y" / "EXW pricing source" / hourly vs daily price | [`price-and-fx.md`](price-and-fx.md) |

## Bridges OUT of EXW (when the question crosses to another domain)

| If the question also asks about... | Route to |
|---|---|
| **Top-line AUM across all platforms** | `domain-aum-and-aua/SKILL.md` — EXW is line 4 of the rollup contract. |
| **TP `TotalRealCrypto` vs wallet balance** | EXW is **additive** to `Fact_AUM.TotalRealCrypto`, not a duplicate. Real-crypto on TP is custodied within the platform; the moment a customer redeems via the REDEEM flow, the asset leaves TP and lands on EXW. Show both, sum both. See [`balance-and-aum.md`](balance-and-aum.md). |
| **Crypto CFD positions / PnL on ETH-pair** | `domain-trading` — CFD is a derivative on price, not a wallet position. Not here. |
| **Position lifecycle around a C2P** | `domain-trading` — `Dim_Position` and `Fact_CustomerAction` (`IsAirDrop=1`, `CompensationReasonID=134`) are the trading-side view. The C2P fact joins to those. |
| **eMoney IBAN settlement of a C2F** | `domain-payments/emoney-accounts-and-cards.md` — `EXW_C2F_E2E.eMoneyTransactionID` joins to `eMoney_Dim_Transaction`. |
| **MIMO panel — how much customer money flowed?** | `domain-payments/mimo-panel-and-ddr.md` — **only** post-C2F crypto appears, as `MIMOPlatform='eMoney' AND IsCryptoToFiat=1`. Inbound on-chain deposits are invisible to MIMO until converted. |
| **Fee revenue from C2F / staking / gas** | `domain-revenue-and-fees` — we provide the transaction (with `TotalFeePercentage`, `TotalFeeUSD`, `BlockchainFee`); they own the revenue line. Specifically: `v_revenue_transfercoinfee`, `v_revenue_stakingfee`. |
| **AML risk classification / SAR for a wallet** | `domain-compliance-and-aml` — we provide `WalletId` + public address + `AmlValidations.AmlDecision`; they own the risk model and the regulatory output. |
| **GCID ↔ RealCID ↔ wallet provider identity** | `domain-customer-and-identity/SKILL.md` — `EXW_DimUser.GCID` is the bridge. |
| **Operator action on a wallet (manual freeze, AML override)** | `domain-customer-and-identity/customer-action-audit-trail` — `Fact_CustomerAction` records the operator events. |

## Cardinal rules — burn these in

1. **`CorrelationId` is the cross-table linker — NOT amount/timestamp.** The single most-important primitive in EXW. Glues customer intent (`Conversions.CorrelationId`, `Redemptions.SendRequestCorrelationId`, `Requests.CorrelationId`) to on-chain execution (`SentTransactions.CorrelationId`). Without it the three Synapse-only facts (`EXW_FactRedeemTransactions`, `EXW_FactConversions`, `EXW_PaymentReconciliation`) cannot be reproduced in UC. Every sub-skill leans on this.

2. **Crypto is OFF the MIMO graph.** Verified — `BI_DB_DDR_Fact_MIMO_Crypto_Platform` does not exist. MIMO sees crypto only post-C2F (`MIMOPlatform='eMoney' AND IsCryptoToFiat=1`). For raw on-chain inflow/outflow, **never** route to MIMO; route to `transactions.md` or `on-chain-ledger.md`.

3. **EXW is additive to TP, not a duplicate.** `Fact_AUM.TotalRealCrypto` = TP-custodied real crypto. EXW = customer's own wallet. Adding both = correct. The REDEEM flow is the transition between them. See [`balance-and-aum.md`](balance-and-aum.md) cardinal rule #9.

4. **Three Synapse-only facts cannot be queried from Databricks.** `EXW_FactRedeemTransactions`, `EXW_FactConversions`, `EXW_PaymentReconciliation`. In UC: rebuild via `CorrelationId` stitch from the bronze layer. See [`redemptions.md`](redemptions.md) and [`on-chain-ledger.md`](on-chain-ledger.md) for the canonical replacement queries.

5. **`AmlValidations` runs PRE-send.** A `SentTransactions` row can exist with an `AmlValidations` row that blocked it. Don't assume "row exists = went through". Check `SentTransactionStatuses` for the actual lifecycle outcome.

6. **`SentTransactionStatuses` is a TRUE event log.** Unlike Synapse's `Fact_Deposit_State` (which is QA-only), the EXW status tables are real per-event logs. Query them directly for "when did this confirm" / "how long pending" / SLA analysis.

7. **`BlockchainCryptoId` self-joins on `CryptoTypes` for ERC-20 tokens.** USDT-on-ETH has `CryptoID` for the token but `BlockchainCryptoId` pointing to ETH's `CryptoID`. To show "asset on chain X" alongside the value, self-join `CryptoTypes` via `BlockchainCryptoId → CryptoID`.

8. **`SentTransactionOutputs` carries the per-output amount, not `SentTransactions`.** One send can fan out to multiple destination addresses. `SentTransactions` (11c) is the envelope; `SentTransactionOutputs` (14c) has the amounts. For total send volume, **SUM the outputs**.

9. **The Synapse `EXW_FactBalance` is NOT migrated to UC.** Per the Synapse wiki, `UC Target = _Not_Migrated`. It was the older balance fact. Use `EXW_FinanceReportsBalancesNew` (UC available, the current canonical) instead. Mentioned because the wiki cross-references can confuse.

10. **Two conversion features are dead.** `EXW_FactConversions` (crypto-to-crypto in-wallet swaps): frozen 2023-06-14, feature deprecated. `EXW_FactPayments` (Simplex fiat-to-crypto on-ramp): frozen 2022-09, decommissioned. Their data is historical only; do not look for live numbers. The current "convert in wallet" flow is C2F (wallet → IBAN), owned by ETM/Finance.

## Owner-side evidence (Confluence titles, not page bodies — for routing context)

| Owner team | Confluence pages found | What it tells us |
|---|---|---|
| **MIMO Group** | `Routing Tool - Redeem`, `Redeem Handling`, `CREATE REDEEM`, `Redeem Approval`, `Bypass Backoffice approval flow in Redeem`, `Redeem Error due to risk`, `Postmortem - DB Permission Issues During Redeem Process Payout Service` | The Redeem flow is owned by **MIMO Group**, not by a wallet team. That's a routing fact: redemption questions should reach MIMO Group's runbooks for ops/policy context. |
| **Operations Wiki** | `Redeem Process`, `eTM Crypto-to-Fiat (C2F) Alerts Review`, `US - Crypto to Fiat` | Operational runbooks for both Redeem and C2F. C2F has its own alerts surface in eToro Money (eTM). |
| **Wallet Group** | `Crypto Wallet - "Gaps" overview on eToro platform`, `PM-100: Crypto Wallet - Drawer Overview - Design Audit` | Product/design ownership — UI flows, gap analysis. |
| **Compliance Dev** | `How to do Transfer to Wallet (crypto wallet)` | Compliance-side runbook for outbound transfers. |
| **Big Data Platform** | `Crypto IN - Address vs Wallet Flow Mapping` | Lineage for the inbound (external→wallet) flow. Confirms the address-vs-wallet distinction (one customer, many addresses across blockchains). |
| **DevOps / NOC** | `Wallet Redeem QA`, `Wallet - Low spendable crypto for Bitgo token - Critically low` | Alerting on liquidity in eToro's omnibus wallets. |
| **Customer Service** | `eToro GoodWallet (non-custodial wallet)` | The customer-facing brand (GoodWallet) maps to the internal name (EXW). |
| **Quality - eToroX** | `Deposit and Withdraw flows for Bitgo currency` | eToroX-side flow doc; relevant for tokenized-asset (USDX, EURX, GBPX) flows. |

## Tableau footprint (production analyst surface)

Verified against `knowledge/tableau/_index/custom_sql_inventory.csv` on 2026-06-09 — **9 production dashboards** drive off `EXW_dbo.EXW_C2F_E2E` directly:

1. **C2F For CS** — Customer Service operational tooling.
2. **C2F report for AM's competition** — Account Manager scorecards.
3. **C2F/C2USD Reconciliation** (×2) — Finance recon dashboards.
4. **C2F Slippage Protection** — rate-slippage monitoring (estimated vs actual).
5. **Crypto to IBAN & Crypto to USD** (×2) — flow analytics.
6. **new ddrs monitoring** + extract — operational dashboard joining `EXW_C2F_E2E` against the DDR fact family. **The only place where C2F data crosses the DDR/MIMO panel.**

Plus 481 calc-field references across the Tableau corpus mention `exw|wallet|crypto`. C2F is the most operationalised flow; the other four flows have less Tableau footprint.

## Provenance

v1 — created 2026-06-09. Built from:
- The pre-existing 380-line skill `knowledge/skills/domain-payments/crypto-wallet.md` (validated 2026-05-11) as the structural backbone.
- Live UC verification of column counts and freshness on 2026-06-09 against `system.information_schema.columns` and recent partitions: all 14 spot-checked tables match wiki claims; `EXW_FactTransactions` last `TranDate = 2026-06-08`, last refresh = 2026-06-09 07:28 UTC; `EXW_C2F_E2E` and `EXW_C2P_E2E` both have rows through 2026-06-07 (not stale as the April-2026 wikis suggest — they have grown to 17,702 and 5,978 rows respectively).
- 50+ Synapse wikis under `knowledge/synapse/Wiki/EXW_dbo/` and `knowledge/synapse/Wiki/EXW_Wallet/`.
- 22 UC wikis under `knowledge/UC_generated/wallet/` plus 25+ wallet-related bronze tables under `knowledge/UC_generated/bi_db/`.
- 9 production Tableau dashboards verified via `knowledge/tableau/_index/custom_sql_inventory.csv`.
- 8 owner-team Confluence spaces (MIMO Group, Operations Wiki, Wallet Group, Compliance Dev, Big Data Platform, DevOps/NOC, Customer Service, Quality-eToroX) found via Atlassian MCP CQL search.

The previous "skill gap" was a **deployment gap**, not a knowledge gap — the source materials existed but were never promoted into the active skill tree under `.cursor/skills/`. This hub closes that.
