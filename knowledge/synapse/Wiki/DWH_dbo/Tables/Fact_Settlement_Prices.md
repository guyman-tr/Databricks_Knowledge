# DWH_dbo.Fact_Settlement_Prices

> Daily end-of-day settlement price reference table for futures/derivatives instruments, providing the official closing settlement price per instrument per trading day.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_staging.EndOfDay_EOD_SettlementPrices (End-of-Day price feed) |
| **Refresh** | Daily incremental (delete-for-date + insert via @dt parameter) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX(InstrumentID ASC, SettlementDateID ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

Fact_Settlement_Prices stores the official end-of-day settlement price for each futures/derivatives instrument on each trading day. Settlement prices are the official closing prices used by clearing houses and exchanges to mark positions to market and calculate daily P&L for futures contracts. They differ from regular bid/ask prices in that they are officially published values used for margin calls and contract settlement.

Data originates from `DWH_staging.EndOfDay_EOD_SettlementPrices`, an end-of-day price feed staging table. The 200 distinct InstrumentIDs in production (range 200004-201004+) correspond to futures and derivatives instruments in Dim_Instrument. Data coverage begins 2024-12-24, suggesting the table was introduced for a new futures product line launched in late 2024. Only 16,385 rows total as of March 2026 -- a very small, tightly-scoped reference table.

Loaded daily by `SP_Fact_Settlement_Prices(@dt)` (author: Inbal BML, 2024-10-31). The SP deletes rows where `SettlementDate` falls on `@dt` then reloads from staging. Two columns are DWH-derived: `SettlementDateID` (YYYYMMDD from Date) and `UpdateDate` (GETDATE()); all others are passthrough renames.

---

## 2. Business Logic

### 2.1 Futures Settlement Price as Mark-to-Market Reference

**What**: Settlement prices are the official reference for end-of-day P&L calculation on futures positions. They are distinct from last-traded prices and are set by the exchange.

**Columns Involved**: `SettlementPrice`, `InstrumentID`, `SettlementDateID`

**Rules**:
- One row per InstrumentID per SettlementDateID (trading day)
- `SettlementPrice` is the exchange-published official closing price, not a bid/ask mid
- Used as the reference price by `SP_Fact_Position_Futures_Snapshot` for daily P&L valuation of futures positions

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on (InstrumentID, SettlementDateID). This composite CI makes point lookups by instrument + date very efficient. Since the table is small (16K rows), broadcast JOINs against it are low-cost and the distribution strategy has negligible performance impact.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, storage details are resolved during the write-objects deployment phase. Given the table's small size, partitioning is unlikely to be needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Settlement price for an instrument on a date | `WHERE InstrumentID = @id AND SettlementDateID = @dateID` |
| All settlement prices for a date | `WHERE SettlementDateID = @dateID ORDER BY InstrumentID` |
| Historical settlement prices for a futures instrument | `WHERE InstrumentID = @id ORDER BY SettlementDateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON f.InstrumentID = di.InstrumentID | Resolve instrument name, symbol, asset class |
| DWH_dbo.Fact_Position_Futures_Snapshot | ON f.InstrumentID + SettlementDateID | This table feeds Fact_Position_Futures_Snapshot for futures P&L |

### 3.4 Gotchas

- Data only covers **2024-12-24 onwards**. No pre-2024 settlement price history is available.
- Only **200 distinct instruments** are covered -- specifically futures/derivatives (InstrumentIDs 200000+). Spot instruments are NOT in this table; use Fact_CurrencyPriceWithSplit for those.
- The table has no explicit primary key constraint in the DDL but (InstrumentID, SettlementDateID) should be unique. Verify before using as a dimension join.
- `SettlementPrice` is `decimal(38,18)` -- very high precision. Use CAST/ROUND when displaying to avoid unnecessary trailing zeros.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 - domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 - upstream wiki, source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 - SP code / DDL)` | From SSDT SP or DDL analysis |
| ★★☆☆☆ | Tier 3 | `(Tier 3 - live data / DDL structure)` | From sampling or DDL |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | NO | Financial instrument identifier. Foreign key to DWH_dbo.Dim_Instrument. Identifies the futures/derivatives contract. Composite CI key -- always include in JOINs and WHERE filters for efficient Synapse queries. 200 distinct instruments in production (InstrumentIDs 200000+ range). (Tier 2 - SP_Fact_Settlement_Prices) |
| 2 | SettlementDateID | int | NO | Settlement date as YYYYMMDD integer (e.g., 20260310). DWH-derived: computed in SP as CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY,0,Date),0), 112)). Composite CI key -- use for date-range filters. Corresponds to DWH_dbo.Dim_Date.DateID. (Tier 2 - SP_Fact_Settlement_Prices) |
| 3 | SettlementDate | date | NO | Settlement date as a DATE type. Source column `Date` from EndOfDay_EOD_SettlementPrices, renamed to SettlementDate in the SP. Use for display or date arithmetic. (Tier 2 - SP_Fact_Settlement_Prices) |
| 4 | SettlementPrice | decimal(38,18) | NO | Official end-of-day settlement price for the futures/derivatives instrument on this date, as published by the exchange or clearing house. Source column `Price` renamed in SP. Used by SP_Fact_Position_Futures_Snapshot for mark-to-market P&L valuation. High-precision decimal(38,18). (Tier 2 - SP_Fact_Settlement_Prices) |
| 5 | UpdateDate | datetime2(7) | NO | DWH load timestamp. Set to GETDATE() at ETL execution time. Not the price date -- use SettlementDate for the business date. (Tier 2 - SP_Fact_Settlement_Prices) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| InstrumentID | DWH_staging.EndOfDay_EOD_SettlementPrices | InstrumentID | Passthrough |
| SettlementDateID | ETL-computed | Date | CONVERT(INT,CONVERT(VARCHAR,DATEADD(DAY,DATEDIFF(DAY,0,Date),0),112)) |
| SettlementDate | DWH_staging.EndOfDay_EOD_SettlementPrices | Date | Renamed to SettlementDate |
| SettlementPrice | DWH_staging.EndOfDay_EOD_SettlementPrices | Price | Renamed to SettlementPrice |
| UpdateDate | ETL-computed | N/A | GETDATE() |

