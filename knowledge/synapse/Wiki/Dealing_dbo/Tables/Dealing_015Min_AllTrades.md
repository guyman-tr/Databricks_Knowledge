# Dealing_dbo.Dealing_015Min_AllTrades

> Fifteen-minute–bucket **LP / exchange all-trades** snapshot: executions with price, size, fees, and order identifiers. **Frozen** — last row date **2024-04-02**; **no active writer stored procedure** found in the DataPlatform SSDT repo; pipeline appears inactive.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | External LP / exchange feed — writer **not found** in SSDT (possible SSIS/ADF or legacy loader) |
| **Refresh** | Frozen (last update **2024-04-02 08:07**; historically intraday ~15-minute batches) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table captures a **raw liquidity-provider (LP) “all trades” feed**, aggregated into **15-minute windows** for intraday monitoring and reconciliation. Each row represents a **single execution** (or execution-level record) as reported by the external venue, including **price**, **quantity**, **notional funds**, **fees**, and **order / exchange metadata**.

The name **`015Min`** reflects how batches were likely collected: runs aligned to **15-minute boundaries**, with **`Last15Min`** marking the **window boundary** for the batch, not necessarily the exact execution instant (use **`execution_time`** for precise timing).

**Business domain**: Dealing — LP trade activity monitoring, intraday reconciliation, execution quality. **Not suitable for current analytics** after April 2024.

Approximate scale from documentation snapshot: **~410,905 rows** from **2022-07-25** through **2024-04-02** (~21 months). **No PII** — no client identifiers in this layout.

**Consumers (historical)**: Any dashboard or control process that needed **near–real-time trade tape** style visibility into LP executions before the freeze. Because the writer is unknown, treat **operational ownership** as **unresolved** until Ops or ADF/SSIS metadata identifies the loader.

## 2. Business Logic

- **Grain**: One row per **LP-reported execution record** within the loaded batch; **`Last15Min`** groups rows into **intraday 15-minute buckets** for the snapshot that loaded them.
- **`Funds`**: Interpreted as **total funds** involved in the trade (price × quantity style notional in the instrument’s context); **`Fee`** is the **exchange/LP fee** for that execution.
- **`Unit` vs `quantity`**: Both are **float** measures from the feed; **`quantity`** is the primary traded size; **`Unit`** may represent **lots**, **contract units**, or an alternate sizing field — **domain confirmation required** (see review sidecar).
- **`Value`**: Total **value** in **USD or instrument denomination** — relationship to **`Funds`** and fees is **not fully verified** without the missing loader code; treat as **feed-sourced** and validate before financial sign-off.
- **`Side`**: Buy/sell as **reported by the exchange** (typically `"BUY"` / `"SELL"` strings; **`char(50)`** may pad with spaces).
- **`Source` vs `source_name`**: Both identify **feed or LP origin**; exact distinction depends on the upstream mapping (unknown without writer).

Because **no SSDT writer** was found, **column semantics** in section 4 are grounded in **DDL + sampling / naming**, not procedure code. Phase 2 sampling previously confirmed **staleness** (`max_date` **2024-04-02**) and approximate row counts.

## 3. Query Advisory

