---
name: domain-exw-wallet
description: |
  C2F (Crypto-to-Fiat) sub-skill. The off-ramp: customer takes crypto held in
  their EXW wallet, converts it into EUR/USD/GBP, and the converted fiat lands
  on their eToro Money (eMoney) IBAN. C2F is the most operationalised flow in
  EXW — 9 production Tableau dashboards drive off the C2F E2E reconciliation
  fact, with Customer Service, Account Management, and Finance all consuming
  it. C2F is also the SINGLE bridge through which crypto activity becomes
  visible to the MIMO panel.

  This sub-skill owns:
   1. The end-to-end fact: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e (103c, 17,702 rows, healthy daily refresh).
   2. The 5-stage lifecycle (Conversion request → on-chain transfer to eToro pool → conversion execution → eMoney credit → fiat settlement).
   3. The eMoney bridge (eMoneyTransactionID, IsCryptoToFiat=1).
   4. The fee-revenue bridge (TotalFeePercentage, TotalFeeUSD → v_revenue_transfercoinfee).
   5. The 9 production Tableau dashboards as the analyst-facing surface.
   6. Slippage analytics (estimated vs actual rate).

  Out of scope:
   - C2P (subset where converted USD funds a position rather than IBAN) → conversions-c2p.md
   - General crypto activity → transactions.md
   - On-chain ledger detail → on-chain-ledger.md
   - eMoney IBAN account/card mechanics → domain-payments/emoney-accounts-and-cards
   - MIMO panel logic (only IsCryptoToFiat=1 view) → domain-payments/mimo-panel-and-ddr

triggers:
  - C2F
  - c2f
  - crypto to fiat
  - crypto-to-fiat
  - off-ramp
  - off ramp
  - convert crypto to euro
  - convert crypto to USD
  - convert crypto to GBP
  - convert crypto to fiat
  - EXW_C2F_E2E
  - exw_c2f_e2e
  - C2F_E2E
  - eMoneyTransactionID
  - IsCryptoToFiat
  - C2F slippage
  - C2F reconciliation
  - C2USD reconciliation
  - C2F failed
  - C2F alerts
  - eTM C2F Alerts
  - TotalFeePercentage
  - TotalFeeUSD
  - SP_EXW_C2F_E2E
  - bronze_walletconversiondb_c2f

required_tables:
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser
  - main.wallet.bronze_walletdb_wallet_conversions
  - main.wallet.bronze_walletdb_wallet_conversiontransactions
  - main.wallet.bronze_walletdb_wallet_senttransactions
  - main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction

intersects_with:
  - domain-exw-wallet/SKILL.md
  - domain-exw-wallet/conversions-c2p.md
  - domain-exw-wallet/on-chain-ledger.md
  - domain-payments/emoney-accounts-and-cards.md
  - domain-payments/mimo-panel-and-ddr.md
  - domain-revenue-and-fees/SKILL.md

version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-06-09"
---

# C2F — wallet → IBAN fiat (the off-ramp)

> **Tier 0 — Flow fact.** Roll-forward contract does NOT apply.

## What C2F means at eToro

A C2F is a customer-initiated conversion of crypto held in their **EXW wallet** to fiat (EUR/USD/GBP) settled into their **eToro Money (eMoney) IBAN**. It is an off-ramp — the customer is moving value out of crypto and onto a regulated fiat balance. The flow has five distinct stages, each tracked on a different system (and a different `*Date` column on the E2E fact):

```
1. ConversionRequest        — customer presses "Convert" in app.
                              Wallet system creates a Conversion intent
                              (wallet.Conversions row) with CorrelationId.
                              ConversionRequestDate.
2. SentToEtoroPool          — wallet broadcasts on-chain send from customer
                              wallet → eToro's omnibus pool (this happens
                              even though both wallets are eToro-controlled
                              because crypto is non-custodial).
                              → wallet.SentTransactions row.
                              SentToEtoroPoolDate / Confirmed at SentToEtoroPoolBlockchainConfirmedDate.
3. ConversionExecuted        — eToro converts the pooled crypto to fiat at
                              its own desk rate. ConversionExecutedDate /
                              ConversionRate / ConversionFeePercentage / ConversionFeeUSD.
4. eMoneyTransfer            — fiat is sent into the customer's eMoney IBAN
                              account. eMoneyTransactionID joins to
                              eMoney_Dim_Transaction. eMoneyTransferDate.
                              MUST end with IsCryptoToFiat = 1 on that row.
5. FiatSettled               — eMoney completes its internal settlement.
                              eMoneyLastTxStatus = Settled.
```

