---
id: position-state-and-grain
name: "Position State, Grain & Lifecycle"
description: "The trading-platform position lifecycle, what every table holds at what grain, and the fact-vs-dim rule. Anchored on the granular `fact_customeraction_w_metrics` (state at event time, authoritative for transactional questions), `Fact_CustomerAction` (the older parent fact, 11 billion rows, sparse columns per ActionTypeID), and `Dim_Position` (134-column metadata catalog with current-state mutable fields — never trust for state at open). Includes the canonical `ActionTypeID` map (with the names that ETL actually uses — `ManualPositionOpen`, `CopyPositionOpen`, `CopyPlusPositionOpen`, `DetachedPositionClose`, the two `*TypeUnknown` fallbacks), the `IsBuy / IsSettled / SettlementTypeID / IsActiveTrade / MirrorID / MirrorTypeID` semantics, the `OrderID` NULL rule (NULL only for positions opened without an order — corporate action / dividend), and how to recreate position state at an arbitrary date via `Dim_PositionChangeLog`. Read FIRST for any position-state, copy-detection, or lifecycle question."
triggers:
  - position state
  - position at open
  - position at close
  - current position
  - active position
  - PositionID
  - Dim_Position
  - fact_customeraction
  - fact_customeraction_w_metrics
  - w_metrics
  - PositionChangeLog
  - point in time
  - position lifecycle
  - ActionTypeID
  - ManualPositionOpen
  - CopyPositionOpen
  - CopyPlusPositionOpen
  - DetachedPositionClose
  - IsActiveTrade
  - IsSettled
  - SettlementTypeID
  - MirrorID at open
  - OrderID NULL
  - open rate
  - close rate
  - Leverage
  - partial close
  - IsPartialCloseParent
  - IsPartialCloseChild
  - position history
  - recreate position state
  - reopen position
  - corporate action open
required_tables:
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog
  - main.trading.bronze_etoro_trade_position_datafactory
  - main.trading.bronze_etoro_history_position_datafactory
version: 3
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Position State, Grain & Lifecycle

A position is not "what `Dim_Position` says about it right now". A position is a **lifecycle**: opened at one rate, possibly modified (partial close, leverage change, mirror detach), eventually closed at another rate. Each mutation throws off an action event. The events are the truth; the dim is the latest snapshot of mutable metadata.

This sub-skill is the **first stop** for any position-state question. The rule it teaches — *prefer the fact, use the dim for static metadata enrichment only* — applies across the rest of `domain-trading`.

## When to Use

Load when the question is about:

- "What was position X's state when it opened?" / "at close?" / "right now?" / "on date Y?"
- "Was this position opened as a copy / mirror?", "what mirror was it under at open?"
- "What's the lifecycle of position X?" — every event, in order
- "What's the difference between `fact_customeraction_w_metrics` and `Dim_Position`?"
- "How do I recreate position state at an arbitrary date?"
- "Why is OrderID NULL on half the rows of Dim_Position?"
- "What's the grain of `fact_customeraction_w_metrics`?", "how many rows per position?"
- "Why does `Dim_Position.MirrorID = 0` but the position was clearly a copy?"
- "What does `ActionTypeID = 28` / `ActionTypeID = 39` actually mean?"

Do **not** load for:

- Filtering by instrument / ticker → `instruments-and-asset-classes.md`
- Aggregated trading volume → `trading-volumes.md`
- AUM / PnL snapshots → `portfolio-value-aum-pnl.md`
- Hedge-execution audit per order → `dealing-investigation-and-execution.md`
- Copy/mirror economics (PI compensation, copy-fund attribution) → `copy-trading-and-mirror.md` *(pending dealing-analyst skill)*

## Scope

