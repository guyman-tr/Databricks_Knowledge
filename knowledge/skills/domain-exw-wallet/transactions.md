---
name: domain-exw-wallet
description: |
  EXW unified transaction-fact sub-skill. The default analytical entry for any
  "show me crypto activity" question — EXW_FactTransactions is the SP-built
  fact that unifies Sent + Received + Conversion + Redemption + Payment into
  one row-level table with USD pricing, AML enrichment, and four mutually-
  exclusive classification flags.

  This sub-skill owns:
   1. The unified fact: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions (45c, 4.7M+ rows, daily T-1).
   2. The four classification flags (IsRedeem / IsConversion / IsPayment / IsFunding) and their TransactionTypeID / ReceivedTransactionTypeID source rules.
   3. The two-row-per-on-chain-tx pattern (ActionTypeID=1 sent, ActionTypeID=2 received).
   4. The EtoroFees normalisation rule (already multiplied by FeeExchangeRate — do NOT re-multiply).
   5. AML enrichment join paths (different by direction — sent uses CorrelationId, received uses BlockchainTransactionId+WalletId).
   6. Per-customer activity windowing patterns.

  Out of scope:
   - Daily SNAPSHOT balance / AUM → balance-and-aum.md
   - Off-platform redemption forensics (TP→wallet drill-down) → redemptions.md
   - C2F end-to-end reconciliation → conversions-c2f.md
   - C2P end-to-end reconciliation → conversions-c2p.md
   - Bronze-layer on-chain hash lookups, status lifecycle, BitGo replacement → on-chain-ledger.md
   - Pricing source detail → price-and-fx.md

triggers:
  - EXW_FactTransactions
  - exw_facttransactions
  - SP_EXW_Fact_Transactions
  - unified transaction fact
  - crypto activity
  - wallet activity
  - IsRedeem
  - IsConversion
  - IsPayment
  - IsFunding
  - TransactionTypeID
  - ReceivedTransactionTypeID
  - ActionTypeID
  - EtoroFees
  - FeeExchangeRate
  - AmountUSD
  - EtoroFeesUSD
  - BlockchainFeesUSD
  - AMLProviderStatus
  - AMLIsPositiveDecision
  - TranID
  - TranDate
  - GCID activity window
  - per-customer crypto

required_tables:
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory
  - main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily

intersects_with:
  - domain-exw-wallet/SKILL.md
  - domain-exw-wallet/on-chain-ledger.md
  - domain-customer-and-identity/SKILL.md      # GCID hub via EXW_DimUser

version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-06-09"
---

# EXW_FactTransactions — the unified transaction fact

> **Tier 0 — Flow fact, NOT a snapshot.** This sub-skill produces flow numbers (counts, sums over a window). The `data-latency-and-rollforward` contract does NOT apply — absence of activity for a date means no activity, not staleness. Don't fabricate. Latest `TranDate` verified 2026-06-08 with refresh stamp `UpdateDate = 2026-06-09 07:28 UTC` — daily T-1 cadence, healthy.

## Why this fact exists

`EXW_FactTransactions` is the analyst-facing landing pad for crypto activity. The production OLTP schema (`main.wallet.bronze_walletdb_wallet_*`) splits crypto activity across five tables — `SentTransactions`, `ReceivedTransactions`, `Conversions`, `ConversionTransactions`, `Redemptions` — each with their own keys, statuses, and quirks. Most analyst questions don't care about those distinctions and just want "crypto activity for customer X in window Y". `SP_EXW_Fact_Transactions` does the joining work and materialises one row per (TranID × ActionTypeID), with USD already normalised, AML already joined, and four flags that classify the row by business intent.

Verified 2026-06-09:
- Column count: **45** (matches Synapse wiki).
- Row count: **4.7M+** (was 4.71M as of April 2026; growing).
- Direction split: ~53% Received / 47% Sent (April 2026 snapshot).
- Refresh: daily incremental DELETE+INSERT per `@d` parameter; the SP processes all transactions whose `TranDate`, `Occurred`, or `LastStatusUpdateOccurred` falls within `[@d, @d+1)`.

