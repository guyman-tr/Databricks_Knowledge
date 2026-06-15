# Spaceship view gaps — investigation & fix proposal (2026-06-11)

## TL;DR

1. **The DDR does NOT consume Spaceship at all.**
   - `BI_DB_DDR_Fact_AUM` has no Spaceship column (only TP / IBAN / Options).
   - `BI_DB_DDR_Fact_MIMO_AllPlatforms` carries only 4 `MIMOPlatform` values: `TradingPlatform`, `eMoney`, `Options`, `MoneyFarm`.
   - There is no `BI_DB_DDR_Fact_*_Spaceship_*` family. Anything labelled "Spaceship in the DDR" is either a downstream report joining the Spaceship prep views into a DDR query, or the `bizops_output_spaceship_gold_daily_update` snapshot — which is a single-row-per-GCID stale table (last UpdateDate 2025-11-18, balance columns all NULL).
   - **So "the DDR makes up for the missing day with max-date selection" is happening in dashboard / Tableau / Genie queries, not in the DDR SPs themselves.** That's the right place to look for the workaround pattern, but the durable fix belongs in the prep views.

2. **The `v_spaceship_aum` view has a real, week-bounded fill-forward bug.** It is the root cause of the "$1B Super drops to $0" symptom. The view's existing weekend fill-forward only fills **Sat/Sun from Friday**, with the candidate-Friday picked per `(user_id, WEEK)` partition. If the *Friday itself* is missing or zero, the fill picks the Friday's own zero row and the gap propagates unfilled into Sat + Sun + Mon. It also does not fill *mid-week* missing days at all.

3. **The Spaceship source feed is genuinely sporadic.** This is not a Mon-Fri / Sat-Sun thing anymore. Verified Super zero-row days in the last 10 weeks: Apr 3 (Fri), Apr 10 (Fri, Super only — Voyager fine), Apr 27 (Mon), May 20 (Wed), May 29 (Fri), Jun 1 (Mon), Jun 8 (Mon), Jun 10 (Wed). Plus Voyager zero on Jun 9 (Tue) and Jun 10 (Wed). These are not weekend artifacts — they're real source-system gaps from the daily BigQuery overwrite landing nothing for that product on that day.

4. **Recommended fix: replace the existing weekend-only fill with a per-`(user_id, product)` last-good-value carry-forward bounded by a configurable lookback (default 7 days).** Independent per product. Add a `source_date` / `is_filled` pair of columns so consumers can tell whether they're looking at the day's own snapshot or a carried-forward value. Apply the same pattern to `v_spaceship_fees`'s Voyager-mgmt balance lookup (currently has the same bug, just hidden inside a `CASE`).

5. **Do NOT roll forward `v_spaceship_mimo`.** Per the cross-cutting roll-forward contract, flow facts (deposits, withdrawals, fees) must not roll forward — T-0 absence is a real signal. MIMO is fine as-is; today is a partial day, that's correct.

---

## Evidence

### Spaceship AUM — last 10 weeks, per-day per-product (AUD millions)

Verified live 2026-06-11 against `main.etoro_kpi.v_spaceship_aum`:

| Date | Day | Super | Voyager | Nova | Row count | Notes |
|---|---|---|---|---|---|---|
| 2026-04-03 | Fri | **0.0** | **0.0** | 56.9 | 19,449 | Friday source-gap — fill-forward CANNOT cover Sat/Sun because it picks this row as the latest weekday |
| 2026-04-04 | Sat | 1053.5 | 626.5 | 56.9 | 389,863 | Picked up Thu's value via QUALIFY tie-break (lucky) |
| 2026-04-05 | Sun | 1053.5 | 626.5 | 56.9 | 389,866 | Same |
| 2026-04-06 | Mon | **0.0** | **0.0** | 56.9 | 19,469 | Source gap, not filled |
| 2026-04-10 | Fri | **0.0** | 632.6 | 57.5 | 376,943 | Super-only Friday gap |
| 2026-04-27 | Mon | **0.0** | **0.0** | 62.4 | 19,714 | Mid-week gap |
| 2026-05-20 | Wed | **0.0** | 692.3 | 67.0 | 377,977 | Mid-week Super-only |
| 2026-05-29 | Fri | **0.0** | 727.7 | 69.2 | 378,164 | Friday Super-only — same week-boundary trap |
| 2026-06-01 | Mon | **0.0** | 743.9 | 70.1 | 378,253 | Mid-week Super-only |
| 2026-06-08 | Mon | **0.0** | **0.0** | 68.2 | 20,247 | Both products, mid-week |
| 2026-06-09 | Tue | 1155.1 | **0.0** | 68.2 | 40,793 | Voyager-only gap |
| 2026-06-10 | Wed | **0.0** | **0.0** | 69.5 | 20,285 | Both products, mid-week |

