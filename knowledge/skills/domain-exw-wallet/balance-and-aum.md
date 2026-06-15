---
name: domain-exw-wallet
description: |
  EXW (eToro Wallet) balance and AUM sub-skill. The "what is the customer's
  on-chain crypto holding RIGHT NOW" / "what is total EXW AUM as of date X"
  side of the EXW super-domain. The hub at domain-exw-wallet/SKILL.md routes
  here for any question about wallet balances, AUM, currency mix, dust
  profile, or per-customer wallet aggregation.

  This sub-skill owns:
   1. The canonical balance fact: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew (40 columns).
   2. The "valid + non-blocked + not test" filter triplet ג€” the canonical AUM cohort.
   3. The grain definition (Customer ֳ— Wallet ֳ— Crypto ֳ— Day) and dust profile (~80% rows have Balance=0).
   4. The currency-mix shape (BTC ~60%, XRP ~22%, ETH ~12%).
   5. The cross-link into domain-aum-and-aua/SKILL.md as a real numbered AUM line.

  Out of scope here (routed to other sub-skills under the hub):
   - Transaction flow (sent/received/redeemed) ג†’ transactions.md / redemptions.md / on-chain-ledger.md
   - C2F (Cryptoג†’Fiat) conversion flow ג†’ conversions-c2f.md
   - C2P (Cryptoג†’Position) conversion flow ג†’ conversions-c2p.md
   - Daily price and FX ג†’ price-and-fx.md
  --- Original frontmatter description below preserved for reference ---
  EXW (eToro Wallet) ג€” the non-custodial crypto wallet product. EXW lets eToro
  customers withdraw their tradable crypto (BTC/ETH/XRP/etc.) from the trading
  platform into a self-custodied on-chain wallet provisioned by BitGo (97.5% of
  wallets) or CUG (2.5%, MPC-based). It is a separate product surface from the
  custodied trading platform ג€” NOT a CFD / NOT an open position. It IS customer
  assets, so it counts toward AUM/AUA.

  This skill owns:
    1. The canonical EXW balance and AUM source on Unity Catalog:
       `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew`
       (the UC mirror of the Synapse `EXW_FinanceReportsBalancesNew` snapshot
       fact, written by `SP_EXW_FinanceReportsBalancesNew`).
    2. The "valid customer + non-blocked" filter triplet that converts the raw
       fact into the canonical EXW-AUM number: `IsTestAccount = 0 AND
       IsValidCustomer = 1 AND AMLClosureEvent = 0`.
    3. The grain definition (per-Wallet ֳ— per-Crypto ֳ— per-Day) and the row-level
       dust profile (~80% of rows have Balance = 0, ~47% of customers have
       BalanceUSD = 0 ג€” many empty-shell wallets created at activation).
    4. The currency-mix top-line (BTC ~60%, XRP/ETH next).
    5. The cross-link into `domain-aum-and-aua/SKILL.md` ג€” EXW is a real,
       quantifiable, currently-flowing AUM line on the rollup contract.

  EXW is a snapshot fact, NOT a flow fact. Ledger movement (deposits, withdraws,
  on-chain sends/receives, conversions, payments, redemptions) lives separately
  on the `main.wallet.bronze_walletdb_wallet_*` family and is OUT of scope here.
  This skill is balance-only.

  Lineage: the canonical Synapse SP `SP_EXW_FinanceReportsBalancesNew` reads
  from the wallet bronze SCD-2 (`bronze_walletdb_wallet_walletbalances`),
  resolves Walletג†’Customer via `bronze_walletdb_wallet_customerwalletsview`,
  joins daily prices from `gold_sql_dp_prod_we_exw_wallet_exw_pricedaily`, then
  enriches with `Fact_SnapshotCustomer` for regulation/country/club/validity.
  The output table lands in BOTH Synapse (`exw_dbo.EXW_FinanceReportsBalancesNew`)
  AND UC (the `bi_db.gold_sql_dp_prod_we_exw_dbo_*` mirror referenced above).
  The Synapse `EXW_FactBalance` is a separate, older balance fact that is NOT
  migrated to UC ג€” do not use it.

triggers:
  - EXW
  - eToro wallet
  - etoro wallet
  - non-custodial wallet
  - non-custodial crypto
  - non custodial wallet
  - self-custody
  - self custody
  - on-chain wallet
  - on chain wallet
  - BitGo
  - CUG
  - wallet AUM
  - wallet balance
  - crypto wallet AUM
  - crypto wallet balance
  - exw_dbo
  - EXW_FactBalance
  - EXW_FinanceReportsBalancesNew
  - SP_EXW_FinanceReportsBalancesNew
  - withdraw to wallet
  - withdraw crypto
  - C2F
  - crypto-to-fiat