The E2E fact has columns for **all five stages** of every conversion, plus 5 separate dates so analysts can compute lag at each stage. Verified shape on 2026-06-09:

- 17,702 rows; 7,898 distinct GCIDs lifetime; date range 2022-11-13 → 2026-06-07.
- 86% of rows have an `eMoneyLastTxStatus` populated (the IBAN-side leg is well-attached — only ~14% are mid-flight or failed before reaching eMoney).
- Daily refresh confirmed via `LastModificationDate` ≤ 1 day behind today.

## Why this is the most-operationalised EXW flow

C2F is the canonical bridge through which crypto value converts into a regulated payment surface. That makes it the most monitored, alerted-on, and dashboarded flow:

| Tableau dashboard | Audience | What it shows |
|---|---|---|
| **C2F For CS** | Customer Service | Per-customer C2F status; "where did my conversion go?" tooling. |
| **C2F report for AM's competition** | Account Managers | C2F volume per AM book — sales scorecard. |
| **C2F/C2USD Reconciliation** (×2) | Finance | Daily volume + leg-by-leg recon (wallet vs eMoney legs match?). |
| **C2F Slippage Protection** | Finance / Trading | Estimated vs actual conversion rate — protects against desk-side rate drift. |
| **Crypto to IBAN & Crypto to USD** (×2) | Finance / Product | Volume analytics, currency mix, cohort analysis. |
| **new ddrs monitoring + extract** | DataPlat / Ops | Cross-join with DDR fact family. **Only place C2F crosses the MIMO panel.** |

Operations Wiki (Confluence) page **"eTM Crypto-to-Fiat (C2F) Alerts Review"** plus **"US - Crypto to Fiat"** are the alert and incident runbooks. Owner is ETM (eToro Money) / Finance; alerts surface on the eMoney side rather than the wallet side.

## Cardinal rules

