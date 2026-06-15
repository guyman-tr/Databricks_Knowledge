---
name: cross-cutting
description: "DEFAULT-ON ROLL-FORWARD, NO PRE-FLIGHT. When a numeric snapshot is requested for a date and that date is missing, partially missing (e.g. FX-null defaults a USD column to 0), or behind a known per-platform lag (Apex weekend plateau, Spaceship Super/Voyager source-system gaps, MoneyFarm same-day FX-null), the answer ALWAYS rolls forward to the latest available clean snapshot within a 3-day lookback window — silently, with the effective-date shown ONLY when it differs from the requested date. Never produce a 0 / NULL / partial answer when a fresh snapshot exists. Never ask the user 'do you want yesterday instead?' before answering. Roll-forward is per-column, not per-table (MoneyFarm GBP can be T-0 while MoneyFarm USD is T-1 due to FX-null). Per-platform 'latest clean date' rules: Apex/Options plateaus on weekends + holidays; Spaceship Super/Voyager have source-system gaps even mid-week (verified: Mon Jun 1 2026 + Fri Jun 5 2026 had super_balance_aud=0 with no weekend explanation); Spaceship Nova publishes 7 days/week; MoneyFarm GBP daily, USD same-day-FX-null = 0; Fact_AUM overall lags T-1 (last DateID is yesterday at most). The 3-day lookback covers every currently-observed lag in the corpus. If no clean snapshot exists within 3 days, escalate to a 7-day lookback and surface the staleness explicitly. Roll-forward applies to AUM/AUA, balance snapshots, fact_pnl, and any other point-in-time fact — NOT to flow facts (deposits, withdrawals, fees, MIMO) where T-0 absence is the right answer (the day didn't happen yet)."
triggers:
  - data latency
  - data freshness
  - data lag
  - latency
  - freshness
  - roll forward
  - rollforward
  - roll-forward
  - latest available
  - latest clean snapshot
  - effective date
  - as-of date
  - as of date
  - stale data
  - same-day FX
  - FX null
  - weekend lag
  - weekend plateau
  - Apex lag
  - Spaceship gap
  - MoneyFarm same-day
  - data not yet available
  - not flowing yet
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
  - main.etoro_kpi.v_spaceship_aum
  - main.etoro_kpi_prep.v_moneyfarm_aum
sample_questions:
  - "What is our AUM as of today?"
  - "AUM on June 9 2026"
  - "Spaceship balance yesterday"
  - "MoneyFarm AUM today"
  - "Options/Apex equity Sunday"
  - "Customer balance for date X (where X has no data yet)"
domain_tags:
  - shared
  - contract
  - latency
  - rollforward
  - point-in-time
version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-06-09"
---

# Data-Latency & Roll-Forward Contract (cross-cutting)

## POLARITY — READ THIS FIRST

Roll-forward is **DEFAULT-ON** for point-in-time / snapshot facts.

When the user asks for a snapshot value (AUM, balance, equity, NOP, position-PnL-as-balance, account value) for a specific date, the agent:

1. Tries the requested date.
2. If that date is missing, partial (FX-null = 0), or behind a known per-platform lag, **silently rolls forward** to the latest available clean snapshot within a **3-day lookback window**.
3. Shows the effective date in the answer **only when it differs** from the requested date (when the requested date is fresh, no extra noise).
4. If no clean snapshot exists within 3 days, escalates to a 7-day lookback and **surfaces the staleness explicitly** ("Latest clean snapshot is N days old — check upstream pipeline").

The user must explicitly opt OUT to disable roll-forward — they do NOT opt IN to apply it. Producing a 0 / NULL / partial answer because the requested date isn't fully landed yet is a **contract violation**, not a polite rendering of "what the data says".

## Why this exists

eToro's snapshot pipelines have **structurally divergent latencies** across platforms, and the agent must hide that complexity behind a single answer. Verified by live UC queries on 2026-06-09 (today = `20260609`):