required_tables:
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew
  # Lineage references (out-of-scope for THIS skill, but useful for tracing):
  #   main.wallet.bronze_walletdb_wallet_walletbalances           # SCD-2 raw balances (CDC partition, NOT a snapshot)
  #   main.wallet.bronze_walletdb_wallet_customerwalletsview      # Walletג†’Customer (Gcid) map
  #   main.bi_db.gold_sql_dp_prod_we_exw_wallet_exw_pricedaily    # daily USD price per crypto
  #   main.wallet.bronze_walletdb_wallet_vw_walletbalanaces       # candidate UC view, not used here

intersects_with:
  - domain-aum-and-aua/SKILL.md       # the EXW row on the AUM rollup contract
  - domain-payments/SKILL.md          # MIMO panel (crypto leg lives in payments)
  - domain-customer-and-identity/SKILL.md  # GCID/RealCID identity model
  - cross-cutting/valid-users-filter-contract.md       # IsTestAccount/IsValidCustomer filter pattern
  - cross-cutting/data-latency-and-rollforward.md      # snapshot roll-forward policy

out_of_scope:
  - On-chain sent/received ledger ג†’ `domain-exw-wallet/on-chain-ledger.md`
  - Unified Sent+Received+Conv+Redeem fact analytics ג†’ `domain-exw-wallet/transactions.md`
  - Off-platform redemption (TPג†’wallet) ג†’ `domain-exw-wallet/redemptions.md`
  - Crypto-to-Fiat (walletג†’IBAN) ג†’ `domain-exw-wallet/conversions-c2f.md`
  - Crypto-to-Position (walletג†’TP position) ג†’ `domain-exw-wallet/conversions-c2p.md`
  - Daily price and FX ג†’ `domain-exw-wallet/price-and-fx.md`
  - Crypto trading on TP (CFD or real-crypto positions) ג†’ `domain-trading`
  - Synapse `EXW_FactBalance` (older balance fact, NOT in UC; do not use)

version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-06-09"
---

# EXW (eToro Wallet) ג€” Non-Custodial Crypto Balances

> **Tier 0 ג€” Data-Latency & Roll-Forward Contract.** This is a snapshot fact.
> When the requested date isn't landed yet, follow
> [`../cross-cutting/data-latency-and-rollforward.md`](../cross-cutting/data-latency-and-rollforward.md):
> silent 3-day roll-forward, effective-date shown only when it differs from
> requested. As of 2026-06-09 the latest landed partition is `etr_ymd =
> '2026-06-08'` (T-1). This is a balance, NOT a flow ג€” never silently report 0
> when a fresh snapshot exists upstream.

## Why EXW exists as its own domain

EXW is the **only customer-asset surface that lives on a public blockchain**.
Every other balance in eToro (TP equity, IBAN, Options, Spaceship products,
MoneyFarm) is custodied within the platform's books. EXW assets are not ג€” they
live on BTC / ETH / XRP / SOL / etc. blockchains under wallet IDs provisioned by
BitGo or CUG, with the customer holding the keys (multi-sig or MPC). That makes
EXW analytically distinct:

- The number is reconstructed by **comparing three sources** (eToro internal
  ledger, BitGo provider API, Blox tracker) ג€” `SP_EXW_FinanceReportsBalancesNew`
  picks the "best available" balance per LevelId-based priority.
- Crypto trades on TP that result in real-crypto holdings (`TotalRealCrypto`)
  are still TP equity. **The moment a customer withdraws to their EXW wallet,
  it leaves TP equity and lands here.** This is the C2F (crypto-to-fiat) flow's
  endpoint and the "withdraw to wallet" transition.
- EXW AUM is therefore **additive** to TP equity in the AUM rollup ג€” it is not
  double-counting.

## The canonical fact

**`main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew`**
(45 columns, partitioned on `etr_ymd` STRING `'YYYY-MM-DD'`).

