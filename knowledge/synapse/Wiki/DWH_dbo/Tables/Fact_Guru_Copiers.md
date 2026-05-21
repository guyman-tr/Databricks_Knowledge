# DWH_dbo.Fact_Guru_Copiers

> Daily aggregated snapshot of Assets Under Copy (AUC) per copier — recording cash, investment, PnL, and detached position values for each customer actively copying a Popular Investor (Guru) through eToro's CopyTrader feature.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Row Count** | Large (daily append, data from 2018 onward) |
| **Production Source** | `etoro.History.GuruCopiers` (via `DWH_staging.etoro_History_GuruCopiers`) |
| **Refresh** | Daily (DELETE + re-INSERT for the day via SP_Fact_Guru_Copiers) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **Synapse PK** | (DateID, CID) NOT ENFORCED |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers` |
| **UC Format** | Parquet |
| **Generic Pipeline** | ID 415, SynapseSourceWithoutSecret, daily Append |

---

## 1. Business Meaning

`Fact_Guru_Copiers` is the daily financial snapshot of eToro's CopyTrader ecosystem, aggregated per copier. Each row represents one customer (CID) on one day (DateID), showing the total value of their copy-trading portfolio: how much cash they have allocated, how much is invested in open positions, their unrealized PnL, and the value of detached positions.

The table answers: "On any given day, what is the total Assets Under Copy (AUC) for each copier, broken down by cash, investment, PnL, and detached positions?"

In eToro's social trading model:
- A **copier** allocates funds to copy a **Popular Investor (PI/Guru)**
- The platform automatically mirrors the PI's trades proportionally
- **CopyFundAUM** is the total value: Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL

The data is aggregated from individual copy relationships (CID → ParentCID pairs in `Ext_FGC_Guru_Copiers`) and filtered to `AccountTypeID = 9` (CopyFund accounts) via `Fact_SnapshotCustomer`.

## 2. Business Logic

### CopyFundAUM Calculation

```
CopyFundAUM = Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL
```

This is the total portfolio value for a copier's CopyTrader activity. It includes:
- **Cash**: Undeployed funds allocated to copy relationships
- **Investment**: Capital in open positions that mirror the guru's trades
- **PnL**: Unrealized gains/losses on those mirrored positions
- **DetachedPosInvestment**: Positions the copier "detached" (took manual control of)
- **Dit_PnL**: PnL on detached positions

### AccountTypeID = 9 Filter

The JOIN to Fact_SnapshotCustomer filters on `AccountTypeID = 9` (CopyFund). This ensures only CopyFund relationships are included, excluding regular trading or Smart Portfolio relationships.

### ISNULL(column, 0) Pattern

All money columns use `ISNULL(x, 0)` before SUM — ensuring NULL values (e.g., a copier with no detached positions) don't null out the entire aggregation.

### Key Transform: Aggregation

The staging table `Ext_FGC_Guru_Copiers` has one row per (CID, ParentCID) — i.e., one row per copy relationship. The SP aggregates across all copy relationships for the same CID, producing one row per copier per day. A copier copying 3 gurus has 3 staging rows collapsed to 1 fact row.

## 3. Query Advisory

| Property | Value |
|----------|-------|
| **Distribution** | HASH(CID) — optimized for per-copier queries |
| **Index** | Clustered Columnstore — efficient for aggregate queries over large date ranges |
| **PK** | (DateID, CID) NOT ENFORCED — composite key, no uniqueness enforcement |
| **Recommended Filters** | Always filter on `DateID` first (YYYYMMDD int format) |
| **Known Issues** | None identified |

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | bigint | NO | Customer ID of the copier — the person allocating funds to copy a Popular Investor. This is the copier's RealCID, not the guru's. Distribution key. (Tier 2 — SP_Fact_Guru_Copiers) |
| 2 | DateID | int | NO | Date key in YYYYMMDD format for the snapshot day. Part of composite PK. (Tier 2 — SP_Fact_Guru_Copiers) |
| 3 | Cash | money | YES | Sum of available cash across all active copy relationships for this copier on this day. Cash not yet deployed into positions. (Tier 2 — Ext_FGC_Guru_Copiers / AUM Life Cycle confluence) |
| 4 | Investment | money | YES | Sum of investment amounts across all copy relationships for this copier on this day. Aggregated from Ext_FGC_Guru_Copiers, which is loaded from [DWH_staging].[etoro_History_GuruCopiers]. |
| 5 | PnL | money | YES | Sum of unrealized profit/loss across all open copy positions. Fluctuates with market movements. (Tier 2 — SP_Fact_Guru_Copiers) |
| 6 | DetachedPosInvestment | money | YES | Sum of investment in positions that have been detached from the copy relationship but remain open. Detachment occurs when a copier manually takes control of an individual position. (Tier 2 — SP_Fact_Guru_Copiers) |
| 7 | Dit_PnL | money | YES | Unrealized PnL on detached positions. Separate from PnL because detached positions are no longer managed by the copy relationship. (Tier 2 — SP_Fact_Guru_Copiers) |
| 8 | CopyFundAUM | money | YES | Total Assets Under Copy: `Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL`. Computed in the SP, not stored at source. This is the headline metric for copy-trading portfolio value. (Tier 2 — SP_Fact_Guru_Copiers) |
| 9 | UpdateDate | datetime | YES | Timestamp when this row was loaded into the DWH via `GETDATE()`. (Tier 2 — SP_Fact_Guru_Copiers) |

## 5. Lineage

### Two-SP Pipeline

```
SP_Fact_Guru_Copiers_DL_To_Synapse(@dt)
  │
  ├─ [Step 1] DELETE from Fact_Guru_Copiers WHERE DateID = @dt
  │    → Idempotent re-run: clears today's data before re-loading
  │
  ├─ [Step 2] TRUNCATE Ext_FGC_Guru_Copiers
  │    → Clears staging table
  │
  ├─ [Step 3] INSERT INTO Ext_FGC_Guru_Copiers
  │    SELECT FROM DWH_staging.etoro_History_GuruCopiers
  │    WHERE [Timestamp] = @Yesterday
  │    → Loads individual copy relationship records for the day
  │    → CAST money columns to decimal(18,4)
  │    → DateID computed from [Timestamp]
  │
  └─ [Step 4] EXEC SP_Fact_Guru_Copiers @Yesterday
       │
       ├─ INSERT INTO Fact_Guru_Copiers
       │    SELECT g.CID, DateID,
       │           SUM(ISNULL(Cash,0)),
       │           SUM(ISNULL(Investment,0)),
       │           SUM(ISNULL(PnL,0)),
       │           SUM(ISNULL(DetachedPosInvestment,0)),
       │           SUM(ISNULL(Dit_PnL,0)),
       │           SUM(Cash)+SUM(Investment)+SUM(PnL)+SUM(DetachedPos)+SUM(Dit_PnL),  -- CopyFundAUM
       │           GETDATE()
       │    FROM Ext_FGC_Guru_Copiers g
       │    JOIN Fact_SnapshotCustomer fsc
       │      ON g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9
       │    JOIN V_M2M_Date_DateRange bb
       │      ON fsc.DateRangeID = bb.DateRangeID AND DateID = bb.DateKey
       │    GROUP BY g.CID, DateID
       │
       └─ Log row count via SP_Log_Full