## Grain

One row per **TranID × ActionTypeID**.

- A single on-chain transaction can produce **two rows**:
  - `ActionTypeID = 1` (Sent) — the originating wallet's outflow.
  - `ActionTypeID = 2` (Received) — the destination wallet's inflow.
- For redemptions and C2F: only `ActionTypeID = 1` exists from the customer's perspective (the receive side is on the customer's external wallet, off our books, unless they sent it back to another eToro wallet).
- For wallet→wallet transfers between eToro customers: both rows exist. Joining `Sent.BlockchainTransactionId = Received.BlockchainTransactionId` is the on-chain reconciliation key (cardinal rule #6 from the hub).

## The four classification flags (mutually exclusive — but ~45% of rows have all four = 0)

```
IsRedeem = 1:
  Sent     → TransactionTypeID IN (0=Redeem, 8=RedeemAsic)
  Received → ReceivedTransactionTypeID IN (2=Redeem, 7) OR matches blockchain hash of a sent redemption
IsConversion = 1:
  Sent     → TransactionTypeID IN (5=ConversionMoneyIn, 6=ConversionMoneyOut)
  Received → ReceivedTransactionTypeID IN (4=ConversionToEtoro, 5=ConversionFromEtoro)
IsPayment = 1:
  Sent     → TransactionTypeID = 7 (Payment, ~Simplex era)
  Received → ReceivedTransactionTypeID = 6 (Payment)
IsFunding = 1:
  Sent     → TransactionTypeID = 4 (Funding — pool wallet pre-funding)
  Received → ReceivedTransactionTypeID = 3
```

The "all flags = 0" residual (~45% of rows) is the un-classified bucket: `CustomerMoneyOut`, `AmlMoneyBack`, `ManualUserMoneyOut`, plus historical types not flagged. Don't filter these out by default — they include real customer activity (e.g., one-off operator-driven sends during AML investigation).

Live distribution since 2026-05-01 (verified):

| Flags | ActionType | Rows | USD volume |
|---|---|---|---|
| All 0 | Received (2) | 82,286 | $21.7M |
| All 0 | Sent (1) | 9,634 | $23.3M |
| IsRedeem=1 | Sent (1) | 5,656 | $14.1M |
| IsRedeem=1 | Received (2) | 5,645 | $14.1M |

Notable: zero `IsConversion=1` and `IsPayment=1` rows in the past month — those features are dead (Simplex 2022, in-wallet swaps 2023). Live conversions go through C2F, which lands on `EXW_C2F_E2E`, not here.

## Cardinal rules

1. **`EtoroFees` is already × `FeeExchangeRate` — do NOT re-multiply.** The SP applies `EtoroFees = source.EtoroFees × FeeExchangeRate` at insert time. For most types `FeeExchangeRate = 1`, so the value equals the raw source. For ConversionOut (type 6) and Payment (type 7) the rate is non-trivial (currency cross-rate or 1/exchange-rate). Re-applying it is the most common analytical bug on this fact.
2. **AML enrichment join differs by direction.**
   - Sent: `AMLProviderStatus` joined via `CorrelationId` — but only for `TransactionTypeID = 1` (CustomerMoneyOut). Other sent types resolve through `SentTransactions.CorrelationId` but the AML pre-aggregation `#amlsent` is filtered to type 1.
   - Received: `AMLProviderStatus` joined via `BlockchainTransactionId + WalletId`, taking the most-recent record (`RnReceived = 1`).
   - NULL (~69% of rows) means no AML check was performed — common for pure inbound or system-internal transfers.
   - AML decision values: `Green` (clear), `Amber` (under review), `Red` (flagged), `NA` (not applicable), `Error` (provider error).
3. **Reach down to bronze for hash forensics, not here.** This fact has `BlockchainTransactionId` but lacks the per-output detail (`SentTransactionOutputs`), the BitGo RBF replacement chain (`SentTransactionReplaces`), and the per-status timeline (`SentTransactionStatuses`). For "when did this confirm / how long pending / was it replaced", load [`on-chain-ledger.md`](on-chain-ledger.md).
4. **Daily holdings — use `EXW_WalletInventory`, not this fact.** This is a transaction (flow) fact. For "what did GCID X hold on date Y", use `EXW_WalletInventory` (19c, daily aggregate). They share the GCID hub via `EXW_DimUser`.
5. **The fact is per-customer-action, not per-customer.** `COUNT(DISTINCT GCID)` over a window gives "active wallet users in window", not total wallet customers. For total wallet customers regardless of activity, see [`balance-and-aum.md`](balance-and-aum.md).

## Canonical SQL patterns

### 1. Customer crypto activity over a window (the most common question)

```sql
SELECT
  ft.TranDate,
  ft.ActionTypeID,           -- 1=sent, 2=received
  ft.IsRedeem, ft.IsConversion, ft.IsPayment, ft.IsFunding,
  ft.CryptoSymbol,
  ft.Amount,
  ft.AmountUSD,
  ft.EtoroFees,
  ft.EtoroFeesUSD,
  ft.AMLProviderStatus,
  ft.AMLIsPositiveDecision,
  ft.BlockchainTransactionId,
  ft.WalletId
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ft
WHERE ft.GCID = :gcid
  AND ft.TranDate BETWEEN :from_dt AND :to_dt
ORDER BY ft.TranDate, ft.ActionTypeID;
```

### 2. Redemption volume per asset per month (live and useful — verified shape)

```sql
SELECT
  DATE_TRUNC('MONTH', TranDate) AS month,
  CryptoSymbol,
  SUM(CASE WHEN ActionTypeID = 1 THEN AmountUSD ELSE 0 END) AS sent_usd,
  SUM(CASE WHEN ActionTypeID = 2 THEN AmountUSD ELSE 0 END) AS received_usd,
  COUNT(DISTINCT GCID)                                       AS active_customers,
  COUNT(DISTINCT BlockchainTransactionId)                    AS distinct_onchain_txs
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions
WHERE IsRedeem = 1
  AND TranDate >= '2026-01-01'
GROUP BY 1, 2
ORDER BY 1 DESC, sent_usd DESC;
```

### 3. AML-blocked sends in a window

```sql
SELECT
  TranDate, GCID, CryptoSymbol, AmountUSD,
  AMLProviderStatus,
  AMLIsPositiveDecision,
  BlockchainTransactionId
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions
WHERE ActionTypeID = 1
  AND AMLIsPositiveDecision = 0   -- explicitly blocked
  AND TranDate BETWEEN :from_dt AND :to_dt;
```

For the actual lifecycle outcome ("did the block hold? did it eventually get released?") drill into `on-chain-ledger.md` and join to `wallet.bronze_walletdb_wallet_senttransactionstatuses`.

### 4. Same-customer enriched (GCID + RealCID + customer demographics)

```sql
SELECT
  ft.TranDate, ft.CryptoSymbol, ft.AmountUSD, ft.IsRedeem, ft.IsConversion,
  du.GCID, du.RealCID,
  du.RegulationID, du.CountryID
FROM      main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ft
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser           du
       ON du.GCID = ft.GCID
WHERE ft.TranDate >= :from_dt;
```

## Provenance

v1 — created 2026-06-09. Verified live:
- ✅ 45 columns in `information_schema.columns`.
- ✅ Latest `TranDate = 2026-06-08` with `UpdateDate = 2026-06-09 07:28 UTC` (daily T-1).
- ✅ Type-flag distribution since 2026-05-01 confirms IsRedeem is the only flag with non-zero rows; IsConversion/IsPayment/IsFunding are dead surfaces.
- Source backbone: pre-existing `knowledge/skills/domain-payments/crypto-wallet.md` (Tier-1 reach order).
- Synapse wiki: `knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_FactTransactions.md` (column-level descriptions, classification flag rules, EtoroFees normalisation rule, AML join semantics).
