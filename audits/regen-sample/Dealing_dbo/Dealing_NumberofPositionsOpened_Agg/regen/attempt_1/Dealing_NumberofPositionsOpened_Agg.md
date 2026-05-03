# Dealing_dbo.Dealing_NumberofPositionsOpened_Agg

> 178K-row daily aggregation of positions opened, grouped by instrument type and marketing region -- a lightweight summary of Dealing_DealingDashboard_Clients used for high-level dealing desk trend analysis. Data from 2022-01-01 to present, refreshed daily by SP_DealingDashboard_Clients.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived — aggregation of Dealing_dbo.Dealing_DealingDashboard_Clients (which itself derives from Dim_Position + BI_DB_PositionPnL + customer/instrument dimensions) |
| **Refresh** | Daily via SP_DealingDashboard_Clients (DELETE + INSERT for @DateID) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| | |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline, Append, 1440min) |

---

## 1. Business Meaning

Dealing_NumberofPositionsOpened_Agg is a compact aggregation table that summarizes the daily count of positions opened, broken down by instrument type (Stocks, ETF, Crypto Currencies, Currencies, Commodities, Indices) and marketing region (21 regions including USA, UK, Spain, ROW, etc.). It is populated at the tail end of `SP_DealingDashboard_Clients` as a GROUP BY rollup of the much larger `Dealing_DealingDashboard_Clients` table (~1.83B rows), collapsing all other dimensions (HedgeServerID, InstrumentID, Regulation, Country, Mifid, IsCopy, IsCFD, Leverage) into just InstrumentType and Region.

As of 2026-04-26: **178,742 rows**, spanning **2022-01-01 to 2026-04-26**. Each date has up to 6 instrument types x 21 regions = 126 rows (fewer when some combinations have zero positions). The table enables quick macro-level queries about position opening trends without scanning the full dashboard table.

The ETL pattern is DELETE + INSERT: each daily run deletes existing rows for `@DateID` and re-inserts the aggregated result. `NumberOfPositionsOpened` excludes partial close children (inherited from the upstream logic in Dealing_DealingDashboard_Clients).

---

## 2. Business Logic

### 2.1 Aggregation from DealingDashboard_Clients

**What**: This table is a SUM rollup of `Dealing_DealingDashboard_Clients.NumberOfPositionsOpened` across all non-grouped dimensions.

**Columns Involved**: `DateID`, `Date`, `InstrumentType`, `Region`, `NumberOfPositionsOpened`

**Rules**:
- Source query: `SELECT DateID, Date, InstrumentType, Region, SUM(NumberOfPositionsOpened), GETDATE() FROM Dealing_DealingDashboard_Clients WHERE DateID = @DateID GROUP BY DateID, Date, InstrumentType, Region`
- NumberOfPositionsOpened in the source excludes partial close children (`ISNULL(IsPartialCloseChild,0)=0`) to avoid double-counting
- The aggregation collapses HedgeServerID, InstrumentID, Regulation, Country, Mifid, IsCopy, IsCFD, Leverage, and IsFuture into just InstrumentType + Region
- Weekends and holidays may have 0 values for all instrument types

### 2.2 InstrumentType Values

**What**: Asset class labels inherited from `Dim_Instrument.InstrumentType`.

**Columns Involved**: `InstrumentType`

**Rules**:
- 6 distinct values: Currencies, Commodities, Indices, Stocks, ETF, Crypto Currencies
- Mapped from InstrumentTypeID via CASE in SP_Dim_Instrument: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies

### 2.3 Region Values

**What**: Marketing region labels inherited from `Dim_Country.Region`.

**Columns Involved**: `Region`

**Rules**:
- 21 distinct values observed: Africa, Arabic GCC, Arabic Other, Australia, Canada, China, Eastern Europe, French, German, Israel, Italian, North Europe, Other Asia, ROE, ROW, Russian, South & Central America, Spain, UK, Unknown, USA
- Sourced from `Dim_Country.Region` (which loads from `Dictionary.MarketingRegion.Name`) via `Fact_SnapshotCustomer`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN distribution with CLUSTERED INDEX on DateID. With 178K rows, the table is small enough for efficient full scans, but filtering by DateID leverages the clustered index for date-specific queries.

### 3.1b UC (Databricks) Storage

