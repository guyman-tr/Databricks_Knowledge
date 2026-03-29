# Dealing_dbo.Dealing_Boundary_Cost_H_Indices

> **Historical** boundary-cost snapshot for **index instruments** only: NOP, spreads, bid/ask, and position aggregates by time window. **Decommissioned** — last row **2023-03-15**; **no active writer**; superseded by **`Dealing_dbo.Dealing_Boundary_Cost`** (all instrument types).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Internal DWH boundary-cost calculation (historical **indices-only** variant; writer **not** referenced by current `SP_Boundary_Cost`) |
| **Refresh** | Frozen (last update **2023-03-16 07:37**; decommissioned **Mar 2023**) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[DateID]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

**Boundary cost** in eToro’s hedging context is the **cost picture when client net-open-position (NOP)** approaches or crosses a **hedging boundary** — the risk threshold where dealing must **hedge or unhedge** to stay within limits. This table is a **historical, indices-only** slice of that analytics dataset.

Naming breakdown:

- **`H`**: **Historical / HOLD** — archived table, **not** the active boundary-cost pipeline.
- **`Indices`**: Content is restricted to **index instruments** (e.g. index CFDs / benchmarks), not the full multi-asset universe in the current **`Dealing_Boundary_Cost`** table.

At documentation time the table held on the order of **~39.6 million rows** from **2021-01-03** through **2023-03-15** (~26 months). The large row count is consistent with **intraday `FromDate`/`ToDate` windows** within each **`Date`**, not only end-of-day summaries.

**Domain**: Dealing — hedging boundary management, **risk**, **index** instruments. **Do not use for current analysis** — refer to **`Dealing_Boundary_Cost`**.

## 2. Business Logic

- **Instrument scope**: Rows are expected to carry **indices** `InstrumentType` / `InstrumentTypeID` values only (naming and column semantics); confirm with a distinct-value check if reviving research.
- **Prices**: **`LastBid`**, **`LastAsk`**, and **`Mid`** describe the **eToro price feed** around **`ToDate`** for the window.
- **Spreads**: **`StdSpreadPercent`** is the **standard spread** as a percent of price; **`LastBidSpreaded`** / **`LastAskSpreaded`** apply that spread model to raw bid/ask (see existing doc: bid scaled by `(1 - StdSpreadPercent/2)` style interpretation).
- **Positions**: **`UnitsBuy`** / **`UnitsSell`** are **net open units** by side; **`WAVG_BuyPrice`** / **`WAVG_SellPrice`** are **volume-weighted average** open prices.
- **NOP**: **Net open position (USD)** ≈ **`(UnitsBuy - UnitsSell) × current price`** in the documented interpretation — sign indicates **net long vs short** exposure.
- **Volumes**: **`VolumeBuy`** / **`VolumeSell`** capture **position volume** (USD or units per legacy definition — confirm vs **`Units*`** with domain).
- **`VariableSpread`**: Additional **variable spread** component for the interval.
- **`IsSettled`**: Flag interpreted as **boundary / hedge settlement state** (e.g. **1** when the position has been **settled** at the boundary vs **0** still open) — **exact business definition needs SME confirmation** (review sidecar).
- **`HedgeServerID`**: Identifies **hedge server** context for the NOP observation.
- **`FX_Bid`**: **FX bid rate** used to convert instrument economics toward **USD**.

**Active vs historical**: **`SP_Boundary_Cost`** maintains **`Dealing_Boundary_Cost`** and **does not write** this `_H_Indices` table — this object is a **frozen branch** of the lineage tree.

## 3. Query Advisory

