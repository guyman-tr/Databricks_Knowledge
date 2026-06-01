---
name: domain-revenue-and-fees
description: |
  MIMO-side fees — fees earned on money movement INTO and OUT of customer
  accounts. Covers the four DDR metrics in the MIMO RevenueMetricCategory
  (ID 3): ConversionFee (FX markup on deposit/withdraw currency conversion),
  CashoutFeeExclRedeem (fiat withdrawal fee, excludes crypto redeem),
  TransferCoinFee (crypto transfer fee), CryptoToFiatFee (C2F conversion).
  Plus the underlying raw fee tables — `BI_DB_DepositWithdrawFee` (and
  `_reversals` for refunds / chargebacks) — which carry pre-PIP-calculation
  detail (`ExchangeRate`, `BaseExchangeRate`, `ExchangeFee` basis points,
  `PIPsCalculation`, `MIDValue`, `Depot`, `CardType`, `BinCountry`, IBAN flag).

  Per-action grain for these same fees is ALSO present in
  `de_output_etoro_kpi_fact_customeraction_w_metrics` as separate columns:
  `ConversionFeeDeposit`, `ConversionFeeWithdraw`, `ConversionFeeReversal`
  (their sum = DDR `ConversionFee`), `CashoutFeeExludingRedeem`,
  `TransferCoinFee`. For per-position-context drill-downs route there;
  for raw provider / payment-method / MID-level analysis use the
  DepositWithdrawFee tables.
triggers: [ConversionFee, ConversionFeeDeposit, ConversionFeeWithdraw,
           ConversionFeeReversal, CashoutFeeExclRedeem, CashoutFeeExludingRedeem,
           TransferCoinFee, CryptoToFiatFee, C2F, crypto to fiat,
           ExchangeRate, BaseExchangeRate, ExchangeFee, ExchangeFeePercentage,
           PIPsCalculation, BI_DB_DepositWithdrawFee, depositwithdrawfee,
           depositwithdrawfee_reversals, FX markup, conversion markup,
           cashout fee, transfer coin fee, redeem fee, deposit fee,
           withdraw fee, IsIBANTrade, MID, MIDValue, MIDName, Depot,
           CardType, CardCategory, BinCountry, reversal, refund, chargeback,
           v_revenue_conversionfee, v_revenue_conversionfee_withpositiondata,
           v_revenue_cashoutfee_excluderedeem, v_revenue_cashoutfee_incredeem,
           v_revenue_transfercoinfee, v_revenue_cryptotofiat_c2f]
load_after: [_router.md, domain-revenue-and-fees/SKILL.md]
intersects_with:
  - domain-revenue-and-fees/trading-revenue-and-fees      # ConversionFee triplet ALSO lives in w_metrics
  - domain-payments/SKILL.md                              # the underlying deposit / withdraw VOLUMES (we own the fees only)
  - domain-payments/emoney-and-iban                       # IsIBANTrade flag join
primary_objects:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals
  - main.etoro_kpi_prep.v_revenue_conversionfee
  - main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata
  - main.etoro_kpi_prep.v_revenue_cashoutfee_excluderedeem
  - main.etoro_kpi_prep.v_revenue_cashoutfee_incredeem  # includes Crypto Redeem (for COMPLETENESS questions)
  - main.etoro_kpi_prep.v_revenue_transfercoinfee
  - main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics  # for per-action drill (NAMED columns)
out_of_scope:
  - Trading-platform fees (FullCommission, Rollover, Ticket, Admin, Spot, Dividends, SDRT) → trading-revenue-and-fees.md
  - Customer money VOLUMES (deposits, withdrawals as $$$ flows) → payments super-domain
  - eMoney IBAN account / wallet identity → payments / emoney-and-iban

version: 1
owner: "dataplatform"

required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals
  - main.etoro_kpi_prep.v_revenue_conversionfee
  - main.etoro_kpi_prep.v_revenue_conversionfee_withpositiondata
  - main.etoro_kpi_prep.v_revenue_cashoutfee_excluderedeem
  - main.etoro_kpi_prep.v_revenue_cashoutfee_incredeem
  - main.etoro_kpi_prep.v_revenue_transfercoinfee
  - main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
last_validated_at: "2026-05-10"

---

# H.2 — Deposit / Withdraw / FX fees (MIMO-side)


