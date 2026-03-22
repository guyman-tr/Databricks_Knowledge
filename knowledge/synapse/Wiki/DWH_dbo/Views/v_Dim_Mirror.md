# DWH_dbo.v_Dim_Mirror

> Thin passthrough view over DWH_dbo.Dim_Mirror that adds a `snapshot_date` column set to today's date (CAST(GETDATE() AS DATE)), providing a stable daily-snapshot label for the full copy-trading relationship dataset.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Production Source** | DWH_dbo.Dim_Mirror (all columns passthrough + snapshot_date added) |
| **Refresh** | On-query (GETDATE() evaluated at query time) |
| | |
| **Synapse Distribution** | N/A (View — inherits from Dim_Mirror: HASH(MirrorID)) |
| **Synapse Index** | N/A (View) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror` |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`v_Dim_Mirror` is a thin view over `DWH_dbo.Dim_Mirror` that exposes all columns of the underlying copy-trading relationship table plus one computed column: `snapshot_date = CAST(GETDATE() AS DATE)`.

The view definition is:
```sql
SELECT *, CAST(GETDATE() AS DATE) AS snapshot_date
FROM [DWH_dbo].[Dim_Mirror]
```

`Dim_Mirror` contains 11.1M rows representing every copy-trading relationship on eToro from 2011 to present — copier (`CID`), copied person (`ParentCID`), investment amount, open/close dates, P&L, risk settings, and mirror type (Regular, Fund, CopyMe, Smart Portfolio). For full documentation of the underlying data model, see [DWH_dbo.Dim_Mirror](../Tables/Dim_Mirror.md).

**Purpose of snapshot_date**: By adding `CAST(GETDATE() AS DATE)`, this view stamps each query result with today's date, enabling consumers (dashboards, pipelines, snapshot exports) to label the result set with its query date without modifying the base table or requiring a separate date join.

**Note**: `snapshot_date` is evaluated at query time, not at ETL load time. It always returns the current calendar date, which means it is not a reliable historical timestamp.

---

## 2. Business Logic

### 2.1 Snapshot Date Labeling

**What**: Adds a query-time date label to each row of Dim_Mirror for snapshot tracking.

**Columns Involved**: `snapshot_date` (computed), all Dim_Mirror columns (inherited)

**Rules**:
- `snapshot_date = CAST(GETDATE() AS DATE)` — evaluated at query execution time
- All other columns are identical to `Dim_Mirror` — no filtering, no transformation
- For filtering active vs. closed mirrors, use `CloseDateID = 0` (open sentinel) or `CloseDateID > 0` (closed) — same rules as `Dim_Mirror`

---

## 3. Query Advisory

### 3.1 Performance

Since this is `SELECT *` over an 11.1M-row table, always add filters when querying. Recommendations are identical to `Dim_Mirror`:

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Active mirrors only | `WHERE CloseDateID = 0` |
| Mirrors opened on a specific date | `WHERE OpenDateID = YYYYMMDD` |
| Snapshot for a specific instrument | `WHERE InstrumentID = @id` |

### 3.2 Gotchas

- **snapshot_date is not a stable timestamp**: It reflects the query execution date, not the data load date. If queried on different days, the same row will show different `snapshot_date` values
- **SELECT * pattern**: If `Dim_Mirror` schema changes (new columns added), this view automatically exposes them — and any downstream consumers may break silently if column position matters
- **11.1M rows**: Always filter. See [Dim_Mirror query advisory](../Tables/Dim_Mirror.md) for indexing details (HASH(MirrorID), clustered on OpenDateID+MirrorID)

---

## 4. Elements

All columns from `DWH_dbo.Dim_Mirror` are inherited by `SELECT *`. For full element descriptions, see [DWH_dbo.Dim_Mirror § Elements](../Tables/Dim_Mirror.md).

The view adds one column beyond Dim_Mirror:

| # | Element | Type | Description |
|---|---------|------|-------------|
| +1 | snapshot_date | date | Current calendar date at query execution time. `CAST(GETDATE() AS DATE)`. Used as a daily snapshot label for dashboards and snapshot exports. Changes on every query invocation — not a stable historical timestamp. (Tier 2 — view DDL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|---------------|---------------|-----------|
| (all Dim_Mirror cols) | DWH_dbo.Dim_Mirror | (all cols) | SELECT * passthrough |
| snapshot_date | — | — | View-computed: CAST(GETDATE() AS DATE) at query time |

### 5.2 Data Flow

```
etoro.Trade.Mirror + etoro.History.Mirror
  |
  v [SP_Dim_Mirror_DL_To_Synapse — daily incremental]
DWH_dbo.Dim_Mirror (11.1M rows)
  |
  v [SELECT *, CAST(GETDATE() AS DATE) AS snapshot_date]
DWH_dbo.v_Dim_Mirror (view — no storage)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (all columns) | DWH_dbo.Dim_Mirror | Base table — see Dim_Mirror.md for full relationship map |

### 6.2 Referenced By (other objects point to this)

No known consumers identified at documentation time. This view serves as a convenience alias for Dim_Mirror with a snapshot date label.

---

## 7. Sample Queries

### 7.1 Active mirrors with snapshot date

```sql
SELECT TOP 100
    snapshot_date,
    MirrorID,
    CID,
    ParentCID,
    Amount,
    OpenDateID
FROM [DWH_dbo].[v_Dim_Mirror]
WHERE CloseDateID = 0
ORDER BY OpenDateID DESC
```

### 7.2 Compare with base table

```sql
-- v_Dim_Mirror returns same rows as Dim_Mirror plus snapshot_date
SELECT COUNT_BIG(*) FROM [DWH_dbo].[v_Dim_Mirror]   -- equals Dim_Mirror count
SELECT COUNT_BIG(*) FROM [DWH_dbo].[Dim_Mirror]      -- baseline
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [Trade.Mirror](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13795033131) | Copy-trading (mirror) relationships — source-system context for Dim_Mirror |
| [Mirror (Copy) Behavior](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/12177343249) | Copy stop loss, drift, and mirror portfolio behavior |
| [Copy trading with Multi-Currency](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14030438427) | How mirrors and allocations work in multi-currency copy trading |
| [DWH Process Data Sources](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11466244151) | Lists `etoro.Trade.Mirror` as a DWH pipeline source |
| [Introduction to CopyTrader](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1135673583) | Product-level copy-trading concepts (balance to mirror, allocation) |

---

*Generated: 2026-03-19 | Quality: 7.8/10 | Phases: 5/14 (simple view — P2/P3/P4/P8/P9/P9B/P10 not applicable)*
*Tiers: 0 T1, 1 T2 (view DDL), 0 T3, 0 T4-Inferred | Elements: 8.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 9/10*
*Object: DWH_dbo.v_Dim_Mirror | Type: View | Production Source: DWH_dbo.Dim_Mirror (passthrough + snapshot_date)*
