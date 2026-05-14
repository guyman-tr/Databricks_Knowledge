# Dealing_dbo.Dealing_Best_Execution_Compensation_CBH_HOLD

> **Decommissioned May 2023** — frozen HOLD snapshot of **position-level best-execution compensation** analysis for the **CBH** LP routing context (**Citadel → BofA → HSBC** order); retains policy caps, LP rates, spread, and paid compensation amounts for historical MiFID II audit.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | N/A — frozen snapshot; writer SP not in current SSDT (slippage + LP enrichment inferred) |
| **Refresh** | Frozen — decommissioned |
| | |
| **Synapse Distribution** | HASH(`CID`) |
| **Synapse Index** | CLUSTERED INDEX (`Date` ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dealing_Best_Execution_Compensation_CBH_HOLD` extends the **slippage-at-position** grain with **best-execution compensation** fields: **`Compensation_Limit`** (policy maximum), **`Compensation`** (amount attributed to the position), **`LP_Rate`**, **`Spread`**, and **`Percent_Diff`** between the **client’s expected rate** and the **LP execution rate**. It answers: *for this routed execution, did we exceed slippage tolerance, what did the LP actually print, and what compensation does policy allow / assign?*

**CBH routing (documentation convention for this wiki)**: **Citadel / BofA / HSBC** LP routing ordering — contrast with **`Dealing_Best_Execution_Compensation_HBC_HOLD`**, the structurally parallel table for **HSBC / BofA / Citadel** ordering (see Relationships).

The table was frozen in **May 2023** (last business date **2023-05-16**, last load **2023-05-17**). The active (non-HOLD) sibling **`Dealing_Best_Execution_Compensation_CBH`** was later documented as decommissioned (**Jan 2025** in platform notes), implying the **whole compensation pipeline family** was retired over time — this HOLD file captures the **archived** CBH slice.

**Scale (frozen)**: on the order of **~10.2M rows** for **2022-06-01 → 2023-05-16**. **PII**: `CID` is the hash-distribution key. **HASH(`CID`)** (vs **ROUND_ROBIN** on some other HOLD slippage tables) suggests this table was tuned for **client-centric** joins and reporting before freeze.

---

## 2. Business Logic

### 2.1 Compensation vs slippage

- **`SlippageInDollar`** and **`[slippage %]`** carry forward the **client slippage** story from the slippage-position lineage.
- **`LP_Rate`**: liquidity-provider **execution rate** observed for the analysis.
- **`Spread`**: **ask minus bid** (or equivalent spread measure) at execution within this routing context.
- **`Percent_Diff`**: percentage gap between **`CustomerChosenRate`** (or client-expected basis) and **`LP_Rate`** — used to evidence **best execution** deviation.
- **`Compensation_Limit`**: **cap** per position under policy (maximum payable even if raw slippage is larger).
- **`Compensation`**: **actual** compensation amount calculated for the position; **`0`** when **`OverThreshold = 0`** (pattern inferred from column semantics; validate on samples).

### 2.2 Eligibility and thresholds

- **`OverThreshold`**: flags rows where slippage exceeded **internal / regulatory** thresholds — primary population for **compensation workflows**.
- **`IsDiscounted`**: indicates whether the position received a **discounted** rate pathway.

### 2.3 Rates and timestamps

- **`ClientViewRate` / `CustomerChosenRate`**: UI vs accepted client pricing.
- **`Bid` / `Ask`**: LP **top-of-book** at execution time.
- **`Occurred` / `OccurredAtServer` / `FinalOccurred`**: execution and server receipt times; **FinalOccurred** captures **delayed** or **finalised** execution timing when it differs from first touch.
- **`PriceRateID`**: ties to the **price feed** rate record used in the calculation chain.

### 2.4 Routing and accounts

- **`HedgingMode`**: **A / B / C** style LP hedging mode.
- **`LiquidityAccountID` / `LiquidityAccountName`**: **sub-account** within the **CBH** routing context (venue / account slice).

### 2.5 ETL

- **`UpdateDate`**: last ETL touch for the row (no active pipeline).

---

## 3. Query Advisory

### 3.1 Distribution and indexing

- **HASH(`CID`)**: filters on **`CID`** are **distribution-aligned** — efficient for **single-client** deep dives. Avoid broadcasting huge dimension tables without predicates.
- **Clustered index on `Date`**: always constrain **`Date`** or a **bounded range** first for **ad hoc** scans; the table is **multi-million** rows.

### 3.2 Analytical patterns

| Question | Pattern |
|----------|---------|
| Policy exposure on a day | `WHERE Date = @d` and aggregate `Compensation`, `Compensation_Limit` |
| Clients over threshold | `WHERE OverThreshold = 1 AND Date BETWEEN …` |
| LP vs client rate gap | Compare `LP_Rate` to `CustomerChosenRate` with `Percent_Diff` |

### 3.3 Joins

- **`InstrumentID`** → `DWH_dbo.Dim_Instrument`.
- **`CID`** → customer dimensions (**PII**).

### 3.4 Gotchas

- **Decommissioned** — do not use for **current** compensation accrual.
- Bracket **`[slippage %]`** in SQL.
- **Pair with HBC_HOLD** when reconciling **routing variants** (volume differs materially — see HBC wiki).

---

## 4. Elements

### Confidence Tier Legend

> Tier tags for this **decommissioned** object come from **DDL** and **structural match** to the non-HOLD CBH compensation table — **not** from a live traced writer SP in repo.

| Stars | Tier | Inline tag (in Description) |
|-------|------|------------------------------|
| ★★★★ | Tier 1 — upstream wiki | `(Tier 1 — upstream wiki, …)` |
| ★★★ | Tier 2 — structure / DDL | `(Tier 2 — inferred from structure)` or `(Tier 2 — DDL)` |
| ★★ | Tier 3 — live data | `(Tier 3 — live data)` |
| ★ | Tier 4 — inferred | `(Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date of the execution / compensation analysis row. (Tier 2 — inferred from structure) |
| 2 | PositionID | bigint | YES | Trade position identifier; joins to production `PositionTbl` pattern. (Tier 2 — inferred from structure) |
| 3 | CID | int | YES | **Customer ID** — **PII**; **HASH** distribution key. (Tier 2 — inferred from structure) |
| 4 | InstrumentID | int | YES | Instrument key; join `DWH_dbo.Dim_Instrument`. (Tier 2 — inferred from structure) |
| 5 | InstrumentName | varchar(50) | YES | Display name. (Tier 2 — inferred from structure) |
| 6 | InstrumentTypeID | int | YES | Type code (e.g. 1=Currencies, 2=Commodities, 5=Stocks). (Tier 2 — inferred from structure) |
| 7 | InstrumentType | varchar(50) | YES | Type label. (Tier 2 — inferred from structure) |
| 8 | HedgeServerID | int | YES | Hedge server routing identifier. (Tier 2 — inferred from structure) |
| 9 | MirrorID | int | YES | Copy / mirror id; **0** = not copy. (Tier 2 — inferred from structure) |
| 10 | IsBuy | int | YES | **1** buy / **0** sell after reversals. (Tier 2 — inferred from structure) |
| 11 | OrigIsBuy | int | YES | Original direction before reversals. (Tier 2 — inferred from structure) |
| 12 | ExecutionAmountInUnits | decimal(16,8) | YES | LP executed units (8 dp). (Tier 2 — inferred from structure) |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | Position-record units (6 dp). (Tier 2 — inferred from structure) |
| 14 | Occurred | datetime | YES | Execution timestamp. (Tier 2 — inferred from structure) |
| 15 | EndForexRate | decimal(16,8) | YES | FX rate at execution. (Tier 2 — inferred from structure) |
| 16 | ConversionRate | decimal(16,8) | YES | Conversion to **USD** for monetary measures. (Tier 2 — inferred from structure) |
| 17 | ActionTypeID | int | YES | Open / close / SL / TP codes. (Tier 2 — inferred from structure) |
| 18 | ActionType | varchar(50) | YES | Action label. (Tier 2 — inferred from structure) |
| 19 | IsOpen | int | YES | Open vs closed position flag. (Tier 2 — inferred from structure) |
| 20 | Bid | float | YES | LP **bid** at execution. (Tier 2 — inferred from structure) |
| 21 | Ask | float | YES | LP **ask** at execution. (Tier 2 — inferred from structure) |
| 22 | OccurredAtServer | datetime | YES | Server receipt time (may differ from `Occurred`). (Tier 2 — inferred from structure) |
| 23 | StopRate | decimal(16,8) | YES | Stop-loss rate. (Tier 2 — inferred from structure) |
| 24 | LimitRate | decimal(16,8) | YES | Take-profit rate. (Tier 2 — inferred from structure) |
| 25 | ClientViewRate | numeric(16,8) | YES | UI-shown rate at submission. (Tier 2 — inferred from structure) |
| 26 | CustomerChosenRate | decimal(16,8) | YES | Client-accepted rate. (Tier 2 — inferred from structure) |
| 27 | SlippageInDollar | money | YES | Slippage **USD** magnitude. (Tier 2 — inferred from structure) |
| 28 | slippage % | decimal(38,21) | YES | Slippage **percent**; bracket name in SQL. (Tier 2 — inferred from structure) |
| 29 | RequestTime | datetime | YES | Client request timestamp. (Tier 2 — inferred from structure) |
| 30 | OverThreshold | tinyint | YES | **1** = beyond slippage threshold. (Tier 2 — inferred from structure) |
| 31 | OpenSession | int | YES | Session code at open. (Tier 2 — inferred from structure) |
| 32 | Volume | int | YES | Trade volume. (Tier 2 — inferred from structure) |
| 33 | Regulation | varchar(50) | YES | Regulatory framework label. (Tier 2 — inferred from structure) |
| 34 | TriggerRate | decimal(16,8) | YES | Stop/limit trigger rate. (Tier 2 — inferred from structure) |
| 35 | ChosenToTrigger | money | YES | Chosen → trigger slippage component. (Tier 2 — inferred from structure) |
| 36 | TriggerToReceived | money | YES | Trigger → executed slippage component. (Tier 2 — inferred from structure) |
| 37 | IsDiscounted | int | YES | **1** if discounted-rate path applied. (Tier 2 — inferred from structure) |
| 38 | PriceRateID | bigint | YES | Price-feed rate record id. (Tier 2 — inferred from structure) |
| 39 | FinalOccurred | datetime | YES | Final execution timestamp when delayed fills exist. (Tier 2 — inferred from structure) |
| 40 | HedgingMode | varchar(10) | YES | Hedging mode **A/B/C**. (Tier 2 — inferred from structure) |
| 41 | LiquidityAccountID | int | YES | **CBH** LP sub-account id. (Tier 2 — inferred from structure) |
| 42 | LiquidityAccountName | varchar(50) | YES | **CBH** LP sub-account / venue label. (Tier 2 — inferred from structure) |
| 43 | Spread | decimal(16,6) | YES | Spread at execution (**ask − bid** semantics). (Tier 2 — inferred from structure) |
| 44 | LP_Rate | float | YES | **LP execution rate** achieved. (Tier 2 — inferred from structure) |
| 45 | Percent_Diff | float | YES | Percentage difference **client expected vs LP** (`LP_Rate` vs chosen/view basis). (Tier 2 — inferred from structure) |
| 46 | Compensation_Limit | decimal(16,6) | YES | **Maximum** compensation payable for this position under policy. (Tier 2 — inferred from structure) |
| 47 | Compensation | decimal(16,6) | YES | **Actual** compensation assigned (**0** when not eligible — pattern inferred). (Tier 2 — inferred from structure) |
| 48 | UpdateDate | datetime | YES | ETL last-update timestamp. (Tier 4 — inferred) |

---

## 5. Lineage

Frozen **HOLD** table — **no active writer** in SSDT. Full narrative, ETL chain sketch, and notes are in:

- **`Dealing_Best_Execution_Compensation_CBH_HOLD.lineage.md`**

**Summary**: inferred enrichment of **slippage-position**-style rows with **LP quotes** and **compensation math** for the **CBH** routing slice; exact upstream tables are **not** Generic-Pipeline-mapped.

---

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_Best_Execution_Compensation_HBC_HOLD` | **Parallel schema**, **HBC** routing (**HSBC / BofA / Citadel** ordering); **~49K** rows vs **~10.2M** here — compare when analysing routing mix. |
| `Dealing_dbo.Dealing_Best_Execution_Compensation_CBH` | Non-HOLD **CBH** companion (later decommissioned per platform notes). |
| `Dealing_dbo.Daily_Slippage_Positions_HOLD` | **Upstream slippage** context (client slippage HOLD table, Jun 2023 freeze). |
| `DWH_dbo.Dim_Instrument` | Instrument attributes. |

---

## 7. Sample Queries

```sql
-- Daily compensation totals and limit headroom (CBH HOLD)
SELECT Date,
       SUM(CAST(Compensation AS decimal(18,4))) AS TotalCompensation,
       SUM(CAST(Compensation_Limit AS decimal(18,4))) AS TotalLimit
FROM Dealing_dbo.Dealing_Best_Execution_Compensation_CBH_HOLD
WHERE Date BETWEEN '2023-05-01' AND '2023-05-16'
GROUP BY Date
ORDER BY Date;
```

```sql
-- Threshold population with LP delta (sample)
SELECT TOP 1000 PositionID, CID, LP_Rate, CustomerChosenRate, Percent_Diff,
       Compensation, Compensation_Limit, OverThreshold
FROM Dealing_dbo.Dealing_Best_Execution_Compensation_CBH_HOLD
WHERE Date = '2023-05-16' AND OverThreshold = 1
ORDER BY ABS(CAST(SlippageInDollar AS float)) DESC;
```

```sql
-- Contrast CBH vs HBC row volumes by month (routing penetration)
SELECT 'CBH_HOLD' AS Variant, COUNT(*) AS Cnt
FROM Dealing_dbo.Dealing_Best_Execution_Compensation_CBH_HOLD
WHERE Date >= '2022-06-01'
UNION ALL
SELECT 'HBC_HOLD', COUNT(*)
FROM Dealing_dbo.Dealing_Best_Execution_Compensation_HBC_HOLD
WHERE Date >= '2022-06-01';
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 5.5/10 (★★★☆☆) | Batch: 7 (redo)*

*Tiers: 0 T1, 47 T2, 0 T3, 1 T4 | Elements: 5.5/10, Logic: 5.5/10, Relationships: 6/10, Sources: 3/10*

*Object: Dealing_dbo.Dealing_Best_Execution_Compensation_CBH_HOLD | Type: Table | Production Source: N/A (decommissioned)*
