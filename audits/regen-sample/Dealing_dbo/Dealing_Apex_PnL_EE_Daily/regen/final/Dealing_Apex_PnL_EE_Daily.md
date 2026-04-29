# Dealing_dbo.Dealing_Apex_PnL_EE_Daily

> **Daily equity-level** (account-level) PnL for the Apex Clearing LP -- one row per account per business day tracking total account equity change after transfers; **2,491 rows** from **2022-07-06 to 2024-06-07** across **6 Apex accounts**; **stale since June 2024** (last load 2024-06-08 09:19); written by **`SP_Apex_PnL`**.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Apex Clearing LP equity/transfer/dividend feeds via `Dealing_staging.LP_APEX_EXT981_3EU` (equity) + `LP_APEX_EXT869_3EU` (transfers/dividends); writer: `SP_Apex_PnL` |
| **Refresh** | Daily (within `SP_Apex_PnL` daily logic path; stale since 2024-06-08) |
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

`Dealing_dbo.Dealing_Apex_PnL_EE_Daily` is the **daily equity-level** counterpart to `Dealing_Apex_PnL_EE` (which is **week-to-date**). It holds **one row per Apex LP account per business day**, tracking how **total account equity** changed from the **prior business day** to the **current day**, after accounting for **cash transfers**. Middle Office uses it for **day-over-day** equity reconciliation against Apex Clearing statements.

The writer is **`Dealing_dbo.SP_Apex_PnL`** (author: Sarah Benchitrit, 2021-07-25), which loads all four Apex tables in a single execution: `Dealing_Apex_PnL` (WTD symbol), `Dealing_Apex_PnL_Daily` (daily symbol), `Dealing_Apex_PnL_EE` (WTD equity), and this table (daily equity). The SP uses a **DELETE+INSERT** pattern by `@Date`.

**Staleness:** The table is **frozen** -- last row date **2024-06-07**, last ETL run **2024-06-08 09:19**. All figures are **historical** unless the Apex LP pipeline is reactivated. The table contains **2,491 rows** across **6 Apex accounts** (3EU05025, 3EU05027, 3EU05028, 3EU05026, 3EU05000, 3EU00101), with date coverage from **2022-07-06** (shorter than the WTD table which starts 2021-02-10, implying the daily equity path was added later).

**No PII** -- account-level LP data only, no individual customer identifiers.

---

## 2. Business Logic

### 2.1 Daily Equity PnL Formula

**What**: The daily equity PnL captures how total account equity moved in one business day, stripping out cash transfers to isolate market-driven change.

**Columns Involved**: `Equity_Start`, `Equity_End`, `Transfers`, `PnL`

**Rules**:
- `PnL = Equity_End - Equity_Start - Transfers`
- `Equity_Start` is the **prior business day EOD** total equity (Monday uses Friday; bank holidays use the day before)
- `Equity_End` is the **current day EOD** total equity (adjusted for bank holidays)
- `Transfers` are net cash movements for the day only (not week-aggregated)
- `PnL` does **not** embed `Dividends` in the same expression -- for "total income" reporting, add `Dividends` explicitly

### 2.2 Weekend and Holiday Handling

**What**: The SP skips non-business days when determining the prior day's equity.

**Columns Involved**: `Date`, `Equity_Start`

**Rules**:
- `@PreviousDay` for Monday rows = **Friday** (DATEADD(day, -3, @Date) when DayNumberOfWeek_Sun_Start = 2)
- All other weekdays: `@PreviousDay` = calendar yesterday
- Bank holiday detection: if `@Date` falls on a bank holiday (per `Dim_Date.IsBankHoliday`), the SP shifts `@DateID` back by one day for NOP/equity end reads
- If `@FridayBefore` is a bank holiday, its equity is read from the day before that (one additional shift)

### 2.3 Account Resolution via FULL OUTER JOIN

**What**: AccountNumber is resolved from whichever feed (equity, transfers, dividends) carries it.

**Columns Involved**: `AccountNumber`

