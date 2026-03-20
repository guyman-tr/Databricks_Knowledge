# DWH_dbo.Dim_HistorySplitRatio

> Stock split and corporate action ratio table: maps each instrument's historical date ranges to the cumulative price and amount adjustment factors needed to normalize prices across split events.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | PriceLog.History.SplitRatio |
| **Refresh** | Daily (ETL) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC, MinDate ASC, MaxDate ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Dim_HistorySplitRatio` stores the cumulative adjustment factors for every stock split and corporate action that has occurred on instruments traded on the eToro platform. Each row defines a contiguous date range (`MinDate` to `MaxDate`) during which a specific price ratio and amount ratio applied. When a new split occurs, the instrument gains a new row with a new date range, and all prior rows are updated to reflect the cumulative adjustment stack. The table is the canonical reference for converting historical prices to split-adjusted form for analytics.

Data originates from `PriceLog.History.SplitRatio` on the price server (AZR-W-PRICEDB-2-Price). The Generic Pipeline exports this table hourly to `Bronze/PriceLog/History/SplitRatio/` in the data lake (UC: `dealing.bronze_pricelog_history_splitratio`). The ETL SP (`SP_Dim_HistorySplitRatio_DL_To_Synapse`) then loads it into Synapse from `DWH_staging.etoro_History_SplitRatio` daily. Source: upstream `PriceLog.History.SplitRatio` (no upstream wiki in DB_Schema -- PriceLog is a standalone price server database).

The ETL uses a full TRUNCATE + INSERT pattern: the entire table is reloaded each run. The `UpdateDate` column is set to `GETDATE()` at load time (not from the source) and reflects the last ETL execution. As of 2026-03-11 the table holds 15,899 rows. The table is also exported downstream to Gold (`dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio`) daily. Note: consumer Fact SPs (`SP_Fact_CurrencyPriceWithSplit`, `SP_Fact_CustomerUnrealized_PnL`) read from the raw staging table or dedicated external tables (`Ext_FCPWS_History_SplitRatio`, `Ext_FCUPNL_History_SplitRatio`) for current-day split detection, not from this Dim_ table directly. The Dim_ form is the persisted reference copy for Gold export and analyst queries.

---

## 2. Business Logic

### 2.1 Date-Range Period Model

**What**: Each instrument has one or more consecutive non-overlapping date ranges. Within each range, the ratio values are constant. The ranges tile the full history from a start sentinel to an end sentinel.

**Columns Involved**: `InstrumentID`, `MinDate`, `MaxDate`

**Rules**:
- Each instrument has at least one row spanning `MinDate=2000-01-01` (beginning-of-history sentinel) to either a split date or `MaxDate=2100-01-01` (open-ended sentinel meaning "currently active").
- When a split occurs, the active row is split into two: the old range closes at the split event timestamp, and a new row opens from that timestamp with the new cumulative ratios.
- There are no gaps between consecutive ranges for a given instrument.
- The most recent (active) row always has `MaxDate=2100-01-01`.

**Diagram**:
```
Instrument with 2 splits (e.g., Apple):
  Row 1: MinDate=2000-01-01 | MaxDate=2014-06-08 | PriceRatio=0.0357 | AmountRatio=28.0
  Row 2: MinDate=2014-06-08 | MaxDate=2020-08-30 | PriceRatio=0.2500 | AmountRatio=4.0
  Row 3: MinDate=2020-08-30 | MaxDate=2100-01-01 | PriceRatio=1.0000 | AmountRatio=1.0
         (active, no further splits yet)
```

### 2.2 Cumulative Ratio Pair

**What**: `PriceRatio` and `AmountRatio` are reciprocal adjustment multipliers. `PriceRatioUnAdjusted` and `AmountRatioUnAdjusted` capture the incremental ratio of the most recent split only (not cumulative).

**Columns Involved**: `PriceRatio`, `AmountRatio`, `PriceRatioUnAdjusted`, `AmountRatioUnAdjusted`

**Rules**:
- `AdjustedPrice = HistoricalPrice * PriceRatio` (converts old price to post-split-equivalent)
- `AdjustedAmount = HistoricalAmount * AmountRatio` (converts old quantity to post-split-equivalent)
- For instruments with no splits: `PriceRatio=1.0`, `AmountRatio=1.0`, `PriceRatioUnAdjusted=1.0`, `AmountRatioUnAdjusted=1.0`
- `PriceRatio * AmountRatio` should approximately equal 1.0 (price and amount adjustments are inverse)
- `PriceRatioUnAdjusted` and `AmountRatioUnAdjusted` reflect only the most recent split increment, not the cumulative history

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `(InstrumentID ASC, MinDate ASC, MaxDate ASC)`. Because it is replicated, it is available on every distribution node without a shuffle -- ideal for JOINs against large fact tables. The clustered index on the three key columns optimizes range lookups: `WHERE InstrumentID = @id AND @price_date >= MinDate AND @price_date < MaxDate` resolves via a clustered index seek.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold table (`dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio`) is exported daily. No partition strategy is defined yet -- _pending write-objects resolution_. For best performance when querying split history in Databricks, filter by `InstrumentID` to leverage potential Z-ORDER.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find the ratio for a specific instrument on a specific date | `WHERE InstrumentID = @id AND @dt >= MinDate AND @dt < MaxDate` -- exactly one row should match |
| Adjust historical prices to current split-adjusted form | Join on the date range condition above, multiply by `PriceRatio` |
| Find all instruments that had splits in a given year | `WHERE MinDate >= @year_start AND MinDate < @year_end AND PriceRatio != 1.0` |
| Get the active (current) ratio for all instruments | `WHERE MaxDate = '2100-01-01'` -- returns one row per instrument |
| Find instruments with the most split history | `GROUP BY InstrumentID HAVING COUNT(*) > 1 ORDER BY COUNT(*) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Currency | `ON Dim_Currency.CurrencyID = Dim_HistorySplitRatio.InstrumentID` | Resolve InstrumentID to instrument name, type, symbol |
| DWH_dbo.Dim_Instrument | `ON Dim_Instrument.InstrumentID = Dim_HistorySplitRatio.InstrumentID` | Resolve to instrument details once Dim_Instrument is documented |
| DWH_dbo.Fact_CurrencyPriceWithSplit | No direct FK -- used as ratio lookup in ETL | Provides split-adjusted price series |