## When to Use
Load when the question is about MIMO-side fees — conversion fee, FX markup, cashout fee, transfer coin fee, C2F fee — or provider/MID/card-level fee analysis on deposits/withdrawals.

## Scope
In scope: ConversionFee (FX markup on deposit/withdraw), CashoutFeeExclRedeem, TransferCoinFee, CryptoToFiatFee, BI_DB_DepositWithdrawFee raw fee panel, PIPsCalculation, ExchangeRate/BaseExchangeRate markup, MID/Depot/CardType context
Out of scope: Trading-platform fees (FullCommission, Rollover, Tickets) → trading-revenue-and-fees.md; Customer money VOLUMES (deposits/withdrawals as flows) → Payments super-domain; eMoney account identity → domain-payments/eMoney
Last verified: 2026-05-10

This sub-skill owns the four MIMO-category revenue metrics — the fees eToro earns when money moves INTO or OUT OF a customer's account (deposits, withdrawals, crypto transfers, fiat conversions).

## The 4 DDR metrics under MIMO (RevenueMetricCategoryID = 3)

| RevenueMetricID | Metric | What it is | Anchor view |
|-----------------|--------|------------|-------------|
| 10 | `ConversionFee` | FX markup on deposit / withdraw currency conversion vs USD | `etoro_kpi_prep.v_revenue_conversionfee`, `v_revenue_conversionfee_withpositiondata` |
| 8 | `CashoutFeeExclRedeem` | Fee on fiat withdrawals (excludes crypto redeem) | `etoro_kpi_prep.v_revenue_cashoutfee_excluderedeem` |
| 9 | `TransferCoinFee` | Crypto transfer fee (ActionTypeID = 30, IsRedeem = 1) | `etoro_kpi_prep.v_revenue_transfercoinfee` |
| 11 | `CryptoToFiatFee` | Crypto-to-fiat (C2F) conversion fee | `etoro_kpi_prep.v_revenue_cryptotofiat_c2f` |

There is also a fifth atomic view, `v_revenue_cashoutfee_incredeem`, which carries cashout fees INCLUDING crypto redeem — for completeness questions. The DDR metric `CashoutFeeExclRedeem` corresponds to the `_excluderedeem` variant.

## Three places the same fee lives

For ConversionFee in particular, the same fee event is materialised in three different places at three different grains. Pick the grain you need:

| Where | Grain | When to use |
|-------|-------|-------------|
| `BI_DB_DDR_Fact_Revenue_Generating_Actions` (and `vg_ddr_revenue`) | Daily aggregated per `(date × RealCID × metric × instrumentType)` | KPI grand totals, revenue dashboards. `WHERE Metric = 'ConversionFee'`. |
| `etoro_kpi_prep.v_revenue_conversionfee` (and `_withpositiondata` variant) | Per-event with payment / FX context | Per-deposit / per-withdrawal fee analysis with FX detail (rate, base rate, markup). |
| `de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` columns `ConversionFeeDeposit` / `ConversionFeeWithdraw` / `ConversionFeeReversal` | Per-position-action grain (directional split) | When the question needs deposit-side vs withdraw-side conversion-fee split AND/OR when you're already joined to the per-action context (positions, copy flags, FTD flags). |
| `bi_db_depositwithdrawfee` (and `_reversals`) | Per-deposit / per-withdrawal RAW grain | Provider / MID / depot / card-type / BIN-country analysis. The most granular FX markup source. |

**Routing decision**:
- Aggregated totals → DDR fact / `vg_ddr_revenue`.
- "Fee per provider / per MID / per card BIN" → `bi_db_depositwithdrawfee`.
- "ConversionFee split deposit vs withdraw vs reversal" → `fact_customeraction_w_metrics` columns.
- "FX markup analysis with `ExchangeRate - BaseExchangeRate`" → `bi_db_depositwithdrawfee`.

## `bi_db_depositwithdrawfee` — the granular FX-fee panel

This table is the canonical per-deposit / per-withdrawal fee event with full provider context. Notable columns:

### Identity & cash event
| Column | Notes |
|--------|-------|
| `DateID`, `Date`, `Occurred` | Event date / timestamp |
| `CID` | Customer (DWH `RealCID`) |
| `DepositWithdrawID`, `DepositID`, `WithdrawPaymentID` | One of the two will be populated depending on direction |
| `TransactionID` | Synthetic: `<DepositID>D` or `<WithdrawPaymentID>W` |
| `TransactionType` | `Deposit`, `Withdraw`, chargeback / refund / rollback types |
| `TransactionStatus`, `PreviousTransactionStatus` | Lifecycle status |