1. **Five dates, five stages — track them all for lag analysis.** A "stuck" C2F means stage X has populated but stage X+1 is null. The most common stuck point is between stage 2 (SentToEtoroPool — on-chain confirmation) and stage 3 (ConversionExecuted — desk hasn't priced it yet).
2. **`eMoneyTransactionID` is the bridge to eMoney.** Join `EXW_C2F_E2E.eMoneyTransactionID = eMoney_Dim_Transaction.TransactionID` to see the IBAN-side history. The matching eMoney row will have `IsCryptoToFiat = 1`.
3. **MIMO panel — only via `IsCryptoToFiat=1`.** This is the **single** place crypto activity surfaces in the MIMO graph. `BI_DB_DDR_Fact_MIMO_Crypto_Platform` does not exist (verified). To answer "how much crypto money flowed in/out via C2F at the MIMO grain", use `BI_DB_DDR_Fact_MIMO_AllPlatforms` filtered on `MIMOPlatform = 'eMoney' AND IsCryptoToFiat = 1`. Pre-conversion crypto inflow to the wallet remains invisible to MIMO.
4. **Fee revenue lives in `domain-revenue-and-fees`, not here.** `TotalFeePercentage`, `TotalFeeUSD`, `ConversionFeeUSD` are the fee components on the C2F fact. They flow into `etoro_kpi_prep.v_revenue_transfercoinfee` (transfer-coin / off-ramp fee category). Don't try to compute revenue from this fact directly — use the canonical fee view.
5. **Slippage = `EstimatedRate - ActualRate`.** The fact carries both an `EstimatedRate` (shown to the customer at quote time) and an `ActualRate` (the rate the desk actually filled at). The dashboard "C2F Slippage Protection" monitors this delta. Larger absolute slippage = either fast-moving market or desk-side issue.
6. **`IsCFD = 1` on a C2F row** means the original position the customer redeemed from was a CFD that had to be converted to real crypto first as part of the redeem flow, then sent to wallet, then converted back to fiat. Rare path — surface separately in lifecycle reporting.
7. **All-time roll vs trailing window — be deliberate.** The fact has 17,702 rows across 4 years. Yearly trends benefit from `DATE_TRUNC('YEAR', ConversionRequestDate)`; live ops monitoring filters last 30/90 days.

## Canonical SQL patterns

### 1. Daily C2F volume + funnel-stage drop-off (the recon-dashboard query)

```sql
SELECT
  CAST(ConversionRequestDate AS DATE)   AS request_dt,
  COUNT(*)                              AS requests,
  SUM(CASE WHEN SentToEtoroPoolDate           IS NOT NULL THEN 1 ELSE 0 END) AS reached_stage2,
  SUM(CASE WHEN ConversionExecutedDate         IS NOT NULL THEN 1 ELSE 0 END) AS reached_stage3,
  SUM(CASE WHEN eMoneyTransferDate             IS NOT NULL THEN 1 ELSE 0 END) AS reached_stage4,
  SUM(CASE WHEN eMoneyLastTxStatus = 'Settled' THEN 1 ELSE 0 END)              AS fully_settled,
  SUM(ConvertedAmountUSD)               AS volume_usd,
  SUM(ConversionFeeUSD)                  AS fee_usd
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
WHERE ConversionRequestDate >= CURRENT_DATE - INTERVAL 30 DAYS
  AND IsTestAccount = 0
GROUP BY 1
ORDER BY 1 DESC;
```

### 2. C2F slippage analytics

```sql
SELECT
  DATE_TRUNC('DAY', ConversionExecutedDate) AS execution_dt,
  CryptoSymbol,
  COUNT(*)                                   AS conversions,
  AVG(EstimatedRate - ActualRate)            AS avg_slippage_abs,
  AVG((EstimatedRate - ActualRate) / NULLIF(EstimatedRate, 0)) AS avg_slippage_pct,
  SUM(ConvertedAmountUSD)                    AS volume_usd
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
WHERE ConversionExecutedDate IS NOT NULL
  AND ConversionExecutedDate >= CURRENT_DATE - INTERVAL 90 DAYS
GROUP BY 1, 2;
```

### 3. eMoney bridge — verify the C2F → IBAN linkage

```sql
SELECT
  c.GCID,
  c.ConversionRequestDate,
  c.ConvertedAmountUSD,
  c.eMoneyTransactionID,
  e.IsCryptoToFiat,
  e.Amount AS emoney_amount,
  e.Currency,
  e.TransactionDate
FROM      main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e         c
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction e
       ON e.TransactionID = c.eMoneyTransactionID
WHERE c.ConversionRequestDate >= CURRENT_DATE - INTERVAL 7 DAYS;
```

### 4. Stuck-conversion alert (operational)

```sql
SELECT *
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
WHERE ConversionRequestDate < CURRENT_DATE - INTERVAL 24 HOURS
  AND eMoneyLastTxStatus IS NULL
  AND IsTestAccount = 0
ORDER BY ConversionRequestDate;
```

## Provenance

v1 — created 2026-06-09. Verified live:
- ✅ 103 columns; 17,702 rows; 7,898 distinct GCIDs; date range 2022-11-13 → 2026-06-07.
- ✅ 86% of rows have populated `eMoneyLastTxStatus` (15,277 / 17,702).
- Synapse wiki: `knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_C2F_E2E.md` (the column-level guide; 9-Tableau-dashboard reference).
- Tableau verification: 9 dashboards confirmed via `knowledge/tableau/_index/custom_sql_inventory.csv`.
- Confluence runbooks: "eTM Crypto-to-Fiat (C2F) Alerts Review" (Operations Wiki), "US - Crypto to Fiat" (Operations Wiki).