### 3.4 Gotchas

- **Orphaned in analytics layer**: Consumer SPs (`SP_Fact_CurrencyPriceWithSplit`, `SP_Fact_CustomerUnrealized_PnL`) read split ratios from staging tables (`DWH_staging.etoro_History_SplitRatio`) and dedicated external tables, NOT from this Dim_ table. Use this table for analyst queries and Gold export only -- do not assume the ETL pipeline reads from it.
- **MaxDate=2100-01-01 means active**: This far-future sentinel indicates the currently applicable ratio. Filter `WHERE MaxDate = '2100-01-01'` to get current ratios per instrument.
- **MinDate=2000-01-01 means "since beginning"**: Any price data before the first recorded split uses the ratio in the row with this sentinel start date.
- **UpdateDate is ETL timestamp, not source timestamp**: The `UpdateDate` column is set to `GETDATE()` by the SP and reflects the last load time (2026-03-11 02:07), not a production-side modification date.
- **Most instruments have only 1 row** (no splits): `PriceRatio=1.0, AmountRatio=1.0` means no adjustment needed. Only instruments with stock splits have multiple rows.
- **Highly-split instruments**: Some instruments (e.g., InstrumentID 4459) have up to 15 split events in history.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- upstream wiki verbatim | `(Tier 1 -- upstream wiki, source)` |
| ★★★ | Tier 2 -- Synapse SP code | `(Tier 2 -- SP/DDL)` |
| ★★ | Tier 3 -- live data / DDL structure | `(Tier 3 -- live data)` |
| ★ | Tier 4 -- inferred [UNVERIFIED] | `[UNVERIFIED] (Tier 4 -- inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NO | Sequential integer primary key for the split ratio record. Passed through from PriceLog.History.SplitRatio without transformation. (Tier 2 -- SP_Dim_HistorySplitRatio_DL_To_Synapse) |
| 2 | InstrumentID | int | NO | Instrument identifier (FK to DWH_dbo.Dim_Currency.CurrencyID and DWH_dbo.Dim_Instrument.InstrumentID). Groups all split ratio records for a single tradeable instrument. (Tier 2 -- SP_Dim_HistorySplitRatio_DL_To_Synapse) |
| 3 | MinDate | datetime | YES | Start of the date range (inclusive) for which the ratio applies. `2000-01-01` is the beginning-of-history sentinel for the earliest period before any splits. (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 4 | MaxDate | datetime | YES | End of the date range (exclusive) for which the ratio applies. `2100-01-01` is the open-ended sentinel indicating the currently active ratio (no further splits yet). (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 5 | PriceRatio | decimal(16,8) | NO | Cumulative price adjustment multiplier for this period. Multiply a historical price by this value to get its split-adjusted equivalent. 1.0 means no adjustment. Example: PriceRatio=0.25 means a 4:1 stock split occurred (1 old share = 4 new shares, price adjusted down to 25%). (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 6 | AmountRatio | decimal(16,8) | NO | Cumulative amount/quantity adjustment multiplier for this period. Multiply a historical position size by this value to get the split-adjusted share count. Inverse of PriceRatio: AmountRatio=4.0 corresponds to PriceRatio=0.25 (4:1 split). (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 7 | PriceRatioUnAdjusted | decimal(19,4) | NO | Incremental (non-cumulative) price ratio from the most recent split event only, before stacking with prior splits. Used to isolate the effect of a single split. 1.0 for the oldest period (before any splits). (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 8 | AmountRatioUnAdjusted | decimal(19,4) | NO | Incremental (non-cumulative) amount ratio from the most recent split event only. Inverse of PriceRatioUnAdjusted for the current split. 1.0 for the oldest period (before any splits). (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 9 | UpdateDate | datetime | NO | ETL load timestamp -- set to GETDATE() by SP_Dim_HistorySplitRatio_DL_To_Synapse at each reload. Not from the production source. Reflects when DWH was last refreshed, not when the split data changed. (Tier 2 -- SP_Dim_HistorySplitRatio_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ID | PriceLog.History.SplitRatio | ID | Passthrough |
| InstrumentID | PriceLog.History.SplitRatio | InstrumentID | Passthrough |
| MinDate | PriceLog.History.SplitRatio | MinDate | Passthrough |
| MaxDate | PriceLog.History.SplitRatio | MaxDate | Passthrough |
| PriceRatio | PriceLog.History.SplitRatio | PriceRatio | Passthrough |
| AmountRatio | PriceLog.History.SplitRatio | AmountRatio | Passthrough |
| PriceRatioUnAdjusted | PriceLog.History.SplitRatio | PriceRatioUnAdjusted | Passthrough |
| AmountRatioUnAdjusted | PriceLog.History.SplitRatio | AmountRatioUnAdjusted | Passthrough |
| UpdateDate | ETL-computed | -- | GETDATE() at load time |

No upstream wiki found for PriceLog.History.SplitRatio -- PriceLog is a standalone price server database (AZR-W-PRICEDB-2-Price) not covered in DB_Schema wiki.

### 5.2 ETL Pipeline

```
PriceLog.History.SplitRatio (AZR-W-PRICEDB-2-Price)
  -> Generic Pipeline (hourly, Override, Bronze/PriceLog/History/SplitRatio/)
  -> dealing.bronze_pricelog_history_splitratio (UC Bronze)
  -> DWH_staging.etoro_History_SplitRatio
  -> SP_Dim_HistorySplitRatio_DL_To_Synapse (TRUNCATE + INSERT, daily)
  -> DWH_dbo.Dim_HistorySplitRatio
  -> Gold/sql_dp_prod_we/DWH_dbo/Dim_HistorySplitRatio/ (daily export)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio (UC Gold)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | PriceLog.History.SplitRatio | Price server split ratio table on AZR-W-PRICEDB-2-Price |
