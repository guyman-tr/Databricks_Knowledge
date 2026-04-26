# BI_DB_dbo.BI_DB_eTorian_PnL

> Month-end snapshot of unrealized open-position PnL for eTorian (VIP) customers, split into three asset buckets: Crypto, Stocks & ETFs, and Other. Written once per month by the `SP_eTorian_PnL_NetProfit` month-end block, sourced from `BI_DB_PositionPnL` filtered to active eTorian CIDs (PlayerLevelID=4). Companion to `BI_DB_eTorian_NetProfit` (daily closed-position net profit, same SP). Jan 2021 – Mar 2026; 78,213 rows; ~1,200 CIDs per month-end.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_PositionPnL` — open position PnL at month-end DateID, joined to eTorian #list |
| **Refresh** | Month-end only — SP guard: `IF @Date = EOMONTH(@Date)`; DELETE WHERE EOM_Snapshot_OpenPosition=@Date + INSERT |
| **OpsDB Priority** | 20 (SB_Daily) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (EOM_Snapshot_OpenPosition ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_eTorian_PnL` captures the **unrealized open-position PnL at each month-end** for eTorian customers — the company's VIP tier (PlayerLevelID=4). Where `BI_DB_eTorian_NetProfit` records the profit/loss realised on positions that closed on a given day, this table records what customers still hold open: how much they are currently up or down on their open positions at the last day of each month.

**eTorian context**: The "eTorian" prefix marks tables scoped to VIP-tier customers (PlayerLevelID=4 in `Fact_SnapshotCustomer`, AccountTypeID IN (7,13), non-cancelled). This is a named customer segment — typically high-value, high-volume traders. CID=149 is an internal/test account included in all eTorian queries by convention.

**Month-end only**: Despite the OpsDB schedule being `SB_Daily`, the SP contains an explicit guard: `IF @Date = EOMONTH(@Date)` before the DELETE+INSERT for this table. On non-month-end runs the PnL block is skipped entirely, and only `BI_DB_eTorian_NetProfit` (the daily closed-positions table) is written.

**Asset buckets**: PnL is split into three buckets using `DWH_dbo.Dim_Instrument.InstrumentTypeID`:
- **Pnl_Crypto** — InstrumentTypeID=10 (cryptocurrency instruments)
- **Pnl_Stocks_ETFs** — InstrumentTypeID IN (5, 6) (equities and exchange-traded funds)
- **Pnl_Other** — InstrumentTypeID IN (1, 2, 4) (Forex, indices, commodities, and other CFDs)

**Observed distribution** (78,213 rows across 63 month-ends): Pnl_Crypto is non-zero for 80% of rows, Pnl_Stocks_ETFs for 73%, and Pnl_Other for only 24% — reflecting that eTorian customers predominantly hold crypto and equity positions.

---

## 2. Business Logic

### 2.1 eTorian Customer Population (#list)

**What**: The SP builds a temp table of active eTorian CIDs and their usernames at the run date.

**Rules**:
- Source: `Fact_SnapshotCustomer` active SCD row (via `Dim_Range`) at `@DateID`
- Filter: `PlayerLevelID=4` AND `(AccountStatusID!=2 OR AccountStatusID IS NULL)` AND `AccountTypeID IN (7,13)` AND `PlayerStatusID!=2`
- Hardcoded inclusion: `OR fsc.RealCID=149` (internal/test account)
- Result: ~1,200–1,290 CIDs per month-end (recent data)

### 2.2 Month-End Open Position PnL (#PnL)

**What**: Aggregates open-position PnL from `BI_DB_PositionPnL` for eTorian CIDs at the month-end date.

**Columns Involved**: Pnl_Crypto, Pnl_Stocks_ETFs, Pnl_Other, EOM_Snapshot_OpenPosition

**Rules**:
- Source: `BI_DB_PositionPnL WHERE DateID = @DateID` (point-in-time open position snapshot)
- Join to `#list` to restrict to eTorian CIDs
- Join to `Dim_Instrument` for InstrumentTypeID routing
- `EOM_Snapshot_OpenPosition` = `@Date` (always a month-end date: Jan 31, Feb 28/29, etc.)
- PnL values can be negative (unrealized losses on underwater positions)
- All three buckets always present per row (0.0000 if no positions in that asset class)

### 2.3 Month-End Guard and DELETE+INSERT

**What**: Ensures idempotent month-end write; skipped entirely on non-month-end days.

**Rules**:
- Guard condition: `IF @Date = EOMONTH(@Date)` — only fires on the last calendar day of a month
- `DELETE FROM BI_DB_eTorian_PnL WHERE EOM_Snapshot_OpenPosition = @Date` — idempotent re-run safety
- `INSERT ... SELECT FROM #PnL` — one row per CID per month-end
- Same SP also writes `BI_DB_eTorian_NetProfit` (closed positions) on EVERY run, not just month-end