| Source | Latest clean date | Lag from today | Cause |
|---|---|---|---|
| `Fact_AUM` overall (latest `DateID`) | `20260608` | **T-1** | DDR pipeline runs after midnight; today's snapshot lands tomorrow |
| `Fact_AUM.OptionsTotalEquity` (non-zero) | `20260608` | **T-1**, plateaus on weekends | Apex/Options uses `Function_AUM_OptionsPlatform(@OptionsMaxDateID,0)` — latest available external buy-power close ≤ ingestion; Sat/Sun have no NYSE feed → Sun = Sat = Fri value carried forward in DDR |
| `v_spaceship_aum` total (Nova non-zero) | `20260608` | **T-1** | Nova source is 7-day |
| `v_spaceship_aum` Super non-zero | `20260607` | **T-2** | Super source has gaps even on weekdays (verified Mon Jun 1 + Fri Jun 5 + Sun Jun 8 = 0) |
| `v_spaceship_aum` Voyager non-zero | `20260607` | **T-2** | Same as Super — source-system gaps beyond weekends |
| `v_moneyfarm_aum.total_balance_gbp` | `20260609` | **T-0** (today fresh) | UK pipeline lands intraday |
| `v_moneyfarm_aum.total_balance_usd` (non-zero) | `20260608` | **T-1** | USD = `gbp * fx_rate`; FX rate not yet published today → defaults to 0 per the column comment |

Three independent lag drivers in three weeks of recent data: pipeline cadence, FX-rate timing, and source-system mid-week gaps. A 3-day default lookback covers all of them.

## The contract

### Tier 1 — Roll-forward is per-column, not per-table

A view can have one column at T-0 and another at T-1 simultaneously. Verified: on 2026-06-09, `v_moneyfarm_aum.total_balance_gbp` is fresh while `total_balance_usd` is null/zero on the same row.

**Rule**: when the user asks for a USD figure and today's USD is 0/null, roll the **USD column** forward (use `total_balance_usd` from `dateid = 20260608`) — do NOT also roll the GBP back to match. Each column's effective date is independent.

### Tier 1 — Roll-forward applies only to point-in-time / snapshot facts

| Fact type | Roll-forward applies? | Why |
|---|---|---|
| Snapshot facts (`Fact_AUM`, `v_spaceship_aum`, `v_moneyfarm_aum`, `Fact_SnapshotEquity`, `Fact_SnapshotCustomer`, balance views) | **YES** | Asking "what's the value as-of date X" implicitly accepts the latest available state ≤ X |
| Flow facts (`Fact_BillingDeposit`, `Fact_BillingWithdraw`, `BI_DB_DDR_Fact_MIMO_*`, fee facts, trade volume facts) | **NO** | "Deposits today" with no rows = no deposits happened yet today; rolling forward to yesterday silently ANSWERS THE WRONG QUESTION |
| Aggregate flow over a window (`SUM(deposits) WHERE DateID BETWEEN X AND Y`) | **NO** | Same as above — partial-day data is a real signal; surfacing it as "stale" is wrong |
| Latest-state question ("right now / currently") | **YES** | Just use the latest available row, no opt-in needed |

**If you're not sure**: a snapshot fact has one row per (entity, date) and the answer is a *level*. A flow fact has one row per *event* and the answer is a *sum / count over time*. Roll-forward applies only to levels.

### Tier 1 — The lookback window is 3 days, escalates to 7 days

```
1. Try requested DateID.
2. If empty / FX-null / partial → walk backwards day-by-day to DateID - 3.
3. Pick the most recent date where the column you need is non-null & non-zero.
4. If no clean snapshot in (DateID-3, DateID]:
   a. Escalate to a 7-day lookback.
   b. Surface staleness explicitly in the answer.
5. If no clean snapshot in 7 days:
   a. Stop — do NOT keep walking back silently.
   b. Surface the gap and ask whether to use a much older snapshot
      or treat the platform as TBD for this query.
```

The 3-day default covers every currently-observed lag in the corpus. The 7-day escalation handles long weekends + holidays + a single missed run.