| Lake | Bronze/PriceLog/History/SplitRatio/ | Hourly Generic Pipeline export |
| Staging | DWH_staging.etoro_History_SplitRatio | Raw staging import |
| ETL | DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse | TRUNCATE + full INSERT; UpdateDate = GETDATE() |
| Target | DWH_dbo.Dim_HistorySplitRatio | 15,899 rows, refreshed daily |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Currency | Universal instrument registry -- resolve InstrumentID to instrument name, symbol, type |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension (to be documented in Batch 7) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_CurrencyPriceWithSplit | InstrumentID + date range | Uses Dim_HistorySplitRatio for split-adjusted price computation (via staging ext table path) |
| DWH_dbo.Fact_CustomerUnrealized_PnL | InstrumentID + date range | Uses split ratios for unrealized PnL calculation (via Ext_FCUPNL_History_SplitRatio) |
| dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio | -- | Gold UC export for downstream Databricks analytics |

---

## 7. Sample Queries

### 7.1 Get the active (current) split ratio for all instruments

```sql
SELECT
    InstrumentID,
    PriceRatio,
    AmountRatio,
    MinDate AS SplitActiveFrom
FROM [DWH_dbo].[Dim_HistorySplitRatio]
WHERE MaxDate = '2100-01-01'
ORDER BY InstrumentID;
```

### 7.2 Find the split ratio applicable on a specific date for an instrument

```sql
DECLARE @InstrumentID INT = 1001;
DECLARE @PriceDate DATE = '2015-01-01';

SELECT
    InstrumentID,
    MinDate,
    MaxDate,
    PriceRatio,
    AmountRatio,
    PriceRatioUnAdjusted,
    AmountRatioUnAdjusted
FROM [DWH_dbo].[Dim_HistorySplitRatio]
WHERE InstrumentID = @InstrumentID
  AND @PriceDate >= MinDate
  AND @PriceDate < MaxDate;
```

### 7.3 Find instruments with the most split events and resolve names

```sql
SELECT
    r.InstrumentID,
    c.[Name]            AS InstrumentName,
    COUNT(*)            AS SplitPeriods,
    MAX(r.MinDate)      AS MostRecentSplitDate
FROM [DWH_dbo].[Dim_HistorySplitRatio] r
JOIN [DWH_dbo].[Dim_Currency] c
    ON c.[CurrencyID] = r.[InstrumentID]
WHERE r.PriceRatio != 1.0   -- exclude no-split (identity) rows
GROUP BY r.InstrumentID, c.[Name]
ORDER BY SplitPeriods DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.2/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 3 T2, 6 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_HistorySplitRatio | Type: Table | Production Source: PriceLog.History.SplitRatio*