**Rules**:
- `ISNULL(ISNULL(equity.AccountNumber, transfers.AccountNumber), dividends.AccountNumber)` -- cascading resolution
- An account may appear in only one of the three feeds on a given day (e.g., equity changes but no transfers and no dividends)
- 6 distinct accounts observed: 3EU05025, 3EU05027, 3EU05028, 3EU05026, 3EU05000, 3EU00101
- Each maps to a hedge server via hardcoded `#AccountToHS` mapping in the SP (used for the symbol-level tables' Zero calculation, not directly for this equity table)

### 2.4 Dividends as Separate Line Item

**What**: Dividends are aggregated per account for the day but not folded into the PnL formula.

**Columns Involved**: `Dividends`

**Rules**:
- Source: `LP_APEX_EXT869_3EU` where `TerminalID = '$+DIV'`, sign-inverted (`SUM(-Amount)`)
- NULL when no dividends were credited on the day (52% of rows)
- To compute "total daily income": `PnL + ISNULL(Dividends, 0)`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** distribution -- no hash key; the table is very small (2,491 rows) so distribution strategy is immaterial for performance. **Clustered index on `Date` ASC** -- always filter on `Date` for clarity, though full scans are trivial at this size.

### 3.1b UC (Databricks) Storage & Partitioning

UC target pending write-objects configuration. At 2,491 rows, no partitioning is needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest available daily equity snapshot | `SELECT MAX(Date) AS LastDate, MAX(UpdateDate) AS LastLoad FROM Dealing_dbo.Dealing_Apex_PnL_EE_Daily` |
| One account, one day equity bridge | `WHERE Date = @Date AND AccountNumber = @Acct` |
| Compare daily equity PnL to sum of daily symbol PnL | Join to `Dealing_Apex_PnL_Daily` grouped by AccountNumber + Date |
| Total income (PnL + dividends) for a day | `SELECT PnL + ISNULL(Dividends, 0) AS TotalIncome` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_dbo.Dealing_Apex_PnL_Daily | `ON Date = Date AND AccountNumber = AccountNumber` | Compare equity-level PnL to sum of symbol-level PnL |
| Dealing_dbo.Dealing_Apex_PnL_EE | `ON AccountNumber = AccountNumber` (different Date grain) | Compare daily to WTD equity bridge |

### 3.4 Gotchas

- **Stale data**: Last load 2024-06-08. Always check `MAX(Date)` before publishing numbers.
- **Transfers NULL vs zero**: NULL means no transfers on the day (61% of rows). The PnL formula uses `ISNULL(Transfers, 0)`, so NULL and 0 are equivalent for PnL computation.
- **Dividends not in PnL**: `PnL` = `Equity_End - Equity_Start - Transfers` only. Add `Dividends` explicitly for total income.
- **Monday Equity_Start = Friday**: The prior business day for Monday is Friday, not Sunday. Do not expect calendar-adjacent equity values on Mondays.
- **Bank holiday shifts**: On bank holidays, both `@DateID` and `@PreviousDayID` shift back by one day. This means the "current day" equity may actually reflect the day before the holiday.
- **Equity_Start NULL**: 7.6% of rows have NULL Equity_Start (190/2491) -- likely new accounts or accounts without positions on the prior day. PnL still computes using `ISNULL(Equity_Start, 0)`.
- **Scientific notation in source**: The SP handles scientific notation in the source staging data (`'%e+%'` pattern) -- this is an Apex file format artifact, transparent to consumers.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 -- SP code / DDL | `(Tier 2 -- SP_Apex_PnL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date for the daily equity row. One row per AccountNumber per trading day. The SP uses `@Date` parameter; bank holidays shift to the prior business day for equity reads. (Tier 2 -- SP_Apex_PnL) |
| 2 | AccountNumber | varchar(20) | YES | Apex LP account identifier (e.g. 3EU05025, 3EU00101). Resolved via ISNULL cascade across equity, transfers, and dividends feeds -- whichever feed carries the account for the day. 6 distinct accounts historically. (Tier 2 -- SP_Apex_PnL) |
| 3 | Equity_Start | decimal(16,6) | YES | Total account equity (USD) at prior business day EOD. Monday rows use Friday; bank holidays shift back one additional day. Source: `Dealing_staging.LP_APEX_EXT981_3EU.TotalEquity` with scientific notation handling. NULL for 7.6% of rows (new accounts or no prior-day position). (Tier 2 -- SP_Apex_PnL) |
| 4 | Equity_End | decimal(16,6) | YES | Total account equity (USD) at current day EOD. Source: `Dealing_staging.LP_APEX_EXT981_3EU.TotalEquity` with scientific notation handling. NULL for 3% of rows. (Tier 2 -- SP_Apex_PnL) |
| 5 | Transfers | decimal(16,8) | YES | Net cash transfers into/out of the Apex account on this day. Source: `SUM(-Amount)` from `LP_APEX_EXT869_3EU` where `TerminalID IN ('CSCSG','FWWRD','MGLOA','MGJNL')`. Positive = funds received; negative = funds withdrawn. NULL when no transfers occurred (61% of rows). (Tier 2 -- SP_Apex_PnL) |
| 6 | PnL | decimal(16,6) | YES | Daily equity PnL: `ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0)`. Isolates market-driven equity change by removing transfer effects. Does NOT include Dividends in the formula. (Tier 2 -- SP_Apex_PnL) |
| 7 | UpdateDate | datetime | YES | ETL execution timestamp from `GETDATE()` in `SP_Apex_PnL`. Reflects when the row was loaded, not when the equity was valued. (Tier 2 -- SP_Apex_PnL) |
| 8 | Dividends | decimal(16,6) | YES | Aggregate dividends credited to the account on this day (all instruments). Source: `SUM(-Amount)` from `LP_APEX_EXT869_3EU` where `TerminalID = '$+DIV'`. NULL when no dividends were credited (52% of rows). Not embedded in PnL -- add explicitly for total daily income. (Tier 2 -- SP_Apex_PnL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP_Apex_PnL | @Date parameter | Passthrough |
| AccountNumber | LP_APEX_EXT981_3EU / LP_APEX_EXT869_3EU | AccountNumber | ISNULL cascade across equity/transfers/dividends feeds |
| Equity_Start | Dealing_staging.LP_APEX_EXT981_3EU | TotalEquity | Scientific notation handling; prior business day filter |
| Equity_End | Dealing_staging.LP_APEX_EXT981_3EU | TotalEquity | Scientific notation handling; current day filter |
| Transfers | Dealing_staging.LP_APEX_EXT869_3EU | Amount | SUM(-Amount) WHERE TerminalID IN transfer codes, daily window |
| PnL | -- (computed) | -- | ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0) |
| UpdateDate | -- (computed) | -- | GETDATE() |
| Dividends | Dealing_staging.LP_APEX_EXT869_3EU | Amount | SUM(-Amount) WHERE TerminalID = '$+DIV', daily window, per account |

### 5.2 ETL Pipeline

```
Apex Clearing LP external files
  |-- Equity statements --> Dealing_staging.LP_APEX_EXT981_3EU
  |-- Activity/dividends --> Dealing_staging.LP_APEX_EXT869_3EU
  |
  v