No upstream wiki available. DWH_staging.EndOfDay_EOD_SettlementPrices is an end-of-day price feed staging table, not documented in DB_Schema etoro wiki.

### 5.2 ETL Pipeline

```
End-of-Day price feed (exchange/clearing house)
  -> DWH_staging.EndOfDay_EOD_SettlementPrices
  -> SP_Fact_Settlement_Prices(@dt)
  -> DWH_dbo.Fact_Settlement_Prices [DELETE for SettlementDate + INSERT]
```

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_staging.EndOfDay_EOD_SettlementPrices | EOD settlement price staging from exchange feed |
| ETL | SP_Fact_Settlement_Prices (Author: Inbal BML, 2024-10-31) | Per-date delete + INSERT with column rename |
| Target | DWH_dbo.Fact_Settlement_Prices | DWH settlement price reference table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument name, symbol, asset class for the futures contract |
| SettlementDateID | DWH_dbo.Dim_Date (via DateID) | Date dimension (year, month, quarter) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_Position_Futures_Snapshot | SettlementPrice via InstrumentID + SettlementDateID | Uses settlement prices for daily P&L valuation of futures positions |

---

## 7. Sample Queries

### 7.1 Settlement prices for all instruments on a date

```sql
SELECT
    f.InstrumentID,
    di.InstrumentDisplayName,
    f.SettlementDate,
    f.SettlementPrice
FROM [DWH_dbo].[Fact_Settlement_Prices] f
JOIN [DWH_dbo].[Dim_Instrument] di ON f.InstrumentID = di.InstrumentID
WHERE f.SettlementDateID = 20260310
ORDER BY di.InstrumentDisplayName;
```

### 7.2 Settlement price history for a specific futures instrument

```sql
SELECT
    f.SettlementDate,
    f.SettlementPrice,
    f.SettlementPrice - LAG(f.SettlementPrice) OVER (ORDER BY f.SettlementDateID) AS daily_change
FROM [DWH_dbo].[Fact_Settlement_Prices] f
WHERE f.InstrumentID = 200004
ORDER BY f.SettlementDate;
```

### 7.3 Latest available settlement price per instrument

```sql
SELECT
    f.InstrumentID,
    di.InstrumentDisplayName,
    f.SettlementDate,
    f.SettlementPrice
FROM [DWH_dbo].[Fact_Settlement_Prices] f
JOIN [DWH_dbo].[Dim_Instrument] di ON f.InstrumentID = di.InstrumentID
WHERE f.SettlementDateID = (SELECT MAX(SettlementDateID) FROM [DWH_dbo].[Fact_Settlement_Prices])
ORDER BY di.InstrumentDisplayName;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 7.2/10 (★★★★☆) | Phases: 7/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10*
*Object: DWH_dbo.Fact_Settlement_Prices | Type: Table | Production Source: DWH_staging.EndOfDay_EOD_SettlementPrices*
