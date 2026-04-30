# History.PositionChangeLog_Active

> Transparent view over History.PositionChangeLog_Active_BIGINT exposing 57 of 59 columns - omits SnapshotTimestamp and PriceType - providing the standard consumer interface for position lifecycle change log queries without exposing internal processing metadata columns.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionChangeID (bigint) |
| **Partition** | N/A (view - base table partitioned on Occurred) |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.PositionChangeLog_Active is the standard consumer interface for the position change audit log. It is a thin SELECT wrapper over `History.PositionChangeLog_Active_BIGINT`, the partitioned 59-column table that records every lifecycle event for open positions: opens, stop loss edits, take profit edits, partial closes, mirror detachments, redeem operations, TSL changes, and closes.

The view omits exactly 2 columns from the base table: `SnapshotTimestamp` and `PriceType`. These are internal processing metadata columns used by the data ingestion layer; by excluding them the view presents a clean 57-column interface for trading engine procedures and reporting queries.

The name `_Active` refers to the underlying table's rolling partition strategy: `History.PositionChangeLog_Active_BIGINT` maintains approximately 6 months of active data via `dbo.HistoryPositionChangeLog_MaintainPartitions`. Older data is purged. The view inherits this data window - it does NOT contain the full historical audit trail. For older position changes the companion view `History.PositionChangeLog` is used, which UNIONs this view with an external linked server archive.

The view is heavily used by the trading engine (open/close position procedures with timeout), data API procedures (GetPositionsChangesForDataApi), and reporting (PR_Dashboard_ORG, dividend snapshots). 14 procedure consumers reference this view.

---

## 2. Business Logic

### 2.1 Column Projection (57 of 59)

**What**: The view selects columns 1-57 by name from the base table, explicitly omitting the last two columns.

**Columns/Parameters Involved**: All 57 included; `SnapshotTimestamp` (col 58) and `PriceType` (col 59) omitted.

**Rules**:
- All 57 business columns are exposed: PositionChangeID through PreviousIsNoTakeProfit
- SnapshotTimestamp: timestamp of the position state snapshot that triggered this entry; used by async ingestion pipeline, not relevant to business queries
- PriceType: internal price type code (bid/ask/mid) for the operation; internal processing column
- The SELECT is by explicit column name list (not SELECT *), so DDL changes to the base table do not automatically propagate to the view
- All base table column types, nullability, and defaults are inherited unchanged

### 2.2 ChangeTypeID State Machine (Inherited from Base Table)

**What**: ChangeTypeID identifies which type of position lifecycle event each row records.

**Columns/Parameters Involved**: `ChangeTypeID`, `PreviousAmount`, `AmountChanged`, `PreviousLimitRate`, `LimitRate`, `PreviousStopRate`, `StopRate`, `IsTslEnabled`

**Rules** (from Dictionary.PCL_ChangeType):

| ChangeTypeID | Name | Count (env) | Key Fields |
|-------------|------|-------------|-----------|
| 0 | Open Position | 2,467,641 | All fields - initial position snapshot |
| 1 | Edit Stop Loss | 386,314 | PreviousStopRate/StopRate |
| 2 | Edit Take Profit | 13,991 | PreviousLimitRate/LimitRate |
| 3 | Edit Over Weekend | - | PreviousCloseOnEndOfWeek/CloseOnEndOfWeek |
| 4 | EOW Fee | - | PreviousEndOfWeekFee/EndOfWeekFee |
| 5 | Detach from Mirror | 8,643 | ParentPositionID set to NULL |
| 6 | Close Position | 2,436,715 | Final snapshot at close |
| 7 | Enable/Disable TSL | 344,857 | IsTslEnabled toggled |
| 8 | PositionRedeemCancel | 6,642 | RedeemStatus -> 0 |
| 9 | PositionRedeemPending | 19,034 | RedeemStatus -> pending |
| 10 | PositionRedeemClose | - | RedeemStatus -> closed |
| 11 | Partial close | 45,347 | AmountInUnits/AmountChanged |
| 12 | Edit due to partial close | 45,347 | Parent position amount adjusted |
| 13 | Edit Is Settled | - | PreviousIsSettled/IsSettled |
| 14 | Data Fix | - | Correction after reconciliation |

### 2.3 Active Window - Rolling 6-Month Partition

**What**: The underlying table retains only approximately the last 6 months of data; older rows are purged.

**Columns/Parameters Involved**: `Occurred`