In scope: the granular fact `fact_customeraction_w_metrics` (purpose, grain, key columns, partition strategy), the older parent fact `Fact_CustomerAction` (11B rows, sparse per ActionTypeID), the `Dim_Position` master record (what it is reliable for vs not), the canonical `ActionTypeID` map (names + semantics for 1-6, 28, 39, 40 plus the dead/deprecated values), the `IsBuy / IsSettled / SettlementTypeID / IsActiveTrade / MirrorID / MirrorTypeID` semantics with at-event-time vs current-state distinction, the `OrderID` NULL rule, `Dim_PositionChangeLog` as point-in-time replay, query patterns for state-at-open / state-at-close / state-on-date / current-state.
Out of scope: instrument filter logic, volume / AUM / PnL aggregates, revenue per position, copy-fund / Smart Portfolio / Popular Investor economics, hedge-execution timing.
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `Dim_Position` is metadata, not state. Reach for the FACT first.** `Dim_Position` has 134 columns including mutable fields — `MirrorID`, `MirrorTypeID`, `IsActiveTrade`, `SettlementTypeID`, `IsSettled`. When a customer detaches their Smart Portfolio but keeps the positions, `Dim_Position.MirrorID` flips to `0`. If you query the dim to answer "was this opened as a copy?", you get a silent wrong answer. Use `fact_customeraction_w_metrics` filtered to the opening `ActionTypeID` (1, 2, 3, or 39) to get the value at open. Use the dim only for fields that don't change (instrument metadata, `OpenRate`, `OpenDateID`, `PositionID`, `CID`). Source: `Dim_Position.md` §1 + Trade-side production SP `Trade.DetachPositionsFromMirror`.
2. **Tier 1 — The fact's grain is ONE ROW PER ACTION EVENT, not one row per position.** A single `PositionID` appears multiple times in `fact_customeraction_w_metrics` — once for open, possibly several for modifications, and once or more for close (partial closes stack). `SELECT * WHERE PositionID = X` returns the whole lifecycle. For state-at-event-time, filter by `ActionTypeID`. For state-now, take the most recent event by `ActionDate`. Source: `Fact_CustomerAction.md` §1 (corrected from "per customer per day" to "per event" by reviewer Guy, 2026-03-03).
3. **Tier 1 — `ActionTypeID = 28` is NOT partial close.** Partial-close is signaled by `IsPartialCloseParent = 1` and `IsPartialCloseChild = 1` on the same close event row. `ActionTypeID = 28` is **`DetachedPositionClose`** — a close after the position was detached from its mirror. `ActionTypeID = 3` is `CopyPlusPositionOpen` (`MirrorID=0, OrigParentPositionID>0`), NOT "Smart Portfolio" — Smart Portfolio identification is `MirrorTypeID = 4`. `ActionTypeID = 39` is `PositionOpenTypeUnknown` (position open without matching History.Credit), and `ActionTypeID = 40` is `PositionCloseTypeUnknown` (close without matching credit). Source: `Fact_CustomerAction.md` §2.1.
4. **Tier 1 — `w_metrics` UC column comments are MISATTRIBUTED on at least two columns.** Trusting `comment` on `de_output_etoro_kpi_fact_customeraction_w_metrics` directly is unsafe: `PositionID.comment` currently carries the description for `CompensationReasonID`, and `IsCopyFund.comment` carries the `MirrorTypeID` enum. The wiki is canonical; UC needs a metadata refresh. Source: live `SELECT comment FROM main.information_schema.columns WHERE table_name='de_output_etoro_kpi_fact_customeraction_w_metrics'` 2026-05-11.
5. **Tier 2 — `Dim_PositionChangeLog` is the ONLY deterministic point-in-time source for arbitrary dates.** The fact captures *events*; the change log captures *every mutation with timestamps*. For "what was position X on 2026-03-15 14:30?", only `Dim_PositionChangeLog` answers. Don't reach for it for state-at-open / state-at-close / state-now — the fact is far faster.
6. **Tier 2 — `Dim_PositionChangeLog` ETL uses DELETE+INSERT (not MERGE).** SP deletes `WHERE OccurredDateID >= @YesterdayID` and re-inserts from staging `WHERE Occurred >= @Yesterday`. A change event whose `Occurred` is one day but processed the next can be **deleted and lost**. Late-arrival risk for retrospective queries near day boundaries. Source: `Dim_PositionChangeLog.review-needed.md`.
7. **Tier 3 — `IsActiveTrade` is current-state on the dim and at-event-time on the fact.** "Was this position active at open?" doesn't make sense — it WAS active because it was just opened. "Is it active now?" → `Dim_Position.IsActiveTrade`. "Was it active as of date Y?" → compute from events (max `ActionDate ≤ Y` AND no close event by Y) or use `Dim_PositionChangeLog`.

## Tables