---

## 3. Query Advisory

### 3.1 Distribution and Index

- **HASH(CID)**: Optimal for CID-specific queries and JOINs on CID (e.g., joining to `BI_DB_eTorian_NetProfit` or `Dim_Customer`)
- **Clustered index on EOM_Snapshot_OpenPosition**: Use `WHERE EOM_Snapshot_OpenPosition = @date` for month-specific slices; `ORDER BY EOM_Snapshot_OpenPosition` is efficient

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Open PnL for a specific eTorian customer across months | `WHERE CID = @cid ORDER BY EOM_Snapshot_OpenPosition` |
| Aggregate crypto PnL for all eTorian customers in a month | `WHERE EOM_Snapshot_OpenPosition = @eom GROUP BY CID SUM(Pnl_Crypto)` |
| Customers with net open loss (sum of all buckets < 0) | `WHERE EOM_Snapshot_OpenPosition = @eom AND Pnl_Crypto + Pnl_Stocks_ETFs + Pnl_Other < 0` |
| Month-over-month crypto PnL trend | `GROUP BY EOM_Snapshot_OpenPosition ORDER BY EOM_Snapshot_OpenPosition` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_eTorian_NetProfit | CID=CID AND EOM_CloseDate=EOM_Snapshot_OpenPosition | Compare open vs realised PnL for same month |
| DWH_dbo.Dim_Customer | CID=RealCID | Enrich with customer attributes |

### 3.4 Gotchas