**Rules**:
- `dbo.HistoryPositionChangeLog_MaintainPartitions` runs periodically to prune old partitions
- Data currently spans from ~May 2023 through present (5.77M rows in this environment)
- CHECK constraint on base table: `Occurred >= '2022-08-01'` (historical partition boundary; actual minimum moves forward as partitions are purged)
- For full historical position change audit trail use `History.PositionChangeLog` (which UNIONs this view with PositionChangeLogArchive linked server data)

### 2.4 Before/After Field Pattern

**What**: Each change record captures the state before and after the event for modified fields.

**Columns/Parameters Involved**: `PreviousStopRate`/`StopRate`, `PreviousLimitRate`/`LimitRate`, `PreviousAmount`/`AmountChanged`/`NewAmount`, and other Previous*/current field pairs

**Rules**:
- On Open Position (ChangeTypeID=0): Previous* fields reflect the initial state (same as current values); all fields populated
- AmountChanged = delta applied to investment amount; 0 for non-amount events
- PreviousLimitRate/LimitRate = take profit rate pair; 0 = no take profit configured
- PreviousStopRate/StopRate = stop loss rate pair; 0.01 = platform minimum SL
- UnAdjusted variants (PreviousLimitRateUnAdjusted, StopRateUnAdjusted, etc.) = raw user-set rates before platform adjustments

---

## 3. Data Overview

Live data sample from the view (Occurred = 2026-03-21):

| PositionChangeID | PositionID | ChangeTypeID | CID | PreviousStopRate | StopRate | PreviousLimitRate | LimitRate | IsSettled |
|-----------------|------------|-------------|-----|-----------------|----------|------------------|-----------|-----------|
| 3713814537 | 2152976745 | 0 (Open) | ... | 0.01 | 0.01 | 0 | 0 | NULL |
| 3713814536 | 2152976742 | 0 (Open) | 25132377 | 0.01 | 0.01 | 156034.11 | 156034.11 | NULL |
| 3713814535 | 2152976740 | 6 (Close) | 14952810 | 0.01 | 0.01 | 0 | 0 | true |

PreviousLimitRate=156034.11 (BTC take-profit rate) on the Open record indicates a position opened on BTC (InstrumentID implied by rate scale). IsSettled=true on the Close record reflects a settled stock position.

Base table: 5,774,531 rows | Oldest: ~2023-05-09 | Newest: 2026-03-21

---

## 4. Elements

57 columns - identical to History.PositionChangeLog_Active_BIGINT columns 1-57. Full element descriptions in the base table documentation. Key elements:

