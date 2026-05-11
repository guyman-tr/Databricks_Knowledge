---
id: position-state-and-grain
name: "Position State, Grain & Lifecycle"
description: "The trading-platform position lifecycle, what every table holds at what grain, and the fact-vs-dim rule. Anchored on the granular `fact_customeraction_w_metrics` (state-at-event-time, authoritative for transactional questions) and `Dim_Position` (metadata only, never trust for state). Includes the `ActionTypeID` map, the IsBuy/IsSettled/IsActiveTrade semantics, the MirrorID-at-open trap, and how to recreate position state at an arbitrary date via `PositionChangeLog`. Read FIRST for any position-state, copy-detection, or lifecycle question."
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
  - IsActiveTrade
  - IsSettled
  - SettlementTypeID
  - MirrorID at open
  - open rate
  - close rate
  - Leverage
  - partial close
  - position history
  - recreate position state
required_tables:
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Position State, Grain & Lifecycle

A position is not "what `Dim_Position` says about it right now". A position is a **lifecycle**: opened at one rate, possibly modified (partial close, leverage change, mirror attach/detach), eventually closed at another rate. Each mutation throws off an action event. The events are the truth; the dim is the latest snapshot of mutable metadata.

This sub-skill is the **first stop** for any position-state question. The rule it teaches — *prefer the fact, use the dim for static metadata enrichment only* — applies across the rest of `domain-trading`.

## When to Use

Load when the question is about:

- "What was position X's state when it opened?" / "at close?" / "right now?" / "on date Y?"
- "Was this position opened as a copy / mirror?", "what mirror was it under at open?"
- "What's the lifecycle of position X?" — every event, in order
- "What's the difference between `fact_customeraction_w_metrics` and `Dim_Position`?"
- "How do I recreate position state at an arbitrary date?"
- "What's the grain of `fact_customeraction_w_metrics`?", "how many rows per position?"
- "Why does `Dim_Position.MirrorID = 0` but the position was clearly a copy?"

Do **not** load for:

- Filtering by instrument / ticker → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- Aggregated trading volume → [`trading-volumes.md`](trading-volumes.md)
- AUM / PnL snapshots → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Copy / mirror economics (PI compensation, copy fund commission) → `copy-trading-and-mirror.md` *(pending dealing-analyst skill)*

## Scope

In scope: the granular fact table `fact_customeraction_w_metrics` (purpose, grain, key columns, partition strategy), the `Dim_Position` master record (what it is reliable for vs not), the `ActionTypeID` reference map (opens, closes, fees, modifications), the `IsBuy` / `IsSettled` / `SettlementTypeID` / `IsActiveTrade` / `MirrorID` / `MirrorTypeID` semantics with the at-event-time vs current-state distinction, `PositionChangeLog` as the point-in-time replay table, query patterns for state-at-open / state-at-close / state-on-date / current-state.
Out of scope: instrument filter logic (separate sub-skill), volume / AUM / PnL aggregates (separate sub-skills), revenue per position (Revenue & Fees super-domain), copy-fund / Smart Portfolio / Popular Investor economics (separate sub-skill).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `Dim_Position` is metadata, not state. Reach for the FACT first.** `Dim_Position` has ~75 columns including `MirrorID`, `MirrorTypeID`, `IsActiveTrade`, `SettlementTypeID`, `IsSettled`. **These columns are mutable.** When a customer detaches their position from a Smart Portfolio, `Dim_Position.MirrorID` flips to `0`. If you query the dim to answer "was this opened as a copy?", you'll get a silent wrong answer. Always use `fact_customeraction_w_metrics` filtered to the **opening** `ActionTypeID` (1, 2, 3, or 39) to get the value at open. Use the dim only for fields that don't change (instrument metadata at open, the `OpenRate`, the `Leverage` if not modified, `OpenDateID`, identity columns like `PositionID` and `CID`).
2. **Tier 1 — The fact's grain is ONE ROW PER ACTION EVENT, not one row per position.** A single `PositionID` will appear multiple times in `fact_customeraction_w_metrics` — once for open, possibly several times for modifications, and once or more for close (partial close splits into one row per slice). If you write `SELECT * FROM fact_customeraction_w_metrics WHERE PositionID = X` you'll get the whole lifecycle. For state-at-event-time, filter by `ActionTypeID`. For state-now, take the most recent event by `ActionDate`.
3. **Tier 2 — `PositionChangeLog` is the ONLY deterministic point-in-time source for arbitrary dates.** The fact captures *events*; the change log captures *every mutation with timestamps*. When you need "what was position X on 2026-03-15 at 14:30?" — only `PositionChangeLog` can answer. Don't reach for it for the common cases (state at open, state at close, current state) — the fact covers those and is far faster. Use it for forensics, regulator queries, and breach investigations.
4. **Tier 3 — Partial closes split the position; sum carefully.** A `$1000` position partially closed `$300` produces a close-event row for `$300` AND a remaining-open event. The volumes fact handles this by zeroing `VolumeOpen` on the remainder. In `fact_customeraction_w_metrics` you'll see two rows: the partial close action and the residual open. When counting "positions closed today", be aware that partial closes count as close events but the position is still alive.
5. **Tier 3 — `IsActiveTrade` is current-state on the dim and at-event-time on the fact.** Asking "was this position active at open?" doesn't make sense — it WAS active because it was just opened. Asking "is this position active now?" — use `Dim_Position.IsActiveTrade` (current). Asking "was this position still active on date Y?" — use `PositionChangeLog` or compute from the events stream (max ActionDate ≤ Y AND no close event before Y).