| Table | Use For |
|---|---|
| `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | **PRIMARY** — granular per-event state with KPI enrichment. State-at-event-time, fastest for transactional questions. Hybrid anchor (DWH-fact lineage upstream, enriched by DE pipeline). UC comments unreliable on this table — see Critical Warning 4. |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Older parent fact, ~11 billion rows. SWITCH-partition loaded daily. HASH(RealCID) in Synapse; UC partitioned by `etr_y / etr_ym / etr_ymd` — always partition-prune. Sparse: most columns NULL for non-position ActionTypeIDs. Reach when `w_metrics` doesn't have a column you need. |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position` | Position metadata master, 134 columns. `OpenRate`, `OpenDateID`, fill prices, spread snapshots at open. Mutable fields (`MirrorID`, `MirrorTypeID`, `IsActiveTrade`, `CloseRate`, current `Leverage`) — DO NOT trust for state at open. PK `(PositionID, CloseDateID)` NOT ENFORCED. |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog` | Point-in-time change log, 17 columns. Every Amount / StopRate / IsSettled / LotCount mutation with timestamps. Late-arrival risk near day boundaries — see Critical Warning 6. |
| `main.trading.bronze_etoro_trade_position_datafactory` | OLTP bronze of `Trade.Position_DataFactory` — **open positions only**. Use when you need `OrderID` and the dim/fact aren't enough. Lake-first; UC column comments mostly empty (only `PositionID` and `CID` carry Tier-1 wiki-derived text). |
| `main.trading.bronze_etoro_history_position_datafactory` | OLTP bronze of `History.Position_DataFactory` — **closed positions only**. Pair with the trade-side bronze for full lifecycle bridging. Lake-first; UC carries some column comments (e.g., `MirrorID` notes it leads to "a Mirror table of a still active copy" — i.e., post-detachment value, mirroring the DWH gotcha). |

---

## ActionTypeID — canonical map (replaces my pre-2026-05 broken map)

Source: `Fact_CustomerAction.md` §2.1. Names are the ones the ETL SPs use.

| ActionTypeID | Name | Source | Notes |
|---|---|---|---|
| 1 | `ManualPositionOpen` | `Trade.OpenPositionEndOfDay` | `MirrorID = 0, OrigParentPositionID = 0`. Customer-initiated manual open. |
| 2 | `CopyPositionOpen` | `Trade.OpenPositionEndOfDay` | `MirrorID > 0, OrigParentPositionID > 0`. Manual mirror copy. |
| 3 | `CopyPlusPositionOpen` | `Trade.OpenPositionEndOfDay` | `MirrorID = 0, OrigParentPositionID > 0`. NOT Smart Portfolio — Smart Portfolio is `MirrorTypeID = 4`, an orthogonal axis. |
| 4 | `ManualPositionClose` | `History.ClosePositionEndOfDay` | Customer-initiated close. |
| 5 | `CopyPositionClose` | `History.ClosePositionEndOfDay` | Mirror copy close. |
| 6 | `CopyPlusPositionClose` | `History.ClosePositionEndOfDay` | Copy-plus close. |
| 28 | `DetachedPositionClose` | `History.ClosePositionEndOfDay` | Close *after* the position was detached from its mirror. NOT partial close (use `IsPartialCloseParent/Child` for that). |
| 39 | `PositionOpenTypeUnknown` | `Trade.OpenPositionEndOfDay` | Position open *without* matching `History.Credit`. Fix attempted at weekly maintenance. |
| 40 | `PositionCloseTypeUnknown` | `History.ClosePositionEndOfDay` | Position close *without* matching `History.Credit`. |

Opens: `ActionTypeID IN (1, 2, 3, 39)`. There should be exactly one per position.
Closes: `ActionTypeID IN (4, 5, 6, 28, 40)`. Multiple if partial closes stack — distinguish parent vs child via `IsPartialCloseParent` / `IsPartialCloseChild`.

Non-position ActionTypeIDs that show up in the fact but route elsewhere:

- **7, 8, 11, 12, 27, 30, 32, 38, 42, 43, 44, 45** → money flow → `../domain-payments/`
- **14, 29** → logins → out of analytical scope
- **35, 36** → fees / compensation → `../domain-revenue-and-fees/`
- **41** → registration → `../domain-customer-and-identity/`
- **15-18, 19** → mirror ops (register/detach) → `copy-trading-and-mirror.md`
- **21-26** → **DEAD DATA** (social engagement; legacy rows exist but no active ETL since deprecation). Confirmed by reviewer Guy 2026-03-03.
- **13, 20, 31, 33** → not found in `Dim_ActionType` or any ETL SP; treat as deprecated / never used.

## Settlement type (`SettlementTypeID`)

`IsSettled` is a **legacy bit** (1 = real, 0 = CFD). It is **not** "settlement complete". The modern column is `SettlementTypeID`:

| SettlementTypeID | Meaning | Implied `IsSettled` |
|---|---|---|
| 0 | CFD | 0 |
| 1 | Real asset | 1 |
| 2 | TRS (Total Return Swap) | 0 |
| 3 | CMT (Crypto custody, real) | 1 |
| 4 | Real Futures | 1 |
| 5 | Margin Trade | 0 (variable) |

OLTP `Trade.PositionTbl` uses `ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint))`. When `SettlementTypeID` is NULL, fall back to `IsSettled`. Live `Leverage = 1 AND IsSettled = 1` → REAL settlement (per UC `Leverage.comment`). Gross notional = `Amount × Leverage`. Source: `Trade.PositionTbl.md` §2.2 + UC column comment.

## Mirror / Copy semantics — the classic trap

| Field | What it means at OPEN | What it means CURRENTLY (on the dim) |
|---|---|---|
| `MirrorID` | The mirror this position copied at open. `0` OR `NULL` = manual. `> 0` = copy. | The mirror this position is *currently* attached to. `0` if it ever detached. |
| `MirrorTypeID` | 4 = Smart Portfolio (copy fund); other values = manual copy variations. Set at open. | Same field, possibly mutated. |
| `OrigParentPositionID` | The leader's position this was copied from at open (or > 0 for CopyPlus). Immutable on OLTP. | Persists; safest "was this a copy" signal *only* when combined with the OPEN event. |
| `IsCopy` (derived) | `MirrorID > 0` at OPEN event ⇒ copy trade. | NOT reliable on the dim — see Critical Warning 1. |
| `IsCopyFund` (derived) | `MirrorTypeID = 4` at OPEN event ⇒ Smart Portfolio fund. | Same caveat. Note: UC comment on `w_metrics.IsCopyFund` is mis-described as `MirrorTypeID` enum — see Critical Warning 4. |

**Production trap**: customer opens via Smart Portfolio (Mr. PI XYZ). Six months later: "Stop Copying Mr. PI XYZ but keep the positions". `Dim_Position.MirrorID` flips to `0` for those positions. `SELECT IsCopy = (MirrorID > 0) FROM Dim_Position` returns **wrong "never was a copy"**. The fact stays correct: the OPEN event has `MirrorID = <Mr. PI's mirror>`. Source: `Dim_Position.md` §2 + `Trade.DetachPositionsFromMirror` SP.

