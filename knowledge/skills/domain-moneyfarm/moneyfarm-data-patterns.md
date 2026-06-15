---
name: domain-moneyfarm
description: "Reusable SQL building blocks for any MoneyFarm query — case-sensitive
  providerName='Moneyfarm' filter (capital M, single word; the lowercase event-side
  spelling), AccountTypeID=4 / FundingTypeID=44 / PaymentMethodTypeId=44 /
  FTDPlatformID=4 dictionary mapping (all = MoneyFarm), GBP→USD conversion via
  fact_currencypricewithsplit InstrumentID=2 with COALESCE(rate, 0) safety,
  TransactionId hash logic from V2 deposit-event HLD (hash of GCID+valueDate+
  Amount via sub-accounts-experience-worker), Identifier_Value↔externalUserId
  alternate join when GCID isn't yet resolved, SourceFile-max dedup on silver
  AUM double-send days, Source_Type='Live Event' filter for live-only activity,
  Date_Source_Type 3-rung mutually-exclusive partitioning (don't double-count),
  1:N GCID-to-PortfolioID handling (always pick a grain), BIGINT-vs-INT GCID
  type-cast on join boundaries, UTC-no-tz-conversion date semantics, and the
  CCM feature-flag patterns (MoneyfarmEventHubEventTypes array, V2 redirect
  flags). Each pattern includes a snippet, a why, and a known-pitfall note.
  Plus the inverse-pattern set: 6 anti-patterns to avoid (querying
  v_moneyfarm_fees expecting data, using providerName='MoneyFarm' camel-case,
  reading silver Market_Value as gross-of-fees, ignoring SourceFile dedup,
  treating TransactionId as a true PK, and counting across 3-rung
  Date_Source_Type sums)."
triggers:
  - moneyfarm sql pattern
  - moneyfarm cte
  - providerName Moneyfarm
  - providerName='Moneyfarm'
  - AccountTypeID 4
  - FundingTypeID 44
  - PaymentMethodTypeId 44
  - FTDPlatformID 4
  - InstrumentID 2
  - GBP USD conversion
  - TransactionId hash
  - sub-accounts-experience-worker
  - Identifier_Value externalUserId
  - SourceFile dedup
  - silver double send
  - Source_Type Live Event
  - Date_Source_Type 3 rung
  - 1:N GCID PortfolioID
  - BIGINT vs INT GCID
  - moneyfarm anti-patterns
sample_questions:
  - "How do I filter for MoneyFarm events in bronze_event_hub?"
  - "What's the canonical GCID->MoneyFarm-customer join filter?"
  - "How do I convert GBP to USD in MoneyFarm queries?"
  - "How do I dedupe silver_moneyfarm double-send days?"
  - "Why did my Source_Type sum double-count?"
  - "What's the AccountTypeID for MoneyFarm in the payments dictionary?"
required_tables:
  - main.etoro_kpi_prep.v_moneyfarm_aum
  - main.etoro_kpi_prep.v_moneyfarm_mimo
  - main.bi_output.bi_output_moneyfarm_customers
  - main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
  - main.bi_output.bi_output_moneyfarm_fact_transactions
  - main.money_farm.silver_moneyfarm_etoro_mf_aum
  - main.bi_db.bronze_sub_accounts_accounts
  - main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-31"
---

# MoneyFarm — Reusable SQL Patterns

Building blocks for any MoneyFarm query. Most patterns are CTE fragments — drop them into a larger query.

## 1. Canonical `providerName` filter

**Use whenever** filtering `bi_db.bronze_sub_accounts_accounts` or `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` for MoneyFarm rows.

```sql
-- For bronze_sub_accounts_accounts:
WHERE sa.providerName = 'Moneyfarm'

-- For bronze_event_hub_prod_event_streaming_we_sub_accounts:
WHERE EventPayloadRowData.ProviderName = 'Moneyfarm'
```

**Why**: case-sensitive — capital M, single word, no space. Both source pipelines write the value as `'Moneyfarm'` (one word, lowercase except the leading M).

**Pitfalls**:
- `'MoneyFarm'` (camel-case) — doesn't match. Confluence and CS use this spelling but the event payload doesn't.
- `'Money Farm'` (with space) — doesn't match.
- `'moneyfarm'` (all lowercase) — doesn't match.

**Source**: V2 HLD (Confluence XP/12216961926) and the live event payload sample. The 3 prep views encode this filter; raw-bronze queries must match it manually.

## 2. Identity bridge — `bronze_sub_accounts_accounts`-side filter

**Use whenever** joining MoneyFarm GCIDs back to the eToro `Dim_Customer` universe via the sub-accounts bridge.

```sql
LEFT JOIN main.bi_db.bronze_sub_accounts_accounts sa
    ON sa.gcid = fps.GCID
    AND sa.providerName = 'Moneyfarm'    -- REQUIRED (per UK BA Genie instruction)
```

**Why**: per UK BA Genie space [WIP] join_spec instruction (id `01f122f379e314879bedaacb2fd0a5b4`):

> *"Make sure to filter/join also on bronze_sub_accounts_accounts where providerName = 'Moneyfarm'. This ensures bronze_sub_accounts_accounts is 'one' in the 'one to many' relationship."*

**Without the filter** the bridge is 1:N on GCID (because a single GCID can have sub-account links across MoneyFarm + Spaceship + eMoney + others). With the filter, it's the "one" side of the 1:N.

## 3. Alternative bridge — `Identifier_Value` ↔ `externalUserId`

**Use whenever** GCID isn't already resolved on the MoneyFarm side (e.g. raw silver queries before the BI pipeline has run).

```sql
LEFT JOIN main.bi_db.bronze_sub_accounts_accounts sa2
    ON silver.Identifier_Value = sa2.externalUserId
    AND sa2.providerName = 'Moneyfarm'
```

**Why**: silver `Identifier_Value` is the MoneyFarm-side externalUserId; `bronze_sub_accounts_accounts.externalUserId` is the eToro-side already-resolved externalUserId. UK BA Genie space registers this as a separate join_spec (id `01f1239e4c5919...`).

## 4. GBP→USD conversion (via `fact_currencypricewithsplit`)

**Use whenever** you need to convert GBP MoneyFarm amounts to USD for cross-platform aggregation.

```sql
WITH gbp_usd_rates AS (
    SELECT
        CAST(OccurredDate AS DATE) AS rate_date,
        (Ask + Bid) / 2 AS gbp_to_usd_rate
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
    WHERE InstrumentID = 2    -- GBP/USD pair
)
SELECT
    m.date,
    m.total_deposits_gbp,
    m.total_deposits_gbp * COALESCE(r.gbp_to_usd_rate, 0) AS total_deposits_usd
FROM <my_moneyfarm_table> m
LEFT JOIN gbp_usd_rates r ON m.date = r.rate_date
```

**Why**: `InstrumentID = 2` is the GBP/USD pair in `fact_currencypricewithsplit`. Mid-rate is `(Ask + Bid) / 2`. The `COALESCE(rate, 0)` is the canonical pattern from the 3 prep views.

**Pitfalls**:
- **Spaceship uses `InstrumentID = 7`** (AUD/USD). MoneyFarm uses `InstrumentID = 2`. Don't confuse.
- **Missing rate row → USD = 0.0** (because of the `COALESCE`). To detect: `total_deposits_gbp > 0 AND total_deposits_usd = 0` is the "missing rate" signal — investigate the `OccurredDate` dimension before reporting.

## 5. Payments-dictionary mapping for cross-platform DDR

**Use whenever** joining MoneyFarm rows in cross-platform DDR / payments queries.

| Dictionary | Column | Value | Meaning |
|---|---|---|---|
| `Dictionary.AccountTypes` | `ID` | `4` | MoneyFarm |
| `Dictionary.FundingType` | `ID` | `44` | MoneyFarm |
| `Dictionary.PaymentMethods` | `ID` | `44` | MoneyFarm (`PaymentMethodTypeId = 44`) |
| `Dim_Customer` | `FTDPlatformID` | `4` | "First deposit happened on MoneyFarm" |
| `Dictionary.FundingType` | `DefaultCurrency` | `5` | GBP |

**For DDR cross-platform MIMO filter**:

```sql
SELECT * FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms
WHERE AccountTypeID = 4   -- MoneyFarm rows only
```

**For "first deposit happened on MoneyFarm" cohort**:

```sql
SELECT * FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer
WHERE FTDPlatformID = 4   -- ISA / MoneyFarm
```

**Source**: Confluence MG/13600227427 ("MoneyFarm - global payments configurations") + the UK BA Genie sql_snippet text quoted in `moneyfarm-dashboard-queries.md` §"UK BA Genie sql_snippet".

## 6. Filter live-only activity — `Source_Type` / `Date_Source_Type`

**Use whenever** counting "newly acquired" or "live activity" customers (vs the silver back-fill).

```sql
-- For per-portfolio rows:
WHERE fps.Source_Type = 'Live Event'

-- For per-customer rows:
WHERE c.Date_Source_Type = 'Live Event (New)'
```

**Why**: the BI pipeline writes 3 distinct provenance values:
- `Live Event` / `Live Event (New)` — streamed from `compliance.bronze_event_hub_*`
- `Bronze Table (Recent)` — back-filled from `general.bronze_moneyfarm_users`
- `Silver History` / `Silver AUM Snapshot (Legacy)` — back-filled from `silver_moneyfarm_etoro_mf_aum`

**Pitfalls**:
- The `bi_output_moneyfarm_fact_portfolio_snapshot` uses a 2-rung subset (`Live Event` / `Silver History`) — **the 3-rung version only exists on `bi_output_moneyfarm_customers`**. Don't expect 1:1 source labels when joining customers→snapshots.
- The 3 rungs are mutually-exclusive partitions of the same universe — **SUMing counts across rungs is correct only if you want the total population**, NOT if you want a deduplicated count.

## 7. SourceFile-max dedup on silver AUM

**Use whenever** querying `silver_moneyfarm_etoro_mf_aum` directly (the 3 prep views handle this internally).

```sql
WITH dedup_aum AS (
    SELECT
        etr_ymd, GCID, Portfolio_Id, Product, Market_Value, SourceFile,
        ROW_NUMBER() OVER (
            PARTITION BY etr_ymd, Portfolio_Id
            ORDER BY SourceFile DESC
        ) AS rn
    FROM main.money_farm.silver_moneyfarm_etoro_mf_aum
)
SELECT * FROM dedup_aum WHERE rn = 1
```

**Why**: Ben Thompson's `AM - ISA Performance V1` Custom SQL preamble explicitly notes:

> *"there are sometimes instances of 'double sends' on one day creating two rows, so taking the row with the most recent SourceFile."*

The `SourceFile` format is `ETORO-MF-AUM-{date}-{seq}` so lexicographic-max is equivalent to recency-max within a day.

**Pitfalls**:
- The 3 prep views (`v_moneyfarm_aum` etc.) DON'T do this dedup explicitly — they SUM across all rows including double-sends. **This means `v_moneyfarm_aum.total_balance_gbp` may be inflated on double-send days.** Verify with raw silver if exact AUM is needed.
- **TODO/INVESTIGATION**: confirm with Ben whether `v_moneyfarm_aum` should be patched to dedup by SourceFile-max before the SUM.

## 8. 1:N GCID → PortfolioID handling

**Use whenever** joining GCID-grain to portfolio-grain.

```sql
-- ANTIPATTERN — multi-row blow-up:
SELECT c.GCID, c.MF_Journey_Beginning, fps.Current_Market_Value_GBP
FROM main.bi_output.bi_output_moneyfarm_customers c
JOIN main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot fps ON fps.GCID = c.GCID
-- ↑ produces N rows per customer (one per portfolio)

-- CORRECT — pick a grain:
-- (a) customer-grain with portfolio aggregate:
SELECT c.GCID, c.MF_Journey_Beginning, SUM(fps.Current_Market_Value_GBP) AS aum
FROM main.bi_output.bi_output_moneyfarm_customers c
LEFT JOIN main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot fps ON fps.GCID = c.GCID
GROUP BY c.GCID, c.MF_Journey_Beginning

-- (b) portfolio-grain with customer attrs:
SELECT fps.GCID, fps.PortfolioID, fps.Product_Name, c.MF_Journey_Beginning
FROM main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot fps
JOIN main.bi_output.bi_output_moneyfarm_customers c ON c.GCID = fps.GCID
```

**Why**: per UK BA Genie space instruction:

> *"A single GCID can have multiple Portfolios (PortfolioIDs) and rows for each portfolio in each table. Therefore when joining on GCID there are multiple different rows for a GCID on left and right."*

**Pitfalls**:
- Joining `fact_portfolio_snapshot.GCID = fact_transactions.GCID` (without an additional `PortfolioID` predicate) Cartesian-explodes within a customer. To stay sane, prefer the explicit join via `PortfolioID`:

  ```sql
  fps.GCID = ft.GCID AND fps.PortfolioID = ft.PortfolioID
  ```

## 9. BIGINT vs INT GCID type-cast on join boundaries

**Use whenever** joining the bizops `bi_output_moneyfarm_*` tables (LONG / BIGINT GCID) to the prep views (INT GCID).

```sql
-- Casting on the boundary keeps both sides honest:
SELECT *
FROM main.etoro_kpi_prep.v_moneyfarm_aum a       -- gcid INT
JOIN main.bi_output.bi_output_moneyfarm_customers c ON c.GCID = CAST(a.gcid AS BIGINT)
```

**Why**: silver `silver_moneyfarm_etoro_mf_aum.GCID` is INT-typed (integer). `bi_output_moneyfarm_*.GCID` is LONG/BIGINT-typed (the BI team's convention). The 3 prep views inherit the silver INT type. Without an explicit cast some Spark engines silently downcast or warn — explicit cast is safe.

**Pitfalls**:
- **eToro internal GCID space is NOT bounded by INT_MAX (2.1B)** today. As of 2026-05 max GCID is in the high tens of millions, but the BI team's choice of LONG suggests they expect future growth past INT_MAX. Don't assume INT is always safe for new queries — prefer BIGINT.

## 10. Date semantics — UTC, no timezone conversion

**Applies to**: `v_moneyfarm_mimo.date`, all bizops fact `*_Date` columns, silver `etr_ymd`.

```sql
-- For UK-local-day analyses, you can usually use UTC-truncated dates as-is:
SELECT date, SUM(total_deposits_gbp)
FROM main.etoro_kpi_prep.v_moneyfarm_mimo
WHERE date BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY date
```

**Why**: MoneyFarm operates in GBP/UK. UK is GMT (winter) or BST = UTC+1 (summer). UTC-truncated date ≈ UK local date most of the year, with edge-case skew on UTC midnight events that would have been the previous UK day during BST.

**Pitfalls**:
- **Spaceship's MIMO converts UTC→Sydney** (`Australia/Sydney` timezone). MoneyFarm does NOT. Cross-domain panels comparing the two need timezone alignment.
- The `value_date` field (parsed in the view's `parsed_events` CTE) is the *settlement* date — different from `date` (event-creation date). For cash-flow / reconciliation work prefer `value_date`; for activity / MIMO prefer `date`. But: `value_date` is NOT exposed in `v_moneyfarm_mimo`'s final SELECT — to use it you'd have to copy the CTE chain.

## 11. TransactionId hash logic

**Per Confluence XP/13551468545** ("MF additions - Support for Money Farm Deposit Event"):

```text
The sub-accounts-experience-worker enriches each PORTFOLIO_DEPOSIT event with:

  TransactionId = hash(GCID, valueDate, Amount)
```

**Use case**: idempotency / retry handling on the publisher side — the worker sends the same `TransactionId` on retry, so downstream `payments-metrics` Service Bus consumers can dedupe.

**Pitfalls**:
- **`TransactionId` is NOT a true PK** — collisions are possible if two PORTFOLIO_DEPOSITS have the same `(GCID, valueDate, Amount)` triple. For analytics use the genuine per-event PK `event_correlation_ID` (format `{EventId UUID}_{EventType}`) — that one is guaranteed unique.

## 12. Capturing pre-Oct-2025 MIMO history

**Use whenever** the time range extends earlier than the live-stream coverage of `v_moneyfarm_mimo`.

```sql
-- v_moneyfarm_mimo only covers Oct 2025+:
SELECT MIN(date), MAX(date) FROM main.etoro_kpi_prep.v_moneyfarm_mimo
-- ~2025-10-01 ... today

-- For earlier history, fall back to bi_output_moneyfarm_fact_transactions
-- with Source_Type filter:
SELECT
    Transaction_Date,
    GCID,
    PortfolioID,
    TransactionType,                    -- Deposit / Withdrawal / Full Withdrawal
    Amount_GBP,
    -- Source_Type column not on transactions fact directly; use UpdateDate
    -- or correlate with fact_portfolio_snapshot.Source_Type
    UpdateDate
FROM main.bi_output.bi_output_moneyfarm_fact_transactions
WHERE Transaction_Date < '2025-10-01'
```

**Pitfalls**:
- Per-event `TransactionType` distinguishes `Full Withdrawal` from regular `Withdrawal`; the live stream and `v_moneyfarm_mimo` do NOT make this distinction (only the bizops `_fact_transactions` does).
- `silver_moneyfarm_historical_events` exists in `money_farm.*` and is the back-fill source for pre-stream events; if `bi_output_moneyfarm_fact_transactions` doesn't have the depth you need, fall back to that table.

---

# Anti-patterns — what NOT to do

### ❌ Anti-pattern 1 — querying `v_moneyfarm_fees` expecting data

```sql
-- WRONG: returns 0 rows always
SELECT SUM(total_fees_gbp) FROM main.etoro_kpi_prep.v_moneyfarm_fees WHERE dateid >= 20260101
```

**Why wrong**: the view DDL is `SELECT NULL CASTS WHERE 1=0`. **Always 0 rows.**

**Right thing to do**: ask Finance directly for booked fee revenue — it's not in UC. Or compute an estimated fee from `v_moneyfarm_aum` × the documented Managed-ISA tiered schedule from `moneyfarm-metric-definitions.md` §7 (with a **prominent caveat** that this is an estimate, not a booked figure — and that S&S ISA fees are not documented eToro-side at all so any estimate is incomplete).

### ❌ Anti-pattern 2 — `providerName = 'MoneyFarm'` (camel-case)

```sql
-- WRONG: matches zero rows
SELECT * FROM main.bi_db.bronze_sub_accounts_accounts
WHERE providerName = 'MoneyFarm'
```

**Why wrong**: source pipelines write `'Moneyfarm'` (capital M, single word). Camel-case `'MoneyFarm'` is the Confluence/CS spelling but not the data spelling.

### ❌ Anti-pattern 3 — treating silver `Market_Value` as gross-of-fees

**Why wrong**: `silver_moneyfarm_etoro_mf_aum.Market_Value` is the MoneyFarm-side NAV after MoneyFarm has netted out their management fees. There's no gross-of-fees view in UC. To estimate gross AUM you'd add the documented fee back, which requires the same Confluence-anchored estimation as anti-pattern 1.

### ❌ Anti-pattern 4 — ignoring `SourceFile` dedup on raw silver

```sql
-- WRONG on double-send days: produces 2x AUM
SELECT etr_ymd, SUM(Market_Value) FROM main.money_farm.silver_moneyfarm_etoro_mf_aum
GROUP BY etr_ymd
```

**Why wrong**: see pattern #7 above. Always dedup by `(etr_ymd, Portfolio_Id)` taking max `SourceFile` lexicographically.

### ❌ Anti-pattern 5 — using `TransactionId` as a PK

```sql
-- WRONG if you assume unique
SELECT TransactionId, COUNT(*)
FROM main.bi_output.bi_output_moneyfarm_fact_transactions
GROUP BY TransactionId
HAVING COUNT(*) > 1
-- May produce >0 rows: hash(GCID, valueDate, Amount) collisions are possible
```

**Why wrong**: `TransactionId = hash(GCID, valueDate, Amount)` — collisions exist when two events share the triple. For uniqueness use `event_correlation_ID`.

### ❌ Anti-pattern 6 — counting across `Date_Source_Type` rungs

```sql
-- WRONG: this is just the total count, but the wording "by source" double-counts in interpretation
SELECT Date_Source_Type, COUNT(*) AS customers
FROM main.bi_output.bi_output_moneyfarm_customers
GROUP BY Date_Source_Type
-- Then SUM(customers) ≠ COUNT(DISTINCT GCID) only if values overlap, which they don't —
-- BUT users often interpret these as overlapping cohorts (e.g. "live + bronze = streamed customers"), which is wrong
```

**Why subtle**: the 3 rungs are mutually-exclusive partitions. `SUM(customers)` across rungs equals `COUNT(*)` of the table, which equals `COUNT(DISTINCT GCID)`. **The trap is interpretation, not arithmetic** — readers tend to think the rungs overlap (because the data sources do overlap upstream — `bronze_moneyfarm_users` and the live event stream cover overlapping populations), but the BI pipeline assigns each GCID to exactly one rung based on `MIN(observation_date)`. Use the right caveat when reporting.

---

## Cross-reference — where each pattern is anchored

| Pattern | Source anchor |
|---|---|
| #1 `providerName='Moneyfarm'` filter | View DDL (`v_moneyfarm_mimo`) + UK BA Genie space instructions |
| #2 sub-accounts bridge filter | UK BA Genie space join_spec instruction |
| #3 `Identifier_Value` ↔ `externalUserId` | UK BA Genie space join_spec |
| #4 GBP/USD via `InstrumentID=2` | View DDLs (`v_moneyfarm_aum`, `v_moneyfarm_mimo`) |
| #5 Payments dictionary mapping | Confluence MG/13600227427 + UK BA Genie sql_snippet |
| #6 `Source_Type` / `Date_Source_Type` filter | Wiki anchors on `bi_output_moneyfarm_*` |
| #7 `SourceFile`-max dedup | Ben's Custom SQL preamble (Tableau lineage) |
| #8 1:N GCID → PortfolioID | UK BA Genie space instruction |
| #9 BIGINT vs INT GCID cast | UC `DESCRIBE` of source tables |
| #10 UTC date semantics | View DDL (`v_moneyfarm_mimo`) |
| #11 `TransactionId` hash | Confluence XP/13551468545 |
| #12 Pre-Oct-2025 fallback | View DDL coverage analysis |