**In Databricks**, exported as Delta via Generic Pipeline (Append, daily). UC target: `bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily position open count by asset class | `SELECT InstrumentType, SUM(NumberOfPositionsOpened) FROM ... WHERE DateID = @DateID GROUP BY InstrumentType` |
| Weekly trend by region | `WHERE DateID BETWEEN @start AND @end GROUP BY Region` |
| Total positions opened on a specific day | `SELECT SUM(NumberOfPositionsOpened) WHERE DateID = @DateID` |
| Compare Stocks vs Crypto over time | `WHERE RTRIM(InstrumentType) IN ('Stocks','Crypto Currencies') GROUP BY DateID, InstrumentType` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Date | ON a.DateID = dd.DateKey | Calendar attributes (week, month, quarter) |

### 3.4 Gotchas

- **InstrumentType and Region are char(50)**: Trailing spaces are present due to `char` type. Use `RTRIM()` when comparing or displaying.
- **NumberOfPositionsOpened can be 0**: Weekend/holiday rows exist with 0 positions opened. These are not NULLs — they are explicit zeros from the upstream SUM.
- **No InstrumentID granularity**: This table aggregates across all instruments within a type. For per-instrument data, query `Dealing_DealingDashboard_Clients` directly.
- **Partial close children excluded**: The upstream NumberOfPositionsOpened already excludes partial close children (IsPartialCloseChild=1), so this count represents distinct new positions only.
- **Data starts 2022-01-01**: Unlike Dealing_DealingDashboard_Clients which starts July 2020, this aggregation table only has data from January 2022 onward (when this INSERT was added to the SP).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 | `(Tier 2 — source)` — ETL-computed or passthrough from ETL-computed upstream |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Snapshot date as YYYYMMDD integer. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients. Range: 20220101 to present. Clustered index column. (Tier 2 — Dealing_DealingDashboard_Clients) |
| 2 | Date | date | YES | Reporting calendar date. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients. (Tier 2 — Dealing_DealingDashboard_Clients) |
| 3 | InstrumentType | char(50) | YES | Asset class label: Currencies, Commodities, Indices, Stocks, ETF, Crypto Currencies. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients; originates from Dim_Instrument.InstrumentType (CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies). (Tier 2 — Dim_Instrument) |
| 4 | Region | char(50) | YES | Marketing region label. Passthrough GROUP BY key from Dealing_DealingDashboard_Clients; originates from Dim_Country.Region (loaded from Dictionary.MarketingRegion.Name). 21 distinct values including USA, UK, Spain, ROW, ROE, Africa, etc. (Tier 2 — Dim_Country) |
| 5 | NumberOfPositionsOpened | int | YES | Total count of positions opened on this date for this InstrumentType and Region. SUM aggregation from Dealing_DealingDashboard_Clients.NumberOfPositionsOpened, which excludes partial close children (IsPartialCloseChild=1). (Tier 2 — Dealing_DealingDashboard_Clients) |
| 6 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at insert time by SP_DealingDashboard_Clients. Not a business date. (Tier 2 — SP_DealingDashboard_Clients) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| DateID | Dealing_DealingDashboard_Clients | DateID | Passthrough (GROUP BY key) |
| Date | Dealing_DealingDashboard_Clients | Date | Passthrough (GROUP BY key) |
| InstrumentType | Dealing_DealingDashboard_Clients | InstrumentType | Passthrough (GROUP BY key) |
| Region | Dealing_DealingDashboard_Clients | Region | Passthrough (GROUP BY key) |
| NumberOfPositionsOpened | Dealing_DealingDashboard_Clients | NumberOfPositionsOpened | SUM aggregation |
| UpdateDate | — | — | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position + BI_DB_dbo.BI_DB_PositionPnL + Fact_SnapshotCustomer + Dim_Instrument + Dim_Country + ...
  |-- SP_DealingDashboard_Clients @Date (multi-step aggregation) --|
  v
Dealing_dbo.Dealing_DealingDashboard_Clients (~1.83B rows)
  |-- Same SP, tail-end: DELETE + INSERT GROUP BY DateID, Date, InstrumentType, Region --|
  v
Dealing_dbo.Dealing_NumberofPositionsOpened_Agg (178K rows)
  |-- Generic Pipeline (Append, delta, 1440min) --|
  v
bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg
```

| Step | Object | Description |
|------|--------|-------------|
| Source | Dealing_dbo.Dealing_DealingDashboard_Clients | Full dealing dashboard fact (1.83B rows) |
| ETL | Dealing_dbo.SP_DealingDashboard_Clients | DELETE + INSERT SUM aggregation at end of SP |
| Target | Dealing_dbo.Dealing_NumberofPositionsOpened_Agg | Aggregated position-open counts (178K rows) |
| Export | Generic Pipeline (daily, Append) | bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_numberofpositionsopened_agg |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DateID | DWH_dbo.Dim_Date | Calendar dimension (implicit, not enforced) |

### 6.2 Referenced By (other objects point to this)

No downstream consumers identified in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Daily position opens by instrument type

```sql
SELECT
    DateID,
    RTRIM(InstrumentType) AS InstrumentType,
    NumberOfPositionsOpened
FROM [Dealing_dbo].[Dealing_NumberofPositionsOpened_Agg]
WHERE DateID = 20260425
ORDER BY NumberOfPositionsOpened DESC;
```

### 7.2 Weekly trend by region (last 7 days)

```sql
SELECT
    RTRIM(Region) AS Region,
    SUM(NumberOfPositionsOpened) AS WeeklyPositionsOpened
FROM [Dealing_dbo].[Dealing_NumberofPositionsOpened_Agg]
WHERE DateID BETWEEN 20260420 AND 20260426
GROUP BY RTRIM(Region)
ORDER BY WeeklyPositionsOpened DESC;
```

### 7.3 Monthly trend — Stocks vs Crypto

```sql
SELECT
    LEFT(CAST(DateID AS VARCHAR(8)), 6) AS YearMonth,
    RTRIM(InstrumentType) AS InstrumentType,
    SUM(NumberOfPositionsOpened) AS MonthlyPositionsOpened
FROM [Dealing_dbo].[Dealing_NumberofPositionsOpened_Agg]
WHERE RTRIM(InstrumentType) IN ('Stocks', 'Crypto Currencies')
  AND DateID >= 20260101
GROUP BY LEFT(CAST(DateID AS VARCHAR(8)), 6), RTRIM(InstrumentType)
ORDER BY YearMonth, InstrumentType;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — Phase 10 skipped).

---

*Generated: 2026-04-30 | Quality: 8.0/10 (★★★★☆) | Phases: 11/14*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 6/6, Logic: 8/10, Relationships: 5/10, Sources: 9/10*
*Object: Dealing_dbo.Dealing_NumberofPositionsOpened_Agg | Type: Table | Production Source: Derived (aggregation of Dealing_DealingDashboard_Clients)*
