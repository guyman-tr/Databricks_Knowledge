# History.GuruCopiers

> Daily snapshot table capturing each active copy-trading relationship (mirror) between a "Guru" (Popular Investor being copied) and a "Copier" customer, recording investment amounts and unrealized P&L at midnight UTC each day.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PK_GuruCopiers: CLUSTERED on ID (IDENTITY bigint) |
| **Partition** | No (stored on [DICTIONARY] filegroup) |
| **Indexes** | 1 (CLUSTERED PK on ID, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table stores a daily midnight snapshot of every active CopyTrader mirror relationship on the platform. eToro's CopyTrader feature allows customers ("Copiers") to automatically replicate the trades of selected traders ("Gurus" / Popular Investors). Every night at midnight UTC, `History.Job_HistoryGuruCopiers` runs and inserts one row per active guru-copier pair, capturing the copier's portfolio state at that moment: how much cash they hold, how much is invested in the guru's open positions (both connected/copied positions and detached/independent positions), and the unrealized P&L.

5.2 million rows span March 2025 to February 2026, representing ~14,900 daily active copy relationships across 4,601 distinct gurus and 17,702 distinct copiers. After inserting the individual snapshots, the job aggregates the data into `dbo.Copiers_DATA` - a summary table used for guru performance metrics (number of copiers, total AUM, total P&L, profitable mirror count).

**Terminology Note**: "Guru" is eToro's legacy term for Popular Investors - experienced traders whose strategies are publicly available for copying. "Copier" is the customer following a guru.

---

## 2. Business Logic

### 2.1 Daily Snapshot Population

**What**: Once per day at midnight UTC, the job queries the live CopyTrader tables to capture a timestamped snapshot of every active mirror relationship.

**Columns/Parameters Involved**: `Timestamp`, `Occurred`, `CID`, `ParentCID`, `ParentUserName`

**Rules**:
- `History.Job_HistoryGuruCopiers` is the sole writer - called by a SQL Agent job at midnight
- Timestamp = midnight of the current day: `CAST(CONVERT(VARCHAR, GETUTCDATE(), 103) AS DATETIME)` - rounded to date boundary
- Occurred = actual insertion time (GETUTCDATE(), DEFAULT constraint) - the true UTC wall-clock time of insertion
- Source query: joins `Trade.Mirror` (active copy relationships) LEFT JOIN to `Trade.Position` (open positions in mirrors), `Trade.Instrument`, `Trade.CurrencyPrice`, `Trade.GetCurrencyConversionsView`
- Filter: `Trade.Mirror.ParentCID IS NOT NULL AND ParentUserName IS NOT NULL`
- GroupBy: (CID, ParentCID, ParentUserName) - one row per unique copier-guru combination per day

### 2.2 Investment and P&L Breakdown

**What**: Each snapshot distinguishes between "connected" positions (positions copied from the guru, maintaining the mirror link) and "detached" positions (positions that were copied but have been detached from the mirror - still open but no longer synchronized with the guru).

**Columns/Parameters Involved**: `Investment`, `DetachedPosInvestment`, `PnL`, `Dit_PnL`, `Cash`

**Rules**:
- Connected position (Trade.Position.ParentPositionID != 0): still actively linked to the guru's position hierarchy
- Detached position (Trade.Position.ParentPositionID = 0): previously copied but disconnected from the mirror
- Investment = SUM(Trade.Position.Amount WHERE Connected=1) - total capital in actively copied positions
- DetachedPosInvestment = SUM(Trade.Position.Amount WHERE Connected=0) - total capital in detached (formerly copied) positions
- PnL = SUM(CalcNetProfit WHERE Connected=1) - unrealized P&L on connected positions, currency-converted to USD
- Dit_PnL = SUM(CalcNetProfit WHERE Connected=0) - unrealized P&L on detached positions
- Cash = MAX(Trade.Mirror.Amount) - the copier's allocated copy-trading cash/balance for this guru
- StartCopy = MAX(Trade.Mirror.Occurred) - when the copy relationship started

### 2.3 Downstream Aggregation to Copiers_DATA

**What**: After inserting individual snapshots, the job immediately aggregates today's rows into `dbo.Copiers_DATA` for guru-level reporting.

**Rules**:
- Filter: `WHERE Timestamp = CAST(CONVERT(VARCHAR, GETUTCDATE(), 103) AS DATETIME)` - today's rows only
- Filter: excludes PlayerLevelID=4 customers (joins Customer.CustomerStatic - likely demo/blocked accounts)
- Aggregation per (Timestamp, ParentCID): COUNT(DISTINCT CID) as NumOfCopiers, SUM(Cash), SUM(Investment), SUM(PnL), COUNT(PnL >= 0) as NumProfitableMirrors
- `dbo.Copiers_DATA` provides the guru analytics dashboard data

---

## 3. Data Overview

| Scale | Value |
|-------|-------|
| Total rows | 5,200,252 |
| Date range | 2025-03-13 to 2026-02-21 (~348 days) |
| Daily volume | ~14,943 active copy relationships per snapshot |
| Distinct Gurus (ParentCID) | 4,601 |
| Distinct Copiers (CID) | 17,702 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK, auto-incrementing. NOT FOR REPLICATION prevents ID re-seeding during replication. Each row represents one guru-copier snapshot for one day. 5.2M rows after ~1 year of daily runs. |
| 2 | Occurred | datetime | NO | GETUTCDATE() | CODE-BACKED | Actual UTC wall-clock time when this row was inserted by the job. Set by DEFAULT constraint to GETUTCDATE() - the true insertion time, which may differ slightly from Timestamp (midnight) depending on job execution time. |
| 3 | Timestamp | datetime | NO | - | CODE-BACKED | Business date of this snapshot, set to midnight UTC: CAST(CONVERT(VARCHAR, GETUTCDATE(), 103) AS DATETIME). This is the "as of" date for the snapshot. All rows for a given calendar day share the same Timestamp value. Used as the grouping key in the downstream Copiers_DATA aggregation. |
| 4 | CID | int | YES | - | CODE-BACKED | Customer ID of the copier (the person who is copying the guru). Can be NULL in rare edge cases (Trade.Mirror rows with missing CID). Implicit FK to Customer.Customer. |
| 5 | ParentCID | int | NO | - | CODE-BACKED | Customer ID of the guru (the Popular Investor being copied). Always populated (filter: ParentCID IS NOT NULL). Used as the grouping dimension in Copiers_DATA aggregations. 4,601 distinct gurus in history. |
| 6 | ParentUserName | varchar(20) | NO | - | CODE-BACKED | Username of the guru at time of snapshot. Always populated (filter: ParentUserName IS NOT NULL). Denormalized for convenient display without joining to customer tables. |
| 7 | StartCopy | datetime | NO | - | CODE-BACKED | When the copy relationship started: MAX(Trade.Mirror.Occurred) for this CID-ParentCID pair. Captures the registration timestamp of the copy relationship. |
| 8 | Cash | money | NO | - | CODE-BACKED | The copier's allocated cash/balance for this guru copy: MAX(Trade.Mirror.Amount). Represents the investment pool the copier has designated for copying this guru. |
| 9 | Investment | money | NO | - | CODE-BACKED | Total USD amount currently invested in actively connected positions (positions still synchronized with the guru's portfolio). SUM(Trade.Position.Amount WHERE ParentPositionID != 0). |
| 10 | PnL | float | YES | - | CODE-BACKED | Unrealized profit/loss in USD on connected (active copy) positions. Calculated using Trade.CalcNetProfit with live CurrencyPrice data, currency-converted to USD. NULL if no connected positions. float (not money) because P&L calculations produce floating-point results. |
| 11 | DetachedPosInvestment | money | NO | - | CODE-BACKED | Total USD amount in detached positions - positions that were originally copied from this guru but have since been detached from the mirror (ParentPositionID=0). Still open but no longer following the guru. |
| 12 | Dit_PnL | float | YES | - | CODE-BACKED | Unrealized P&L on detached positions. "Dit" = "Detached". Same calculation method as PnL but only for positions with ParentPositionID=0. NULL if no detached positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | The copier's customer account. Joined via CustomerStatic in downstream aggregation. |
| ParentCID | Customer.Customer | Implicit | The guru's customer account. No FK constraint on this history table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Job_HistoryGuruCopiers | - | Writer | Inserts daily snapshots and then aggregates into dbo.Copiers_DATA |
| dbo.Copiers_DATA | Timestamp, ParentCID | Reader/Aggregation target | Reads today's rows to compute guru-level daily metrics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GuruCopiers (table)
- populated by History.Job_HistoryGuruCopiers
  - reads Trade.Mirror, Trade.Position, Trade.Instrument, Trade.CurrencyPrice
  - writes to dbo.Copiers_DATA
```

### 6.1 Objects This Depends On

No code-level dependencies (leaf table).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Job_HistoryGuruCopiers | Stored Procedure | Sole writer + reads today's rows for Copiers_DATA aggregation |
| dbo.Copiers_DATA | Table | Populated by aggregation of today's History.GuruCopiers rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_GuruCopiers | CLUSTERED | ID ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [DICTIONARY] filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_GuruCopiers | CLUSTERED PK | ID - bigint identity, required for 5.2M+ rows |
| DF_GuruCopiers_Occurred | DEFAULT | Occurred = GETUTCDATE() - actual insertion timestamp |

### 7.3 Notes

- FILLFACTOR not specified on PK - this is an append-only table (inserts only, no updates), so default fill factor is appropriate
- Stored on [DICTIONARY] filegroup despite containing trading data - likely a legacy placement decision
- The job uses `set DATEFORMAT DMY` before the INSERT - DMY is needed for the CONVERT(103) date format used in the Timestamp calculation

---

## 8. Sample Queries

### 8.1 Daily copier count and AUM for a guru over the last 30 days

```sql
SELECT
    gc.Timestamp AS SnapshotDate,
    gc.ParentCID,
    gc.ParentUserName,
    COUNT(DISTINCT gc.CID) AS NumCopiers,
    SUM(gc.Cash) AS TotalCash,
    SUM(gc.Investment) AS TotalInvestment,
    SUM(gc.PnL) AS TotalUnrealizedPnL
FROM History.GuruCopiers gc WITH (NOLOCK)
WHERE gc.ParentCID = @ParentCID
  AND gc.Timestamp >= DATEADD(DAY, -30, CAST(GETUTCDATE() AS DATE))
GROUP BY gc.Timestamp, gc.ParentCID, gc.ParentUserName
ORDER BY gc.Timestamp DESC;
```

### 8.2 Snapshot for a specific copier-guru relationship on a date

```sql
SELECT
    gc.ID,
    gc.Timestamp,
    gc.CID,
    gc.ParentCID,
    gc.ParentUserName,
    gc.StartCopy,
    gc.Cash,
    gc.Investment,
    gc.PnL,
    gc.DetachedPosInvestment,
    gc.Dit_PnL
FROM History.GuruCopiers gc WITH (NOLOCK)
WHERE gc.CID = @CID
  AND gc.ParentCID = @ParentCID
  AND gc.Timestamp >= @StartDate
  AND gc.Timestamp <= @EndDate
ORDER BY gc.Timestamp;
```

### 8.3 Top gurus by total copier AUM on the most recent snapshot date

```sql
SELECT TOP 20
    gc.Timestamp,
    gc.ParentCID,
    gc.ParentUserName,
    COUNT(DISTINCT gc.CID) AS NumCopiers,
    SUM(gc.Investment) AS TotalInvestmentUSD,
    SUM(gc.PnL) AS TotalPnLUSD
FROM History.GuruCopiers gc WITH (NOLOCK)
WHERE gc.Timestamp = (SELECT MAX(Timestamp) FROM History.GuruCopiers WITH (NOLOCK))
GROUP BY gc.Timestamp, gc.ParentCID, gc.ParentUserName
ORDER BY TotalInvestmentUSD DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.Job_HistoryGuruCopiers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GuruCopiers | Type: Table | Source: etoro/etoro/History/Tables/History.GuruCopiers.sql*