## Tables

| Table | Use For |
|---|---|
| `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | **PRIMARY** — granular per-event state. State-at-event-time, fastest source, the fact for all transactional questions. ~billions of rows; partitioned. |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position` | Position metadata master. `OpenRate`, `Leverage` (often), `OpenDateID`, fill prices, spread snapshots at open. Mutable fields (`MirrorID`, `MirrorTypeID`, `IsActiveTrade`, current `CloseRate`) — DO NOT trust for at-event-time. |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Older / less enriched granular fact. `fact_customeraction_w_metrics` supersedes it for most queries — use this only when you need a column the metrics-fact doesn't have. |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_positionchangelog` *(or `main.trade.positionchangelog` mirror)* | Point-in-time change-log. Every mutation, every timestamp. Rare use, deterministic. |

---

## Core Concepts

### Position lifecycle

```
[Customer clicks Buy]
        │
        ▼
   ActionTypeID ∈ {1, 2, 3, 39}    ← OPEN events
        │  ← Dim_Position created at open
        │  ← fact_customeraction_w_metrics row created with state-AT-OPEN
        │
        ▼
   ActionTypeID ∈ {modify events}  ← optional intermediate events (leverage change, SL/TP, mirror change)
        │  ← Dim_Position updated (mutable fields overwritten)
        │  ← fact_customeraction_w_metrics row appended (state captured at modify time)
        │
        ▼
   ActionTypeID ∈ {4, 5, 6, 28, 40} ← CLOSE events (full or partial)
        │  ← Dim_Position.IsActiveTrade ← 0, CloseDateID populated
        │  ← fact_customeraction_w_metrics row(s) appended for the close
```

### ActionTypeID map (the canonical reference)

| ActionTypeID | Meaning | Notes |
|---|---|---|
| 1 | Position Open — manual | Customer manually opened |
| 2 | Position Open — copied | Mirror copy auto-opened (`MirrorID > 0` at this event) |
| 3 | Position Open — Smart Portfolio | Copy fund (`MirrorTypeID = 4`) |
| 39 | Position Open — other (e.g. IBAN auto-trade) | Less common opening pathway |
| 4 | Position Close — manual | Customer manually closed |
| 5 | Position Close — auto (TP/SL/Margin call) | Take-profit, stop-loss, margin-call |
| 6 | Position Close — system | Automated system close |
| 28 | Position Close — partial | Partial close (residual position remains) |
| 40 | Position Close — other (rollover, settlement) | Settlement-driven close |
| 30 | Cashout / Withdraw | Money-out, NOT a position event — routes to `domain-payments` |
| 35 | Fee / Dividend (use `IsFeeDividend` to subdivide) | NOT a position event — routes to `domain-revenue-and-fees` |
| 36 | Compensation / Admin (use `CompensationReasonID` to subdivide) | Same as above |