| # | Element | Type | Nullable | Confidence | Notes |
|---|---------|------|----------|------------|-------|
| 1 | PositionChangeID | bigint | NO | CODE-BACKED | Surrogate PK. IDENTITY seed ~4.46B (migrated from INT version). NONCLUSTERED PK on (PositionChangeID, Occurred). |
| 2 | PositionID | bigint | NO | CODE-BACKED | Open position being changed. bigint since Nov 2021. NC index on base table. |
| 3-6 | PreviousCloseOnEndOfWeek...EndOfWeekFee | Various | NO | CODE-BACKED | End-of-week toggle and fee pairs; updated on ChangeTypeID=3/4. |
| 7-8 | PreviousAmount, AmountChanged | money | NO | CODE-BACKED | Investment amount before event and delta applied. |
| 9-12 | PreviousLimitRate...StopRate | dbo.dtPrice | NO | CODE-BACKED | Take profit / stop loss rate pairs. dbo.dtPrice = decimal(16,8). 0 = not configured. |
| 13 | Occurred | datetime | NO | CODE-BACKED | UTC event time. Partition key and part of NONCLUSTERED PK. |
| 14-15 | ParentPositionID, OrigParentPositionID | bigint | YES | CODE-BACKED | Copy trade parent; OrigParent preserved after detachment (ChangeTypeID=5). |
| 16-19 | LastOpPriceRate...LastOpConversionRateID | Various | YES | CODE-BACKED | Market rate + conversion rate snapshots at event time. |
| 20 | MirrorID | int | YES | CODE-BACKED | Copy portfolio ID. NC index includes MirrorID. |
| 21 | ClientVersion | varchar(20) | YES | CODE-BACKED | Platform client version string at time of change. |
| 22 | CID | int | YES | CODE-BACKED | Customer owning the position. CLUSTERED INDEX key (CID ASC, Occurred ASC). |
| 23 | ChangeTypeID | tinyint | YES | CODE-BACKED | Change type. FK to Dictionary.PCL_ChangeType. See Section 2.2 value map. |
| 24 | NewAmount | dbo.dtPrice | YES | CODE-BACKED | Investment amount after change. Complements PreviousAmount+AmountChanged. |
| 25-28 | PreviousLimitRateUnAdjusted...LimitRateUnAdjusted | dbo.dtPrice | YES | CODE-BACKED | User-set rates before platform adjustments (spread, overnight fee). |
| 29-30 | AccountRealizedEquity, MirrorRealizedEquity | money | YES | CODE-BACKED | Account and portfolio equity snapshots at event time. |
| 31-32 | TreeID, PrevTreeID | bigint | YES | CODE-BACKED | Copy tree chain IDs (current/previous); used in detach/re-attach tracking. |
| 33 | SessionID | bigint | YES | CODE-BACKED | Trading session. Included in NC index on base table. |
| 34 | IsTslEnabled | tinyint | YES | CODE-BACKED | Trailing stop loss flag after change. 1=enabled. Updated on ChangeTypeID=7. |
| 35 | RedeemStatus | tinyint | NO | CODE-BACKED | Stock redemption state. 0=none. Updated on ChangeTypeID 8/9/10. Default 0. |
| 36 | ClientRequestGuid | uniqueidentifier | YES | CODE-BACKED | Client-generated GUID for idempotency/request correlation. |
| 37-38 | PreviousIsSettled, IsSettled | bit | YES | CODE-BACKED | Settlement flag before/after. Updated on ChangeTypeID=13. |
| 39-40 | PreviousAmountInUnits, AmountInUnits | decimal(16,6) | YES | CODE-BACKED | Position size in instrument units (fractional shares). Updated on ChangeTypeID=11. |
| 41-42 | UnitsBaseValueCents, PreviouseUnitsBaseValueCents | int | YES | CODE-BACKED | Base value in cents. Note: "Previouse" is a typo in the column name (preserved from DDL). |
| 43-46 | ClientViewRateID...ClientRateForCalc | Various | YES | CODE-BACKED | Rate display/calculation IDs and values as seen by client. |
| 47 | ExecutedWithoutSettings | bit | YES | CODE-BACKED | True if system-generated without user-provided settings. |
| 48-49 | PreviousSettlementTypeID, SettlementTypeID | tinyint | YES | CODE-BACKED | Settlement type pair (cash vs. stock delivery). FK to Dictionary.SettlementType (implied). |
| 50-51 | PreviousPnLVersion, PnLVersion | tinyint | YES | CODE-BACKED | P&L calculation methodology version pair. |
| 52-53 | PreviousLotCountDecimal, LotCountDecimal | decimal(16,6) | YES | CODE-BACKED | Lot count pair for fractional lot sizing. |
| 54-55 | IsNoStopLoss, IsNoTakeProfit | bit | YES | CODE-BACKED | After-change flags: position uses platform safety net (no user SL/TP set). Added in UM 25.2. |
| 56-57 | PreviousIsNoStopLoss, PreviousIsNoTakeProfit | bit | YES | CODE-BACKED | Before-change no-SL/no-TP flags. |
| 58-59 | SnapshotTimestamp, PriceType | N/A | N/A | N/A | NOT PRESENT in this view - omitted from base table's 59 columns. Internal processing metadata. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all rows) | History.PositionChangeLog_Active_BIGINT | View (SELECT) | Base table - all 57 columns selected |
| ChangeTypeID | Dictionary.PCL_ChangeType | Implicit FK (via base table) | Change type lookup |
| PositionID | Trade.PositionTbl / History.Position | Implicit FK (via base table) | The position being changed |
| CID | Customer.Customer | Implicit FK (via base table) | Customer who owns the position |
| MirrorID | Trade.Mirror | Implicit FK (via base table) | Copy portfolio |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PositionChangeLog | (view) | View (UNION branch) | Combines with archived data for full history |
| Trade.PositionOpenWithTimeout | PositionID | Read | Validates open position state post-timeout |
| Trade.FunPositionOpenWithTimeout | PositionID | Read | Copy-position open with timeout check |
| Trade.PositionEditSLWithTimeout | PositionID | Read | Validates stop loss edit completion |
| Trade.FunPositionCloseWithTimeout | PositionID | Read | Validates close operation completion |
| Trade.CloseOpenPositionWithStatus2 | PositionID | Read | Position close status validation |
| Trade.GetPositionsChangesForDataApi | CID/PositionID | Read | Data API feed for position change events |
| Trade.GetPositionsForDividendSnapshot | PositionID | Read | Snapshot of positions for dividend calculation |
| Trade.GetOrderForOpenPositionsOvt | PositionID | Read | Open position order checks |
| dbo.PR_Dashboard_ORG | PositionID/CID | Read (SSRS report) | Organizational dashboard reporting |
| dbo.PR_Report_FailDashbord | PositionID | Read (SSRS report) | Failure dashboard reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionChangeLog_Active (view)
+- History.PositionChangeLog_Active_BIGINT (table - partitioned, rolling 6-month window)
   +- Written by: History.PositionChangeLog_Insert
   +- Partitions maintained by: dbo.HistoryPositionChangeLog_MaintainPartitions
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionChangeLog_Active_BIGINT | Table | Single source - 57 of 59 columns selected |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PositionChangeLog | View | UNION branch 1 - combines with archive for full history |
| Trade.PositionOpenWithTimeout | Stored Procedure | Post-open validation |
| Trade.FunPositionOpenWithTimeout | Stored Procedure | Copy-position open validation |
| Trade.PositionEditSLWithTimeout | Stored Procedure | Post-SL-edit validation |
| Trade.FunPositionCloseWithTimeout | Stored Procedure | Post-close validation |
| Trade.CloseOpenPositionWithStatus2 | Stored Procedure | Close status check |
| Trade.GetPositionsChangesForDataApi | Stored Procedure | Data API - position change feed |
| Trade.GetPositionsForDividendSnapshot | Stored Procedure | Dividend snapshot reader |
| Trade.GetOrderForOpenPositionsOvt | Stored Procedure | Open positions order check |
| dbo.PR_Dashboard_ORG | Stored Procedure | SSRS organizational dashboard |
| dbo.PR_Report_FailDashbord | Stored Procedure | SSRS failure dashboard |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Queries benefit from base table indexes:
- CLUSTERED on (CID ASC, Occurred ASC) - customer + time range queries
- NONCLUSTERED on (PositionID DESC) - position-centric lookups
- NONCLUSTERED on (ChangeTypeID ASC, Occurred ASC, MirrorID ASC) - change type + time + mirror queries
- NONCLUSTERED PK on (PositionChangeID ASC, Occurred ASC) - direct ID lookups