## `OrderID` semantics — when it is NULL

`OrderID` on `Trade.PositionTbl` (and the DWH dim/fact derivatives) is FK to `Trade.Orders` — the order that opened the position. It is **NULL** when the position was opened without an originating order. From the OLTP wiki: *"NULL for positions opened without an order (corporate action, dividend)."* Examples include:

- Corporate-action opens (stock splits → reissued PositionIDs without a customer order).
- Dividend reinvestment.
- ACATS_IN transfers (`OpenActionType = 13` on `Trade.PositionTbl`; data sample on wiki confirms — incoming external account transfers).

What `OrderID NULL` does **not** mean: a copy/hierarchical open with a non-NULL parent is not, by itself, a guarantee of NULL `OrderID` — that depends on whether the parent originated from an order. Do not extrapolate beyond the wiki: NULL is documented for corporate-action / dividend / external-transfer opens, and the rest of the rule has not been verified end-to-end.

Source: `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` §4 column 10 + sample data block. UC `bronze_etoro_history_position_datafactory.OrderID.comment`: *"If there is a key, it leads to the historical order through which the position opened."* — implicit "if not, no order link".

## `IsActiveTrade`

- On `fact_customeraction_w_metrics`: captured per event. At open event it's typically 1; at close events it flips.
- On `Dim_Position`: 1 = currently open; 0 = closed. **Current state.**

For "is this open now?" — dim is fine. For "was this open as of yesterday?" — compute from events (max `ActionDate ≤ yesterday` AND no close event by then) or use `Dim_PositionChangeLog`.

## Position lifecycle (ASCII)

```
[Customer clicks Buy]
        │
        ▼
   ActionTypeID ∈ {1, 2, 3, 39}    ← OPEN events
        │  ← Dim_Position row created at open
        │  ← w_metrics row created with state-AT-OPEN
        │
        ▼
   amount/SL/TP/Mirror changes      ← Dim_PositionChangeLog rows appended (no ActionTypeID; ChangeTypeID instead)
        │  ← Dim_Position mutable fields overwritten
        │
        ▼
   ActionTypeID ∈ {4, 5, 6, 28, 40} ← CLOSE events (partial closes stack via IsPartialCloseParent/Child)
        │  ← Dim_Position.IsActiveTrade ← 0; CloseDateID populated
        │  ← w_metrics row(s) appended for the close
```

---

## Query Patterns

### Pattern 1 — State AT OPEN (the most common case)
```sql
SELECT PositionID, CID, ActionDate, ActionTypeID,
       InstrumentID, IsBuy, Amount, OpenRate, Leverage,
       MirrorID, MirrorTypeID, IsSettled, SettlementTypeID
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE PositionID = 123456789
  AND ActionTypeID IN (1, 2, 3, 39)
  AND etr_y = '2026'
ORDER BY ActionDate;
```
Use when: "what mirror was position X under at open?", "was it a copy?", "leverage at open?". Always include `etr_y / etr_ym / etr_ymd` partition-pruning.

