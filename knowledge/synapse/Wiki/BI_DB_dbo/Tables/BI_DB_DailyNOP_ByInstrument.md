# BI_DB_dbo.BI_DB_DailyNOP_ByInstrument

> 40.4M-row daily Net Open Position (NOP) report by instrument and hedge server, tracking aggregated customer exposure across all tradeable instruments from January 2018 to present — 12,501 distinct instruments across 41 hedge servers, refreshed daily via SP_DailyNOP_ByInstrument (delete date + insert from BI_DB_PositionPnL aggregation enriched with latest price from SpreadedPriceCandle60MinSplitted).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_PositionPnL (NOP aggregation) + BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted (latest price) via SP_DailyNOP_ByInstrument |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE for @date + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX([Date] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_DailyNOP_ByInstrument is a daily risk monitoring table that reports the Net Open Position (NOP) for every tradeable instrument, broken down by hedge server. Each row represents the total aggregated NOP for one instrument on one hedge server on one date, along with the latest available market price.

The table contains 40.4M rows spanning January 2018 to April 2026 across 3,005 distinct dates. It covers 12,501 distinct instruments across 41 hedge servers, with 6 instrument types (Stocks dominating at ~85%, followed by ETFs, Crypto Currencies, Commodities, Currencies, and Indices).

The ETL runs daily: SP_DailyNOP_ByInstrument first obtains the latest BidLast price per instrument from BI_DB_SpreadedPriceCandle60MinSplitted (using ROW_NUMBER partitioned by InstrumentID, ordered by DateFrom DESC). Then it aggregates NOP from BI_DB_PositionPnL for the date, filtering to valid customers only (Dim_Customer.IsValidCustomer = 1), grouped by InstrumentID and HedgeServerID. A FULL OUTER JOIN between NOP and price data ensures instruments with positions but no price and instruments with price but no positions are both captured. The result is enriched with Dim_Instrument metadata (InstrumentType, InstrumentDisplayName).

NOP (Net Open Position) is the total directional exposure in the instrument — positive means net long, negative means net short. This is a key risk metric for monitoring platform-wide market exposure per hedge server.

---

## 2. Business Logic

### 2.1 NOP Aggregation

**What**: Net Open Position is the sum of all individual customer positions for an instrument on a given hedge server, filtered to valid customers.
**Columns Involved**: NOP, InstrumentID, HedgeServer
**Rules**:
- NOP = SUM(BI_DB_PositionPnL.NOP) WHERE Dim_Customer.IsValidCustomer = 1 AND DateID = @dateINT
- Grouped by InstrumentID + HedgeServerID
- Positive NOP = net long exposure; negative NOP = net short exposure
- Range: -65.1M to 1.67B (extreme values for high-volume instruments)
- ISNULL(NOP, 0) applied — instruments from price data with no positions get NOP = 0

### 2.2 Latest Price Capture

**What**: The most recent bid price for each instrument as of the reporting date.
**Columns Involved**: LastPrice, InstrumentID
**Rules**:
- Source: BI_DB_SpreadedPriceCandle60MinSplitted.BidLast
- Selected via ROW_NUMBER partitioned by InstrumentID, ordered by DateFrom DESC, WHERE DateFrom < @NextDate
- ISNULL(LastPrice, 0) — instruments with NOP but no price data get LastPrice = 0
- LastPrice = 0 observed in recent data for some instruments (price candle not yet available)

### 2.3 FULL OUTER JOIN Coverage

**What**: Ensures complete instrument coverage regardless of whether price or position data exists.
**Columns Involved**: InstrumentID, HedgeServer, NOP, LastPrice
**Rules**:
- FULL OUTER JOIN between price and NOP temp tables on InstrumentID
- Instruments with NOP but no price: LastPrice = 0
- Instruments with price but no NOP: NOP = 0, HedgeServer = 0
- ISNULL on both InstrumentID sides ensures no NULL InstrumentIDs in output

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN ��� no natural distribution key (grain is InstrumentID + HedgeServer)
- **Clustered Index**: Date ASC — always filter by Date/DateID for efficient range scans

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total NOP for an instrument today | `WHERE DateID = @today AND InstrumentID = @id; SELECT SUM(NOP)` (sum across hedge servers) |
| Largest exposures by instrument type | `WHERE DateID = @today GROUP BY InstrumentType ORDER BY ABS(SUM(NOP)) DESC` |
| NOP trend for an instrument | `WHERE InstrumentID = @id ORDER BY Date` |
| Instruments with no price data | `WHERE DateID = @today AND LastPrice = 0 AND NOP <> 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Get ISIN, AssetClass, exchange details |
| BI_DB_dbo.BI_DB_PositionPnL | ON InstrumentID + DateID | Drill into individual position P&L |
| BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted | ON InstrumentID + DateFrom range | Full price candle history |

### 3.4 Gotchas

- **Multiple rows per instrument per date** — one per HedgeServer. SUM(NOP) across HedgeServer for total instrument NOP
- **LastPrice = 0** does not mean the price is zero — it means no price candle was available. Filter `WHERE LastPrice > 0` for pricing analysis
- **HedgeServer = 0** means the instrument came from the price side of the FULL OUTER JOIN with no matching NOP (no positions)
- **NOP is in units of the instrument**, not in USD — multiply by LastPrice for dollar exposure
- **Only valid customers** (IsValidCustomer = 1) are included — internal/test accounts are excluded from NOP
- **Date column is DATE type**, DateID is INT (YYYYMMDD) — use DateID for efficient integer comparisons

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest — verified by source system owner |
| Tier 2 | SP code / ETL logic analysis | High — derived from version-controlled code |
| Tier 3 | Live data observation + schema inference | Medium — empirically verified but no code/wiki confirmation |
| Tier 4 | Inferred from naming / context | Lower — best-effort, needs reviewer validation |
| Tier 5 | Propagation rule (ETL metadata pattern) | Standard — canonical description for known ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date for the NOP snapshot. One snapshot per date, populated from @date SP parameter. Range: 2018-01-01 to present, 3,005 distinct dates. (Tier 2 — SP_DailyNOP_ByInstrument) |
| 2 | DateID | int | YES | Integer representation of Date in YYYYMMDD format. Computed as CAST(CONVERT(CHAR(8), @date, 112) AS INT). Use for efficient integer range filtering. (Tier 2 — SP_DailyNOP_ByInstrument) |
| 3 | InstrumentType | varchar(50) | YES | Instrument asset class category from Dim_Instrument. 6 values: Stocks, ETF, Crypto Currencies, Commodities, Currencies, Indices. CASE-computed in SP_Dim_Instrument from InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. (Tier 1 — DWH_dbo.Dim_Instrument) |
| 4 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 — upstream wiki, Trade.Instrument) |
| 5 | Instrument | varchar(100) | YES | Display name of the instrument from Dim_Instrument.InstrumentDisplayName. Human-readable name including contract details (e.g., "Spot Quoted S&P 500 Jun 26 Future", "Amundi FTSE 100 UCITS ETF Acc"). Renamed from InstrumentDisplayName in SP. (Tier 1 — DWH_dbo.Dim_Instrument) |
| 6 | HedgeServer | int | YES | Hedge server ID where the positions are held. 41 distinct values in current data. Value 0 indicates instrument came from price data with no matching positions (FULL OUTER JOIN ISNULL). Renamed from HedgeServerID in SP. (Tier 2 — SP_DailyNOP_ByInstrument via BI_DB_PositionPnL.HedgeServerID) |
| 7 | NOP | float | YES | Net Open Position — total directional exposure for this instrument on this hedge server. SUM of individual BI_DB_PositionPnL.NOP for valid customers (IsValidCustomer=1). Positive = net long, negative = net short. Range: -65.1M to 1.67B. Units are instrument-specific (not USD). ISNULL(NOP, 0) when no positions exist. (Tier 2 — SP_DailyNOP_ByInstrument) |
| 8 | LastPrice | numeric(16,8) | YES | Latest bid price for the instrument as of the reporting date. Source: BI_DB_SpreadedPriceCandle60MinSplitted.BidLast, latest available (ROW_NUMBER DESC by DateFrom). ISNULL(LastPrice, 0) when no price candle exists. Value 0 means missing price, not zero price. (Tier 2 — SP_DailyNOP_ByInstrument) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 — Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Date | SP parameter | @date | Direct assignment |
| DateID | SP parameter | @dateINT | CAST(CONVERT(CHAR(8), @date, 112) AS INT) |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | JOIN on InstrumentID |
| InstrumentID | BI_DB_PositionPnL / SpreadedPriceCandle60MinSplitted | InstrumentID | ISNULL via FULL OUTER JOIN |
| Instrument | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Renamed |
| HedgeServer | BI_DB_dbo.BI_DB_PositionPnL | HedgeServerID | ISNULL(HedgeServerID, 0), renamed |
| NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM, filtered IsValidCustomer=1, ISNULL(,0) |
| LastPrice | BI_DB_SpreadedPriceCandle60MinSplitted | BidLast | Latest per instrument (ROW_NUMBER), ISNULL(,0) |
| UpdateDate | SP computation | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (position P&L per CID/instrument)
  + DWH_dbo.Dim_Customer (IsValidCustomer=1 filter)
  |-- SUM(NOP) GROUP BY InstrumentID, HedgeServerID ---|
  v
#NOP (temp: aggregated NOP per instrument per hedge server)
  |
  |-- FULL OUTER JOIN on InstrumentID ---|
  |                                      |
BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted
  |-- Latest BidLast per InstrumentID (ROW_NUMBER) ---|
  v
#Price (temp: latest price per instrument)
  |
  v
#final (temp: merged NOP + price)
  + DWH_dbo.Dim_Instrument (InstrumentType, InstrumentDisplayName)
  |-- DELETE @date + INSERT ---|
  v
BI_DB_dbo.BI_DB_DailyNOP_ByInstrument (40.4M rows, ROUND_ROBIN, CI(Date))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | FK to instrument dimension — resolves type, name, ISIN, asset class |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| (none found in SSDT) | — | Used for risk monitoring dashboards (inferred) |

---

## 7. Sample Queries

### 7.1 Top 20 Instruments by Absolute NOP Today

```sql
SELECT InstrumentID, Instrument, InstrumentType,
       SUM(NOP) AS total_nop,
       MAX(LastPrice) AS price
FROM [BI_DB_dbo].[BI_DB_DailyNOP_ByInstrument]
WHERE [Date] = (SELECT MAX([Date]) FROM [BI_DB_dbo].[BI_DB_DailyNOP_ByInstrument])
GROUP BY InstrumentID, Instrument, InstrumentType
ORDER BY ABS(SUM(NOP)) DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
```

### 7.2 Daily NOP Trend for a Specific Instrument

```sql
SELECT [Date], SUM(NOP) AS total_nop, MAX(LastPrice) AS price
FROM [BI_DB_dbo].[BI_DB_DailyNOP_ByInstrument]
WHERE InstrumentID = 1001
  AND [Date] >= '2026-01-01'
GROUP BY [Date]
ORDER BY [Date];
```

### 7.3 NOP by Instrument Type and Hedge Server

```sql
SELECT InstrumentType, HedgeServer,
       COUNT(DISTINCT InstrumentID) AS instruments,
       SUM(NOP) AS total_nop
FROM [BI_DB_dbo].[BI_DB_DailyNOP_ByInstrument]
WHERE DateID = 20260412
GROUP BY InstrumentType, HedgeServer
ORDER BY InstrumentType, HedgeServer;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14 (P10 Atlassian unavailable)*
*Tiers: 3 T1, 5 T2, 0 T3, 0 T4, 1 T5 | Elements: 9/9, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_DailyNOP_ByInstrument | Type: Table | Production Source: BI_DB_PositionPnL + SpreadedPriceCandle60MinSplitted*