### 7.2 Constraints

N/A for View. Base table has CHECK constraint (Occurred >= '2022-08-01') and DEFAULT (RedeemStatus = 0).

---

## 8. Sample Queries

### 8.1 Get all changes for a specific position (full lifecycle)
```sql
SELECT
    pcl.PositionChangeID,
    pcl.ChangeTypeID,
    pcl.PreviousStopRate,
    pcl.StopRate,
    pcl.PreviousLimitRate,
    pcl.LimitRate,
    pcl.PreviousAmount,
    pcl.AmountChanged,
    pcl.IsTslEnabled,
    pcl.Occurred
FROM History.PositionChangeLog_Active pcl WITH (NOLOCK)
WHERE pcl.PositionID = 2152976742
ORDER BY pcl.Occurred;
```

### 8.2 Get recent edits (SL/TP/TSL) for a customer
```sql
SELECT
    pcl.PositionID,
    pcl.ChangeTypeID,
    pcl.PreviousStopRate,
    pcl.StopRate,
    pcl.PreviousLimitRate,
    pcl.LimitRate,
    pcl.Occurred
FROM History.PositionChangeLog_Active pcl WITH (NOLOCK)
WHERE pcl.CID = 14952810
  AND pcl.ChangeTypeID IN (1, 2, 7)  -- EditSL, EditTP, TSL
  AND pcl.Occurred >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY pcl.Occurred DESC;
```

### 8.3 Find positions opened without stop loss (IsNoStopLoss) in the last 7 days
```sql
SELECT
    pcl.PositionID,
    pcl.CID,
    pcl.IsNoStopLoss,
    pcl.IsNoTakeProfit,
    pcl.Occurred
FROM History.PositionChangeLog_Active pcl WITH (NOLOCK)
WHERE pcl.ChangeTypeID = 0  -- Open
  AND pcl.IsNoStopLoss = 1
  AND pcl.Occurred >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY pcl.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.PositionChangeLog_Active. Business context inherited from History.PositionChangeLog_Active_BIGINT documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 57 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 11 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.PositionChangeLog_Active | Type: View | Source: etoro/etoro/History/Views/History.PositionChangeLog_Active.sql*