SP_Apex_PnL @Date (DELETE + INSERT daily)
  |-- #EquityStart_ApexFiles_Daily (LP_APEX_EXT981_3EU @ @PreviousDayID)
  |-- #EquityEnd_ApexFiles (LP_APEX_EXT981_3EU @ @DateID)
  |-- #Equity_Daily = Start FULL JOIN End on AccountNumber
  |-- #Transfers_Daily (LP_APEX_EXT869_3EU @ @DateID, transfer TerminalIDs)
  |-- #Dividends_PerAcc_Daily (LP_APEX_EXT869_3EU @ @DateID, '$+DIV')
  |
  v
FULL OUTER JOIN #Equity_Daily + #Transfers_Daily + #Dividends_PerAcc_Daily
  |
  v
Dealing_dbo.Dealing_Apex_PnL_EE_Daily (2,491 rows, stale since 2024-06-08)
```

---

## 6. Relationships

| Object | Relationship |
|--------|----------------|
| **`Dealing_dbo.Dealing_Apex_PnL_EE`** | WTD equity sibling -- same SP, same columns, week-start equity instead of prior-day. Use WTD for weekly packs; use this table for DOD checks. |
| **`Dealing_dbo.Dealing_Apex_PnL_Daily`** | Daily symbol-level PnL -- per-instrument detail at daily grain. Sum of symbol PnL should approximate this table's equity PnL after transfers and presentation differences. |
| **`Dealing_dbo.Dealing_Apex_PnL`** | WTD symbol-level PnL -- per-instrument detail at weekly grain. |
| **`Dealing_staging.LP_APEX_EXT981_3EU`** | Apex equity statement staging -- provides TotalEquity for Equity_Start/End. |
| **`Dealing_staging.LP_APEX_EXT869_3EU`** | Apex activity staging -- provides Transfers and Dividends. |
| **`DWH_dbo.Dim_Date`** | Calendar dimension for bank holiday detection and weekend logic. |

---

## 7. Sample Queries

### Latest daily equity snapshot (stale check)

```sql
SELECT MAX(Date) AS LastReportDate, MAX(UpdateDate) AS LastLoad, COUNT(*) AS TotalRows
FROM Dealing_dbo.Dealing_Apex_PnL_EE_Daily;
```

### One account, multi-day equity bridge

```sql
SELECT Date, AccountNumber, Equity_Start, Equity_End, Transfers, PnL, Dividends,
       PnL + ISNULL(Dividends, 0) AS TotalIncome
FROM Dealing_dbo.Dealing_Apex_PnL_EE_Daily
WHERE AccountNumber = '3EU05025'
  AND Date BETWEEN '2024-06-01' AND '2024-06-07'
ORDER BY Date;
```

### Compare daily equity PnL to sum of daily symbol PnL

```sql
SELECT ee.Date, ee.AccountNumber, ee.PnL AS EquityPnL,
       SUM(d.PnL) AS SumSymbolPnL,
       ee.PnL - SUM(d.PnL) AS Diff
FROM Dealing_dbo.Dealing_Apex_PnL_EE_Daily AS ee
JOIN Dealing_dbo.Dealing_Apex_PnL_Daily AS d
  ON d.Date = ee.Date AND d.AccountNumber = ee.AccountNumber
WHERE ee.Date = '2024-06-07'
GROUP BY ee.Date, ee.AccountNumber, ee.PnL;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 7.5/10 (stars: 4/5) | Batch: regen-harness*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4 | Elements: 8/8, Logic: 8/10, Relationships: 8/10, Sources: 5/10*
*Object: Dealing_dbo.Dealing_Apex_PnL_EE_Daily | Type: Table | Production Source: LP external data (Apex Clearing)*