- **Frozen data**: Cap analysis at **2023-03-15**; for current boundary cost use **`Dealing_dbo.Dealing_Boundary_Cost`**.
- **Cluster key**: Table is **clustered on `DateID`** (integer **YYYYMMDD**). Prefer **`WHERE DateID BETWEEN @d1 AND @d2`** for partition-style pruning behavior on Synapse; filtering on **`Date`** alone may be less efficient.
- **Volume**: **Tens of millions of rows** — always **restrict `Date`/`DateID`** and, if needed, **`InstrumentID`** before heavy joins.
- **Time windows**: Use **`FromDate`/`ToDate`** when reconstructing **intraday boundary snapshots**; do not assume one row per instrument per day without checking.
- **PII**: **No client identifiers** — instrument and aggregate position metrics only.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — DDL / schema inference)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Calendar date** of the boundary-cost snapshot window. (Tier 2 — DDL / schema inference) |
| 2 | DateID | int | YES | **Integer date key** `YYYYMMDD`; **clustered index** key; joins to **`DWH_dbo.Dim_Date.DateKey`**. (Tier 2 — DDL / schema inference) |
| 3 | FromDate | datetime | YES | **Start** of the boundary-cost **time window** for this row. (Tier 2 — DDL / schema inference) |
| 4 | ToDate | datetime | YES | **End** of the boundary-cost **time window** for this row. (Tier 2 — DDL / schema inference) |
| 5 | InstrumentID | int | YES | **Instrument** key — table scoped to **indices** only. (Tier 2 — DDL / schema inference) |
| 6 | InstrumentName | varchar(100) | YES | **Display name** (e.g. **US500**, **UK100**). (Tier 2 — DDL / schema inference) |
| 7 | InstrumentType | varchar(50) | YES | **Instrument type** label — expect **indices** family values. (Tier 2 — DDL / schema inference) |
| 8 | StdSpreadPercent | decimal(16,6) | YES | **Standard spread** as **percent of price** for the instrument in this window. (Tier 2 — DDL / schema inference) |
| 9 | LastBid | decimal(16,6) | YES | **Last bid** from eToro price feed at **`ToDate`**. (Tier 2 — DDL / schema inference) |
| 10 | LastAsk | decimal(16,6) | YES | **Last ask** from eToro price feed at **`ToDate`**. (Tier 2 — DDL / schema inference) |
| 11 | Mid | decimal(16,6) | YES | **Mid price**: **`(LastBid + LastAsk) / 2`**. (Tier 2 — DDL / schema inference) |
| 12 | LastBidSpreaded | decimal(16,6) | YES | **Bid with spread model applied** (derived from **`LastBid`** and **`StdSpreadPercent`**). (Tier 2 — DDL / schema inference) |
| 13 | LastAskSpreaded | decimal(16,6) | YES | **Ask with spread model applied** (derived from **`LastAsk`** and **`StdSpreadPercent`**). (Tier 2 — DDL / schema inference) |
| 14 | UnitsBuy | decimal(16,6) | YES | **Net buy-side units** open for the instrument in this window. (Tier 2 — DDL / schema inference) |
| 15 | UnitsSell | decimal(16,6) | YES | **Net sell-side units** open for the instrument in this window. (Tier 2 — DDL / schema inference) |
| 16 | WAVG_BuyPrice | decimal(16,6) | YES | **Weighted average** open price — **buy** legs. (Tier 2 — DDL / schema inference) |
| 17 | WAVG_SellPrice | decimal(16,6) | YES | **Weighted average** open price — **sell** legs. (Tier 2 — DDL / schema inference) |
| 18 | NOP | decimal(16,6) | YES | **Net open position (USD)** — long/short exposure from units × price interpretation. (Tier 2 — DDL / schema inference) |
| 19 | VolumeBuy | decimal(16,6) | YES | **Buy volume** aggregate for the window (USD or units per historical definition). (Tier 2 — DDL / schema inference) |
| 20 | VolumeSell | decimal(16,6) | YES | **Sell volume** aggregate for the window. (Tier 2 — DDL / schema inference) |
| 21 | VariableSpread | decimal(16,6) | YES | **Variable spread** component for the interval. (Tier 2 — DDL / schema inference) |
| 22 | UpdateDate | datetime | YES | **ETL last-update** timestamp. [UNVERIFIED] (Tier 4 — inferred) |
| 23 | FX_Bid | decimal(16,6) | YES | **FX bid** rate for **USD conversion** of instrument prices. (Tier 2 — DDL / schema inference) |
| 24 | InstrumentTypeID | int | YES | **Instrument type** code — expect **indices** type ids. (Tier 2 — DDL / schema inference) |
| 25 | HedgeServerID | int | YES | **Hedge server** identifier for this NOP observation. (Tier 2 — DDL / schema inference) |
| 26 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |

## 5. Lineage

See **`Dealing_Boundary_Cost_H_Indices.lineage.md`** for pipeline notes and inferred column sources.

- **Status**: **DECOMMISSIONED** — **no active writer SP**; last data **2023-03-15**. **`SP_Boundary_Cost`** does **not** reference this table.
- **Interpretation**: Historical **indices-filtered** boundary-cost table, likely a **parallel or predecessor** path to today’s **`Dealing_Boundary_Cost`**.
- **Sources (inferred)**: Internal **price feed**, **positions**, **NOP** math — not mapped in Generic Pipeline documentation.

## 6. Relationships

| Object | Relationship |
|--------|----------------|
| `Dealing_dbo.Dealing_Boundary_Cost` | **Active successor** — all instrument types, maintained pipeline. |
| `Dealing_dbo.Dealing_HedgeCost` | **Hedge cost** analytics derived from boundary-cost family (confirm dependencies via repo search). |
| `DWH_dbo.Dim_Instrument` | **Instrument** attribute lookup for ids/names/types. |
| `DWH_dbo.Dim_Date` | **Date dimension** join on **`DateID` ↔ DateKey**. |

## 7. Sample Queries

**1) Coverage and row density by date (sample week)**

```sql
SELECT Date, DateID, COUNT(*) AS RowsPerDay
FROM Dealing_dbo.Dealing_Boundary_Cost_H_Indices
WHERE Date BETWEEN '2023-03-01' AND '2023-03-15'
GROUP BY Date, DateID
ORDER BY Date;
```

**2) One instrument’s intraday windows on a day**

```sql
SELECT FromDate, ToDate, NOP, UnitsBuy, UnitsSell, IsSettled, HedgeServerID
FROM Dealing_dbo.Dealing_Boundary_Cost_H_Indices
WHERE Date = '2022-06-01'
  AND InstrumentName = 'US500'
ORDER BY FromDate, ToDate;
```

**3) Join to Dim_Date for reporting labels**

```sql
SELECT h.DateID, d.Date AS CalDate, h.InstrumentName, MAX(h.NOP) AS MaxNOP
FROM Dealing_dbo.Dealing_Boundary_Cost_H_Indices h
JOIN DWH_dbo.Dim_Date d ON d.DateKey = h.DateID
WHERE h.DateID BETWEEN 20230101 AND 20230315
GROUP BY h.DateID, d.Date, h.InstrumentName
ORDER BY h.DateID, h.InstrumentName;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 6.5/10 (★★★☆☆) | Batch: 7 (redo)*

*Tiers: 0 T1, 25 T2, 0 T3, 1 T4 | Elements: 7/10, Logic: 6/10, Relationships: 7/10, Sources: 5/10*

*Object: Dealing_dbo.Dealing_Boundary_Cost_H_Indices | Type: Table | Production Source: Internal DWH boundary-cost (historical indices variant)*
