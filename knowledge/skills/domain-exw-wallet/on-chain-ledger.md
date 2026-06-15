---
name: domain-exw-wallet
description: |
  EXW on-chain ledger sub-skill. The bronze layer that EVERY other EXW
  sub-skill ultimately drains from: the production OLTP mirror under
  main.wallet.bronze_walletdb_wallet_*. This is where you go when you
  need on-chain hash forensics, status-lifecycle drilldown, AML pre-check
  detail, BitGo replacement-chain (RBF) analysis, or wallet → customer
  GCID resolution at the address level.

  Owns:
   1. The 14-table bronze layer schema as a navigable catalog.
   2. The CorrelationId master pattern (the cross-table linker that powers manual UC rebuilds of all three Synapse-only facts).
   3. The PRE-send AML semantics (AmlValidations runs BEFORE broadcast).
   4. The status lifecycle (SentTransactionStatuses / ReceivedTransactionStatuses are TRUE event logs).
   5. The Wallet ↔ Customer resolution path (CustomerWalletsView → DimUser).
   6. BlockchainCryptoId self-join for ERC-20 token-on-chain-X resolution.
   7. The SentTransactionOutputs fan-out rule (one send → many outputs → SUM the outputs for total volume).
   8. Travel-rule data layer (TransactionTravelRule*).
   9. Known data-freshness issue: EXW_EthFeeSent_Blockchain stale since 2026-03-09.

  Out of scope:
   - The unified analytical fact (use that first if you can) → transactions.md
   - Daily AUM snapshot → balance-and-aum.md
   - Redemption / C2F / C2P E2E facts (use those first if you can) → redemptions.md / conversions-*.md
   - Pricing layer → price-and-fx.md

triggers:
  - on-chain
  - blockchain hash
  - blockchain transaction
  - BlockchainTransactionId
  - SentTransactions
  - SentTransactionOutputs
  - SentTransactionStatuses
  - SentTransactionReplaces
  - ReceivedTransactions
  - ReceivedTransactionStatuses
  - Conversions
  - ConversionTransactions
  - Redemptions
  - Requests
  - WalletPool
  - Wallets
  - WalletAssets
  - WalletBalances
  - CustomerWalletsView
  - AmlValidations
  - AmlClosureEvent
  - AmlDecision
  - CryptoTypes
  - BlockchainCryptos
  - BlockchainCryptoId
  - FiatTypes
  - public address
  - sender address
  - receiver address
  - BitGo replacement
  - RBF
  - replace by fee
  - SentTransactionReplaces
  - TransactionTravelRule
  - TransactionTravelRuleStatus
  - TransactionTravelRuleAddress
  - travel rule
  - VASP
  - bronze_walletdb_wallet
  - EXW_EthFeeSent_Blockchain

required_tables:
  # Wallet identity / customer-resolution
  - main.wallet.bronze_walletdb_wallet_customerwalletsview
  - main.wallet.bronze_walletdb_wallet_walletpool
  - main.wallet.bronze_walletdb_wallet_wallets
  - main.wallet.bronze_walletdb_wallet_walletassets
  - main.wallet.bronze_walletdb_wallet_walletbalances
  # Sent / received
  - main.wallet.bronze_walletdb_wallet_senttransactions
  - main.wallet.bronze_walletdb_wallet_senttransactionoutputs
  - main.wallet.bronze_walletdb_wallet_senttransactionstatuses
  - main.wallet.bronze_walletdb_wallet_senttransactionreplaces
  - main.wallet.bronze_walletdb_wallet_receivedtransactions
  - main.wallet.bronze_walletdb_wallet_receivedtransactionstatuses
  # Conversions / redemptions / requests
  - main.wallet.bronze_walletdb_wallet_conversions
  - main.wallet.bronze_walletdb_wallet_conversiontransactions
  - main.wallet.bronze_walletdb_wallet_redemptions
  - main.wallet.bronze_walletdb_wallet_requests
  - main.wallet.bronze_walletdb_wallet_requeststatuses
  # AML
  - main.wallet.bronze_walletdb_wallet_amlvalidations
  # Reference
  - main.wallet.bronze_walletdb_wallet_cryptotypes
  - main.wallet.bronze_walletdb_wallet_blockchaincryptos
  - main.wallet.bronze_walletdb_wallet_fiattypes
  # Travel rule
  - main.bi_db.bronze_walletdb_wallet_transactiontravelruleinformation
  - main.bi_db.bronze_walletdb_wallet_transactiontravelrulestatuses
  # Known-stale fact (warn before use)
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_ethfeesent_blockchain