### FX detail (the headline for this table)
| Column | Notes |
|--------|-------|
| `Amount` | Deposit amount in deposit currency (capped 2025-04-17 to prevent outliers distorting aggregates) |
| `Currency` | Deposit currency code |
| `ExchangeRate` | Rate from deposit currency to USD AT PROCESSING TIME |
| `AmountUSD` | DWH-computed: `Amount × ExchangeRate` |
| `BaseExchangeRate` | Reference rate BEFORE fee markup. **`FX markup = ExchangeRate - BaseExchangeRate`** |
| `ExchangeFee` | Fee in basis-points (provider-specific integer encoding) |
| `ExchangeFeePercentage` | Fee as a % |
| `PIPsCalculation` | **`ABS(PIPsInUSD)`** — the authoritative per-deposit fee in USD AFTER applying direction rules and post-join updates. **Use this for per-deposit fee accuracy** rather than recomputing from `(ExchangeRate - BaseExchangeRate) * Amount`. |

### Provider / payment method context
| Column | Notes |
|--------|-------|
| `PaymentMethod` | `Dim_FundingType.Name` |
| `Depot` | Billing depot |
| `MIDValue`, `MIDName` | Merchant identifier (value + display name) |
| `CardType`, `CardCategory` | Card type + product category (`STANDARD`, `GOLD`, `PLATINUM`, `BUSINESS`) |
| `BinCountry`, `RegCountry`, `RegCountryByIP` | BIN country, registration country, IP country |
| `IsIBANTrade` | 1 when deposit `FlowID = 1` or withdraw `FlowID = 2` — i.e. via the eMoney IBAN funnel |
| `ExternalTransactionID` | Provider transaction id (matches PSP recon) |
| `RegulationID`, `Regulation` | eToro legal entity governing this customer |
| `Club`, `PlayerLevelID`, `PlayerStatus` | Customer attributes at the time of the event |

### `bi_db_depositwithdrawfee_reversals`

Same schema, but rows are REVERSALS — chargebacks, refunds, rollbacks. Amounts are PRE-SIGNED: refunds / chargebacks are negative, chargeback-reversals are positive. There are 8+ reversal types — do NOT filter by string-match on `TransactionType` naively; use the wiki's lookup table.

## Query patterns

### Pattern 1 — Total MIMO-side fees by metric
```sql
SELECT Metric, SUM(Amount) AS revenue
FROM main.etoro_kpi.vg_ddr_revenue
WHERE IncludedInTotalRevenue = 1
  AND RevenueMetricCategoryID = 3   -- MIMO category
  AND DateID BETWEEN 20260101 AND 20260331
GROUP BY Metric
ORDER BY revenue DESC;
```
**Use when:** "What's our deposit / withdraw fee revenue?", "MIMO fee breakdown last quarter."

### Pattern 2 — FX markup per provider (MID)
```sql
SELECT
    MIDName,
    Depot,
    SUM(PIPsCalculation) AS fx_markup_usd,
    SUM(AmountUSD)       AS deposit_volume_usd,
    COUNT(DISTINCT DepositID) AS n_deposits
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
WHERE TransactionType = 'Deposit'
  AND DateID BETWEEN 20260101 AND 20260331
GROUP BY MIDName, Depot
ORDER BY fx_markup_usd DESC
LIMIT 50;
```
**Use when:** "Which provider gives us the best FX margin?", "Fee revenue per PSP."

### Pattern 3 — Conversion-fee split (deposit vs withdraw vs reversal) from w_metrics
```sql
SELECT
    SUM(ConversionFeeDeposit)  AS conv_deposit_usd,
    SUM(ConversionFeeWithdraw) AS conv_withdraw_usd,
    SUM(ConversionFeeReversal) AS conv_reversal_usd,
    SUM(ConversionFeeDeposit + ConversionFeeWithdraw + ConversionFeeReversal) AS conv_total_usd
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE DateID BETWEEN 20260101 AND 20260331;
```
**Use when:** "How is conversion-fee revenue split between deposit-side and withdraw-side?" The sum equals the DDR `ConversionFee` total.