| Property | Value |
|---|---|
| Grain | one row per Customer (`GCID`) ֳ— Wallet (`WalletID`) ֳ— Crypto (`CryptoID`) ֳ— Snapshot day (`BalanceDateID`) |
| Filter for "as-of date" | `etr_ymd = '2026-06-08'` (string `YYYY-MM-DD`) ג€” also equals `BalanceDateID = 20260608` (INT YYYYMMDD) |
| USD column (use this) | `BalanceUSD` (DECIMAL(38,8)) ג€” already pre-converted via `Rate ֳ— Balance`; 0 if `Rate IS NULL` (price unavailable) |
| Native crypto column | `Balance` (DECIMAL(38,18)) |
| Customer keys | `GCID` (global customer ID), `RealCID` (platform customer ID) |
| Wallet keys | `WalletID` (GUID, business key), `CryptoID`, `CryptoName` (e.g. BTC, ETH) |
| Validity flags | `IsTestAccount`, `IsValidCustomer`, `AMLClosureEvent` (see filter below) |
| Customer attributes (denormalised) | `RegulationID` / `Regulation` / `CountryID` / `Country` / `PlayerLevelID` / `Club` / `WalletEntity` |
| Refresh cadence | T-1 daily; partition `etr_ymd` = the snapshot business date |

### "Valid for AUM" filter (canonical)

```sql
WHERE IsTestAccount = 0
  AND IsValidCustomer = 1
  AND AMLClosureEvent = 0
```

Verified breakdown on `etr_ymd = '2026-06-08'`:

| `IsTestAccount` | `IsValidCustomer` | `AMLClosureEvent` | Rows | Sum BalanceUSD |
|---|---|---|---|---|
| 0 | 1 | 0 | 1,610,625 | **$105,126,184** ג† canonical AUM |
| 0 | 1 | 1 | 214,708 | $1,331,213 (AML-blocked but still customer money) |
| 0 | 0 | 0 | 2,435 | $196,400 |
| 0 | 0 | 1 | 2,089 | $43,896 |
| 1 | * | * | 1,215 | $35,833 (test accounts ג€” exclude) |

The "valid + non-blocked" triplet captures **98.5% of total dollar value** while
excluding test accounts, invalid customers, and AML-frozen wallets. This is
what `domain-aum-and-aua` uses on the rollup line.

