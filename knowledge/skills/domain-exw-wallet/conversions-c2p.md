---
name: domain-exw-wallet
description: |
  C2P (Crypto-to-Position) sub-skill. A late-2025 product that lets a customer
  use the value of their EXW wallet crypto to fund a NEW open trading position
  on the trading platform, instead of converting to fiat IBAN. Mechanically
  C2P shares the conversion path with C2F (wallet → eToro pool → desk
  conversion) but the SINK is a new TP position rather than the eMoney IBAN.
  Launched 2025-12-11; 5,978 rows / 2,432 distinct GCIDs as of 2026-06-07.

  This sub-skill owns:
   1. The end-to-end fact: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e (90c, 5,978 rows).
   2. The TP-side bridge: PositionID + the IsAirDrop=1 / CompensationReasonID=134 marker on Fact_CustomerAction.
   3. How C2P differs from C2F and when each applies.

  Out of scope:
   - C2F (wallet → IBAN) → conversions-c2f.md
   - General crypto activity → transactions.md
   - Position lifecycle on TP → domain-trading
   - AdminPositionLog / AdminCompensation reason codes outside this flow → domain-trading

triggers:
  - C2P
  - c2p
  - crypto to position
  - crypto-to-position
  - convert crypto to position
  - convert to TP position
  - EXW_C2P_E2E
  - exw_c2p_e2e
  - C2P_E2E
  - IsAirDrop
  - CompensationReasonID 134
  - AdminPositionLog Crypto Transfer
  - SP_EXW_C2P_E2E
  - bronze_walletconversiondb_c2p

required_tables:
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position

intersects_with:
  - domain-exw-wallet/SKILL.md
  - domain-exw-wallet/conversions-c2f.md
  - domain-trading/SKILL.md

version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-06-09"
---

# C2P — wallet → TP open position

> **Tier 0 — Flow fact.** Roll-forward contract does NOT apply.

## What C2P means at eToro

C2P (Crypto-to-Position) is the newer cousin of C2F. Same mechanical pipe up to the conversion stage; different sink:

```
C2F: customer wallet crypto → eToro omnibus pool → desk conversion → eMoney IBAN
C2P: customer wallet crypto → eToro omnibus pool → desk conversion → NEW open position on TP
```