### Tier 1 — How to disclose effective dates in the answer

**When effective_date == requested_date** (fresh data): say nothing extra. Just answer with the requested date.

**When effective_date != requested_date** (rolled forward): show it inline next to the affected number, with a one-clause "why":
```
- Trading Platform equity: $16.68B (as of 2026-06-08; 06-09 not yet landed)
- Options/Apex equity:     $4.64M  (as of 2026-06-08; weekend lag — Sat=Sun=Mon plateau)
- MoneyFarm AUM:           $484M   (as of 2026-06-08; same-day USD FX rate not yet published)
```

**When everything was rolled forward to the same date**: collapse to one footer, not per-line:
```
*All snapshots above are as of 2026-06-08; 06-09 had not fully landed at query time.*
```

**When 3-day lookback failed and 7-day kicked in**: explicit warning at the top, not a footer:
```
⚠️ Latest clean snapshot for Spaceship Super is 2026-06-02 (7 days old). 
Upstream pipeline may be stuck — do not treat as authoritative without checking.
```

### Tier 2 — Per-platform "latest clean date" probes

For each platform, there's a different cheapest probe to find the latest clean date. Use the right one:

| Platform | Latest-clean-date probe | Notes |
|---|---|---|
| `Fact_AUM` (TP/IBAN/Options) | `MAX(DateID)` on the table — pipeline emits all 3 columns together | TP and IBAN are deterministic on the latest DateID; Options can plateau within that — see next row |
| `Fact_AUM.OptionsTotalEquity` (Apex specifically) | `MAX(DateID) WHERE OptionsTotalEquity > 0` | Apex never has a "today is gone" gap (it just plateaus), so any latest DateID is fine to query — but be aware the value might equal yesterday's |
| Spaceship Super | `MAX(date_id) WHERE super_balance_aud > 0 FROM main.etoro_kpi.v_spaceship_aum` | The view's own comment promises Fri-fill-forward for Sat/Sun, but mid-week zeros happen anyway |
| Spaceship Voyager | `MAX(date_id) WHERE voyager_balance_aud > 0 FROM main.etoro_kpi.v_spaceship_aum` | Same as Super |
| Spaceship Nova | `MAX(date_id) WHERE nova_balance_aud > 0 FROM main.etoro_kpi.v_spaceship_aum` | 7-day source — almost always T-1 |
| MoneyFarm GBP | `MAX(dateid) WHERE total_balance_gbp > 0 FROM main.etoro_kpi_prep.v_moneyfarm_aum` | Often T-0 |
| MoneyFarm USD | `MAX(dateid) WHERE total_balance_usd > 0 FROM main.etoro_kpi_prep.v_moneyfarm_aum` | T-0 USD requires the day's FX rate; otherwise T-1 |
| Snapshot customer (Fact_SnapshotCustomer / V_Fact_SnapshotCustomer_FromDateID) | `MAX(DateID)` on the table | Daily fact; T-1 typical |

Run the probe **lazily** — only when the requested date returns 0 or null on the column being read. Don't probe upfront on every query.

### Tier 2 — SQL pattern: roll-forward in a single CTE

This is the canonical roll-forward pattern. Use it whenever you need a level value for a date that might not be there yet. Replace `:requested_date_id` with the user's date and `:column_name` with the column you need non-null.

```sql
-- Generic roll-forward: latest clean snapshot ≤ requested date, within 3 days
WITH effective AS (
  SELECT MAX(DateID) AS effective_date_id
  FROM <fact_or_view>
  WHERE DateID BETWEEN (:requested_date_id - 3) AND :requested_date_id
    AND <column_name> IS NOT NULL
    AND <column_name> <> 0
)
SELECT
  e.effective_date_id,
  CASE WHEN e.effective_date_id = :requested_date_id THEN 'fresh' ELSE 'rolled-forward' END AS staleness,
  /* aggregations on the chosen date */
  SUM(f.<column_name>) AS value
FROM <fact_or_view> f
CROSS JOIN effective e
WHERE f.DateID = e.effective_date_id;
```