### Pattern 2 — State AT CLOSE (or every close event for partial closes)
```sql
SELECT PositionID, CID, ActionDate, ActionTypeID,
       CloseRate, NetProfit,
       IsPartialCloseParent, IsPartialCloseChild,
       IsSettled, SettlementTypeID
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE PositionID = 123456789
  AND ActionTypeID IN (4, 5, 6, 28, 40)
  AND etr_y >= '2025'
ORDER BY ActionDate;
```
Use when: "realized PnL on close?", "auto-closed by TP/SL?", "did this position detach before closing?" (look for ActionTypeID = 28).

### Pattern 3 — Full lifecycle (every event for a position)
```sql
SELECT PositionID, ActionDate, ActionTypeID,
       MirrorID, MirrorTypeID, IsSettled, SettlementTypeID,
       OpenRate, CloseRate, Leverage, Amount
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE PositionID = 123456789
ORDER BY ActionDate;
```
Use when: forensics, customer complaint, breach investigation. Drop the partition filter only when you must — full-PositionID scans pay the partition price.

### Pattern 4 — Current state
```sql
SELECT PositionID, CID, InstrumentID,
       OpenRate, CloseRate, Leverage,
       MirrorID, MirrorTypeID,
       IsActiveTrade, SettlementTypeID,
       OpenDateID, CloseDateID
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position
WHERE PositionID = 123456789
  AND COALESCE(CloseDateID, 0) NOT IN (19000101);
```
Use when: "is it open now?", "current leverage / mirror linkage?". Caveat: mutable fields reflect *now*, not history. Always exclude `CloseDateID = 19000101` (transient ETL state).

### Pattern 5 — State AT ARBITRARY DATE Y
```sql
SELECT *
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog
WHERE PositionID = 123456789
  AND Occurred <= '2026-03-15 14:30:00'
  AND OccurredDateID BETWEEN 20260301 AND 20260316
ORDER BY Occurred DESC
LIMIT 1;
```
Use when: regulator query, retrospective audit. Slow. Authoritative. Watch the day-boundary DELETE+INSERT risk (Critical Warning 6).

### Pattern 6 — Enrich fact with dim for static metadata
```sql
SELECT f.PositionID, f.ActionDate, f.MirrorID,
       p.OpenRate, p.OpenDateID, p.OpenPositionReasonID
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics f
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position p
  ON f.PositionID = p.PositionID
WHERE f.PositionID = 123456789
  AND f.ActionTypeID IN (1, 2, 3, 39)
  AND f.etr_y >= '2024';
```
Use when: fact gives state-at-event; you want immutable metadata only on the dim (`OpenPositionReasonID`, `OpenDateID`).

### Pattern 7 — Copy-trades opened today (fact-only, no dim trap)
```sql
SELECT COUNT(*) AS copy_opens
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE ActionTypeID IN (1, 2, 3, 39)
  AND MirrorID > 0
  AND ActionDate >= CURRENT_DATE - 1
  AND etr_ymd = DATE_FORMAT(CURRENT_DATE - 1, 'yyyyMMdd');
```
Use when: "how many copy trades opened yesterday?". Uses the fact's MirrorID at open event. Do NOT use the dim.

---

## Deep `Dim_Position` gotchas (harvested from wiki)

UC table comments give the 1024-char summary. The full wiki (`knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md`, 653 lines, 134 columns) has gotchas no UC comment will surface:

