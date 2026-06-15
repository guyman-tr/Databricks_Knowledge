---
name: domain-exw-wallet
description: |
  REDEEM flow sub-skill — TP position → wallet (the canonical "withdraw crypto
  to my own wallet" flow). When a customer closes a real-crypto position on
  the trading platform with the intent to take custody, eToro broadcasts an
  on-chain send from an internal omnibus wallet to the customer's wallet
  address. This sub-skill owns the analytical reconstruction.

  Lifetime volume: 1.13M rows. Owned operationally by MIMO Group (per Confluence
  routing tools, postmortems, approval flows). Deprecated Synapse fact:
  EXW_FactRedeemTransactions (NOT in UC). Live UC analytical surfaces:
  EXW_V_RedeemReconciliation (51c, 1.13M rows) — analyst-facing reconciled view —
  and EXW_FactTransactions (filtered IsRedeem=1) for activity analytics.

  This sub-skill owns:
   1. EXW_V_RedeemReconciliation column-level guide and the (eToro-side, Wallet-side) twin-prefix structure.
   2. The CorrelationId stitch path to rebuild EXW_FactRedeemTransactions in UC.
   3. The owner mapping (MIMO Group runbooks).
   4. The cross-link: TP-side `Redemption` action / `RedeemID` ↔ wallet-side `WalletRedeemID` ↔ on-chain `BlockchainTransactionID`.

  Out of scope:
   - Inbound on-chain receives (external→wallet) → on-chain-ledger.md
   - Pure transaction analytics (Sent/Received aggregates) → transactions.md
   - C2F off-ramp → conversions-c2f.md
   - C2P → conversions-c2p.md

triggers:
  - redeem
  - redemption
  - redeem to wallet
  - redeem crypto
  - withdraw crypto
  - withdraw to wallet
  - transfer to wallet
  - transfer coin
  - transfercoin
  - off-platform transfer
  - off platform redemption
  - EXW_FactRedeemTransactions
  - EXW_V_RedeemReconciliation
  - exw_v_redeemreconciliation
  - SP_EXW_FactRedeemTransactions
  - SendRequestCorrelationId
  - WalletRedeemID
  - WalletSentTransactionID
  - EtoroRedeemStatus
  - WalletRedeemStatus
  - Routing Tool Redeem
  - MIMO Group redeem
  - Bypass Backoffice approval Redeem
  - Redeem Approval

required_tables:
  - main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions
  - main.wallet.bronze_walletdb_wallet_redemptions
  - main.wallet.bronze_walletdb_wallet_requests
  - main.wallet.bronze_walletdb_wallet_senttransactions
  - main.wallet.bronze_walletdb_wallet_senttransactionoutputs
  - main.wallet.bronze_walletdb_wallet_senttransactionstatuses
  - main.wallet.bronze_walletdb_wallet_amlvalidations

intersects_with:
  - domain-exw-wallet/SKILL.md
  - domain-exw-wallet/transactions.md
  - domain-exw-wallet/on-chain-ledger.md
  - domain-trading/SKILL.md                # TP-side Redemption customer-action and Dim_Position close
  - domain-revenue-and-fees/SKILL.md       # transfer-coin fee bridge

version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-06-09"
---

# REDEEM — TP position → wallet

> **Tier 0 — Flow fact.** Roll-forward contract does NOT apply.

## What "redeem" means at eToro

A redemption is a customer-initiated outbound from eToro's trading platform to the customer's **own non-custodial wallet** (which itself can be: (a) the customer's eToro EXW wallet — most common; or (b) an external 3rd-party wallet the customer specified — less common). The customer chooses an amount or a percentage of an open real-crypto position on TP to take into custody. eToro internally:

1. Closes/partial-closes the TP position (TP-side audit: `Fact_CustomerAction` row with `ActionTypeID = 12` Redemption + `Dim_Position` partial close).
2. Reconciles the cost basis (TP-side: `EtoroRedeemStatus` / `EtoroRedeemReason` / `EtoroAmount`).
3. Calls the wallet system to broadcast a `SentTransactions` from eToro's omnibus pool wallet to the customer's destination address.
4. The wallet system performs an `AmlValidations` pre-check on the destination address.
5. If clear, broadcasts on-chain (BitGo or CUG provider).
6. Tracks status until `BlockchainStatus = Confirmed` (or `Failed` / `Cancelled`).

This whole arc is what `EXW_V_RedeemReconciliation` reconciles row-by-row.

## The reconciliation view: `EXW_V_RedeemReconciliation`

UC: `main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation` (51 columns, 1.13M rows lifetime — verified 2026-06-09).

**Twin-prefix structure** — every key field exists in two columns, one per system:

| eToro side (TP / Trade DB) | Wallet side (EXW DB) | Meaning |
|---|---|---|
| `RedeemID` | `WalletRedeemID` | The redeem request ID. Mismatch = orphan. |
| `EtoroRedeemAmount` | `WalletRequestedAmount` | Crypto amount requested. Should match exactly. |
| `EtoroRedeemFee`, `EtoroBlockchainFee` | `WalletSentTXEtoroFees`, `WalletSentTTXBlockchainFees`, `WalletEffectiveBlockchainFees` | Fee components. Effective vs estimated split. |
| `EtoroRedeemStatus`, `EtoroCashoutStatus` | `WalletRedeemStatus` | Lifecycle status on each side. |
| `RequestDate`, `ModificationDate` | (UpdateDate) | Twin timestamps. |
| `EtoroAmountOnRequestUSD`, `EtoroAmountOnCloseUSD` | — | TP-side USD valuation (rate-locked at request vs at close). |
| `WithdrawID`, `FundingID` | `WalletSendingWalletID`, `WalletSentTransactionID`, `WalletBlockchainTransactionID` | Settlement linkages. |
| — | `WalletSenderAddress`, `WalletReceiverAddress` | The on-chain leg. |
| `IsCFD`, `IsGermanBaFin` | — | Regulatory flags (BaFin redeems have special handling). |
| `ManagerID`, `ManagerOpsID`, `EtoroRemark` | — | Operator audit (when an ops user manually intervened). |

Use this view as the **default analytical entry for redemption questions** — it pre-joins both sides. Bronze drill-down only for failures or hash forensics.

## Cardinal rules

1. **MIMO Group owns the operational runbooks** (Confluence-evidence: "Routing Tool - Redeem", "Bypass Backoffice approval flow in Redeem", "Redeem Approval", "Postmortem - DB Permission Issues During Redeem Process Payout Service"). Route process/policy questions there. Data questions stay here.
2. **Twin-prefix mismatches are the QA goldmine.** `EtoroRedeemAmount ≠ WalletRequestedAmount` typically means a request that broke between systems. `EtoroRedeemStatus = 'Cancelled'` while `WalletRedeemStatus = 'Sent'` = a customer-facing inconsistency.
3. **Synapse `EXW_FactRedeemTransactions` is NOT in UC.** UC Target on the wiki = `_Not_Migrated`. Rebuild via the CorrelationId stitch (canonical SQL §2 below).
4. **For confirmed-on-chain only**, the view does NOT filter — it includes the entire lifecycle. To reproduce the analyst-friendly "completed redeems" surface from Synapse `EXW_RedeemReconciliation` (which the wiki notes was filtered to fully-reconciled blockchain-confirmed only), filter `WalletRedeemStatus IN ('Sent','Confirmed')` AND `EtoroRedeemStatus = 'Completed'`.
5. **CFD-redemption is a thing** — the `IsCFD = 1` flag identifies redeems that originated from CFD positions (via the conversion logic — they had to be converted to real crypto first). These are not pure "real-crypto redeems" — surface that distinction in monthly volume reporting.
6. **Cross-link to trading**: a redemption row corresponds to a `Fact_CustomerAction` row with `ActionType = 'Redemption'` (`ActionTypeID = 12`). Joining on `(GCID, RequestDate, EtoroRedeemAmount)` is brittle; prefer joining `RedeemID` if it appears as `Fact_CustomerAction.AdminPositionLogID` or via a downstream view. Cross-link to trading:`Fact_CustomerAction` (see `domain-trading/`) plus `Dim_Position` for the underlying position close.
7. **Cross-link to revenue**: `EtoroRedeemFee` is the customer-charged eToro side fee (a transfer-coin / spread fee type). It surfaces in `etoro_kpi_prep.v_revenue_transfercoinfee`. `EtoroBlockchainFee` is the gas-fee passthrough (or absorbed by eToro for some assets). See `domain-revenue-and-fees/revenue-transactional.md`.

## Canonical SQL patterns

### 1. Monthly redeem volume per asset (the operational dashboard query)

```sql
SELECT
  DATE_TRUNC('MONTH', RequestDate) AS month,
  CryptoName,
  COUNT(*)                              AS redeem_count,
  COUNT(DISTINCT CID)                   AS distinct_customers,
  SUM(EtoroAmountOnRequestUSD)          AS volume_usd_at_request,
  SUM(EtoroAmountOnCloseUSD)            AS volume_usd_at_close,
  SUM(EtoroRedeemFee + EtoroBlockchainFee) AS fee_usd_total
FROM main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation
WHERE WalletRedeemStatus IN ('Sent','Confirmed')
  AND EtoroRedeemStatus = 'Completed'
  AND IsTestAccount = 0
  AND RequestDate >= '2026-01-01'
GROUP BY 1, 2
ORDER BY 1 DESC, volume_usd_at_request DESC;
```

### 2. Manual UC rebuild of `EXW_FactRedeemTransactions` (the Synapse-only fact)

Replicates the Synapse SP's grain (one row per redeem) using the bronze layer + the V view, plus on-chain hash forensics.

```sql
WITH redeem_intent AS (
  SELECT r.RedemptionId AS WalletRedeemID,
         r.SendRequestCorrelationId,
         r.RequestedAmount,
         r.PositionId AS WalletPositionID,
         r.CreatedAt,
         r.UpdatedAt,
         r.RedemptionStatusId
  FROM   main.wallet.bronze_walletdb_wallet_redemptions r
),
sent AS (
  SELECT s.SentTransactionId,
         s.CorrelationId AS SendRequestCorrelationId,
         s.BlockchainTransactionId,
         s.WalletId      AS WalletSendingWalletID,
         s.CreatedAt     AS SentAt
  FROM   main.wallet.bronze_walletdb_wallet_senttransactions s
),
status_latest AS (
  SELECT SentTransactionId, MAX(StatusUpdatedAt) AS LastStatusAt
  FROM   main.wallet.bronze_walletdb_wallet_senttransactionstatuses
  GROUP  BY SentTransactionId
)
SELECT ri.WalletRedeemID,
       ri.WalletPositionID,
       ri.RequestedAmount,
       s.SentTransactionId AS WalletSentTransactionID,
       s.BlockchainTransactionId,
       s.WalletSendingWalletID,
       sl.LastStatusAt
FROM      redeem_intent ri
LEFT JOIN sent             s  ON s.SendRequestCorrelationId = ri.SendRequestCorrelationId
LEFT JOIN status_latest    sl ON sl.SentTransactionId       = s.SentTransactionId;
```

This is the "CorrelationId stitch" pattern referenced in the hub cardinal rule #4.

### 3. Stuck-pending alert (operational use)

```sql
SELECT *
FROM   main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation
WHERE  WalletRedeemStatus = 'Pending'
  AND  EtoroRedeemStatus  = 'Completed'
  AND  RequestDate < CURRENT_DATE - INTERVAL 24 HOURS
  AND  IsTestAccount = 0
ORDER BY RequestDate;
```

This reproduces the "Wallet Redeem QA" alert surface (Confluence-evidenced under DevOps/NOC).

## Provenance

v1 — created 2026-06-09. Verified live:
- ✅ `EXW_V_RedeemReconciliation`: 51 columns (full list pulled via `SHOW COLUMNS`); 1,125,338 rows lifetime.
- Synapse wiki: `knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_FactRedeemTransactions.md` (deprecated fact — UC Target = `_Not_Migrated`); `knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_V_RedeemReconciliation.md` (the live UC view).
- Confluence ownership: 7 MIMO Group pages, 1 DevOps/NOC alert page, 1 Operations Wiki runbook.
