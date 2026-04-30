# History.Job_HistoryGuruCopiers

> Nightly SQL Agent job procedure that snapshots all active CopyTrader mirror relationships into History.GuruCopiers, then aggregates the results into dbo.Copiers_DATA for guru performance metrics.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - executed nightly as a SQL Agent job step |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.Job_HistoryGuruCopiers` is the nightly snapshot engine for eToro's CopyTrader analytics. Every night at midnight UTC, this procedure is invoked as a SQL Agent job step. It queries the live trading tables (`Trade.Mirror`, `Trade.Position`, `Trade.Instrument`, `Trade.CurrencyPrice`) to capture a point-in-time snapshot of every active guru-copier relationship, including how much capital is invested and what the unrealized P&L is at that moment.

The procedure exists to support two distinct business needs: (1) a time-series audit of individual copy relationships captured in `History.GuruCopiers` (one row per copier-guru pair per day), and (2) a daily aggregated guru metrics feed in `dbo.Copiers_DATA` (one row per guru per day, summarizing copier count, AUM, total P&L, and profitable mirror count). Without this job, eToro would have no historical record of how copy networks evolved over time - the live `Trade.Mirror` table only reflects the current state.

The procedure executes in two sequential phases within a single BEGIN TRY block: first it INSERTs the individual copier snapshots into `History.GuruCopiers`, then it immediately reads those same rows back and INSERTs the aggregated summary into `dbo.Copiers_DATA`. Both writes happen in the same job step execution.

---

## 2. Business Logic

### 2.1 Connected vs. Detached Position Split

**What**: Each copier's open positions in the guru's portfolio are classified as either "connected" (still actively synchronized with the guru) or "detached" (previously copied but now independent), and their investment amounts and P&L are tracked separately.

**Columns/Parameters Involved**: `Trade.Position.ParentPositionID`, `Investment`, `DetachedPosInvestment`, `PnL`, `Dit_PnL`

**Rules**:
- `ParentPositionID != 0` -> Connected position: still linked to the guru's position hierarchy (actively copied)
- `ParentPositionID = 0` -> Detached position: originally copied from this guru but disconnected from the mirror
- Investment = SUM(Trade.Position.Amount WHERE Connected=1) - capital still actively under the guru's influence
- DetachedPosInvestment = SUM(Trade.Position.Amount WHERE Connected=0) - capital from formerly-copied positions still open
- PnL = SUM(CalcNetProfit WHERE Connected=1) - unrealized P&L on active copy positions
- Dit_PnL = SUM(CalcNetProfit WHERE Connected=0) - unrealized P&L on detached positions; "Dit" = Detached

**Diagram**:
```
Trade.Position rows for a MirrorID
        |
        +-- ParentPositionID != 0 --> Connected = 1
        |     Amount  -> Investment
        |     CalcNetProfit -> PnL
        |
        +-- ParentPositionID = 0 --> Connected = 0
              Amount  -> DetachedPosInvestment
              CalcNetProfit -> Dit_PnL
```

### 2.2 P&L Calculation with Currency Conversion

**What**: Unrealized P&L for each open position is computed using `Trade.CalcNetProfit` and converted to USD using live currency prices.

**Columns/Parameters Involved**: `Trade.CalcNetProfit`, `Trade.CurrencyPrice`, `Trade.GetCurrencyConversionsView`, `Trade.Instrument.SellCurrencyID`, `Trade.GetCurrencyConversionsView.IsReciprocal`

**Rules**:
- Function call: `etoro.Trade.CalcNetProfit(IsBuy, InitForexRate, CurrentRate, AmountInUnitsDecimal, ConversionRate)`
- CurrentRate: if IsBuy=1 use CurrencyPrice.Bid, else use CurrencyPrice.Ask (bid/ask spread)
- ConversionRate resolution: SellCurrencyID=1 (USD) -> ConversionRate=1 (no conversion needed); IsReciprocal=1 -> 1/d.Bid; else -> d.Bid
- LEFT OUTER JOINs used for CurrencyPrice and GetCurrencyConversionsView - positions without live prices produce NULL P&L (included as 0 via ISNULL in SUM)

### 2.3 Two-Phase INSERT Architecture

**What**: The procedure executes two sequential INSERTs: first the individual copier-guru snapshots, then an immediate aggregation into the guru metrics table.

**Columns/Parameters Involved**: `History.GuruCopiers.Timestamp`, `dbo.Copiers_DATA.DateModified`, `Customer.CustomerStatic.PlayerLevelID`

**Rules**:
- Phase 1: INSERT into History.GuruCopiers grouped by (CID, ParentCID, ParentUserName)
- Filter: Trade.Mirror.ParentCID IS NOT NULL AND ParentUserName IS NOT NULL
- Timestamp = `CAST(CONVERT(VARCHAR, GETUTCDATE(), 103) AS DATETIME)` - midnight of the current day (DMY format, set by `SET DATEFORMAT DMY` at top)
- Phase 2: INSERT into dbo.Copiers_DATA grouped by (Timestamp, ParentCID)
- Phase 2 filter: Timestamp = today's midnight (reads rows just inserted in Phase 1)
- Phase 2 filter: `cs.PlayerLevelID <> 4` (joins Customer.CustomerStatic) - excludes PlayerLevelID=4 (demo/blocked accounts) from guru metrics
- NumProfitableMirrors = SUM(CASE WHEN PnL >= 0 THEN 1 ELSE 0 END) - count of copiers breaking even or in profit
- Note: An older simpler version of the Phase 2 INSERT is commented out (did not include Cash, Investment, PnL, or NumProfitableMirrors)

**Diagram**:
```
[SQL Agent Job - midnight UTC]
        |
        v