1. **`CloseDateID = 19000101` is a transient ETL state, NOT closed.** During `SP_Dim_Position_DL_To_Synapse @dt`, closing positions are UPDATEd back to `CloseOccurred='1900-01-01', CloseDateID=19000101` before being re-inserted from staging. For confirmed-closed positions filter `CloseDateID NOT IN (0, 19000101)`.
2. **`OpenDateID` / `CloseDateID` are INT YYYYMMDD, NOT date.** `CAST(CAST(OpenDateID AS VARCHAR(8)) AS DATE)`. `CloseDateID = 0` means still open.
3. **`IsPartialCloseChild` filter is asymmetric.** Use `WHERE COALESCE(IsPartialCloseChild, 0) = 0` when aggregating **open-side** metrics (e.g., `Volume` is pro-rated for the child, excluding children would double-discount). NEVER filter children on **close-side** aggregations.
4. **`Volume` and `VolumeOnClose` are ETL `ROUND(...)` approximations.** Formula: `ROUND(AmountInUnitsDecimal * InitForexRate * USD_conversion, 0)`. For precise USD notional use `AmountInUnitsDecimal * InitForex_USDConversionRate`, not `Volume`.
5. **`RegulationIDOnOpen = 0` means "ETL JOIN to `etoro_History_BackOfficeCustomer` found nothing", not "no regulation".** Defaulted via `ISNULL(..., 0)`. Use `RegulationIDOnOpen > 0` to filter.
6. **`RegulationIDOnOpen` JOIN uses ETL-run-date, not position-open-date.** Per `Dim_Position.review-needed.md`: the BackOfficeCustomer history JOIN uses `c.ValidFrom < @CurrentDate AND c.ValidTo >= @CurrentDate` — i.e., the customer's regulation as of the ETL run, not at the position's actual open. Pending reviewer confirmation; treat as wrong-time-window risk.
7. **`UpdateDate` mixes `GETDATE()` (new inserts) and `GETUTCDATE()` (updates of closing positions).** Timezone discontinuity within the same column — not a reliable "data freshness" indicator.
8. **PK on `(PositionID, CloseDateID)` is NOT ENFORCED.** Synapse does not validate uniqueness; ETL bugs can produce duplicates. Don't assume globally-unique `PositionID` without de-dup.
9. **Late-added column NULL patterns.** Columns added after some positions were already loaded will be NULL for older positions: `OpenMarket_*`/`CloseMarket_*` (2023-03-07), `OpenMarkup`/`CloseMarkup`/`SpreadedCommission` (2024-01-15), `DLTOpen`/`DLTClose` (2024-06-02), `CommissionVersion` (2024-08-22), `OpenTotalTaxes`/`CloseTotalTaxes`/`OpenTotalFees`/`CloseTotalFees` (2025-06-25), `Close_CalculationRate`/`Close_ConversionRate`/`Close_PriceType` (2025-09-08).
10. **`HedgeID` is NULL until the hedge fires.** Don't `INNER JOIN` to `Trade.Hedge` if you want un-hedged positions.
11. **`SettlementTypeID` supersedes `IsSettled`.** Already covered above; reinforced here as a column-level gotcha.
12. **ETL has six supplementary staging joins.** `SP_Dim_Position_DL_To_Synapse @dt` reads from `etoro_History_BackOfficeCustomer` (regulation), `etoro_Trade_GetInstrument` (`IsSettled` logic), `etoro_History_PositionChangeLog` (`IsSettled` + `Amount` corrections), `etoro_Trade_PositionAirdropLog` (`IsAirDrop`), `PriceLog_History_CurrencyPrice_Active` (price book), `Ext_Dim_Position_FundCIDs` (`IsCopyFundPosition`). Reconciliation discrepancies usually trace to one of these six staging tables.

---

## Deep `Dim_PositionChangeLog` gotchas (harvested from wiki)

The change-log table (`knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PositionChangeLog.md`, 17 columns):

1. **Multiple rows per `(PositionID, OccurredDateID)`.** Many same-day events — particularly `ChangeTypeID = 12` (amount adjustments) which the `Dim_Position` ETL sums via `SUM(AmountChanged) GROUP BY PositionID`. Do NOT assume one row per position-day.
2. **`ChangeTypeID` is Tier 4 UNVERIFIED — no official lookup in DWH.** Values inferred from SP code:
   - `0` = Initial open event (used by `Dim_Position` ETL to detect first appearance for hedge-server snapshot)
   - `1` = Rate change (StopRate or LimitRate modification)
   - `2` = Unknown, seen in live data
   - `5` = Added 2024-04-30, unknown
   - `11` = Partial close related event
   - `12` = Amount adjustment (sum cumulatively for same-day mods)
   - `13` = Unknown
3. **Historical completeness gap.** Before **2025-01-05**, only `ChangeTypeID ∈ {1, 5, 11, 12, 13}` were loaded. Pre-2025-01-05 history for `ChangeTypeID ∈ {0, 2, …}` is **missing**.
4. **DELETE+INSERT ETL (not MERGE).** Already in Critical Warning 6 — late-arriving rows near day boundaries can be deleted.
5. **`AmountChanged = 0` is valid.** Can represent a StopRate/LimitRate-only change.
6. **`PreviousIsSettled` can be NULL.** If the change event did not involve settlement-status mutation, both `IsSettled` and `PreviousIsSettled` are NULL — filter explicitly when looking for settlement transitions.
7. **`PreviousStopRate` and `StopRate` NOT NULL, but `0.0` means "no stop set"** — not a real rate.

---

## `Fact_CustomerAction`-specific gotchas (harvested from wiki + reviewer corrections)