intersects_with:
  - domain-exw-wallet/SKILL.md
  - domain-exw-wallet/transactions.md
  - domain-exw-wallet/redemptions.md
  - domain-exw-wallet/conversions-c2f.md
  - domain-exw-wallet/conversions-c2p.md
  - domain-compliance-and-aml/SKILL.md

version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-06-09"
---

# On-Chain Ledger — bronze layer drilldown

> **Tier 0 — Mostly flow facts.** Roll-forward contract does NOT apply.
> **EXCEPTION**: `WalletBalances` is a snapshot (latest known balance per wallet × asset). Treat it as a snapshot if you need "balance right now" for a single wallet — but for AUM, use `balance-and-aum.md` not this.

## When to come here

This sub-skill is the **last resort drilldown**. If `transactions.md`, `redemptions.md`, `conversions-c2f.md`, `conversions-c2p.md`, or `balance-and-aum.md` can answer the question, USE THEM — they pre-join, pre-enrich, and apply the right filters. Come here only when you need:

1. **Hash forensics**: "where did this `0xabc...` transaction land / what was its lifecycle / was it replaced?"
2. **Status lifecycle**: "how long was this tx pending? what was the Confirmed timestamp specifically?"
3. **AML pre-check forensics**: did `AmlValidations` block this send before broadcast?
4. **Wallet → Customer resolution at the address level**: "which GCID owns public address `bc1q...`?"
5. **BitGo replacement (RBF) analysis**: "this send shows two on-chain hashes — why?"
6. **Per-output amounts**: "this send fan-outs to 4 destinations — break down the amounts."
7. **Travel-rule disclosure**: "which originator / beneficiary VASP info do we have for this transfer?"
8. **CorrelationId rebuilds**: replicating any of the three Synapse-only facts (`EXW_FactRedeemTransactions`, `EXW_FactConversions`, `EXW_PaymentReconciliation`) inside UC.

## The 14-table catalog

```
─── Identity / Customer-Resolution ───
CustomerWalletsView (13c) — Customer ↔ Wallet ↔ Address mapping. ONE customer can have MANY addresses.
WalletPool (?)             — All eToro-managed wallet pools (per-asset omnibus + per-customer).
Wallets (?)                — Individual wallet IDs.
WalletAssets (?)           — Per-wallet supported asset list.
WalletBalances (?)         — LATEST balance per (Wallet × Asset). SNAPSHOT shape — use for spot.

─── Sent flow (outbound) ───
SentTransactions (11c)         — Envelope. ONE row per send. Has CorrelationId + BlockchainTransactionId.
SentTransactionOutputs (14c)   — Per-destination amount. ONE-TO-MANY off SentTransactions.
SentTransactionStatuses (7c)   — TRUE event log. ONE row per (sent × status-change). Use for lifecycle.
SentTransactionReplaces (?)    — RBF chain. When BitGo bumps a fee, the replaced + replacement form a chain here.

─── Received flow (inbound) ───
ReceivedTransactions (19c)     — ONE row per receive. Has BlockchainTransactionId + WalletId.
ReceivedTransactionStatuses(8c)— TRUE event log per receive.

─── Conversions (in-wallet swap, mostly DEAD post-2023) ───
Conversions (16c)              — Intent. CorrelationId is the linker.
ConversionTransactions (17c)   — On-chain leg of a conversion. (Modern C2F/C2P live on the gold E2E facts; this layer is mostly historical.)

─── Redemptions / Requests ───
Redemptions (20c)              — TP→wallet redeem intent. SendRequestCorrelationId is the linker.
Requests (?)                   — Generic outbound request envelope.
RequestStatuses (?)            — Status lifecycle for requests.

─── AML (PRE-SEND) ───
AmlValidations (17c)           — Runs BEFORE broadcast. AmlDecision in (Green/Amber/Red/NA/Error).

─── Reference dictionaries ───
CryptoTypes / BlockchainCryptos / FiatTypes — naming/symbol/precision lookups.

─── Travel Rule (regulator-driven, FATF) ───
TransactionTravelRuleInformation — originator/beneficiary VASP info attached to a tx.
TransactionTravelRuleStatuses    — verification-state lifecycle for travel-rule data.
```