```

### Source Chain

```
etoro.History.GuruCopiers (production — daily snapshot of copy relationships)
  → Generic Pipeline (Bronze, daily)
  → DWH_staging.etoro_History_GuruCopiers
  → SP_Fact_Guru_Copiers_DL_To_Synapse (staging loader)
  → Ext_FGC_Guru_Copiers (staging table, ROUND_ROBIN)
  → SP_Fact_Guru_Copiers (aggregation + JOIN)
  → DWH_dbo.Fact_Guru_Copiers (final)
  → Generic Pipeline ID 415 (Gold, daily Append, parquet)
  → dwh.gold_sql_dp_prod_we_dwh_dbo_fact_guru_copiers (UC)
```

### Referenced By

| Object | Usage |
|--------|-------|
| SP_Fact_Guru_Copiers | Writer SP (daily load) |
| SP_Fact_Guru_Copiers_DL_To_Synapse | Orchestration SP (staging + trigger) |
| CopiersAPI | REST API that exposes copy trading graph data (may query downstream) |

## 6. Relationships

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Ext_FGC_Guru_Copiers | CID = g.CID (source) | Staging source — individual copy relationship records | Inbound |
| DWH_dbo.Fact_SnapshotCustomer | g.ParentCID = fsc.RealCID AND fsc.AccountTypeID = 9 | Filters to CopyFund accounts — links copier to their guru's snapshot state | Inbound |
| DWH_dbo.V_M2M_Date_DateRange | fsc.DateRangeID = bb.DateRangeID AND DateID = bb.DateKey | Date range expansion — ensures the copier's snapshot is active for the target date | Inbound |
| DWH_dbo.Dim_Date | DateID = DateKey | Calendar dimension | Outbound FK (implicit) |
| DWH_dbo.Dim_Customer | CID = RealCID | Customer who is the copier | Outbound FK (implicit) |

## 7. Sample Queries

```sql
-- Daily AUC for a specific copier
SELECT DateID, CopyFundAUM, Cash, Investment, PnL
FROM [DWH_dbo].[Fact_Guru_Copiers]
WHERE CID = 12345678
ORDER BY DateID DESC;

-- Total platform AUC by day (last 30 days)
SELECT DateID,
       SUM(CopyFundAUM) AS total_auc,
       COUNT(DISTINCT CID) AS active_copiers
FROM [DWH_dbo].[Fact_Guru_Copiers]
WHERE DateID >= 20260218
GROUP BY DateID
ORDER BY DateID;
```

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| [AUM Life Cycle](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13816037555) | Detailed explanation of Cash, Investment, PnL components and their upstream sources (Trade.Mirror, Trade.Position, History.GuruCopiers) |
| [CopiersAPI Documentation](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/13983646311) | REST API exposing copy trading social graph data |
| [Introduction to CopyTrader](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1135673583) | Business overview of CopyTrader feature — proportional trade mirroring |

---

*Generated: 2026-03-19 | Quality: 8.5/10 (★★★★☆) | Phases: 10/14*
*Tiers: 0 T1, 9 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10*
*Object: DWH_dbo.Fact_Guru_Copiers | Type: Table | Production Source: etoro.History.GuruCopiers*