If you want **gross EXW** (what's on chain regardless of compliance state), use
no filter and reach **$106,733,525** ג€” that includes blocked wallets and a
sliver of test/invalid accounts.

## Canonical SQL ג€” EXW AUM for one date

```sql
-- EXW (eToro non-custodial crypto wallet) AUM as of a given date.
-- Filter: valid + non-blocked + not test (the canonical AUM cohort).
-- Substitute the date string in BOTH places (etr_ymd partition prune + BalanceDateID).

SELECT
  SUM(BalanceUSD)             AS exw_aum_usd,
  COUNT(DISTINCT GCID)        AS distinct_customers,
  COUNT(*)                    AS rows_total,
  COUNT(DISTINCT WalletID)    AS distinct_wallets,
  SUM(CASE WHEN BalanceUSD > 0 THEN 1 ELSE 0 END) AS rows_with_value
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew
WHERE etr_ymd = '2026-06-08'         -- partition prune (string YYYY-MM-DD)
  AND BalanceDateID = 20260608        -- snapshot business date (INT)
  AND IsTestAccount = 0
  AND IsValidCustomer = 1
  AND AMLClosureEvent = 0;
```

Verified output on 2026-06-08:

```
exw_aum_usd          : $105,126,184
distinct_customers   : ~715,000 (cohort within filter)
rows_total           : 1,610,625
rows_with_value      : ~340,000 (~21% of rows have positive USD; rest are dust/empty)
```

## Currency mix (top 10, valid-cohort, 2026-06-08)

| Crypto | Sum USD | Share |
|---|---|---|
| BTC | $63.1M | ~60% |
| XRP | $23.1M | ~22% |
| ETH | $12.9M | ~12% |
| TRX | $1.9M | ~2% |
| XLM | $1.5M | ~1.4% |
| ADA | $0.71M | ~0.7% |
| SOL | $0.36M | ~0.3% |
| DOGE | $0.33M | ~0.3% |
| USDC | $0.33M | ~0.3% |
| LTC | $0.21M | ~0.2% |

EXW is dominated by BTC and XRP ג€” consistent with eToro's customer base.

## Sanity rules (don't screw this up)

1. **`etr_ymd` is a STRING `'YYYY-MM-DD'`, not an INT.** The Spaceship habit of
   `etr_ymd = 20260608` will silently match nothing here. Use `'2026-06-08'`.
2. **`BalanceDateID` is the business snapshot date.** It always equals `etr_ymd`
   reformatted to INT (verified Jun 5, 6, 7, 8: `etr_ymd = 'YYYY-MM-DD'` ג‡”
   `BalanceDateID = YYYYMMDD`). Either one alone is correct; using both
   tightens the partition prune and the read.
3. **80% of rows have `Balance = 0`.** Empty shell wallets created at customer
   activation. Filter `BalanceUSD > 0` to count "wallets with skin in the game",
   but never filter that on the SUM ג€” `SUM(BalanceUSD)` already treats zero
   rows as zero.
4. **`Rate` can be NULL** for cryptos lacking a recent price record. The SP
   then sets `BalanceUSD = 0` (not NULL) by `Balance ֳ— COALESCE(Rate, 0)`. So
   a rare un-priced asset silently disappears from USD AUM. For dust assets
   this is fine; for any new listing audit `WHERE Rate IS NULL AND Balance > 0`.
5. **One customer can have many wallets.** Same `GCID` ֳ— different `WalletID` ֳ—
   different `CryptoID` is normal (one BitGo wallet per crypto per customer).
   Always aggregate to `GCID` for customer-level analysis, never to `WalletID`.
6. **`Reserved` (XRP) is informational, not subtracted from `BalanceUSD`.**
   The 10-XRP minimum reserve to activate an XRP wallet on-chain is reported
   for visibility but `Balance` already includes it. Don't double-deduct.
7. **`ComplianceClosureEvent` is hardcoded to 0.** Per Synapse wiki ג€” schema
   leftover, do NOT use it as a filter.
8. **Don't confuse with `EXW_FactBalance`.** The Synapse `exw_dbo.EXW_FactBalance`
   is an OLDER, separately-built balance fact that was **never migrated to UC**
   (`UC Target: _Not_Migrated`). It is NOT this table. The current canonical
   surface ג€” both in Synapse and in UC ג€” is `EXW_FinanceReportsBalancesNew`.

## Routing ג€” when this skill is the right one

Load this skill when the user asks:

- "What is our EXW AUM?" / "wallet AUM" / "non-custodial crypto AUM"
- "How much do customers hold in their eToro wallets?"
- "Wallet balance for customer X" / "wallet portfolio breakdown"
- Currency mix on EXW / "BTC on wallet" / "ETH withdrawn to wallet"
- BitGo vs CUG wallet split
- AML-frozen wallet value / blocked-wallet asset value

Bounce to other skills when:

| User question | Route to |
|---|---|
| Top-line total AUM (all platforms) | `domain-aum-and-aua/SKILL.md` (this skill provides the EXW row) |
| Real-crypto positions on TP (NOT yet withdrawn) | `domain-trading` (`Fact_AUM.TotalRealCrypto`) |
| Crypto trade events / fills | `domain-trading` |
| Wallet ג†’ wallet transactions, sends, receives | `main.wallet.bronze_walletdb_wallet_senttransactions/_receivedtransactions` (no curated skill yet) |
| C2F (crypto-to-fiat) flow into IBAN | `domain-payments` |
| MIMO panel crypto-leg behaviour | `domain-payments/mimo-panel-and-ddr.md` |

## Provenance

v1 ג€” created 2026-06-09. Built after probing `main.wallet.*` for a UC-curated
EXW balance and finding the SCD-2 bronze (`walletbalances` partitioned on CDC
`etr_ymd`, not snapshot) too expensive to scan on demand. The user pointed to
`main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew` as the
canonical replacement ג€” verified end-to-end:

- ג… Schema: 45 columns, partition keys `etr_y`/`etr_ym`/`etr_ymd` STRING.
- ג… Latest partition: `'2026-06-08'` on 2026-06-09 (T-1 cadence).
- ג… Grain: per-Customer ֳ— per-Wallet ֳ— per-Crypto ֳ— per-Day (1.83M rows on
  the latest partition; 717K distinct GCID).
- ג… Total BalanceUSD on 2026-06-08 = $106,733,525 (raw); $105,126,184 (valid
  + non-blocked + not test).
- ג… Currency mix: BTC ~60% / XRP ~22% / ETH ~12% / long tail.
- ג… Validity-flag triplet (`IsTestAccount=0, IsValidCustomer=1,
  AMLClosureEvent=0`) captures 98.5% of total USD value and is the canonical
  AUM cohort.
- ג… `etr_ymd` is STRING `'YYYY-MM-DD'`, not INT ג€” verified by reading
  `MAX(etr_ymd)` and confirming the `IN ('2026-06-05',ג€¦)` filter shape works
  while `IN ('20260605',ג€¦)` returns 0 rows.
- ג ן¸ The Synapse `EXW_FactBalance` is documented in the Synapse wiki as
  `UC Target: _Not_Migrated`. Do not chase it.