A "good" day shows ~393K rows. A "zero Super" day shows ~378K rows (Super contributes ~15K rows). A "zero both" day shows ~20K rows (only Nova).

**Row-count drops confirm these are upstream source-gap days, not view-layer bugs in aggregation. The view-layer bug is that the fill-forward doesn't compensate.**

### How the existing fill-forward works (and why it fails)

From `v_spaceship_aum` DDL (Super CTE, Voyager is identical):

```sql
super_last_weekday AS (
  SELECT date, user_id, balance_aud,
    NEXT_DAY(date, 'SA')              AS fill_sat,
    DATE_ADD(NEXT_DAY(date, 'SA'), 1) AS fill_sun
  FROM (
    SELECT date, user_id, balance_aud,
      ROW_NUMBER() OVER (
        PARTITION BY user_id, DATE_TRUNC('week', date)
        ORDER BY date DESC
      ) AS rn
    FROM super_bal_raw
    WHERE DAYOFWEEK(date) BETWEEN 2 AND 6  -- Mon..Fri only
  ) WHERE rn = 1
)
```

Failure modes:

| # | Failure | Why |
|---|---|---|
| F1 | Mon..Thu source-gap | Filter `WHERE DAYOFWEEK BETWEEN 2..6` includes the zero-row weekday in `super_bal_raw`, but raw output already has that gap. Fill-forward only emits rows for `fill_sat` and `fill_sun` — no rows ever fill Mon..Thu. |
| F2 | Friday source-gap | `PARTITION BY user_id, DATE_TRUNC('week', date)` is week-bounded. If Friday is zero, that week's Mon..Thu rows are candidates BUT `super_bal_raw` only contains source rows (no synthesised carry-forward), so for users whose only entry that week is the zero Friday, the `rn=1` row is the zero Friday — Sat/Sun get filled with 0. |
| F3 | Week with NO source rows at all | Some users have no row for any day in a week → no fill emitted at all → user disappears from AUM that week. |
| F4 | Source publishes zero rows (not just zero values) | Confirmed by row-count drops (393K → 19K). When the source emits no row at all for a user-day, the join produces nothing. The view should synthesise a carry-forward row, but it doesn't. |

F1 / F2 / F3 / F4 together explain every gap in the table above.

### v_spaceship_fees has the same bug

The Voyager-mgmt CTE uses an identical weekend-only fill expression for the balance lookup:

```sql
pb.effective_date = CASE
  WHEN DAYOFWEEK(fee_date) = 1 THEN DATE_ADD(fee_date, -2)  -- Sun → Fri
  WHEN DAYOFWEEK(fee_date) = 7 THEN DATE_ADD(fee_date, -1)  -- Sat → Fri
  ELSE fee_date END
```

When `fee_date` is a Mon..Thu with a zero-row balance gap, this resolves to the (zero) same-day balance row, and the fee pro-rata denominator collapses → the entire day's Voyager-mgmt fee allocation can be wrong or dropped. Evidence in the fees query: Voyager (mgmt) is present on 2026-06-07 (Sun) and 2026-06-10 (Wed) but the fee amount stays flat at ~9337 AUD across Jun 6 / 7 / 10 even though the balance source had gaps — meaning the existing partition fix prevented division blow-up, but the underlying balance lookup is still wrong for any user whose Friday balance row was missing or zero.

### Where the DDR isn't compensating

Verified live:

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
  → no SpaceShipTotalEquity / SpaceShip* column at all (43 columns total)

main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
  → DISTINCT MIMOPlatform = {MoneyFarm, Options, TradingPlatform, eMoney}
  → no 'Spaceship' rows for DateID >= 20260601

main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
  → 0 columns matching %spaceship%, %sps%, %super%, %voyager%, %nova%

main.bizops_output.bizops_output_spaceship_gold_daily_update
  → last UpdateDate = 2025-11-18 (7 months stale), all balance columns NULL
  → not a current source