- **Month-end dates only** — EOM_Snapshot_OpenPosition values are always last-day-of-month (e.g., 2026-03-31). Queries on mid-month dates return no rows
- **OpsDB says SB_Daily but writes monthly** — the schedule is inherited from the SP's daily run; the table itself only gains a new partition on month-end
- **CID=149 always included** — this is an internal/test account present in all eTorian queries; exclude it for customer analytics (`WHERE CID != 149`)
- **Pnl_Other = 0 in 76% of rows** — zero is a valid value, not missing data; eTorian customers rarely hold Forex/index/commodity positions
- **Values are per-CID totals** — each row is the SUM across all instruments in that bucket for that CID at that month-end; there is no instrument-level breakdown in this table

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from DWH_dbo wiki (Tier 1 source for BI_DB_dbo) |
| Tier 2 | From SP code (SP_eTorian_PnL_NetProfit) |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best available — unverified |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NOT NULL | Customer ID for eTorian (VIP) customer. PlayerLevelID=4 in Fact_SnapshotCustomer. HASH distribution key. FK to Dim_Customer (CID=RealCID). (Tier 2 — SP_eTorian_PnL_NetProfit #list) |
| 2 | UserName | varchar(max) | NULL | Customer display name at time of month-end run. Sourced from DWH_dbo.Dim_Customer via #list. Included for audit/display; not a join key. (Tier 2 — SP_eTorian_PnL_NetProfit #list) |
| 3 | EOM_Snapshot_OpenPosition | date | NULL | Month-end date of the open-position PnL snapshot (e.g., 2026-03-31). Clustered index key. Always EOMONTH(@Date) by SP guard. Range: 2021-01-31 to 2026-03-31. (Tier 2 — SP_eTorian_PnL_NetProfit) |
| 4 | Pnl_Crypto | decimal(16,4) | NULL | Sum of unrealized open-position PnL on cryptocurrency instruments (InstrumentTypeID=10) for this CID at month-end. Negative = unrealized loss. Non-zero in ~80% of rows. (Tier 2 — SP_eTorian_PnL_NetProfit) |
| 5 | Pnl_Stocks_ETFs | decimal(16,4) | NULL | Sum of unrealized open-position PnL on equity and ETF instruments (InstrumentTypeID IN (5, 6)) for this CID at month-end. Negative = unrealized loss. Non-zero in ~73% of rows. (Tier 2 — SP_eTorian_PnL_NetProfit) |
| 6 | Pnl_Other | decimal(16,4) | NULL | Sum of unrealized open-position PnL on other instruments — Forex, indices, commodities, CFDs (InstrumentTypeID IN (1, 2, 4)) for this CID at month-end. Negative = unrealized loss. Non-zero in ~24% of rows. (Tier 2 — SP_eTorian_PnL_NetProfit) |
| 7 | UpdateDate | datetime | NULL | ETL timestamp set to GETDATE() at INSERT time. NULL if row pre-dates column addition (unlikely for this table starting 2021). (Tier 2 — SP_eTorian_PnL_NetProfit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Via #list; eTorian filter applied |
| UserName | DWH_dbo.Dim_Customer | UserName | Via #list join on RealCID |
| EOM_Snapshot_OpenPosition | SP parameter | @Date | Direct; only written when @Date=EOMONTH(@Date) |
| Pnl_Crypto | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | SUM WHERE InstrumentTypeID=10 |
| Pnl_Stocks_ETFs | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | SUM WHERE InstrumentTypeID IN (5, 6) |
| Pnl_Other | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | SUM WHERE InstrumentTypeID IN (1, 2, 4) |
| UpdateDate | ETL | GETDATE() | Set at INSERT time |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Customer
  |-- Filter: PlayerLevelID=4, active SCD row at @DateID
  |-- → #list (eTorian CIDs + UserNames)
  |
BI_DB_dbo.BI_DB_PositionPnL
  |-- WHERE DateID = @DateID
  |-- JOIN #list ON CID
  |-- JOIN DWH_dbo.Dim_Instrument ON InstrumentID (→ InstrumentTypeID)
  |-- GROUP BY CID, UserName (SUM by instrument bucket)
  |-- → #PnL temp table
  |
  [IF @Date = EOMONTH(@Date)]
  |-- DELETE WHERE EOM_Snapshot_OpenPosition = @Date
  |-- INSERT
  v
BI_DB_dbo.BI_DB_eTorian_PnL
  (78,213 rows | Jan 2021 – Mar 2026 | 63 months | HASH(CID), CLUSTERED(EOM_Snapshot_OpenPosition))
  UC: _Not_Migrated

Companion (written every day, not just month-end):
  DWH_dbo.Dim_Position (closed positions, CloseDateID=@DateID)
  v
BI_DB_dbo.BI_DB_eTorian_NetProfit
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (CID = RealCID) |
| (source) | BI_DB_dbo.BI_DB_PositionPnL | Primary PnL source — open position snapshot at month-end |
| (population) | DWH_dbo.Fact_SnapshotCustomer | eTorian customer filter (PlayerLevelID=4) |
| (instrument) | DWH_dbo.Dim_Instrument | InstrumentTypeID routing for PnL buckets |

### 6.2 Referenced By

| Object | Column | Usage |
|--------|--------|-------|
| BI_DB_dbo.BI_DB_eTorian_NetProfit | (companion) | Same SP also writes this table (closed positions, daily) |

---

## 7. Sample Queries

### Open PnL trend for a specific eTorian customer

```sql
SELECT [EOM_Snapshot_OpenPosition],
       [Pnl_Crypto],
       [Pnl_Stocks_ETFs],
       [Pnl_Other],
       [Pnl_Crypto] + [Pnl_Stocks_ETFs] + [Pnl_Other] AS Total_Open_PnL
FROM [BI_DB_dbo].[BI_DB_eTorian_PnL]
WHERE [CID] = 12345
ORDER BY [EOM_Snapshot_OpenPosition]
```

### eTorian aggregate open PnL by asset class for a month-end

```sql
SELECT [EOM_Snapshot_OpenPosition],
       COUNT(*) AS CID_Count,
       SUM([Pnl_Crypto]) AS Total_Crypto_PnL,
       SUM([Pnl_Stocks_ETFs]) AS Total_Stocks_ETFs_PnL,
       SUM([Pnl_Other]) AS Total_Other_PnL
FROM [BI_DB_dbo].[BI_DB_eTorian_PnL]
WHERE [EOM_Snapshot_OpenPosition] = '2026-03-31'
  AND [CID] != 149  -- exclude internal test account
GROUP BY [EOM_Snapshot_OpenPosition]
```

### Customers with net open position losses at month-end

```sql
SELECT [CID], [UserName],
       [Pnl_Crypto] + [Pnl_Stocks_ETFs] + [Pnl_Other] AS Total_Open_PnL
FROM [BI_DB_dbo].[BI_DB_eTorian_PnL]
WHERE [EOM_Snapshot_OpenPosition] = '2026-03-31'
  AND [Pnl_Crypto] + [Pnl_Stocks_ETFs] + [Pnl_Other] < 0
  AND [CID] != 149
ORDER BY Total_Open_PnL ASC
```

---

## 8. Atlassian Knowledge Sources

No dedicated Confluence or Jira pages found for this table. See `BI_DB_eTorian_NetProfit` wiki for related context on the eTorian closed-position companion table.

---

*Generated: 2026-04-22 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 7 T2, 0 T3, 0 T4, 0 T5 | Elements: 7/7, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_eTorian_PnL | Type: Table | Production Source: BI_DB_dbo.BI_DB_PositionPnL*