- **Do not use for current state** — data **frozen April 2024**.
- **Typical filters**: `WHERE Date = @Date` or `WHERE Last15Min >= @Start AND Last15Min < @End` for intraday windows.
- **Columnstore**: **Clustered columnstore** suits **aggregations** over large slices; avoid `SELECT *` over wide history without filters.
- **`char(50)` text columns**: Expect **trailing spaces** — use **`RTRIM()`** when joining or grouping on `Instrument_Name`, `exchange`, `source_name`, `order_id`, `Source`, `Side`.
- **Float types**: **`price`**, **`quantity`**, **`Funds`**, **`Fee`**, **`Unit`**, **`Value`** may introduce **precision drift** in large **`SUM`s** — cast to **`decimal`** for audited money math.
- **`Last15Min` vs `execution_time`**: Use **`execution_time`** for **chronological** execution analysis; **`Last15Min`** for **batch/window** alignment.
- **Deduplication**: If reconciling to another trade store, **`id`** plus **`order_id`** and **`execution_time`** may form a natural key — **confirm** with the feed specification once the LP is identified.
- **Exchange / source filters**: Prefer **`RTRIM(exchange)`**, **`RTRIM(source_name)`** in `WHERE` clauses to avoid missed matches due to padding.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — DDL / Synapse definition)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** of the trade rows in this load batch. (Tier 2 — DDL / Synapse definition) |
| 2 | Last15Min | datetime | YES | **15-minute window boundary** timestamp for the snapshot batch — bucket marker, not the execution time. (Tier 2 — DDL / Synapse definition) |
| 3 | id | int | YES | **Trade record identifier** from the LP/exchange feed. (Tier 2 — DDL / Synapse definition) |
| 4 | execution_time | datetime | YES | **Execution timestamp** at the venue — use for precise intraday ordering. (Tier 2 — DDL / Synapse definition) |
| 5 | Instrument_Name | char(50) | YES | **Symbol / instrument** name (e.g. equity ticker); fixed-width — trim for joins. (Tier 2 — DDL / Synapse definition) |
| 6 | Side | char(50) | YES | **Buy/sell** side as reported by the exchange/LP. (Tier 2 — DDL / Synapse definition) |
| 7 | price | float | YES | **Execution price** per unit. (Tier 2 — DDL / Synapse definition) |
| 8 | quantity | float | YES | **Traded size** in units/shares/contracts per feed definition. (Tier 2 — DDL / Synapse definition) |
| 9 | Funds | float | YES | **Notional funds** for the trade (price × quantity style); confirm currency vs **`Value`**. (Tier 2 — DDL / Synapse definition) |
| 10 | Fee | float | YES | **Fee** charged by exchange/LP for this execution. (Tier 2 — DDL / Synapse definition) |
| 11 | exchange | char(50) | YES | **Venue identifier** (e.g. NASDAQ/NYSE-style labels in feed encoding). (Tier 2 — DDL / Synapse definition) |
| 12 | source_name | char(50) | YES | **Source system or LP** name submitting the record. (Tier 2 — DDL / Synapse definition) |
| 13 | order_id | char(50) | YES | **Order id** from LP/exchange — reconciliation key to upstream orders. (Tier 2 — DDL / Synapse definition) |
| 14 | Unit | float | YES | **Alternate unit** measure — possibly lot/contract sizing; confirm vs **`quantity`**. (Tier 2 — DDL / Synapse definition) |
| 15 | Value | float | YES | **Total trade value** in USD or instrument currency — relationship to **`Funds`** unverified without loader. (Tier 2 — DDL / Synapse definition) |
| 16 | UpdateDate | datetime | YES | **ETL update timestamp** for the row. [UNVERIFIED] (Tier 4 — inferred) |
| 17 | Source | char(50) | YES | **Feed identifier** when multiple LP streams load into one table. (Tier 2 — DDL / Synapse definition) |

## 5. Lineage

See **`Dealing_015Min_AllTrades.lineage.md`** for the full narrative and column-level mapping assumptions.

- **Status**: **Stale** — no Generic Pipeline mapping found; **no Dealing_dbo SP** located in SSDT.
- **Chain (conceptual)**: `[Unknown LP/exchange feed] → [Unknown writer or external loader] → Dealing_015Min_AllTrades`.
- **Implication**: Column transforms (e.g. how **`Last15Min`** is truncated) are **inferred**, not proven from repo code.

## 6. Relationships

| Object | Relationship |
|--------|----------------|
| `Dealing_dbo.Dealing_MarketMakerAllTrade` | Similar **LP all-trades** style table (active, market-maker scope — compare patterns). |
| `Dealing_dbo.Dealing_DailyAvgSpread` | **Spread analytics** that may consume related LP trade feeds (confirm with repo search). |

## 7. Sample Queries

**1) Data coverage and max window**

```sql
SELECT
    MIN(Date) AS MinDate,
    MAX(Date) AS MaxDate,
    MIN(Last15Min) AS MinBucket,
    MAX(Last15Min) AS MaxBucket,
    COUNT(*) AS RowCnt
FROM Dealing_dbo.Dealing_015Min_AllTrades;
```

**2) Trades in a 15-minute bucket (trimmed keys)**

```sql
SELECT
    RTRIM(Instrument_Name) AS Symbol,
    execution_time,
    Side,
    price,
    quantity,
    Funds,
    Fee,
    RTRIM(exchange) AS exchange
FROM Dealing_dbo.Dealing_015Min_AllTrades
WHERE Date = '2024-03-15'
  AND Last15Min = '2024-03-15T14:30:00'
ORDER BY execution_time;
```

**3) Top symbols by notional for a day (watch float aggregation)**

```sql
SELECT
    RTRIM(Instrument_Name) AS Symbol,
    SUM(CAST(Funds AS decimal(38,6))) AS SumFunds,
    COUNT(*) AS Trades
FROM Dealing_dbo.Dealing_015Min_AllTrades
WHERE Date = '2024-03-01'
GROUP BY RTRIM(Instrument_Name)
ORDER BY SumFunds DESC;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 6.5/10 (★★★☆☆) | Batch: 7 (redo)*

*Tiers: 0 T1, 16 T2, 0 T3, 1 T4 | Elements: 7/10, Logic: 6/10, Relationships: 6/10, Sources: 5/10*

*Object: Dealing_dbo.Dealing_015Min_AllTrades | Type: Table | Production Source: External LP / exchange feed (writer not in SSDT)*
