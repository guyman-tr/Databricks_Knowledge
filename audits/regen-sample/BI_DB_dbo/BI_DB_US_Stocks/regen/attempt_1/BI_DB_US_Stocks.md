# BI_DB_dbo.BI_DB_US_Stocks

> 1,025-row static reference table listing US-traded stock and ETF instruments by InstrumentID and ticker name. Data spans 2019-03-24 to 2019-11-24. No writer SP or scheduled refresh — appears manually loaded and dormant since late 2019. Used as a lookup in SP_Daily_Dividends to flag US stock positions.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (dormant) — no writer SP, no generic pipeline, no OpsDB entry |
| **Refresh** | None detected — last UpdateDate is 2019-11-24; table appears static |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | None |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_US_Stocks is a small reference table containing 1,025 rows that enumerate US-listed stocks and ETFs available on the eToro platform. Each row maps an InstrumentID to a human-readable ticker name in the format `SYMBOL/USD` (e.g., `AAPL/USD`, `FB/USD`, `MSFT/USD`).

The table is used exclusively by `SP_Daily_Dividends` as a LEFT JOIN lookup to derive the `Is_US_Stock` flag (1 if the instrument exists in this table, 0 otherwise) for the `BI_DB_Daily_Dividends` reporting table.

There is no writer stored procedure, no generic pipeline mapping, and no OpsDB scheduling entry for this table. The data appears to have been loaded manually — all UpdateDate values fall between 2019-03-24 and 2019-11-24, with no evidence of subsequent refreshes. A `BI_DB_Migration.BI_DB_US_Stocks` migration table and a `BI_DB_Migration.JUNK_BI_DB_US_Stocks` cleanup table exist in the SSDT repo, suggesting the data was migrated from a legacy BI system.

There are 1,021 distinct InstrumentIDs and 1,018 distinct names. Four InstrumentIDs (5945-5948) appear twice, and five names (SPHD/USD, SDY/USD, DVY/USD, VIG/USD, SPXU/USD) have duplicate entries. No NULL InstrumentIDs exist.

---

## 2. Business Logic

### 2.1 US Stock Identification

**What**: The table serves as a static whitelist of US-traded instruments.
**Columns Involved**: InstrumentID
**Rules**:
- If an instrument's InstrumentID exists in this table, it is classified as a US stock/ETF.
- SP_Daily_Dividends uses `CASE WHEN e.InstrumentID IS NOT NULL THEN 1 ELSE 0 END AS Is_US_Stock` to derive this flag.
- The flag feeds into dividend reporting segmentation in BI_DB_Daily_Dividends.

### 2.2 Ticker Naming Convention

