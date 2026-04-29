# Dealing_dbo.Dealing_Apex_PnL_EE

> Week-to-date (WTD) equity-level PnL for eToro's Apex Clearing LP account -- 5,130 rows across 6 accounts from 2021-02-10 to 2024-06-07; **stale since 2024-06-08** (last ETL update). Reconciles total account equity movement (not per-symbol) against Apex LP statements for Middle Office.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Apex Clearing LP external files via `Dealing_staging.LP_APEX_EXT981_3EU` (equity) + `LP_APEX_EXT869_3EU` (transfers/dividends), written by `SP_Apex_PnL` |
| **Refresh** | Stale (last ETL update 2024-06-08 09:19; historically weekly, Saturday WTD reporting date) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on `[Date]` ASC |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`Dealing_dbo.Dealing_Apex_PnL_EE` is the **week-to-date (WTD) equity-level** PnL reconciliation table for eToro's Apex Clearing LP (liquidity provider) account. Each row represents one LP account on one reporting date, capturing the total account equity at the start and end of the WTD window, net cash transfers, dividends, and the resulting equity PnL. The table does **not** break PnL down by traded symbol -- that detail is in the sibling table `Dealing_Apex_PnL` (per-symbol WTD). Middle Office uses this table to verify that total account equity movements at Apex match internal expectations.

**Staleness warning:** The dataset is **frozen** -- last row date is **2024-06-07**, last ETL update was **2024-06-08 09:19**. The pipeline has not loaded new data for approximately two years. Treat all figures as historical unless the Apex LP pipeline is reactivated.

**Scale:** 5,130 rows across 6 distinct Apex LP accounts (3EU05025, 3EU05027, 3EU00101, 3EU05028, 3EU05026, 3EU05000). Date range: **2021-02-10 to 2024-06-07**. Grain: one row per `(Date, AccountNumber)`.

**Writer SP:** `Dealing_dbo.SP_Apex_PnL` (author: Sarah Benchitrit, 2021-07-25). The SP executes DELETE WHERE Date=@Date + INSERT for idempotent daily/weekly reload. The same SP also writes `Dealing_Apex_PnL` (per-symbol WTD), `Dealing_Apex_PnL_Daily` (per-symbol daily), and `Dealing_Apex_PnL_EE_Daily` (equity daily). The WTD equity window starts at the **previous Friday EOD** (or Thursday if Friday is a bank holiday) and ends at the current `@Date`.

---

## 2. Business Logic

### 2.1 WTD Equity PnL Bridge

**What**: The core PnL formula measures the change in total account equity over the week-to-date window, adjusted for non-trading cash movements.

**Columns Involved**: `Equity_Start`, `Equity_End`, `Transfers`, `PnL`

**Rules**:
- `PnL = Equity_End - Equity_Start - Transfers`
- `Equity_Start` is the total account equity at **Friday EOD of the prior week** (from `LP_APEX_EXT981_3EU.TotalEquity` at `@FridayBeforeID`). If that Friday is a bank holiday, the SP falls back to Thursday.
- `Equity_End` is the total account equity at the **current reporting date EOD** (from `LP_APEX_EXT981_3EU.TotalEquity` at `@DateID`). If `@Date` is a bank holiday, the SP uses the previous day.
- `Transfers` are **net cash transfers** (funding in/out) from `LP_APEX_EXT869_3EU` with `TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL')`, aggregated over the WTD window (Saturday-before through @Date). These are subtracted from the equity delta so that PnL reflects trading activity only, not funding flows.
- The SP handles scientific notation in the Apex LP files (e.g., `1.5e+06`) by parsing them explicitly.

### 2.2 Dividends (Account Level)

**What**: Total dividends credited to the LP account during the WTD window, aggregated from per-symbol dividend activity.

**Columns Involved**: `Dividends`

**Rules**:
- Sourced from `LP_APEX_EXT869_3EU` WHERE `TerminalID = '$+DIV'`, aggregated per `AccountNumber` over the WTD window.
- Dividends are stored separately from the equity PnL bridge -- they are **not** a component of the `PnL` column formula. They provide supplemental information about dividend income received during the period.
- NULL when no dividends were credited in the WTD window (54% of rows are NULL).

### 2.3 Account Number Mapping

**What**: Each Apex LP account maps to a specific eToro hedge server for zero-PnL reconciliation in the sibling per-symbol tables.

**Columns Involved**: `AccountNumber`