Note that `DateID - 3` works because `DateID` is an `INT YYYYMMDD`. Across a month boundary this **breaks** (e.g. `20260601 - 3 = 20260598` which doesn't exist). Two safe approaches:

1. **For typical near-today queries (within the same month)**: the simple subtraction is fine.
2. **For month-boundary safety**: use a date arithmetic conversion:
   ```sql
   CAST(DATE_FORMAT(DATE_SUB(TO_DATE(CAST(:requested_date_id AS STRING), 'yyyyMMdd'), 3), 'yyyyMMdd') AS INT)
   ```
   Verbose but correct. Worth the noise only when the requested date is within 3 days of a month boundary.

### Tier 3 — Composing roll-forward across multiple platforms

When the rollup contract (e.g. AUM cross-platform breakdown) calls multiple sources, **resolve effective dates independently per source** and then assemble the breakdown with each line carrying its own effective date.

Worked example — "AUM as of 2026-06-09" (today; nothing has fully landed):

| Line | Probe target | Effective date used | Why |
|---|---|---|---|
| TP / IBAN / Options | `MAX(DateID)` on `Fact_AUM` | `20260608` | Today's DDR snapshot not yet landed (T-1) |
| Spaceship Nova | `MAX(date_id) WHERE nova_balance_aud > 0` | `20260608` | T-1 |
| Spaceship Super | `MAX(date_id) WHERE super_balance_aud > 0` | `20260607` | Super source-system gap on Jun 8 |
| Spaceship Voyager | `MAX(date_id) WHERE voyager_balance_aud > 0` | `20260607` | Same as Super |
| MoneyFarm USD | `MAX(dateid) WHERE total_balance_usd > 0` | `20260608` | Today's FX null |

The output answer collapses these into a footer **only if** the user's requested date was today AND every line was rolled. Otherwise show the effective date per-line where it differs from requested.

### Tier 4 — Don't double-count when rolling forward across days

If the user asks for a 7-day window of *flow* and you wrongly apply roll-forward, you'll double-count the rolled-forward day. Roll-forward is for **levels**, not flows. (Repeated for emphasis — this is the easiest way to corrupt a number.)

## Opt-out

Only when the user literally says one of:

- "no roll-forward"
- "exact date only"
- "raw value as of <date>"
- "include the null"
- "include the zero"
- "show me what's actually there"
- "literal data"

…the contract is silenced for that turn: return the raw value (including 0 / NULL) for the exact requested date, with no roll-forward attempted. **Never opt-out on topic inference** ("audit" / "regulatory" / "month-end report" do NOT opt-out by themselves — many regulatory questions still want the rolled-forward number).

## Interactions with other contracts

- **Valid-users filter contract** (`valid-users-filter-contract.md`): orthogonal. Filter the customer base FIRST, then apply roll-forward on the per-customer aggregate. Both contracts run silently and both surface their behavior in the answer footer.
- **Future scope-disclosure contract**: when added, the effective-date footer becomes one of multiple lines in a single composite footer.

## Verification log (2026-06-09)

The latency table above was verified live. Summary:

- ✅ Fact_AUM has `MAX(DateID) = 20260608` while today is 20260609 (T-1 on overall).
- ✅ MoneyFarm `total_balance_gbp` is fresh on 20260609 ($362.8M) but `total_balance_usd` is 0 due to FX-null.
- ✅ Spaceship Super and Voyager non-zero stop at 20260607; Nova stops at 20260608.
- ✅ Apex/Options shows verified plateau Jun 6 = Jun 7 = Jun 8 ($4.636M repeated) and Jun 1 = Jun 2 (Memorial Day). Confirms the weekend-lag claim.
- ⚠️ Spaceship Super=0 / Voyager=0 on Mon Jun 1 + Fri Jun 5 + Sun Jun 8 — the documented Sat/Sun fill-forward does NOT cover all observed gaps. The 3-day lookback handles this.
