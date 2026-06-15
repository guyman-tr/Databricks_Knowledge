---
name: domain-exw-wallet
description: |
  EXW pricing and FX sub-skill. The USD-normalisation backbone for every other
  EXW sub-skill. EXW_PriceDaily provides one row per (CryptoID × Date) at the
  daily grain — 422K lifetime rows across 175 distinct assets, fresh through
  T-1. Used by EXW_FactTransactions, EXW_FinanceReportsBalancesNew, and the
  E2E facts to convert native crypto amounts into USD for analytics.

  Owns:
   1. EXW_PriceDaily — daily mark price (10c, 422K rows, T-1 fresh).
   2. The 175-asset coverage and how to handle missing prices.
   3. Pricing-source caveat: AvgPrice is eToro's mark, NOT a CoinMarketCap public reference.

  Out of scope:
   - Position-side pricing on TP (PriceRate / Dim_Instrument) → domain-trading
   - Real-time tick prices (this is a daily roll, not a tick feed)
   - Hourly intra-day pricing if a separate EXW_Price hourly fact is needed (not in current UC scope)

triggers:
  - EXW_PriceDaily
  - exw_pricedaily
  - EXW Price
  - exw_price
  - crypto price USD
  - crypto USD valuation
  - daily crypto price
  - AvgPrice
  - mark price
  - USD normalisation
  - USD normalization
  - crypto FX
  - price USD value of BTC

required_tables:
  - main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily
  - main.wallet.bronze_walletdb_wallet_cryptotypes

intersects_with:
  - domain-exw-wallet/SKILL.md
  - domain-exw-wallet/transactions.md
  - domain-exw-wallet/balance-and-aum.md

version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-06-09"
---

# Pricing and FX

> **Tier 0 — Snapshot fact** (one mark per asset per day). The
> [`../cross-cutting/data-latency-and-rollforward.md`](../cross-cutting/data-latency-and-rollforward.md)
> contract DOES apply: if today's mark is missing for an asset, silently
> roll forward to the most recent populated value within a 3-day window
> and disclose if `effective_date != requested_date`.

## What this is

`EXW_PriceDaily` is the per-asset daily mark price used to convert native crypto amounts into USD across the EXW super-domain. Verified shape on 2026-06-09:

| Property | Value |
|---|---|
| UC location | `main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily` |
| Columns | 10 |
| Lifetime rows | 422,171 |
| Date range | 2018-04-23 → 2026-06-08 (covers full EXW lifetime) |
| Distinct `CryptoID` | 175 |
| Avg coverage | ~145 of 175 assets per recent day (some are listed but not actively priced) |
| Refresh | Daily, T-1 |

Schema:

| Column | Use |
|---|---|
| `CryptoID` | Internal crypto ID (joins to `CryptoTypes.CryptoID`). |
| `CryptoName` | Display name (BTC, ETH, USDT, ...). |
| `AvgPrice` | The mark in USD. **eToro internal mark, not a public reference.** |
| `BlockchainCryptoId` / `BlockchainCryptoName` | The chain on which the asset lives (relevant for ERC-20 tokens — see `on-chain-ledger.md` rule #5). |
| `InstrumentID`, `eToroInstrumentID` | Bridge into TP-side instrument catalog (see `domain-trading/instrument-catalogue`). |
| `FullDate`, `FullDateID` | Snapshot date (the partition key — STRING DATE / INT YYYYMMDD). |
| `UpdateDate` | Last-refresh stamp. |

## Cardinal rules

1. **`AvgPrice` is eToro's mark — not a public reference.** Don't compare it head-to-head with a CoinMarketCap or CoinGecko snapshot and call any delta a "discrepancy" without context. The mark is the rate eToro used for that day's analytics; small deviations from public refs are normal.
2. **Use `FullDate` (STRING DATE) for filtering** — the partition key. The integer alternative `FullDateID` (YYYYMMDD) works for joins to DDR-style integer date dimensions.
3. **Coverage is incomplete on a per-day basis.** ~145 of 175 known assets price on a typical recent day; the missing ones are usually delisted or thinly-traded. For a missing asset, silently roll back up to 3 days per the cross-cutting contract; if still missing, fall back to `EXW_FactTransactions.AmountUSD` (which uses its own SP-side mark) for that specific transaction.
4. **For ERC-20 tokens, price is ON THE TOKEN ID, not on the chain ID.** Pricing USDT-on-ETH means joining `EXW_PriceDaily.CryptoID = CryptoTypes.CryptoID` for USDT — `BlockchainCryptoId` only tells you which chain. Don't accidentally price the chain instead of the token.
5. **Daily, not hourly.** This is the only EXW pricing surface in current UC scope. If a question requires intra-day FX (e.g. "value at the moment of conversion"), the in-place rate already exists on the relevant E2E fact (`EXW_C2F_E2E.ActualRate`, `EXW_C2P_E2E.ActualRate`); use that, don't try to interpolate from `EXW_PriceDaily`.

## Canonical SQL patterns

### 1. Today's prices for the top assets (sanity check)

```sql
SELECT CryptoName, AvgPrice, FullDate, UpdateDate
FROM   main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily
WHERE  FullDate = (SELECT MAX(FullDate) FROM main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily)
  AND  CryptoName IN ('BTC','ETH','XRP','SOL','USDT','USDC')
ORDER  BY AvgPrice DESC;
```

### 2. Roll-forward pattern (per the cross-cutting contract)

```sql
WITH requested AS (
  SELECT :requested_dt AS dt
), latest_for_asset AS (
  SELECT  p.CryptoID,
          p.CryptoName,
          p.AvgPrice,
          p.FullDate AS effective_dt
  FROM    main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily p
  WHERE   p.FullDate <= (SELECT dt FROM requested)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY p.CryptoID ORDER BY p.FullDate DESC) = 1
)
SELECT l.*,
       (SELECT dt FROM requested)         AS requested_dt,
       l.effective_dt = (SELECT dt FROM requested) AS is_exact_match
FROM   latest_for_asset l;
```

### 3. Native amount → USD conversion (the most-common use)

```sql
SELECT
  ft.GCID,
  ft.CryptoSymbol,
  ft.Amount                 AS native_amount,
  p.AvgPrice                 AS mark_usd,
  ft.Amount * p.AvgPrice    AS reconstructed_amount_usd,
  ft.AmountUSD              AS sp_side_amount_usd  -- for cross-check vs the SP's mark
FROM      main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions ft
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily     p
       ON p.CryptoID = ft.CryptoID
      AND p.FullDate = CAST(ft.TranDate AS DATE)
WHERE ft.TranDate >= CURRENT_DATE - INTERVAL 7 DAYS;
-- reconstructed vs sp_side delta should be small.
```

## Provenance

v1 — created 2026-06-09. Verified live:
- ✅ 10 columns; 422,171 rows; date range 2018-04-23 → 2026-06-08; 175 distinct assets.
- The earlier "1 row/day" claim from notes was a misread — the table is per-(asset × day), so ~145 rows/day on recent dates.
- Synapse wiki: `knowledge/synapse/Wiki/EXW_Wallet/Tables/EXW_PriceDaily.md`.