**Rules**:
- Hardcoded mapping in SP: 3EU05026→HS9, 3EU05025→HS112, 3EU05027→HS102, 3EU00101→HS223, 3EU05028→HS3
- `AccountNumber` is resolved via COALESCE across the equity, transfers, and dividends temp tables (FULL OUTER JOIN ensures accounts appearing in any source are captured)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** distribution with **CLUSTERED INDEX on `Date`**. At 5,130 rows the table is trivially small. Always filter on `Date` for clustered index seek, though full scans are cheap at this scale.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest available WTD equity snapshot | `SELECT MAX(Date), MAX(UpdateDate) FROM Dealing_dbo.Dealing_Apex_PnL_EE` |
| Weekly equity bridge for one account | `WHERE AccountNumber = @Acct AND Date BETWEEN @From AND @To ORDER BY Date` |
| Compare equity PnL to symbol-level roll-up | Join to `Dealing_Apex_PnL` on `(Date, AccountNumber)` and compare `SUM(PnL)` |
| Daily vs WTD equity comparison | Join to `Dealing_Apex_PnL_EE_Daily` on `(Date, AccountNumber)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_dbo.Dealing_Apex_PnL | `ON Date = Date AND AccountNumber = AccountNumber` | Compare equity-level WTD PnL to symbol-level WTD PnL roll-up |
| Dealing_dbo.Dealing_Apex_PnL_EE_Daily | `ON Date = Date AND AccountNumber = AccountNumber` | Compare WTD equity snapshot to daily equity snapshot |
| Dealing_dbo.Dealing_Apex_PnL_Daily | `ON Date = Date AND AccountNumber = AccountNumber` | Cross-reference equity totals to per-symbol daily detail |

### 3.4 Gotchas

- **Stale data**: Last row date is **2024-06-07**, last ETL update **2024-06-08 09:19**. Do not assume current data exists -- always check `MAX(Date)` before publishing figures.
- **NULL Transfers/Dividends**: 57% of rows have NULL Transfers (no cash movement that week); 54% have NULL Dividends (no dividends received). The PnL formula uses `ISNULL(..., 0)` so PnL is always populated even when components are NULL.
- **NULL Equity_End**: 14% of rows have NULL Equity_End -- typically occurs when an account had no position file on the report date. PnL is still computed (defaults to 0 via ISNULL).
- **WTD window**: `Equity_Start` references the **prior Friday**, not "last week's reporting date." Bank holidays shift the anchor to Thursday. Monday through Saturday of the current week all share the same `Equity_Start` anchor.
- **Cross-check with per-symbol table**: Summing `Dealing_Apex_PnL.PnL` for all symbols on a given `(Date, AccountNumber)` should approximately match this table's `PnL` after accounting for transfers and presentation differences -- investigate gaps with Middle Office.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 -- SP code / DDL | `(Tier 2 -- SP_Apex_PnL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date for the WTD equity snapshot -- the Saturday (or equivalent) end-of-week date per the SP's WTD calendar logic. Used as the DELETE/INSERT key for idempotent reload. (Tier 2 -- SP_Apex_PnL) |
| 2 | AccountNumber | varchar(20) | YES | Apex LP account number identifying the reconciled LP account (e.g., 3EU05025, 3EU05027). Resolved via COALESCE across equity, transfers, and dividends staging sources. 6 distinct accounts in the dataset. (Tier 2 -- SP_Apex_PnL) |
| 3 | Equity_Start | decimal(16,6) | YES | Total account equity at the prior week's Friday EOD (or Thursday if Friday is a bank holiday) -- opening equity for the WTD bridge. Sourced from LP_APEX_EXT981_3EU.TotalEquity at @FridayBeforeID. NULL when no equity file exists for the start date (4% of rows). (Tier 2 -- SP_Apex_PnL) |
| 4 | Equity_End | decimal(16,6) | YES | Total account equity at the reporting date EOD -- closing equity for the WTD bridge. Sourced from LP_APEX_EXT981_3EU.TotalEquity at @DateID. NULL when no equity file exists for the end date (14% of rows). (Tier 2 -- SP_Apex_PnL) |
| 5 | Transfers | decimal(16,8) | YES | Net cash transfers into or out of the Apex account during the WTD window (Saturday-before through @Date). Aggregated as SUM(-Amount) from LP_APEX_EXT869_3EU WHERE TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL'). Non-PnL cash movements excluded from the equity bridge. NULL when no transfers occurred (57% of rows). (Tier 2 -- SP_Apex_PnL) |
| 6 | PnL | decimal(16,6) | YES | Week-to-date equity PnL: ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0). Represents the net trading and mark-to-market effect at account level for the WTD window. Always populated (0% NULL) due to ISNULL defaults. (Tier 2 -- SP_Apex_PnL) |
| 7 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() at insert time by SP_Apex_PnL. Does not reflect production or Apex file timestamps. Last value: 2024-06-08 09:19. (Tier 2 -- SP_Apex_PnL) |
| 8 | Dividends | decimal(16,6) | YES | Total dividends credited to the Apex LP account during the WTD window. Aggregated per AccountNumber from LP_APEX_EXT869_3EU WHERE TerminalID = '$+DIV'. Stored separately from the PnL bridge formula. NULL when no dividends were received (54% of rows). (Tier 2 -- SP_Apex_PnL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP_Apex_PnL | @Date parameter | SET to report date (Saturday WTD) |
| AccountNumber | LP_APEX_EXT981_3EU / LP_APEX_EXT869_3EU | AccountNumber | COALESCE across equity, transfers, dividends |
| Equity_Start | LP_APEX_EXT981_3EU | TotalEquity | At @FridayBeforeID; scientific notation parsed |
| Equity_End | LP_APEX_EXT981_3EU | TotalEquity | At @DateID; scientific notation parsed |
| Transfers | LP_APEX_EXT869_3EU | Amount | SUM(-Amount) WHERE TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL') |
| PnL | -- | -- | ETL-computed: ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0) |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| Dividends | LP_APEX_EXT869_3EU | Amount | SUM(-Amount) WHERE TerminalID = '$+DIV', aggregated per AccountNumber |