Launched **2025-12-11** (verified — first material activity in `EXW_C2P_E2E` is 2025-12-08, ramp starts 2025-12-11). Only 5,978 lifetime rows as of 2026-06-07 (vs C2F's 17,702) — still a small product, but live and growing.

The reason C2P exists at all: with C2F, the customer's crypto value briefly leaves the trading-platform world (lands on IBAN, can sit there) before re-entering as a position. C2P collapses that — the converted USD never sees IBAN; it goes directly into a fresh `Dim_Position` open. From a customer perspective it's "use my wallet to open a trade".

## The TP-side bridge: AdminPositionLog + IsAirDrop=1

When C2P opens a position, it is recorded as a **system-driven action** on the trading-platform audit trail (NOT a normal `Action` of customer-deposit-then-trade-then-open). The marker:

| Column on `Fact_CustomerAction` | Value | Meaning |
|---|---|---|
| `IsAirDrop` | `1` | The position was opened via a non-cash funding event (the legacy flag — predates C2P; also used for true airdrops, MIMO compensation, tax adjustments). |
| `CompensationReasonID` | `134` | Distinguishes "C2P-funded position" from other airdrop-style events. (Verify against `Dim_CompensationReason` — see `domain-trading/`.) |
| `AdminPositionLog.LogType` | `'Crypto Transfer'` | The internal log type for the operator-side audit (also used for TP↔TP rebalances). |

Joining `EXW_C2P_E2E.PositionID = Dim_Position.PositionID` is the canonical bridge. From there you reach the position lifecycle (open → close → P&L) on the trading side.

## C2F vs C2P — when does each apply

| Aspect | C2F | C2P |
|---|---|---|
| Sink | eMoney IBAN | TP open position |
| `IsCryptoToFiat` on eMoney leg | `1` | N/A (no eMoney leg) |
| Visible to MIMO panel? | YES (post-conversion as eMoney row) | NO (position open is not a MIMO event) |
| Fee revenue surface | `v_revenue_transfercoinfee` (transfer-coin fee) | Standard trading commission on the new position (no special transfer fee) |
| Stuck-state risk | Multi-stage (wallet → pool → desk → eMoney → settle) | Shorter (wallet → pool → desk → position open) |
| Customer intent | "I want fiat in my IBAN" | "I want a fresh trading position funded by my wallet" |
| Launched | Long-standing | 2025-12-11 |

## Cardinal rules

1. **C2P is invisible to MIMO.** Unlike C2F (which emerges as `IsCryptoToFiat=1` on the eMoney leg), a C2P never produces an eMoney row. From the MIMO panel's perspective, a C2P-funded position appears spontaneously without any deposit.
2. **The position does not contribute to a deposit count.** It will appear in the customer's TP `Dim_Position` and contribute to AUM/PnL, but does not count as an `IsFTD` candidate or trigger the registration-to-FTD funnel. Surface this in funnel/cohort reporting.
3. **C2P doesn't cannibalise C2F volume — yet.** C2P has 2,432 distinct GCIDs vs C2F's 7,898 lifetime; volume is small. Don't assume C2P will eat C2F until product/data confirms.
4. **The 90-column structure mirrors C2F.** Most columns parallel `EXW_C2F_E2E`. The ones that differ: C2P substitutes the eMoney-side leg (the `eMoney*` columns from C2F) with TP-side columns (`PositionID`, `InstrumentID`, `OpenAmountUSD`, `Leverage`, `IsBuy`).

## Canonical SQL patterns

### 1. Daily C2P volume (the launch-monitoring query)

```sql
SELECT
  CAST(ConversionRequestDate AS DATE) AS request_dt,
  COUNT(*)                            AS requests,
  COUNT(DISTINCT GCID)                AS distinct_users,
  SUM(ConvertedAmountUSD)             AS volume_usd,
  AVG(Leverage)                       AS avg_leverage
FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e
WHERE IsTestAccount = 0
  AND ConversionRequestDate >= '2025-12-01'
GROUP BY 1
ORDER BY 1;
```

### 2. C2P → Dim_Position bridge (verify positions opened correctly)

```sql
SELECT
  c.GCID,
  c.ConversionRequestDate,
  c.ConvertedAmountUSD,
  c.PositionID,
  p.OpenDate,
  p.Amount AS position_amount,
  p.IsBuy,
  p.Leverage,
  p.CloseDate
FROM      main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e         c
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position           p
       ON p.PositionID = c.PositionID
WHERE c.ConversionRequestDate >= CURRENT_DATE - INTERVAL 30 DAYS;
```

### 3. C2P-funded position vs same-customer C2F volume (cannibalization check)

```sql
WITH c2f AS (
  SELECT GCID, SUM(ConvertedAmountUSD) AS c2f_usd, COUNT(*) AS c2f_count
  FROM   main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e
  WHERE  ConversionRequestDate >= '2025-12-01' AND IsTestAccount = 0
  GROUP  BY GCID
), c2p AS (
  SELECT GCID, SUM(ConvertedAmountUSD) AS c2p_usd, COUNT(*) AS c2p_count
  FROM   main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e
  WHERE  ConversionRequestDate >= '2025-12-01' AND IsTestAccount = 0
  GROUP  BY GCID
)
SELECT COALESCE(c2f.GCID, c2p.GCID) AS GCID,
       c2f_usd, c2f_count, c2p_usd, c2p_count
FROM   c2f FULL OUTER JOIN c2p USING (GCID)
ORDER  BY COALESCE(c2p_usd, 0) DESC;
```

## Provenance

v1 — created 2026-06-09. Verified live:
- ✅ 90 columns; 5,978 rows; 2,432 distinct GCIDs; date range 2025-12-08 → 2026-06-07.
- ✅ Confirmed 2025-12-11 launch (first material activity 3 days into the date range).
- Synapse wiki: `knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_C2P_E2E.md`.
