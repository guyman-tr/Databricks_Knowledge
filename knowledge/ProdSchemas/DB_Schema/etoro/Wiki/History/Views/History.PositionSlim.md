# History.PositionSlim

> High-performance alternative to History.Position covering 2021+ closed positions only - same 124-column schema as History.Position's modern branches plus PartitionCol (PositionID%50) for hash-partitioned JOINs - deliberately excludes all 62 quarterly archive tables (pre-2021Q2 data) for fast queries on recent positions. 85 procedure consumers make this the most heavily-used position view for portfolio history and account statement procedures.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (bigint) |
| **Partition** | N/A (view - base tables partitioned/indexed) |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.PositionSlim is the primary position history view for procedures that need recent closed positions (2021+) at scale. It covers the same data as `History.Position`'s 3 modern source branches but deliberately omits all 62 quarterly archive tables (dbo.HistoryPosition_2007Q3 through dbo.HistoryPosition_2022Q4), which makes it dramatically faster for queries that do not need pre-2021 trade history.

The name "Slim" does not mean fewer columns - it has **125 columns** (one more than History.Position's 124). "Slim" refers to the reduced UNION ALL fan-out: 3 sources instead of History.Position's 4-source architecture that includes 62 archive tables. For portfolio history, account statements, and close-position procedures that only need positions from 2021 onward, History.PositionSlim avoids scanning 62 additional tables.

The extra column is `PartitionCol = [PositionID]%(50)`, a hash bucket derived from PositionID modulo 50. This column enables efficient hash-partitioned JOINs: procedures that need to cross-join position data with Trade.PositionTreeInfo can filter on `abs(TPOS.TreeID%50) = TPTI.PartitionCol` to shard the JOIN across partition buckets rather than doing a full cross-join or range scan.

**Three UNION ALL sources**:
1. `History.Position_Active` - the primary 2021+ closed position archive (2,511,608 rows)
2. `Trade.PositionTbl INNER JOIN Trade.PositionTreeInfo WHERE StatusID=2` - live recently-closed positions not yet archived
3. `History.PositionClosePartial` - partial-close position records

**85 procedure consumers** make this the most widely-referenced position view in the codebase, used by: TAPI portfolio history, account statements, manual position close, dividend snapshots, execution reports, and monitoring.

---

## 2. Business Logic

### 2.1 UNION ALL Architecture (3 Sources - Modern Data Only)

**What**: Combines 3 sources covering 2021+ closed positions. Does NOT include the 62 quarterly dbo.HistoryPosition_* archive tables.

**Rules**:
- Branch 1: `History.Position_Active` - permanent archive for positions closed >= 2021-04-01. 2,511,608 rows. SELECT * (all columns) plus PartitionCol computed.
- Branch 2: `Trade.PositionTbl INNER JOIN Trade.PositionTreeInfo WHERE Trade.PositionTbl.StatusID=2` - live closed positions awaiting async archival. Identical 124-column SELECT as Branch 1 (same format as History.Position's Trade branch).
- Branch 3: `History.PositionClosePartial` - positions created by the partial-close flow (clones with only the closed units; never passed through Trade.PositionTbl).
- PartitionCol is computed in each branch as `[PositionID]%(50)` - a value 0-49 derived from PositionID modulo 50.
- UNION ALL is used (not UNION): the same PositionID cannot appear in multiple branches simultaneously due to the archive pattern (DELETE...INSERT for full closes; direct inserts for partial closes).

**Diagram**:
```
History.Position_Active (2021+ archive, 2.5M rows)
  SELECT PositionID...(124 cols), [PositionID]%(50) AS PartitionCol
  |
UNION ALL
  |
Trade.PositionTbl INNER JOIN Trade.PositionTreeInfo
  WHERE Trade.PositionTbl.StatusID=2 (recently closed, pending archival)
  SELECT PositionID...(124 cols), [PositionID]%(50) AS PartitionCol
  |
UNION ALL
  |
History.PositionClosePartial (partial-close position records)
  SELECT PositionID...(124 cols), [PositionID]%(50) AS PartitionCol
  |
  v
History.PositionSlim (125 cols - 124 position cols + PartitionCol)
```

### 2.2 PartitionCol - Hash-Partitioned JOIN Pattern

**What**: The extra column PartitionCol = PositionID%(50) enables hash-partitioned JOINs that reduce cross-join overhead when joining position history with tree/portfolio data.

**Columns/Parameters Involved**: `PartitionCol`, `PositionID`

**Rules**:
- PartitionCol = [PositionID]%(50), producing values 0 through 49
- Consumers use this pattern: `JOIN History.PositionSlim ps ON ps.PartitionCol = abs(TPOS.TreeID%50)`
- This distributes the join workload into 50 hash buckets rather than a full scan
- The pattern is used by TAPI procedures that aggregate portfolio history across millions of positions
- History.Position does NOT have PartitionCol; History.PositionSlim exists specifically to provide it

### 2.3 Coverage vs History.Position

**What**: History.PositionSlim and History.Position differ in data coverage and schema.

| Aspect | History.PositionSlim | History.Position |
|--------|---------------------|-----------------|
| Source count | 3 branches | 4 branches |
| Quarterly archives | NONE | 62 tables (2007Q3-2022Q4) |
| Pre-2021 data | NOT available | Available (via quarterly archives) |
| Column count | 125 (adds PartitionCol) | 124 |
| History.PositionClosePartial | Included | Included |
| Trade (StatusID=2) branch | Included | Included |
| History.Position_Active | Included | Included |
| Performance for 2021+ queries | Fast (3-way UNION ALL) | Slower (65-way UNION ALL) |
| Use case | Portfolio history, account statements, recent positions | Full historical analysis, compliance, pre-2021 data |

### 2.4 Partial Close Positions (History.PositionClosePartial branch)

**What**: History.PositionClosePartial contributes synthetic position records created by the partial-close flow.

**Columns/Parameters Involved**: `PositionID`, `AmountInUnitsDecimal`, `PartialCloseRatio`, `SubCloseTypeID`

**Rules**:
- When a position is partially closed, a clone is created with only the closed units
- This clone is inserted directly into History.PositionClosePartial (never passes through Trade.PositionTbl)
- Identifies via: non-NULL PartialCloseRatio AND non-NULL OriginalPositionID (or SubCloseTypeID set)
- The original position remains in Trade.PositionTbl with the reduced unit count
- History.PositionSlim includes these partial-close records alongside full-close records

---

## 3. Data Overview

History.PositionSlim data is sourced from History.Position_Active (primary) + Trade.PositionTbl StatusID=2 (live) + History.PositionClosePartial.

Sample data from History.Position_Active branch (most recent rows):

| PositionID | CID | InstrumentID | Amount | NetProfit | ActionType | CloseOccurred | IsSettled |
|------------|-----|-------------|--------|-----------|-----------|--------------|-----------|
| 2152976743 | 14952810 | 100000 (BTC) | $99.97 | varies | 0 | 2026-03-19 | true |
| (Trade branch rows) | ... | ... | ... | ... | ... | (live, recently closed) | ... |

Base data: History.Position_Active has 2,511,608 rows (2020-04-07 open through 2026-03-19 close). Trade branch contributes recently-closed positions. PositionClosePartial contributes partial-close clones.

---

## 4. Elements

125 output columns. Columns 1-124 are identical in name, type, and meaning to the modern branches of History.Position (the History.Position_Active branch column set). Column 125 is the additional PartitionCol.

See History.Position.md for full element descriptions of columns 1-124. Key elements:

| # | Element | Type | Nullable | Confidence | Notes |
|---|---------|------|----------|------------|-------|
| 1 | PositionID | bigint | NO | CODE-BACKED | Primary identifier. bigint since Nov 2021. NONCLUSTERED PK in History.Position_Active. |
| 2 | CID | int | NO | CODE-BACKED | Customer ID. CLUSTERED INDEX key (CID, CloseOccurred) in History.Position_Active. |
| 3 | InstrumentID | int | NO | CODE-BACKED | Traded instrument. 100000=BTC (crypto), 1=EURUSD, etc. |
| 4-12 | Amount, IsBuy, Leverage, StopLossRate, TakeProfitRate... | Various | Various | CODE-BACKED | Core position parameters at open time. |
| 13 | ActionType | tinyint | YES | CODE-BACKED | Close reason. 0=normal, 1=stop-loss, 2=take-profit, 3=copy-close, etc. See History.Position for full value map. |
| 14 | OpenOccurred | datetime | NO | CODE-BACKED | Position open timestamp (UTC). |
| 15 | CloseOccurred | datetime | NO | CODE-BACKED | Position close timestamp (UTC). |
| 16 | OpenRate / EndForexRate | dbo.dtPrice | YES | CODE-BACKED | Open and close instrument rates. |
| 17 | NetProfit | money | YES | CODE-BACKED | Realized P&L at close (USD). Negative = loss. |
| 18-30 | Commission fields, OpenBalance, CloseBalance... | Various | Various | CODE-BACKED | Financial execution details at open and close. |
| 31 | MirrorID | int | YES | CODE-BACKED | Copy-trading portfolio ID. NULL for non-copy trades. 8.4% of rows have MirrorID > 0. |
| 32 | ParentPositionID | bigint | YES | CODE-BACKED | Parent position for copy trades. NULL for non-copy. |
| 33 | IsSettled | bit | NO | CODE-BACKED | Settlement flag. 91.6% of rows have IsSettled=1 (Free Stocks flow). |
| 34 | SettlementTypeID | tinyint | YES | CODE-BACKED | Settlement method. FK to Dictionary.SettlementType (implied). |
| 35-42 | Redeem fields (RedeemStatus, RedeemID...) | Various | YES | CODE-BACKED | Stock redemption workflow fields. NULL for non-redeemed positions. |
| 43-50 | Units-based fields (AmountInUnitsDecimal, UnitsBaseValueCents...) | Various | YES | CODE-BACKED | Fractional shares trading fields. Added for Free Stocks. |
| 51-62 | Rate/conversion fields (InitConversionRate, NormalizationRate...) | Various | YES | CODE-BACKED | FX conversion rates at open/close. NULL in older branches. |
| 63-78 | Fee fields (CommissionOnOpen, CommissionOnClose, MarkupByUnits...) | Various | YES | CODE-BACKED | All commission and markup fields. |
| 79-86 | CloseTotalFees, CloseTotalTaxes, OpenTotalFees, OpenTotalTaxes... | Various | YES | CODE-BACKED | Fee/tax transparency columns added in UM 25.2. |
| 87 | IsNoStopLoss | bit | YES | CODE-BACKED | Position opened without stop loss (platform safety net used). Added in UM 25.2. |
| 88 | IsNoTakeProfit | bit | YES | CODE-BACKED | Position opened without take profit. Added in UM 25.2. |
| 89 | OriginalOpenActionType | tinyint | YES | CODE-BACKED | Original open action type before any modifications. Added in UM 25.2. |
| 90 | InitialLotCount | decimal(16,6) | YES | CODE-BACKED | Initial lot count at open. Added in UM 25.2. |
| 91-124 | (remaining position columns) | Various | Various | CODE-BACKED | All remaining position columns. See History.Position.md for complete list. |
| **125** | **PartitionCol** | **int** | **NO** | **CODE-BACKED** | **Hash bucket: PositionID%(50). Values 0-49. Enables hash-partitioned JOINs with Trade.PositionTreeInfo. Key differentiator from History.Position.** |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (branch 1) | History.Position_Active | View (UNION branch) | Primary 2021+ closed position archive |
| (branch 2) | Trade.PositionTbl | View (UNION branch, WHERE StatusID=2) | Recently closed positions pending archival |
| (branch 2) | Trade.PositionTreeInfo | View (INNER JOIN with Trade.PositionTbl) | Copy tree metadata joined to live closed positions |
| (branch 3) | History.PositionClosePartial | View (UNION branch) | Partial-close position records |
| PositionID | History.PositionChangeLog_Active | Implicit (via consumers) | Position change audit log |
| CID | Customer.Customer | Implicit FK | Customer who owns the position |
| InstrumentID | Trade.Instrument | Implicit FK | Traded instrument |
| MirrorID | Trade.Mirror | Implicit FK | Copy portfolio |

### 5.2 Referenced By (other objects point to this)

85 procedure consumers. Major categories:

| Source Object | Relationship Type | Description |
|--------------|-------------------|-------------|
| Trade.TAPI_GetHistoryPortfolioAgg | Read (aggregation) | Portfolio aggregate history via TAPI - uses PartitionCol for hash JOIN |
| Trade.TAPI_GetFlatCreditHistoryByCID | Read | Flat credit history per customer |
| Trade.PostClosePositionActions | Read (validation) | Post-close async validation against position history |
| Trade.GetPositionsByTimeRange | Read | Position lookup by time range |
| Trade.ManualPositionClose | Read (validation) | Manual close validation |
| Trade.CloseOpenPositionWithStatus2 | Read | Close operation using StatusID=2 branch |
| dbo.AccountStatement_GetTransactionsReport_v9 | Read (report) | Account statement transaction report |
| dbo.AccountStatement_GetUserStatementSummary | Read (report) | Account statement user summary |
| Trade.GetOrdersForExecutionReport | Read (report) | Execution report data |
| Trade.GetPositionsForDividendSnapshot | Read | Dividend calculation snapshot |
| Monitor.* procedures | Read (monitoring) | Position monitoring and alerting |
| History.UpdateLastPostionOperationDataByCID | Read | Reads recent closed positions (last 2 days by open or close date) to maintain History.LastPostionOperationDateByCID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionSlim (view)
|- History.Position_Active (table - primary 2021+ closed position archive)
|    - Written by: Trade.PostClosePositionActions (async, full close)
|    - Written by: History.MovePartialClosePositionToPosition_Active (partial close)
|
|- Trade.PositionTbl (table - live positions, WHERE StatusID=2)
|    INNER JOIN Trade.PositionTreeInfo (table - copy tree metadata)
|
+- History.PositionClosePartial (table - partial-close position records)
     - Written by: partial close flow
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position_Active | Table | UNION ALL branch 1 - primary 2021+ archive |
| Trade.PositionTbl | Table | UNION ALL branch 2 - live closed (StatusID=2) |
| Trade.PositionTreeInfo | Table | INNER JOIN with Trade.PositionTbl in branch 2 |
| History.PositionClosePartial | Table | UNION ALL branch 3 - partial-close records |

### 6.2 Objects That Depend On This

85 total consumers. Key objects:

| Object | Type | How Used |
|--------|------|----------|
| Trade.TAPI_GetHistoryPortfolioAgg | Stored Procedure | Portfolio aggregate history |
| Trade.TAPI_GetFlatCreditHistoryByCID | Stored Procedure | Flat credit history |
| Trade.PostClosePositionActions | Stored Procedure | Post-close async validation |
| Trade.GetPositionsByTimeRange | Stored Procedure | Time-range position lookup |
| Trade.ManualPositionClose | Stored Procedure | Manual close validation |
| Trade.CloseOpenPositionWithStatus2 | Stored Procedure | StatusID=2 close operations |
| dbo.AccountStatement_GetTransactionsReport_v9 | Stored Procedure | Account statement report |
| dbo.AccountStatement_GetUserStatementSummary | Stored Procedure | Account statement summary |
| Trade.GetOrdersForExecutionReport | Stored Procedure | Execution report |
| Trade.GetPositionsForDividendSnapshot | Stored Procedure | Dividend snapshot |
| (80+ additional consumers) | Various | TAPI portfolio procedures, monitoring, reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Queries benefit from base table indexes:
- `History.Position_Active`: CLUSTERED on (CID, CloseOccurred), NONCLUSTERED PK on PositionID, NC on MirrorID+CloseOccurred, NC on CloseOccurred DESC
- `Trade.PositionTbl`: Primary indexes serve the WHERE StatusID=2 filter
- `Trade.PositionTreeInfo`: Indexed for INNER JOIN with PositionTbl on PositionID/TreeID
- `History.PositionClosePartial`: Indexed for PositionID and CloseOccurred

### 7.2 Constraints

N/A for View.

### 7.3 Performance Notes

- History.PositionSlim is significantly faster than History.Position for 2021+ queries because it omits the 62-table quarterly archive UNION ALL
- The PartitionCol column enables hash-partitioned JOINs that further improve performance for multi-million-row portfolio aggregations
- Consumers that need pre-2021 position data must use History.Position instead
- The view should always be queried with appropriate WHERE filters (CID, CloseOccurred range, MirrorID) to leverage base table indexes

---

## 8. Sample Queries

### 8.1 Get recent closed positions for a customer (fast via PositionSlim)
```sql
SELECT
    ps.PositionID,
    ps.InstrumentID,
    ps.Amount,
    ps.IsBuy,
    ps.Leverage,
    ps.ActionType,
    ps.NetProfit,
    ps.OpenOccurred,
    ps.CloseOccurred,
    ps.IsSettled
FROM History.PositionSlim ps WITH (NOLOCK)
WHERE ps.CID = 14952810
  AND ps.CloseOccurred >= DATEADD(MONTH, -3, GETUTCDATE())
ORDER BY ps.CloseOccurred DESC;
```

### 8.2 Portfolio aggregate using PartitionCol hash JOIN pattern
```sql
-- Consumers like Trade.TAPI_GetHistoryPortfolioAgg use PartitionCol for hash-partitioned JOINs:
SELECT
    ps.PositionID,
    ps.CID,
    ps.NetProfit,
    ps.CloseOccurred,
    pti.TreeID
FROM History.PositionSlim ps WITH (NOLOCK)
INNER JOIN Trade.PositionTreeInfo pti WITH (NOLOCK)
    ON pti.PositionID = ps.PositionID
    AND ps.PartitionCol = ABS(pti.TreeID % 50)  -- hash partition filter
WHERE ps.CID = 14952810;
```

### 8.3 Count copy-trade positions by mirror in the last 6 months
```sql
SELECT
    ps.MirrorID,
    COUNT(*) AS ClosedPositions,
    SUM(ps.NetProfit) AS TotalNetProfit,
    AVG(ps.Amount) AS AvgAmount
FROM History.PositionSlim ps WITH (NOLOCK)
WHERE ps.MirrorID IS NOT NULL
  AND ps.CloseOccurred >= DATEADD(MONTH, -6, GETUTCDATE())
GROUP BY ps.MirrorID
ORDER BY ClosedPositions DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.PositionSlim. Business context inherited from History.Position_Active and History.Position documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 125 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 85 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.PositionSlim | Type: View | Source: etoro/etoro/History/Views/History.PositionSlim.sql*