To find every OPEN event for a position: `WHERE ActionTypeID IN (1, 2, 3, 39) AND PositionID = X` (there should be exactly one).
To find every CLOSE event: `WHERE ActionTypeID IN (4, 5, 6, 28, 40) AND PositionID = X` (one or more — partial closes can stack).

### Settlement type (`SettlementTypeID`)

| SettlementTypeID | Meaning | Common `IsSettled` value |
|---|---|---|
| 0 | CFD | 0 |
| 1 | Real asset | 1 |
| 2 | TRS (Total Return Swap) | 0 |
| 3 | CMT (Crypto settled, eToro custody) | 1 (real) |
| 4 | Real Futures | 1 |
| 5 | Margin Trade | 0 (variable) |

`IsSettled = 1` means "the customer owns the underlying" (real stock, real crypto, real futures). `IsSettled = 0` means CFD / derivative / margin product. The `Dim_Position` carries the FALLBACK formula `IsBuy = 1 AND Leverage = 1 AND TypeID IN (10, 5, 6)` when `SettlementTypeID` is null on older rows.

### Mirror / copy semantics — THE classic trap

| Field | What it means at OPEN | What it means CURRENTLY (on the dim) |
|---|---|---|
| `MirrorID` | The mirror this position copied at the moment of open. `0` if not a copy. | The mirror this position is *currently* attached to. `0` if it ever detached (Smart Portfolio stopped, customer kept the position). |
| `MirrorTypeID` | 4 = Smart Portfolio (copy fund); other values = manual copy variations. Set at open. | Same field, updated to `0` or another value if relationship changed. |
| `IsCopy` (fact) / derived | `MirrorID > 0` at the OPEN event ⇒ this was a copy trade | Not a reliable copy-trade flag on the dim — see Critical Warning #1 |
| `IsCopyFund` (fact) / derived | `MirrorTypeID = 4` at the OPEN event ⇒ this was a Smart Portfolio fund position | Same caveat — current-state, can be `0` |

**The example from production**: a customer opens a position as part of a Smart Portfolio (Mr. PI XYZ). Six months later they "Stop Copying Mr. PI XYZ but keep the positions". `Dim_Position.MirrorID` flips to `0` for those positions. If your query is `SELECT IsCopy = (MirrorID > 0) FROM Dim_Position`, you get **wrong "no, never was a copy"**. The fact stays correct: the OPEN event has `MirrorID = <Mr. PI's mirror>`.

### `IsActiveTrade`

- On `fact_customeraction_w_metrics`: typically captured per event — at the open event it's 1, at the close event(s) it flips.
- On `Dim_Position`: 1 = currently open; 0 = closed. **Current state.**

For "is this position open right now?" — the dim is fine. For "was this position open as of yesterday?" — compute from events (max `ActionDate` ≤ yesterday AND no close event by that date) or use `PositionChangeLog` for a precise timestamp.

---

## Query Patterns

### Pattern 1 — State AT OPEN (the most common case)
```sql
SELECT PositionID, CID, ActionDate, ActionTypeID,
       InstrumentID, IsBuy, Units, Amount, OpenRate, Leverage,
       MirrorID, MirrorTypeID, IsSettled, SettlementTypeID
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE PositionID = 123456789
  AND ActionTypeID IN (1, 2, 3, 39)
ORDER BY ActionDate;
```
**Use when:** "what mirror was position X under at open?", "was it a copy?", "what was the leverage at open?"

### Pattern 2 — State AT CLOSE (or every close event for partial closes)
```sql
SELECT PositionID, CID, ActionDate, ActionTypeID,
       CloseRate, NetProfit, ClosedUnits, ClosedAmount,
       IsSettled, SettlementTypeID
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE PositionID = 123456789
  AND ActionTypeID IN (4, 5, 6, 28, 40)
ORDER BY ActionDate;
```
**Use when:** "what was the realized PnL on position X?", "did this position get auto-closed by TP/SL?"

### Pattern 3 — Full lifecycle (every event for a position)
```sql
SELECT PositionID, ActionDate, ActionTypeID, ActionTypeName,
       MirrorID, MirrorTypeID, IsSettled,
       OpenRate, CloseRate, Leverage, Units, Amount
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE PositionID = 123456789
ORDER BY ActionDate;
```
**Use when:** "show me everything that happened to position X", forensics, breach investigation, customer complaint.

