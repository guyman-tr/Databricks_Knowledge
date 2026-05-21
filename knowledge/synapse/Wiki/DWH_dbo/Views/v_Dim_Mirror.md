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

| # | Column | Type | Nullable | Source | Description |
|---|--------|------|----------|--------|-------------|
| 1 | MirrorID | int | NO | Dim_Mirror.MirrorID | Primary key. Allocated by identity on INSERT via Trade.RegisterMirror. Referenced by Trade.Position.MirrorID, History.Mirror. (Tier 1 — inherited from Dim_Mirror wiki) |
| 2 | CID | int | NO | Dim_Mirror.CID | Copier customer ID. The user who allocates money to follow the leader. Trade.ValidateNumOfActiveMirrors counts mirrors per CID. (Tier 1 — inherited from Dim_Mirror wiki) |
| 3 | ParentCID | int | YES | Dim_Mirror.ParentCID | Leader customer ID. The user whose trades are copied. Trade.GetActiveCopiersForParents filters by ParentCID. (Tier 1 — inherited from Dim_Mirror wiki) |
| 4 | ParentUserName | varchar(50) | YES | Dim_Mirror.ParentUserName | Leader username at mirror creation. Denormalized for display; Trade.RegisterMirror passes from caller. (Tier 1 — inherited from Dim_Mirror wiki) |
| 5 | Amount | numeric(16,8) | YES | Dim_Mirror.Amount | Allocation amount in dollars. Credit allocated to this mirror. Trade.RegisterMirror sets from @AmountInCents/100. (Tier 1 — inherited from Dim_Mirror wiki) |
| 6 | OpenOccurred | datetime | YES | Dim_Mirror.OpenOccurred | Datetime the copy relationship was opened (started). From Trade.Mirror.Occurred. Covers back to 2011-06-13 (first CopyTrader launch). (Tier 2 — via Dim_Mirror) |
| 7 | OpenDateID | int | YES | Dim_Mirror.OpenDateID | yyyymmdd integer of OpenOccurred. Clustered index key -- use for efficient date-range filtering. (Tier 1 — inherited from Dim_Mirror wiki) |
| 8 | CloseOccurred | datetime | YES | Dim_Mirror.CloseOccurred | Datetime the copy relationship was closed. '1900-01-01 00:00:00' sentinel = still open (CloseDateID=0). For closed mirrors, this is History.Mirror.ModificationDate at the close event. (Tier 2 — via Dim_Mirror) |
| 9 | CloseDateID | int | YES | Dim_Mirror.CloseDateID | yyyymmdd integer of CloseOccurred. 0 = open mirror (active); > 0 = closed on that date. Primary filter for open/closed status. (Tier 1 — inherited from Dim_Mirror wiki) |
| 10 | MirrorTypeID | int | YES | Dim_Mirror.MirrorTypeID | 1=Regular, 2=CopyMe, 3=Social Index, 4=Fund (Dictionary.MirrorType). Determines mirror behavior. (Tier 1 — inherited from Dim_Mirror wiki) |
| 11 | CloseMirrorActionType | int | YES | Dim_Mirror.CloseMirrorActionType | Why mirror closed: 0=Customer, 1=Stop Loss, 2=BSL, 3=Manual Liquidation, 4=BackOffice, 5=Customer Detach, 6=BackOffice Detach. NULL when active. (Tier 1 — inherited from Dim_Mirror wiki) |
| 12 | IsActive | tinyint | YES | Dim_Mirror.IsActive | 1=mirror is live (copier follows leader), 0=mirror closed. (Tier 1 — inherited from Dim_Mirror wiki) |
| 13 | IsOpenOpen | bit | YES | Dim_Mirror.IsOpenOpen | Flag for open-on-open copy behavior. NULL in sample data. (Tier 1 — inherited from Dim_Mirror wiki) |
| 14 | PauseCopy | bit | YES | Dim_Mirror.PauseCopy | 0=copying, 1=paused. No new positions when paused. (Tier 1 — inherited from Dim_Mirror wiki) |
| 15 | MirrorSL | money | YES | Dim_Mirror.MirrorSL | Absolute mirror stop-loss threshold in dollars. Trade.RegisterMirror validates against MirrorSLPercentage. (Tier 1 — inherited from Dim_Mirror wiki) |
| 16 | MirrorSLPercentage | money | YES | Dim_Mirror.MirrorSLPercentage | MSL as percentage. Default 2. Trade.RegisterMirror validates MirrorSL = Amount * (MirrorSLPercentage/100). (Tier 1 — inherited from Dim_Mirror wiki) |
| 17 | RealizedEquity | money | YES | Dim_Mirror.RealizedEquity | Realized equity for this mirror. Used with MirrorCalculationType=0 for MSL. Updated on position close. (Tier 1 — inherited from Dim_Mirror wiki) |
| 18 | InitialInvestment | money | YES | Dim_Mirror.InitialInvestment | Initial allocation. Trade.RegisterMirror sets from @AmountInDollars or @InitialInvestment. (Tier 1 — inherited from Dim_Mirror wiki) |
| 19 | WithdrawalSummary | money | YES | Dim_Mirror.WithdrawalSummary | Sum of withdrawals from mirror. (Tier 1 — inherited from Dim_Mirror wiki) |
| 20 | DepositSummary | money | YES | Dim_Mirror.DepositSummary | Sum of deposits into mirror. Trade.RegisterMirror accepts from caller. (Tier 1 — inherited from Dim_Mirror wiki) |
| 21 | RealziedPnL | money | YES | Dim_Mirror.RealziedPnL | Net realized profit/loss of the mirror in USD. NOTE: column name has a typo ('Realzied' not 'Realized'). For closed mirrors: final P&L from History.Mirror.NetProfit. (Tier 1 — inherited from Dim_Mirror wiki) |
| 22 | GuruTPV | money | YES | Dim_Mirror.GuruTPV | Guru/leader take-profit value. NULL in sample. Optional override. (Tier 1 — inherited from Dim_Mirror wiki) |
| 23 | UseCopyDividend | tinyint | YES | Dim_Mirror.UseCopyDividend | 1=copy dividends to copier, 0=do not. Trade.MirrorDividendWithdrawal checks. (Tier 1 — inherited from Dim_Mirror wiki) |
| 24 | UpdateDate | datetime | YES | Dim_Mirror.UpdateDate | ETL run timestamp from the last SP update that touched this row. Set to GETDATE() on each UPDATE/INSERT by the SP. (Tier 2 — via Dim_Mirror) |
| 25 | SessionID | bigint | YES | Dim_Mirror.SessionID | Session identifier from History.Mirror.SessionID at the mirror open event (MirrorOperationID=1). Links the mirror opening to a specific trading session. NULL for older historical mirrors predating SessionID tracking. (Tier 2 — via Dim_Mirror) |
| 26 | IsCopyFundMirror | int | YES | Dim_Mirror.IsCopyFundMirror | 1 if the ParentCID is an eToro Fund account (BackOffice AccountTypeID=9); 0 or NULL for regular customer-to-customer copies. Derived post-load from BackOffice_Customer data. Fund mirrors (IsCopyFundMirror=1) overlap with MirrorTypeID=4. (Tier 2 — via Dim_Mirror) |
| 27 | snapshot_date | date | NO | Computed: CAST(GETDATE() AS DATE) | Current calendar date at query execution time. Used as a daily snapshot label for dashboards and snapshot exports. Non-deterministic — changes on every query invocation. (Tier 2 — view DDL) |

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

*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Batch: 17 | 27 columns expanded (26 Tier 1 inherited from Dim_Mirror wiki + 1 computed) | Sources: SSDT DDL, Dim_Mirror.md*