### Pattern 4 — IBAN-funnel conversion fee
```sql
SELECT
    CASE WHEN IsIBANTrade = 1 THEN 'Via IBAN' ELSE 'Card / other' END AS funnel,
    TransactionType,
    SUM(PIPsCalculation) AS fx_markup_usd,
    SUM(AmountUSD)       AS volume_usd
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
WHERE DateID BETWEEN 20260101 AND 20260331
GROUP BY funnel, TransactionType;
```
**Use when:** "FX-fee revenue from eMoney-IBAN deposits vs cards."

### Pattern 5 — Cashout fees by card-product category
```sql
SELECT
    CardCategory,
    BinCountry,
    SUM(PIPsCalculation) AS fee_revenue,
    COUNT(*) AS n_cashouts
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee
WHERE TransactionType IN ('Withdraw', 'Cashout')
  AND DateID BETWEEN 20260101 AND 20260331
  AND CardCategory IS NOT NULL
GROUP BY CardCategory, BinCountry
ORDER BY fee_revenue DESC;
```
**Use when:** "Cashout fee revenue by card type", "Are PLATINUM customers more fee-bearing?"

## Critical Warnings

1. **`bi_db_depositwithdrawfee` `Amount` is capped (2025-04-17 onwards)** via a CASE expression in ETL to prevent extreme outlier values from distorting aggregations. For historical (pre-2025-04-17) analysis the raw `Amount` may be uncapped. `AmountUSD` is `Amount × ExchangeRate` — same cap applies.
2. **Use `PIPsCalculation` for per-deposit fee accuracy.** Do NOT recompute fee as `(ExchangeRate - BaseExchangeRate) * Amount` from this table — there are direction rules, sign rules, and post-join `UPDATE` corrections that `PIPsCalculation` applies. The naive recomputation will be wrong for chargeback / reversal rows.
3. **`bi_db_depositwithdrawfee_reversals` amounts are pre-signed.** Refunds / chargebacks negative; chargeback-reversals positive. Adding the two tables without sign-awareness double-counts.
4. **`ConversionFee` in the DDR fact = sum of `ConversionFeeDeposit + ConversionFeeWithdraw + ConversionFeeReversal`** in `fact_customeraction_w_metrics`. Don't multi-count by reading both sources in the same query.
5. **`v_revenue_cashoutfee_excluderedeem` vs `v_revenue_cashoutfee_incredeem`** — the DDR metric `CashoutFeeExclRedeem` excludes crypto redeem. For a "total cashout fee including crypto redeem" question, use the `_incredeem` variant explicitly — but be aware the DDR `IncludedInTotalRevenue = 1` total uses the EXCLUDED variant.
6. **`TransferCoinFee` filters `ActionTypeID = 30` AND `IsRedeem = 1`** — it is the crypto transfer fee, NOT all of ActionTypeID = 30 (which is also cashout/withdraw on the action audit trail).
7. **`PIPsCalculation` lives on the FEE table, not the MIMO movement table.** Don't confuse with `Fact_Deposit_State.PIPsInUSD` (the production-OLTP source) — they have the same intent but different sign / direction conventions; the fee table version has corrections applied.
8. **`IsIBANTrade` is derived** from `Fact_BillingDeposit.FlowID = 1` (deposit-side IBAN) or `Fact_BillingWithdraw.FlowID = 2` (withdraw-side IBAN). Treat it as authoritative for the IBAN funnel without re-deriving.
9. **`DateID` partition is mandatory** — both `bi_db_depositwithdrawfee` and `_reversals` are billions of rows total over history.
10. **Card-type / BIN country is only populated for card-funded events** — IBAN / SEPA / wire deposits have `CardType / CardCategory / BinCountry = NULL`. Filter accordingly.

## Cluster provenance

- `bi_db_depositwithdrawfee` — Cluster 47 (Finance Recon, outflow).
- `v_revenue_conversionfee` and friends — `etoro_kpi_prep` schema, scattered by their join partners.
- DDR fact MIMO rows — Cluster 13.

## Source of truth

- `bi_db_depositwithdrawfee` is built by the Synapse SP `SP_DepositWithdrawFee` from `Fact_Deposit_State` + `Fact_Cashout_State` + `Dim_Customer` + payment dictionaries.
- The `v_revenue_*` atomic views are defined in `/Users/guyman@etoro.com/a_semantic_etoro_kpi_prep/`.
- `fact_customeraction_w_metrics` columns are maintained by the DE / KPI team.