`Fact_CustomerAction` is the older parent fact (11 billion rows, 71 columns). `w_metrics` is its KPI-enriched downstream. Gotchas that apply when reaching for either:

1. **`PlatformID` is FK to `Dim_Product.ProductID`, NOT a login-platform enum.** Badly named. Resolve via `JOIN DWH_dbo.Dim_Product ON fca.PlatformID = dp.ProductID` for Product / Platform / SubPlatform. Never hard-code value mappings. Confirmed by reviewer Guy 2026-03-03.
2. **`HistoryID` has duplicates — NEVER use for joins/dedup/row identification.** Intended as a key, but ETL produces duplicates. Per reviewer Guy 2026-03-03.
3. **`Tagline` is "one row per event" — NOT "per customer per day".** The fact's grain is per-event; SP inserts individual rows. Per reviewer Guy.
4. **`IsBuy NULL` and `Leverage = 0` both mean non-position event.** For a position event, `IsBuy` is 1=Buy / 0=Sell, and `Leverage = 1` means "no leverage / real ownership", NOT "missing data".
5. **`IsReal` is hard-coded to 1 in this table.** No demo FCA table exists; demo actions are simply not tracked. Filtering `WHERE IsReal = 1` is redundant but harmless.
6. **`DemoCID` is always 0.** Same reason.
7. **`StatusID` is nearly always 1 (~11B rows); ~2M rows are NULL.** NULL meaning unverified (deleted? failed? legacy?).
8. **`Description` is sparse — only for fees (ActionTypeID=35) and a few others.** Don't rely on it for non-fee events.
9. **Reopen Commission Adjustment**: for reopened positions (`IsReOpen = 1`), `CommissionOnClose = new_position.CommissionOnClose − original_position.CommissionOnClose`; `CommissionOnCloseOrig` preserves the pre-adjustment value.
10. **~33 position-derived columns are duplicated in this fact from staging — NOT joined from `Dim_Position`.** Columns like `InstrumentID`, `Amount`, `Leverage`, `Commission`, `MirrorID`, `IsSettled`, etc. are populated from the same staging extract that feeds `Dim_Position`, so column meanings match — but they are independent column writes.

---

## Position-reason lookups (`Dim_Position.OpenPositionReasonID` / `ClosePositionReasonID`)

These are **separate** from the fact's `ActionTypeID` enumeration. They tell you the **reason** a position opened/closed:

| Field | Value | Meaning |
|---|---:|---|
| `OpenPositionReasonID` | 0 | Customer-initiated open (most common) |
| `OpenPositionReasonID` | 1 | Hierarchical Open — copy-trade child auto-opened |
| `OpenPositionReasonID` | 2 | Reopen — `IsReOpen = 1`, `ReopenForPositionID` points to the original |
| `OpenPositionReasonID` | 3 | Open Open — `IsOpenOpen = 1` copy behaviour |
| `OpenPositionReasonID` | 13 | ACATS_IN — incoming external account transfer |
| `ClosePositionReasonID` | 0 | Customer-initiated close |
| `ClosePositionReasonID` | 1 | Stop Loss triggered |
| `ClosePositionReasonID` | 5 | Take Profit triggered |
| `ClosePositionReasonID` | 9 | Hierarchical Close — copy-trade parent close cascaded |

Source: `SP_Dim_Position_DL_To_Synapse` mapping from production `ActionType` columns. The full `Dim_ClosePositionReason` dimension exists at `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason`.

---

## Mental model — pick a table

| Question shape | First reach for | Why |
|---|---|---|
| "Was this ever a copy?" | fact + ActionTypeID open | Mirror state at open event |
| "Currently linked to a mirror?" | dim | Current state, mutable |
| "Realized PnL on close?" | fact + ActionTypeID close | Close event has CloseRate/NetProfit |
| "OpenRate?" | dim (or fact open event) | Immutable |
| "Current Leverage?" | dim | Can change; dim is current |
| "Leverage at open?" | fact + ActionTypeID open | Captured at open event |
| "How many open right now?" | dim, `IsActiveTrade = 1` | Snapshot; dim canonical for "now" |
| "How many open as of last Friday?" | events stream OR `Dim_PositionChangeLog` | Point-in-time |
| "Lifecycle of position X" | fact, ORDER BY ActionDate | Full event sequence |
| "Why is OrderID NULL?" | `Trade.PositionTbl` wiki + dim `OpenPositionReasonID` | Corp action / dividend / transfer per wiki |

---

## Why this rule matters

