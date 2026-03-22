# Dealing_dbo.Daily_Slippage_Positions_HOLD

> **Decommissioned Jun 2023** — frozen HOLD snapshot of daily **client-facing** slippage per executed position (execution quality vs expected rate), retained for historical MiFID II / ESMA best-execution audit; do not use for current operations.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | N/A — frozen snapshot; writer SP not present in current SSDT (LP execution / position data inferred from structure) |
| **Refresh** | Frozen — decommissioned |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (`Date` ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Daily_Slippage_Positions_HOLD` is an **archived (HOLD)** table that stores one row per **position-level** execution context on a given **business date**, capturing how far the **rate the client saw or chose** diverged from the **rate implied by actual execution** (via `EndForexRate` and related fields). Slippage is expressed in **pips**, **USD**, and as a **percentage**, and is further decomposed for stop/limit paths (`ChosenToTrigger`, `TriggerToReceived`).

The table was the **predecessor** to `Dealing_dbo.Dealing_Daily_Slippage_Positions` (which was itself later decommissioned as of Jan 2025). The **HOLD** suffix marks a **pipeline cutover** in **mid-2023**: loading stopped after **2023-06-13** (last pipeline touch **2023-06-14**). The Dealing organisation historically used this family of tables for **best execution monitoring**, **regulatory compliance**, and **slippage auditing** under **MiFID II** and **ESMA**.

**Scale (frozen)**: on the order of **~65.9M rows** spanning roughly **2022-06-01 → 2023-06-13**. **PII**: `CID` identifies the client.

**Operational stance**: treat as **read-only history** only. For any current process, confirm with Dealing / data platform owners which successor objects (if any) are authoritative.

---

## 2. Business Logic

### 2.1 Slippage intent (client vs execution)

- **Reference rates**: `ClientViewRate` is the rate shown in the UI at submission; `CustomerChosenRate` is the rate the client accepted (may differ from the view rate if the market moved). Execution-side pricing is represented through `EndForexRate` and related conversion via `ConversionRate`.
- **Monetary slippage**: `SlippageInDollar` is the **USD** cost or benefit of execution vs the client’s expected rate; `SlippageInPips` expresses slippage in **pip** units for FX-style instruments.
- **Percentage**: the column `[slippage %]` stores slippage as a fraction of the expected rate (column name contains a **space** and **`%`** — always bracket-qualify in SQL).

### 2.2 Stop / limit decomposition

- **`ChosenToTrigger`**: slippage component from **customer-chosen rate** to the **trigger** rate (when a stop/limit fires).
- **`TriggerToReceived`**: component from **trigger** rate to the **rate actually received** at execution.
- **Rule of thumb** (analysts): `SlippageInDollar` should align conceptually with **`ChosenToTrigger` + `TriggerToReceived`** in aggregate; validate on a sample before relying on exact equality (original ETL not available in repo).

### 2.3 Thresholding and compensation eligibility

- **`OverThreshold`**: when `1`, slippage exceeded **regulatory or internal** policy thresholds — these rows were primary candidates for **client compensation** analysis downstream (see `Dealing_Best_Execution_Compensation_*_HOLD`).

### 2.4 Trade lifecycle and direction

- **`IsBuy` / `OrigIsBuy`**: direction after vs before **reversals** (1 = buy, 0 = sell).
- **`ActionTypeID` / `ActionType`**: e.g. open, close, stop-loss, take-profit (codes documented in Elements).
- **`IsOpen`**: whether the position was **open** at the time of the snapshot row.
- **`HedgingMode`**: LP hedging mode (**A / B / C** routing strategy).
- **`Regulation`**: framework applied to the client (e.g. ESMA, ASIC, FCA) for **segmented** regulatory reporting.

### 2.5 ETL metadata

- **`UpdateDate`**: non-null **ETL audit** timestamp for the row’s last load (no active pipeline today).

---

## 3. Query Advisory

### 3.1 Distribution and indexing

- **ROUND_ROBIN** distribution: no hash key — **no colocation** with `CID` on the data slice. Favour **narrow `Date` filters** first; the **clustered index** is on **`Date` ASC**.
- **Table size**: tens of millions of rows — **avoid** full scans; always constrain **`Date`** (and optionally **`CID`**, **`PositionID`**, **`InstrumentID`**) for ad hoc analysis.

### 3.2 Typical access patterns

| Goal | Guidance |
|------|----------|
| Regulatory replay for one day | `WHERE Date = @d` |
| Client history | `WHERE CID = @cid AND Date BETWEEN @a AND @b` |
| Instrument slice | Join or filter on `InstrumentID` **after** restricting `Date` |

### 3.3 Joins and lookups

- **`InstrumentID`** → `DWH_dbo.Dim_Instrument` for name, type, currency metadata.
- **`Date`** → `DWH_dbo.Dim_Date` for calendar attributes.
- **`CID`** → customer dimensions (treat as **PII**; follow access controls).

### 3.4 Gotchas

- **Decommissioned** — max business data **2023-06-13**; do not use for **current** slippage KPIs.
- **Bracket** the `[slippage %]` identifier in T-SQL.
- **No writer SP in repo** — formulas above are **reconstructed** from column semantics and lineage notes, not traced line-by-line to active code.

---

## 4. Elements

### Confidence Tier Legend

> For this **decommissioned** table, tier tags reflect **DDL**, **historical sampling**, and **structural analogy** to related Dealing slippage objects — not an active documented writer SP.

| Stars | Tier | Inline tag (in Description) |
|-------|------|-----------------------------|
| ★★★★ | Tier 1 — upstream wiki | `(Tier 1 — upstream wiki, …)` |
| ★★★ | Tier 2 — structure / DDL | `(Tier 2 — inferred from structure)` or `(Tier 2 — DDL)` |
| ★★ | Tier 3 — live data | `(Tier 3 — live data)` |
| ★ | Tier 4 — inferred | `(Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date of the slippage snapshot row (daily grain). (Tier 2 — inferred from structure) |
| 2 | PositionID | bigint | YES | Unique **trade position** identifier; aligns with production `PositionTbl.PositionID` pattern. (Tier 2 — inferred from structure) |
| 3 | CID | int | YES | **Customer ID** — **PII**; join key to customer dimensions. (Tier 2 — inferred from structure) |
| 4 | InstrumentID | int | YES | Traded instrument key; join to `DWH_dbo.Dim_Instrument`. (Tier 2 — inferred from structure) |
| 5 | InstrumentName | varchar(45) | YES | Display name of the instrument (e.g. ticker / pair). (Tier 2 — inferred from structure) |
| 6 | InstrumentTypeID | int | YES | Instrument type code (e.g. 1=FX, 2=CFD, 5=Real Stock, 6=ETF — values inferred from domain usage). (Tier 2 — inferred from structure) |
| 7 | InstrumentType | varchar(50) | YES | Instrument type label (e.g. Crypto, Stocks). (Tier 2 — inferred from structure) |
| 8 | HedgeServerID | int | YES | Hedge server / routing identifier determining **which LP stack** handled the flow. (Tier 2 — inferred from structure) |
| 9 | MirrorID | int | YES | Copy / mirror portfolio identifier; **0** = not a copy trade. (Tier 2 — inferred from structure) |
| 10 | IsBuy | int | YES | Direction after potential reversals: **1**=buy, **0**=sell. (Tier 2 — inferred from structure) |
| 11 | OrigIsBuy | int | YES | Original direction before reversals. (Tier 2 — inferred from structure) |
| 12 | ExecutionAmountInUnits | decimal(16,8) | YES | Units executed at the LP (**8** decimal precision). (Tier 2 — inferred from structure) |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | Units as stored on the position record (**6** decimal precision). (Tier 2 — inferred from structure) |
| 14 | Occurred | datetime | YES | Server timestamp when the execution occurred. (Tier 2 — inferred from structure) |
| 15 | EndForexRate | decimal(16,8) | YES | FX conversion rate at execution for non-USD/normalised pricing paths. (Tier 2 — inferred from structure) |
| 16 | ConversionRate | decimal(16,8) | YES | Rate applied to express PnL / slippage in **USD**. (Tier 2 — inferred from structure) |
| 17 | ActionTypeID | int | YES | Action code: e.g. **1** Open, **2** Close, **3** Stop loss, **4** Take profit. (Tier 2 — inferred from structure) |
| 18 | ActionType | varchar(50) | YES | Human-readable action label. (Tier 2 — inferred from structure) |
| 19 | HedgingMode | varchar(10) | YES | LP hedging mode (**A** / **B** / **C**). (Tier 2 — inferred from structure) |
| 20 | Precision | int | YES | Price decimal precision for the instrument. (Tier 2 — inferred from structure) |
| 21 | IsOpen | int | YES | **1** if position open at row time, **0** if closed. (Tier 2 — inferred from structure) |
| 22 | ExecutionID | int | YES | Execution event identifier. (Tier 2 — inferred from structure) |
| 23 | StopRate | decimal(16,8) | YES | Configured stop-loss rate. (Tier 2 — inferred from structure) |
| 24 | LimitRate | decimal(16,8) | YES | Configured take-profit rate. (Tier 2 — inferred from structure) |
| 25 | RequestID | bigint | YES | Client request / order trace identifier. (Tier 2 — inferred from structure) |
| 26 | ClientViewRate | numeric(16,8) | YES | Rate shown in the UI at order submission. (Tier 2 — inferred from structure) |
| 27 | CustomerChosenRate | decimal(16,8) | YES | Rate the client accepted (may differ from view rate). (Tier 2 — inferred from structure) |
| 28 | SlippageInPips | money | YES | Slippage expressed in **pip** units vs expected rate. (Tier 2 — inferred from structure) |
| 29 | SlippageInDollar | money | YES | Slippage in **USD** — monetary client impact of execution quality. (Tier 2 — inferred from structure) |
| 30 | slippage % | decimal(38,21) | YES | Slippage as **percentage** of expected rate; **bracket** name in SQL. (Tier 2 — inferred from structure) |
| 31 | UpdateDate | datetime | NO | ETL row **last update** timestamp (pipeline metadata). (Tier 4 — inferred) |
| 32 | RequestTime | datetime | YES | Client order submission time. (Tier 2 — inferred from structure) |
| 33 | OverThreshold | tinyint | YES | **1** = slippage beyond policy/regulatory threshold; **0** = within. (Tier 2 — inferred from structure) |
| 34 | OpenSession | int | YES | Trading session code when the position opened. (Tier 2 — inferred from structure) |
| 35 | Volume | int | YES | Trade volume in notional units. (Tier 2 — inferred from structure) |
| 36 | Regulation | varchar(50) | YES | Regulatory framework label for the client (ESMA, ASIC, FCA, etc.). (Tier 2 — inferred from structure) |
| 37 | TriggerRate | decimal(16,8) | YES | Rate at which stop/limit **triggered**. (Tier 2 — inferred from structure) |
| 38 | ChosenToTrigger | money | YES | Slippage component: **chosen rate → trigger** rate. (Tier 2 — inferred from structure) |
| 39 | TriggerToReceived | money | YES | Slippage component: **trigger → executed** rate. (Tier 2 — inferred from structure) |

---

## 5. Lineage

This object is **decommissioned**: **no active writer** stored procedure is present in the current **DataPlatform / SSDT** tree. Detailed notes, inferred production touchpoints, and column-level hints are recorded in:

- **`Daily_Slippage_Positions_HOLD.lineage.md`** (same folder as this wiki)

**Summary**: rows are **DWH-internal** snapshots inferred to combine **position / execution** attributes with **computed slippage** measures; exact upstream tables are **not** mapped in Generic Pipeline documentation. Treat lineage statements in the sidecar file as **reconstruction**, not operational orchestration truth.

---

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_Daily_Slippage_Positions` | Logical **successor** non-HOLD slippage table (later also decommissioned per platform notes). |
| `Dealing_dbo.Dealing_Daily_Slippage_Totals` | **Aggregated** slippage totals family — use for pre-aggregated reporting patterns when applicable. |
| `Dealing_dbo.Dealing_Best_Execution_Compensation_CBH_HOLD` | **Downstream** best-execution **compensation** analysis (CBH LP routing variant, HOLD). |
| `Dealing_dbo.Dealing_Best_Execution_Compensation_HBC_HOLD` | **Downstream** compensation analysis (**HBC** routing variant, HOLD). |
| `DWH_dbo.Dim_Instrument` | Resolve `InstrumentID` to instrument attributes. |
| `DWH_dbo.Dim_Date` | Calendar attributes for `Date`. |

---

## 7. Sample Queries

```sql
-- One-day regulatory slice: high slippage USD, ESMA clients
SELECT PositionID, CID, InstrumentID, SlippageInDollar, OverThreshold, Regulation
FROM Dealing_dbo.Daily_Slippage_Positions_HOLD
WHERE Date = '2023-06-01'
  AND Regulation LIKE '%ESMA%'
  AND ABS(CAST(SlippageInDollar AS float)) > 100
ORDER BY SlippageInDollar DESC;
```

```sql
-- Client history over HOLD window (PII — restrict access)
SELECT Date, PositionID, InstrumentID, SlippageInDollar, [slippage %], OverThreshold
FROM Dealing_dbo.Daily_Slippage_Positions_HOLD
WHERE CID = @CID
  AND Date BETWEEN '2022-06-01' AND '2023-06-13'
ORDER BY Date, PositionID;
```

```sql
-- Threshold candidates counts by regulation and month
SELECT DATEFROMPARTS(YEAR(Date), MONTH(Date), 1) AS MonthStart,
       Regulation,
       SUM(CASE WHEN OverThreshold = 1 THEN 1 ELSE 0 END) AS RowsOverThreshold,
       COUNT(*) AS RowCount
FROM Dealing_dbo.Daily_Slippage_Positions_HOLD
GROUP BY DATEFROMPARTS(YEAR(Date), MONTH(Date), 1), Regulation
ORDER BY MonthStart, Regulation;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

## Appendix — extended context (row grain and freeze metadata)

The following **operational metadata** is preserved from the prior documentation pass for auditors who need explicit **freeze** evidence alongside this template:

| Topic | Value |
|-------|-------|
| Last row `Date` | **2023-06-13** |
| Last pipeline touch | **2023-06-14** (approx. **09:28** in sampled environment) |
| Approximate row count | **~65.9 million** (frozen) |
| Writer SP | **None** active — HOLD archive |
| PII | **CID** present — restrict access |

---

*Generated: 2026-03-21 | Quality: 6.0/10 (★★★☆☆) | Batch: 7 (redo)*

*Tiers: 0 T1, 38 T2, 0 T3, 1 T4 | Elements: 6/10, Logic: 6/10, Relationships: 6/10, Sources: 3/10*

*Object: Dealing_dbo.Daily_Slippage_Positions_HOLD | Type: Table | Production Source: N/A (decommissioned)*