**What**: Instrument names follow the `SYMBOL/USD` format.
**Columns Involved**: Name
**Rules**:
- All ticker names are denominated against USD (e.g., `AAPL/USD`, `TSLA/USD`).
- This is consistent with the eToro platform convention for US equities and ETFs.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution means rows are spread evenly across compute nodes with no data locality optimization. The CLUSTERED INDEX on InstrumentID supports efficient point lookups and range scans. At 1,025 rows, the table fits entirely in memory on any single node.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Is this instrument a US stock? | `SELECT 1 FROM BI_DB_dbo.BI_DB_US_Stocks WHERE InstrumentID = @id` |
| List all US stock tickers | `SELECT Name FROM BI_DB_dbo.BI_DB_US_Stocks ORDER BY Name` |
| Find duplicates | `SELECT InstrumentID, COUNT(*) FROM BI_DB_dbo.BI_DB_US_Stocks GROUP BY InstrumentID HAVING COUNT(*) > 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Instrument | `ON di.InstrumentID = us.InstrumentID` | Resolve instrument type, symbol, exchange |
| DWH_dbo.Dim_Position | `ON dp.InstrumentID = us.InstrumentID` | Identify positions in US stocks |

### 3.4 Gotchas

- **Dormant table** — data has not been refreshed since 2019-11-24. New US instruments added to the platform after that date are NOT included.
- **Duplicate InstrumentIDs** — InstrumentIDs 5945-5948 each appear twice. JOINs may produce row multiplication.
- **No FK constraint** — there is no enforced foreign key to Dim_Instrument; orphaned InstrumentIDs are possible.
- **Name format** — all names include `/USD` suffix; strip it for display purposes if needed.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki — highest confidence |
| Tier 2 | Derived from SP code or ETL logic — high confidence |
| Tier 3 | No upstream wiki or SP; grounded in DDL and live data — moderate confidence |
| Tier 4 | Inferred from column name only — low confidence (banned in this pipeline) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | YES | Instrument identifier for a US-traded stock or ETF. Matches DWH_dbo.Dim_Instrument.InstrumentID. Used as the JOIN key in SP_Daily_Dividends to derive the Is_US_Stock flag. No writer SP found; table is manually loaded. 1,021 distinct values across 1,025 rows; 4 InstrumentIDs have duplicates. No NULLs observed. (Tier 3 — no writer SP; grounded in DDL and live data) |
| 2 | Name | varchar(50) | YES | Human-readable ticker name for the instrument in `SYMBOL/USD` format (e.g., `AAPL/USD`, `FB/USD`, `TSLA/USD`). Represents the trading pair denomination on the eToro platform. 1,018 distinct values; 5 names have duplicates. No NULLs observed. (Tier 3 — no writer SP; grounded in DDL and live data) |
| 3 | UpdateDate | datetime | NO | Timestamp indicating when the record was last inserted or updated. All values fall between 2019-03-24 and 2019-11-24, clustering around a small number of batch-load dates. NOT NULL by DDL constraint. (Tier 3 — no writer SP; grounded in DDL and live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| InstrumentID | Unknown (manual load) | InstrumentID | None |
| Name | Unknown (manual load) | Name | None |
| UpdateDate | Unknown (manual load) | UpdateDate | None |

### 5.2 ETL Pipeline

```
Unknown external source (manual load / ad-hoc script)
  |-- One-time load (2019) ---|
  v
BI_DB_dbo.BI_DB_US_Stocks (1,025 rows, dormant since 2019-11-24)
  |-- LEFT JOIN in SP_Daily_Dividends ---|
  v
BI_DB_dbo.BI_DB_Daily_Dividends (Is_US_Stock flag derived from existence check)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| InstrumentID | DWH_dbo.Dim_Instrument | Logical FK — no DDL constraint enforced |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Element | Description |
|---|---|---|
| BI_DB_dbo.SP_Daily_Dividends | InstrumentID | LEFT JOIN to derive Is_US_Stock flag for BI_DB_Daily_Dividends |

---

## 7. Sample Queries

### 7.1 Check if an Instrument is a US Stock

```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM BI_DB_dbo.BI_DB_US_Stocks WHERE InstrumentID = 1001
) THEN 'US Stock' ELSE 'Not US Stock' END AS classification;
```

### 7.2 List All US Stock Instruments with Dim_Instrument Details

```sql
SELECT us.InstrumentID,
       us.Name AS US_Ticker,
       di.InstrumentDisplayName,
       di.InstrumentType,
       di.Exchange
FROM BI_DB_dbo.BI_DB_US_Stocks us
JOIN DWH_dbo.Dim_Instrument di ON di.InstrumentID = us.InstrumentID
ORDER BY di.InstrumentType, us.Name;
```

### 7.3 Find Duplicate InstrumentIDs

```sql
SELECT InstrumentID, Name, UpdateDate
FROM BI_DB_dbo.BI_DB_US_Stocks
WHERE InstrumentID IN (
    SELECT InstrumentID FROM BI_DB_dbo.BI_DB_US_Stocks
    GROUP BY InstrumentID HAVING COUNT(*) > 1
)
ORDER BY InstrumentID, Name;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this object.

---

*Generated: 2026-04-30 | Quality: 6/10 | Phases: 12/14*
*Tiers: 0 T1, 0 T2, 3 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 4/10, Lineage: 3/10*
*Object: BI_DB_dbo.BI_DB_US_Stocks | Type: Table | Production Source: Unknown (dormant)*