### Pattern 4 — Current state (when current is what you want)
```sql
SELECT PositionID, CID, InstrumentID,
       OpenRate, CloseRate, Leverage,
       MirrorID, MirrorTypeID,
       IsActiveTrade, SettlementTypeID,
       OpenDateID, CloseDateID
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position
WHERE PositionID = 123456789;
```
**Use when:** "is this position open now?", "what's the current leverage / mirror linkage?". Caveat: the mutable fields (MirrorID, MirrorTypeID, IsActiveTrade) reflect *now*, not history.

### Pattern 5 — State AT ARBITRARY DATE Y (the slow but deterministic answer)
```sql
SELECT *
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_positionchangelog
WHERE PositionID = 123456789
  AND ChangeDate <= '2026-03-15 14:30:00'
ORDER BY ChangeDate DESC
LIMIT 1;
```
**Use when:** "what was position X's state on March 15?", regulator queries, retrospective audit. Rare. Slow. Authoritative.

### Pattern 6 — Enrich fact with dim for static metadata
```sql
SELECT f.PositionID, f.ActionDate, f.MirrorID,
       i.Symbol, i.InstrumentTypeID,
       p.OpenRate, p.OpenDateID,
       i.IsSettled AS instrument_is_settled_metadata
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics f
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position p
  ON f.PositionID = p.PositionID
LEFT JOIN main.etoro_kpi_prep.v_dim_instrument_enriched i
  ON f.InstrumentID = i.InstrumentID AND i.InstrumentTypeID = 5
WHERE f.PositionID = 123456789
  AND f.ActionTypeID IN (1, 2, 3, 39);
```
**Use when:** the fact gives you the state-at-event, and you want to add slow-moving metadata (instrument industry, exchange, fill spread) that lives only on the dim or the enriched instrument view.

### Pattern 7 — How many copy-trades opened today (the fact-only version)
```sql
SELECT COUNT(*) AS copy_opens
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE ActionTypeID IN (1, 2, 3, 39)
  AND MirrorID > 0
  AND ActionDate >= CURRENT_DATE - 1;
```
**Use when:** "how many copy trades opened yesterday?". Uses the fact, MirrorID at the open event. Do NOT use the dim — see Critical Warning #1.

---

## Mental model — pick a table

| Question shape | First reach for | Why |
|---|---|---|
| "Was this position ever a copy?" | fact + ActionTypeID open | Mirror state at open event |
| "Is this position currently linked to a mirror?" | dim | Current state, mutable |
| "What was the realized PnL on this close?" | fact + ActionTypeID close | Close event captures CloseRate/NetProfit |
| "What's the OpenRate?" | dim (or fact open event) | Immutable for the position |
| "What's the current Leverage?" | dim | Can change over life, dim is current |
| "What was leverage at open?" | fact + ActionTypeID open | Event captured at open |
| "How many positions are open right now?" | dim, `IsActiveTrade = 1` | Snapshot question; dim is canonical for "now" |
| "How many positions were open as of last Friday?" | events stream OR PositionChangeLog | Point-in-time — dim cannot tell you yesterday |
| "What did the operator do on position X last week?" | fact (or `Fact_CustomerAction`) | Audit trail of events |
| "Lifecycle of position X" | fact, ORDER BY ActionDate | Full event sequence |

---

## Why this rule matters

Every analytical mistake on this team that involved "the answer feels wrong on stale positions" traces back to querying `Dim_Position` for a field that has mutated. The dim is a brilliant catalog — but it is **current-state catalog**, not history. The fact is history. The change-log is point-in-time history with timestamps.

If you remember nothing else from this skill: **the fact wins for everything transactional**, the dim is for enrichment with non-mutating metadata, and `PositionChangeLog` is the escape hatch for forensics.

## Cross-references

- Instrument filter rules → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- Volume aggregates → [`trading-volumes.md`](trading-volumes.md)
- AUM / PnL aggregates → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Per-position revenue / fees → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md) — join by `PositionID` / `ActionID`
- Copy-trade economics, Popular Investor compensation → `copy-trading-and-mirror.md` *(pending dealing-analyst skill)*
- Execution forensics on a single position → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