### 5.2 ETL Pipeline

```
Apex Clearing LP external files
  |-- LP_APEX_EXT981_3EU (account equity snapshots by date)
  |-- LP_APEX_EXT869_3EU (cash activity: transfers, dividends, fees)
  v
Dealing_staging (Synapse staging tables)
  |-- SP_Apex_PnL @Date
  |   |-- #EquityStart_ApexFiles (TotalEquity at FridayBefore EOD)
  |   |-- #EquityEnd_ApexFiles (TotalEquity at @Date EOD)
  |   |-- #Equity (FULL JOIN start/end on AccountNumber)
  |   |-- #Transfers (SUM cash movements for WTD window)
  |   |-- #Dividends_PerAcc (SUM dividends per account for WTD window)
  |   |-- FULL OUTER JOIN #Equity, #Transfers, #Dividends_PerAcc
  v
Dealing_dbo.Dealing_Apex_PnL_EE (5,130 rows, stale since 2024-06-08)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountNumber | Dealing_staging.LP_APEX_EXT981_3EU | Apex LP account equity snapshots |
| AccountNumber | Dealing_staging.LP_APEX_EXT869_3EU | Apex LP cash activity (transfers, dividends) |

### 6.2 Referenced By (other objects point to this)

| Downstream | Schema | Notes |
|------------|--------|-------|
| (none known) | -- | Equity-level summary; consumers typically use the per-symbol Dealing_Apex_PnL tables |

### 6.3 Sibling Objects (same SP family)

| Object | Relationship |
|--------|----------------|
| `Dealing_dbo.Dealing_Apex_PnL` | **Per-symbol WTD** -- same SP, symbol-level detail with NOP/prices/volume. |
| `Dealing_dbo.Dealing_Apex_PnL_Daily` | **Per-symbol daily** -- same SP, prior-business-day NOP start. |
| `Dealing_dbo.Dealing_Apex_PnL_EE_Daily` | **Equity-level daily** -- same SP, same column layout, daily grain instead of WTD. |
| `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` | **Upstream** -- feeds `Zero` column in per-symbol siblings (not directly used by this equity-level table). |

---

## 7. Sample Queries

### 7.1 Latest available WTD equity snapshot (stale-aware)

```sql
SELECT MAX(Date) AS LastReportDate, MAX(UpdateDate) AS LastLoad
FROM Dealing_dbo.Dealing_Apex_PnL_EE;
```

### 7.2 WTD equity bridge for a date range

```sql
SELECT
    Date,
    AccountNumber,
    Equity_Start,
    Equity_End,
    Transfers,
    Dividends,
    PnL,
    ISNULL(Equity_End, 0) - ISNULL(Equity_Start, 0) - ISNULL(Transfers, 0) AS PnL_Recompute_Check
FROM Dealing_dbo.Dealing_Apex_PnL_EE
WHERE Date BETWEEN '2024-05-01' AND '2024-06-07'
ORDER BY Date, AccountNumber;
```

### 7.3 Cross-check equity PnL vs symbol-level roll-up

```sql
SELECT
    ee.Date,
    ee.AccountNumber,
    ee.PnL AS EquityPnL,
    SUM(p.PnL) AS SymbolPnLSum,
    ee.PnL - SUM(p.PnL) AS Gap
FROM Dealing_dbo.Dealing_Apex_PnL_EE ee
LEFT JOIN Dealing_dbo.Dealing_Apex_PnL p
  ON p.Date = ee.Date AND p.AccountNumber = ee.AccountNumber
WHERE ee.Date = '2024-06-07'
GROUP BY ee.Date, ee.AccountNumber, ee.PnL
ORDER BY ABS(ee.PnL - SUM(p.PnL)) DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 7.5/10 (★★★★☆) | Batch: regen-harness*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4 | Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10*
*Object: Dealing_dbo.Dealing_Apex_PnL_EE | Type: Table | Production Source: Apex LP external data via SP_Apex_PnL*