SET DATEFORMAT DMY
        |
        v
Phase 1: INSERT History.GuruCopiers
  FROM Trade.Mirror a
  LEFT JOIN (Trade.Position + Trade.Instrument + Trade.CurrencyPrice + Trade.CalcNetProfit) b
  WHERE a.ParentCID IS NOT NULL AND ParentUserName IS NOT NULL
  GROUP BY a.CID, a.ParentCID, a.ParentUserName
  -> ~14,900 rows inserted (one per active copy relationship)
        |
        v
Phase 2: INSERT dbo.Copiers_DATA
  FROM History.GuruCopiers
  JOIN Customer.CustomerStatic (exclude PlayerLevelID=4)
  WHERE Timestamp = today
  GROUP BY Timestamp, ParentCID
  -> ~4,600 rows inserted (one per active guru)
        |
        v
END TRY / BEGIN CATCH
  -> RAISERROR(60000, 16, 1, @ErrMsg) + RETURN 60000
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters - it is invoked with no arguments as a scheduled SQL Agent job step.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|

No input parameters. No output parameters. No SELECT result set returned. The procedure communicates success/failure only via return code (0 = success, 60000 = error caught in CATCH block).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.Mirror | Reads | Source of all active copy-trading relationships; filtered to ParentCID IS NOT NULL AND ParentUserName IS NOT NULL |
| (body) | Trade.Position | Reads | Open positions per MirrorID; used to compute Investment, DetachedPosInvestment, PnL, Dit_PnL |
| (body) | Trade.Instrument | Reads | Joined to Trade.Position on InstrumentID; SellCurrencyID used for P&L currency conversion |
| (body) | Trade.CurrencyPrice | Reads | Live bid/ask prices for P&L calculation (current rate) and currency conversion rate |
| (body) | Trade.GetCurrencyConversionsView | Reads | Currency conversion metadata (IsReciprocal, ConversionInstrumentID) for USD P&L conversion |
| (body) | Trade.CalcNetProfit | Function Call | Computes unrealized P&L per position given open rate, current rate, amount, and conversion rate |
| (body) | History.GuruCopiers | Writes (INSERT) | Sole writer; inserts daily copier-guru snapshot rows |
| (body) | Customer.CustomerStatic | Reads | Joined in Phase 2 to filter out PlayerLevelID=4 accounts from guru metrics |
| (body) | dbo.Copiers_DATA | Writes (INSERT) | Inserts guru-level daily aggregated metrics (copier count, AUM, P&L, profitable mirror count) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job (midnight UTC) | - | Caller | Executed nightly as a job step; no callers in the SSDT repository |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Job_HistoryGuruCopiers (procedure)
+-- Trade.Mirror (table - source of active copy relationships)
+-- Trade.Position (table - open positions per mirror)
+-- Trade.Instrument (table - instrument details for FX conversion)
+-- Trade.CurrencyPrice (table - live bid/ask for P&L and conversion)
+-- Trade.GetCurrencyConversionsView (view - currency conversion metadata)
+-- Trade.CalcNetProfit (function - P&L computation)
+-- History.GuruCopiers (table - Phase 1 INSERT target)
+-- Customer.CustomerStatic (table - PlayerLevelID filter in Phase 2)
+-- dbo.Copiers_DATA (table - Phase 2 INSERT target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | SELECT source for active copy relationships; outer loop grouped by CID/ParentCID/ParentUserName |
| Trade.Position | Table | LEFT JOIN via MirrorID; supplies open position amounts and ParentPositionID for connected/detached split |
| Trade.Instrument | Table | JOIN via InstrumentID; supplies SellCurrencyID for P&L currency conversion path |
| Trade.CurrencyPrice | Table | LEFT OUTER JOIN via InstrumentID; supplies live Bid/Ask for position rate and conversion instrument |
| Trade.GetCurrencyConversionsView | View | LEFT OUTER JOIN via SellCurrencyID; determines IsReciprocal and ConversionInstrumentID |
| Trade.CalcNetProfit | Function | Scalar function called per position to compute unrealized P&L |
| History.GuruCopiers | Table | Phase 1 INSERT target - daily copier-guru snapshot |
| Customer.CustomerStatic | Table | Phase 2 INNER JOIN to exclude PlayerLevelID=4 accounts from guru aggregation |
| dbo.Copiers_DATA | Table | Phase 2 INSERT target - guru-level daily metrics aggregation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent Job (midnight UTC) | External | Scheduled executor of this procedure - no SSDT callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- `SET DATEFORMAT DMY` is set at the top before the TRY block - required because `CONVERT(VARCHAR, GETUTCDATE(), 103)` produces a DMY-formatted string (e.g., "21/03/2026"), and CAST to DATETIME requires the session's DATEFORMAT to match
- Error handling: BEGIN TRY / BEGIN CATCH; on error, builds @ErrMsg with ERROR_LINE() + ERROR_MESSAGE() + ERROR_NUMBER(), then RAISERROR(60000, 16, 1, @ErrMsg) + RETURN 60000. Returns 60000 as the error code (custom application error code)
- No transaction wrapper - the two-phase INSERT is not atomic. If Phase 2 fails after Phase 1 succeeds, GuruCopiers has the day's data but Copiers_DATA does not. The job can be re-run for Phase 2 but would duplicate Phase 1 rows
- Commented-out INSERT: an older, simpler version of the Copiers_DATA INSERT (using DATEADD to get yesterday's date, without Cash/Investment/PnL/NumProfitableMirrors columns) is preserved in comments as historical reference
- WITH(NOLOCK) applied to Trade.Mirror; Trade.Position uses WITH (NOLOCK); Trade.Instrument, Trade.CurrencyPrice, Trade.GetCurrencyConversionsView use WITH (NOLOCK) - read-committed reads not required for this analytics snapshot job

---

## 8. Sample Queries

### 8.1 View the most recent daily snapshot for a specific guru

```sql
SELECT
    gc.Timestamp,
    gc.CID,
    gc.ParentCID,
    gc.ParentUserName,
    gc.Cash,
    gc.Investment,
    gc.DetachedPosInvestment,
    gc.PnL,
    gc.Dit_PnL
FROM History.GuruCopiers gc WITH (NOLOCK)
WHERE gc.ParentCID = @GuruCID
  AND gc.Timestamp = (SELECT MAX(Timestamp) FROM History.GuruCopiers WITH (NOLOCK))
ORDER BY gc.Investment DESC
```

### 8.2 Check today's Copiers_DATA aggregation for a guru

```sql
SELECT
    cd.DateModified,
    cd.CID AS GuruCID,
    cd.NumOfCopiers,
    cd.Cash,
    cd.Investment,
    cd.PnL,
    cd.NumProfitableMirrors
FROM dbo.Copiers_DATA cd WITH (NOLOCK)
WHERE cd.CID = @GuruCID
  AND cd.DateModified >= DATEADD(DAY, -7, CAST(GETUTCDATE() AS DATE))
ORDER BY cd.DateModified DESC
```

### 8.3 Diagnose a failed job run - check if GuruCopiers was populated but Copiers_DATA was not

```sql
-- Check Phase 1 rows for today
SELECT COUNT(*) AS GuruCopiersRowsToday
FROM History.GuruCopiers WITH (NOLOCK)
WHERE Timestamp = CAST(CONVERT(VARCHAR, GETUTCDATE(), 103) AS DATETIME)

-- Check Phase 2 rows for today
SELECT COUNT(*) AS CopiersDataRowsToday
FROM dbo.Copiers_DATA WITH (NOLOCK)
WHERE DateModified = CAST(CONVERT(VARCHAR, GETUTCDATE(), 103) AS DATETIME)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [dwh-user-guide-Fact_Guru_Copiers](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11646796478) | Confluence | Found via search - DWH user guide for the Fact_Guru_Copiers data warehouse table (downstream consumer of this job's output); inaccessible (BDP space) |

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 1 Confluence found (inaccessible) + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.Job_HistoryGuruCopiers | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.Job_HistoryGuruCopiers.sql*