## The CorrelationId master pattern

`CorrelationId` is the single most important primitive in EXW. It is the bridge from customer **intent** (a redemption, a conversion, a request) to on-chain **execution** (a sent transaction). Without it, the three Synapse-only facts cannot be reproduced in UC. Here's the canonical map:

| Intent table | Linker column | Execution table | Linker column |
|---|---|---|---|
| `Conversions` | `CorrelationId` | `SentTransactions` | `CorrelationId` |
| `Redemptions` | `SendRequestCorrelationId` | `SentTransactions` | `CorrelationId` |
| `Requests` | `CorrelationId` | `SentTransactions` | `CorrelationId` |

Joining on amount and timestamp instead of `CorrelationId` is **wrong** — multiple sends with the same amount can occur within seconds, and same-amount duplicates cause silent double-counting. Cardinal rule.

## Cardinal rules

1. **`SentTransactions` is the envelope, `SentTransactionOutputs` has the amounts.** A single send can fan out to multiple destinations. SUM `Outputs.Amount` for total volume; never use `SentTransactions.Amount` (which doesn't exist — verify your column list before assuming).
2. **`SentTransactionStatuses` is a TRUE event log.** Unlike Synapse's `Fact_Deposit_State` (QA-only), the EXW status tables are real. Query for "max status per tx" via `ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY StatusUpdatedAt DESC)` to get current state, or join the full lifecycle for "time-to-confirmation" SLA reporting.
3. **`AmlValidations` runs PRE-SEND, blocking.** A row in `SentTransactions` with a matching row in `AmlValidations` where `AmlDecision = 'Red'` may have been blocked before broadcast — do NOT assume "row exists = went through". Always reach for `SentTransactionStatuses` for the actual outcome.
4. **AML join differs by direction** (also stated in `transactions.md` cardinal rule #2 — repeated here because the bronze level is where you'll feel it): `AmlValidations` joins to **Sent** via `CorrelationId` (and only for `TransactionTypeID = 1` CustomerMoneyOut in the SP); to **Received** via `BlockchainTransactionId + WalletId` taking most-recent.
5. **`BlockchainCryptoId` self-joins on `CryptoTypes` for ERC-20 tokens.** USDT-on-ETH has its own `CryptoID` for the token, but `BlockchainCryptoId` pointing to ETH's `CryptoID` (the underlying chain). To display "token X on chain Y", self-join `CryptoTypes` via `BlockchainCryptoId → CryptoID`.
6. **One customer → many addresses.** `CustomerWalletsView` is one-to-many: a single customer can have a different public address per blockchain (e.g. one for BTC, one for ETH, one for SOL), and on chains supporting multiple addresses, multiple addresses per chain. Don't assume "1 customer = 1 address".
7. **`EXW_EthFeeSent_Blockchain` is STALE** as of 2026-06-09: max `TranDate = 2026-03-09`, 338,404 rows. **3 months stale**. If you need recent ETH gas-fee detail, do NOT use this table — fall back to `SentTransactions` + `SentTransactionOutputs` filtered to ETH for the underlying gas, or escalate as a data-freshness issue. Do not silently produce stale numbers.
8. **Travel-rule data is sparse.** Only a fraction of cross-VASP transfers have travel-rule rows attached. Don't infer "no row = travel-rule violation"; check `TransactionTravelRuleStatuses` for whether validation was even attempted.

## Canonical SQL patterns

### 1. Wallet → Customer GCID resolution at the address level

```sql
SELECT DISTINCT GCID, RealCID, WalletID, PublicAddress, CryptoID
FROM   main.wallet.bronze_walletdb_wallet_customerwalletsview
WHERE  PublicAddress = :address;
```

### 2. Send lifecycle with all status events

```sql
WITH latest AS (
  SELECT s.SentTransactionId,
         st.Status,
         st.StatusUpdatedAt,
         ROW_NUMBER() OVER (PARTITION BY s.SentTransactionId ORDER BY st.StatusUpdatedAt DESC) AS rn
  FROM      main.wallet.bronze_walletdb_wallet_senttransactions       s
  LEFT JOIN main.wallet.bronze_walletdb_wallet_senttransactionstatuses st
         ON st.SentTransactionId = s.SentTransactionId
  WHERE s.BlockchainTransactionId = :hash
)
SELECT * FROM latest;  -- All events; current status = WHERE rn=1
```

### 3. Total send volume — fan-out aware (correct)

```sql
SELECT
  s.SentTransactionId,
  s.BlockchainTransactionId,
  s.WalletId AS sending_wallet,
  SUM(o.Amount) AS total_amount,
  COUNT(*)      AS output_count
FROM      main.wallet.bronze_walletdb_wallet_senttransactions       s
LEFT JOIN main.wallet.bronze_walletdb_wallet_senttransactionoutputs o
       ON o.SentTransactionId = s.SentTransactionId
WHERE s.CreatedAt >= :from_dt
GROUP BY 1, 2, 3;
```

### 4. AML-blocked (or warned) lifecycle outcome

```sql
SELECT
  s.SentTransactionId,
  s.BlockchainTransactionId,
  a.AmlDecision,
  a.AmlReason,
  st.Status AS final_status,
  st.StatusUpdatedAt AS final_status_at
FROM      main.wallet.bronze_walletdb_wallet_senttransactions       s
LEFT JOIN main.wallet.bronze_walletdb_wallet_amlvalidations          a
       ON a.CorrelationId = s.CorrelationId
LEFT JOIN (
   SELECT SentTransactionId, Status, StatusUpdatedAt,
          ROW_NUMBER() OVER (PARTITION BY SentTransactionId ORDER BY StatusUpdatedAt DESC) AS rn
   FROM   main.wallet.bronze_walletdb_wallet_senttransactionstatuses
) st ON st.SentTransactionId = s.SentTransactionId AND st.rn = 1
WHERE a.AmlDecision IN ('Red','Amber')
  AND s.CreatedAt >= :from_dt;
```

### 5. CorrelationId rebuild — pattern reference

The full rebuild of `EXW_FactRedeemTransactions` is in `redemptions.md` § "Manual UC rebuild of EXW_FactRedeemTransactions". Use the same pattern (intent table → CorrelationId → execution table → status-latest) for `EXW_FactConversions` and `EXW_PaymentReconciliation`.

### 6. ERC-20 token + chain resolution (self-join on CryptoTypes)

```sql
SELECT
  ct_token.CryptoID    AS token_crypto_id,
  ct_token.Symbol      AS token_symbol,
  ct_chain.CryptoID    AS chain_crypto_id,
  ct_chain.Symbol      AS chain_symbol
FROM      main.wallet.bronze_walletdb_wallet_cryptotypes ct_token
LEFT JOIN main.wallet.bronze_walletdb_wallet_cryptotypes ct_chain
       ON ct_chain.CryptoID = ct_token.BlockchainCryptoId
WHERE ct_token.Symbol IN ('USDT','USDC','DAI');
-- Returns: USDT/ETH, USDT/TRX, USDC/ETH, etc.
```

## Provenance

v1 — created 2026-06-09. Verified live:
- ✅ All 14 bronze tables present in UC with column counts matching their UC wikis (probed via `information_schema.columns`).
- ✅ `EXW_EthFeeSent_Blockchain` stale: max TranDate = 2026-03-09 (338,404 rows lifetime). Flagged.
- Source backbone: `knowledge/skills/domain-payments/crypto-wallet.md` cardinal rules; UC wikis under `knowledge/UC_generated/wallet/`; Synapse wikis under `knowledge/synapse/Wiki/EXW_dbo/Tables/` for the SP-side semantics.
- Confluence: "Crypto IN - Address vs Wallet Flow Mapping" (Big Data Platform) confirms the address-vs-wallet (one customer → many addresses) distinction.