Every analytical mistake on this team that started "the answer feels wrong on stale positions" traces back to querying `Dim_Position` for a field that has mutated. The dim is a brilliant catalog — but **current-state catalog**, not history. The fact is history. The change-log is point-in-time history with timestamps.

If you remember nothing else: **fact wins for everything transactional**, dim is for enrichment with non-mutating metadata, and `Dim_PositionChangeLog` is the escape hatch for forensics.

## Cross-references

- Instrument filter rules → `instruments-and-asset-classes.md`
- Volume aggregates → `trading-volumes.md`
- AUM / PnL aggregates → `portfolio-value-aum-pnl.md`
- Per-position revenue / fees → `../domain-revenue-and-fees/SKILL.md` (join by `PositionID` / `ActionID`)
- Copy-trade economics, Popular Investor compensation → `copy-trading-and-mirror.md` *(pending dealing-analyst skill)*
- Execution forensics on a single position → `dealing-investigation-and-execution.md`

## Deeper reading — authoritative sources

This skill summarizes and routes. For full column-level reference, ETL SP source, daily refresh logic, and tier confidence:

- `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md` — 653 lines, source of every Dim_Position gotcha above. ETL: `SP_Dim_Position_DL_To_Synapse @dt`. 134 columns in 26 groups.
- `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.lineage.md` — column-by-column lineage `etoroDB-REAL → Bronze → DWH_staging → Dim_Position → UC`.
- `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.review-needed.md` — author-flagged uncertainty; source of the `RegulationIDOnOpen` time-window gotcha.
- `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md` — 407 lines, source of the canonical ActionTypeID map and the `~33 position-derived columns` rule.
- `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.review-needed.md` — reviewer Guy's corrections (PlatformID, HistoryID, social engagement dead data, etc.).
- `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PositionChangeLog.md` — 238 lines, source of the DELETE+INSERT late-arrival gotcha.
- `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionTbl.md` — 407 lines, OLTP truth. Source of the `OrderID` NULL rule, `IsSettled` legacy semantics, `MirrorID NULL` handling.
- `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Stored Procedures/Trade.DetachPositionsFromMirror.md` — the SP that mutates `MirrorID` post-detachment (the trap).

**Doctrine for this skill family:** skills route, wikis explain. When a question goes past the gotchas captured here, drill to the wiki for the column-by-column ground truth.

---

## Sources Consulted (per `/speckit.skill` Phase 2.5)

Per-anchor reach record. `Class`: S = Synapse-first, L = Lake-first, H = Hybrid.

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| main.dwh.gold_..._dim_position | S | 1a | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md | 134-col reference; all 12 Dim_Position gotchas in this skill |
| main.dwh.gold_..._dim_position | S | 1a | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.review-needed.md | RegulationIDOnOpen wrong-time-window risk; partition column anomaly |
| main.dwh.gold_..._dim_position | S | 2 | knowledge/ProdSchemas/.../Trade/Tables/Trade.PositionTbl.md | OLTP truth: OrderID NULL rule, IsSettled is legacy, MirrorID NULL handling |
| main.dwh.gold_..._fact_customeraction | S | 1a | knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md | Canonical ActionTypeID names (replaces my pre-2026-05 broken map); 33-column duplication rule |
| main.dwh.gold_..._fact_customeraction | S | 1a | knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.review-needed.md | Reviewer Guy 2026-03-03 corrections (PlatformID, HistoryID, social-engagement dead data, Tagline grain) |
| main.dwh.gold_..._dim_positionchangelog | S | 1a | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PositionChangeLog.md | 17-col reference; ChangeTypeID Tier 4 unverified note |
| main.dwh.gold_..._dim_positionchangelog | S | 1a | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PositionChangeLog.review-needed.md | DELETE+INSERT late-arrival gotcha |
| main.de_output..._w_metrics | H | 1b | UC `information_schema.columns` 2026-05-11 | **PositionID.comment and IsCopyFund.comment misattributed** — flagged in Critical Warning 4 |
| main.de_output..._w_metrics | H | 1b | UC column `Leverage.comment` | Gross notional formula `Amount × Leverage` |
| main.trading.bronze_..._trade_position_datafactory | L | 1a | UC `information_schema.tables.comment` | Tier-1 wiki-derived description (Generic Pipeline, 60-min refresh) |
| main.trading.bronze_..._trade_position_datafactory | L | 1b | UC `information_schema.columns` | Mostly empty; only PositionID + CID carry Tier-1 text |
| main.trading.bronze_..._history_position_datafactory | L | 1b | UC `information_schema.columns` | `MirrorID.comment` confirms post-detachment value reflects "still active copy"; `OrderID.comment` confirms NULL = no order link |

---