```

So the user's recollection of "in the DDR we make up for that by selecting the max date" is most likely **dashboard-side / Tableau-side / Genie-side max-date logic on top of the prep views**, not anything in the DDR SP code. That works for snapshot-style report cells ("latest AUM"), but it does NOT work when the report wants a time-series chart — which is exactly the case where "$1B Super drops to $0" becomes visible.

---

## Recommended fix

### Option A — Patch `v_spaceship_aum` in place (preferred, smallest blast radius)

Replace the weekend-only Super / Voyager fill-forward CTEs with a per-product **last-good-value carry-forward** bounded by a configurable lookback (default 7 days), independent per product, plus a `source_date` column so consumers can see when the carry started.

Pseudocode (apply to Super; same shape for Voyager):

```sql
super_dates AS (
  -- spine of every (user_id, date) we want to emit
  SELECT DISTINCT user_id, d.date
  FROM (SELECT DISTINCT user_id FROM super_bal_raw_nonzero) u
  CROSS JOIN (
    SELECT explode(sequence(MIN(date), MAX(date), INTERVAL 1 DAY)) AS date
    FROM super_bal_raw_nonzero
  ) d
),
super_bal_raw_nonzero AS (
  SELECT date, user_id, balance_aud
  FROM super_bal_raw
  WHERE balance_aud > 0   -- treat zero-row days as missing
),
super_bal_filled AS (
  SELECT
    s.date,
    s.user_id,
    LAST_VALUE(r.balance_aud, true) OVER (
      PARTITION BY s.user_id ORDER BY s.date
      ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
    ) AS balance_aud,
    LAST_VALUE(r.date, true) OVER (
      PARTITION BY s.user_id ORDER BY s.date
      ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
    ) AS source_date
  FROM super_dates s
  LEFT JOIN super_bal_raw_nonzero r USING (user_id, date)
)
SELECT date, user_id, balance_aud,
       (source_date <> date) AS is_filled,
       source_date
FROM super_bal_filled
WHERE balance_aud IS NOT NULL
```

Key properties:
- Carry-forward is per-user, per-product, independent of any week boundary.
- 7-day bound matches the cross-cutting roll-forward contract's escalation window. If a user has been silent for >7 days, treat them as "gone for now" — don't carry their balance indefinitely.
- `is_filled` / `source_date` make staleness visible to consumers and let the dashboard footer say "as of 2026-06-09 — source-system gap" automatically.
- Nova stays unchanged (7-day source, no gaps observed).
- Money still excluded (existing v2 plan).

Apply the same `is_filled` / `source_date` columns to the final `SELECT`, exposing two booleans `is_super_filled` / `is_voyager_filled` and two dates `super_source_date` / `voyager_source_date`. That's additive — no breaking changes to existing consumers.

### Option B — Create `v_spaceship_aum_filled` alongside the existing view

If patching the canonical view is risky (downstream consumers may rely on exact zeros to detect "missing"), create a sibling view `main.etoro_kpi.v_spaceship_aum_filled` with the same column shape PLUS the four new columns above. Migrate dashboards over view-by-view, then deprecate. This is the lower-risk path if the dashboard team has hard-coded "WHERE super_balance_aud > 0" to mask the gaps.

### Option C — Fix downstream queries only

Push the roll-forward into the dashboard / Genie queries (the cross-cutting contract's canonical pattern: `MAX(DateID) WHERE column > 0` within a 3-day window, with 7-day escalation). This is the lightest-touch fix and exactly what the user described as the existing DDR-side workaround. The downside is that every consumer has to do this independently and most won't, so the "$1B → $0" bug will keep showing up.

**Recommended**: B + C in parallel. Ship `v_spaceship_aum_filled` first, then migrate dashboards onto it, then alias the old view to the new one with `is_filled` defaulting to false for backward compatibility.

### Also fix v_spaceship_fees Voyager-mgmt balance lookup

Replace the existing Sat/Sun-only `CASE` with a join onto the new filled balance, partitioned by fee date (the existing fix). The window-partition-by-fee-date fix from 2026-04-13 stays; only the balance source becomes the filled view.

---

## What to NOT touch

- `v_spaceship_mimo` — no roll-forward. Flow fact. T-0 partial is correct.
- Nova balance — already 7-day, no gaps.
- The DDR SPs (`SP_DDR_Fact_AUM`, `SP_DDR_Fact_MIMO_AllPlatforms`) — they don't touch Spaceship today. Adding Spaceship to the DDR is a separate, larger scope (cross-platform AUM rollup contract) and would need Finance / FP&A sign-off.

---

## Open questions for the Spaceship engineer

1. **Is the BigQuery side actually publishing rows for the missing days?** The fact that row counts drop from 393K to 19K on gap days suggests the BigQuery export is missing the data entirely — not "publishing zeros". If so, the carry-forward fix is the right one; if BigQuery has the data and we're dropping it in the BigQuery → Delta full-overwrite step (the 07:30 UTC `Spaceship - process table` notebook), we should fix the overwrite instead.
2. **Is the Apr 10 / May 20 / May 29 pattern of "Super-only gap" caused by a different upstream than the Apr 27 / Jun 1 / Jun 8 / Jun 10 "both-products gap"?** If the upstreams are different, "Super source publishes nothing" vs "the daily overwrite job failed for Super-only tables" are different root causes. The view fix masks both, but the engineer may want to fix one of them at source.
3. **Is there a documented SLA for Mon..Fri source freshness?** The skill says "weekday-only source" but the data shows weekday gaps are routine. The user is right to push back on this — the documented behaviour and the observed behaviour disagree.

