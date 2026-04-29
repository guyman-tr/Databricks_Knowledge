# BI_DB_dbo.BI_DB_Stocks_HS125

> 57.4M-row instrument-level daily aggregation of stock and ETF open positions across 10 hedge servers (HS125, HS121, HS126, HS112, HS130, HS128, HS9, HS3, HS102, HS124) from 2019-04-15 to present — tracking units held, net open position (NOP) value in USD, and position count per instrument per regulation per settlement type. Sourced from BI_DB_PositionPnL via SP_Stocks_HS125 with daily DELETE+INSERT by Date. Used in Tableau Finance/Regulation reports. ~55K rows per day.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_PositionPnL → SP_Stocks_HS125 (Amir Gurewitz, 2019) |
| **Refresh** | Daily DELETE+INSERT by Date (SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| **UC Target** | _Not_Migrated (not in Generic Pipeline mapping) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Stocks_HS125 is the instrument-level daily aggregation table for eToro's stock and ETF open positions across 10 hedge servers. Each row represents one unique combination of Date × HedgeServerID × InstrumentID × IsSettled × Regulation, showing total units held, total NOP value in USD, and position count.

The table was created by Amir Gurewitz in April 2019 for Finance and Regulation Tableau dashboards. It sources from BI_DB_PositionPnL (the daily open-position snapshot) filtered to InstrumentTypeID IN (5=Stocks, 6=ETFs) and validated customers only (Dim_Customer.IsValidCustomer=1). Instrument metadata (display name, symbol, ISIN, sell currency) comes from Dim_Instrument, and regulation name from Dim_Regulation via the customer's RegulationID.

The SP also writes the companion CID-level detail table BI_DB_Stocks_HS121_CIDs (documented in Batch 102) in the same run.

Key facts:
- 57.4M total rows spanning 2019-04-15 to 2026-04-12
- ~55,362 rows per recent day (7,505 distinct instruments × 7 active hedge servers × 11 regulations × 2 settlement types, with sparse coverage)
- 7 hedge servers actively contributing data (102, 112, 121, 124, 126, 128, 130); HS125, HS9, HS3 appear in filter but have zero rows currently
- Regulation distribution on latest day: CySEC (13.5K), FCA (12.8K), FSA Seychelles (10.4K), ASIC & GAML (9.1K), FSRA (8.1K), MAS (573), BVI (491), ASIC (406), FinCEN (29), NYDFS+FINRA (11), None (4)
- IsSettled: 1=real asset (85.7%), 0=CFD (14.3%)

---

## 2. Business Logic

### 2.1 Instrument Type Filter

**What**: Only stocks and ETFs are included.
**Columns Involved**: InstrumentTypeID (from BI_DB_PositionPnL)
**Rules**:
- Filter: `InstrumentTypeID IN (5, 6)` where 5=Stocks, 6=ETFs
- All other instrument types (forex, commodities, indices, crypto) are excluded

### 2.2 Hedge Server Filter

**What**: Positions from 10 specific hedge servers are included.
**Columns Involved**: HedgeServerID
**Rules**:
- Filter: `HedgeServerID IN (125, 121, 126, 112, 130, 128, 9, 3, 102, 124)`
- Hedge servers added over time: original (125), then 121 (Jul 2019), 126/112 (Jan 2020), 130/128/9/3 (Sep 2022), 124/102 (Feb 2023)
- Currently 7 of 10 servers have active data

### 2.3 Valid Customer Filter

**What**: Only positions for validated customers are included.
**Columns Involved**: CID (via Dim_Customer.IsValidCustomer)
**Rules**:
- JOIN Dim_Customer on RealCID = CID, filter IsValidCustomer = 1
- Removes test accounts, internal accounts, and invalid customers

### 2.4 Aggregation Grain

**What**: Position-level data is aggregated to instrument level per hedge server per date.
**Columns Involved**: Date, HedgeServerID, InstrumentDisplayName, Symbol, ISINCode, SellCurrency, Regulation, InstrumentID, IsSettled
**Rules**:
- GROUP BY all dimension columns
- TotalUnits = SUM(AmountInUnitsDecimal) — total units held across all positions
- PositionValue = SUM(NOP) — net open position in USD
- CountPositions = COUNT(PositionID) — number of open positions

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with clustered index on [Date]. All queries should filter on Date for index seek. No distribution key optimization available — cross-node movement occurs on all JOINs.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Total NOP by regulation on a given date | `WHERE Date = @date GROUP BY Regulation` |
| Instrument exposure by hedge server | `WHERE Date = @date GROUP BY HedgeServerID, InstrumentDisplayName` |
| Top instruments by position value | `WHERE Date = @date ORDER BY PositionValue DESC` |
| Settled vs CFD exposure trend | `GROUP BY Date, IsSettled` with Date range filter |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Full instrument metadata (asset class, exchange, tradability) |
| BI_DB_dbo.BI_DB_Stocks_HS121_CIDs | Date + HedgeServerID + InstrumentID + IsSettled | CID-level detail drill-down |

### 3.4 Gotchas

- **Symbol is Dim_Instrument.Name, not Symbol**: The SP maps `di.Name AS Symbol` — for some instruments, `Name` differs from the standard ticker (e.g., pair notation for forex-like instruments). Use InstrumentDisplayName for user-facing display.
- **PositionValue is NOP in USD**: Not the nominal invested amount — it is units × pair rate × direction × USD conversion from BI_DB_PositionPnL.NOP.
- **Hedge servers 125, 9, 3 have zero current data**: They are in the SP filter but produce no rows in recent dates — these may be legacy or inactive servers.
- **No CID column**: This is the instrument-aggregated table. For CID-level data, use BI_DB_Stocks_HS121_CIDs.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Description | Tag Pattern |
|------|-------------|-------------|
| Tier 1 | Upstream wiki verbatim | `(Tier 1 — source)` |
| Tier 2 | SP code / DDL evidence | `(Tier 2 — SP)` |
| Tier 3 | Live data / structure | `(Tier 3 — source)` |
| Tier 5 | ETL metadata | `(Tier 5 — ETL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | Snapshot calendar date — the SP parameter @Date. One row per instrument per hedge server per regulation per settlement type per date. Clustered index key. (Tier 3 — SP_Stocks_HS125, parameter @Date) |
| 2 | HedgeServerID | int | NO | Hedge server hosting the positions. Active servers: 102, 112, 121, 124, 126, 128, 130 (plus 125, 9, 3 in filter but currently inactive). Passthrough from BI_DB_PositionPnL. (Tier 2 — SP_Stocks_HS125, BI_DB_PositionPnL.HedgeServerID) |
| 3 | InstrumentDisplayName | varchar(100) | NO | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). Passthrough from Dim_Instrument. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 4 | Symbol | varchar(25) | YES | Instrument name from Dim_Instrument.Name (aliased as Symbol in SP). For stocks: ticker notation (e.g., AAPL). For some instruments, differs from the standard Symbol field. (Tier 2 — SP_Stocks_HS125, DWH_dbo.Dim_Instrument.Name) |
| 5 | ISINCode | varchar(25) | YES | International Securities Identification Number — 12-character alphanumeric code standardized by ISO 6166 (e.g., US0378331005 for Apple). Passthrough from Dim_Instrument. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 6 | SellCurrency | varchar(25) | YES | Text abbreviation of the sell-side (denomination) currency from Dim_Instrument. Example: USD, EUR, GBX (GBP pence). DWH-added denormalization from Dictionary.Currency.Abbreviation. (Tier 2 — SP_Dim_Instrument) |
| 7 | Regulation | varchar(25) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation via Dim_Customer.RegulationID. (Tier 1 — Dictionary.Regulation) |
| 8 | TotalUnits | numeric(16,6) | YES | Total instrument units held across all positions in this group. Aggregation: SUM(AmountInUnitsDecimal) from BI_DB_PositionPnL. Represents fractional share quantities. (Tier 2 — SP_Stocks_HS125, SUM of BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 9 | PositionValue | money | YES | Net open position (NOP) value in USD across all positions in this group. Aggregation: SUM(NOP) from BI_DB_PositionPnL where NOP = units × pair rate × direction × USD conversion factor. (Tier 2 — SP_Stocks_HS125, SUM of BI_DB_PositionPnL.NOP) |
| 10 | CountPositions | int | YES | Number of open positions in this group. Aggregation: COUNT(PositionID) from BI_DB_PositionPnL. (Tier 2 — SP_Stocks_HS125, COUNT of BI_DB_PositionPnL.PositionID) |
| 11 | UpdateDate | datetime | YES | Row load timestamp set to GETDATE() at insert time. Not a business date. (Tier 5 — ETL metadata, GETDATE()) |
| 12 | InstrumentID | int | YES | Traded instrument identifier. FK to DWH_dbo.Dim_Instrument. Passthrough from BI_DB_PositionPnL. (Tier 2 — SP_Stocks_HS125, BI_DB_PositionPnL.InstrumentID) |
| 13 | IsSettled | tinyint | YES | Settlement type: 1=real asset (shares held in custody), 0=CFD (contract for difference). Passthrough from BI_DB_PositionPnL. (Tier 2 — SP_Stocks_HS125, BI_DB_PositionPnL.IsSettled) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP parameter | @Date | Passthrough |
| HedgeServerID | BI_DB_dbo.BI_DB_PositionPnL | HedgeServerID | Passthrough (GROUP BY key) |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Dim-lookup passthrough |
| Symbol | DWH_dbo.Dim_Instrument | Name | Dim-lookup passthrough (renamed) |
| ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Dim-lookup passthrough |
| SellCurrency | DWH_dbo.Dim_Instrument | SellCurrency | Dim-lookup passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough via Dim_Customer.RegulationID |
| TotalUnits | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM() aggregation |
| PositionValue | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM() aggregation |
| CountPositions | BI_DB_dbo.BI_DB_PositionPnL | PositionID | COUNT() aggregation |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL | InstrumentID | Passthrough (GROUP BY key) |
| IsSettled | BI_DB_dbo.BI_DB_PositionPnL | IsSettled | Passthrough (GROUP BY key) |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position + DWH_dbo.Fact_CurrencyPriceWithSplit + ...
  |-- SP_PositionPnL (daily partition swap) ---|
  v
BI_DB_dbo.BI_DB_PositionPnL (open-position snapshot, ~billions of rows)
  |-- SP_Stocks_HS125 @Date ---|
  |  + DWH_dbo.Dim_Instrument (display name, symbol, ISIN, currency)
  |  + DWH_dbo.Dim_Customer (IsValidCustomer filter + RegulationID)
  |  + DWH_dbo.Dim_Regulation (regulation name)
  |  + DWH_dbo.Fact_CurrencyPriceWithSplit (#Prices for NOP)
  |  Filter: InstrumentTypeID IN (5,6), HedgeServerID IN (125,121,...), IsValidCustomer=1
  |  Aggregation: GROUP BY HedgeServerID, Instrument, Regulation, IsSettled
  v
BI_DB_dbo.BI_DB_Stocks_HS125 (57.4M rows, instrument-level daily aggregation)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata lookup |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship |
|-------------------|-------------|
| Tableau Finance/Regulation dashboards | Primary consumer (external) |

---

## 7. Sample Queries

### 7.1 Daily NOP Exposure by Regulation

```sql
SELECT Date, Regulation,
       SUM(PositionValue) AS TotalNOP,
       SUM(CountPositions) AS TotalPositions,
       SUM(TotalUnits) AS TotalUnits
FROM BI_DB_dbo.BI_DB_Stocks_HS125
WHERE Date = '2026-04-12'
GROUP BY Date, Regulation
ORDER BY TotalNOP DESC
```

### 7.2 Top 20 Instruments by Position Value

```sql
SELECT InstrumentDisplayName, Symbol, ISINCode, SellCurrency,
       SUM(PositionValue) AS TotalNOP,
       SUM(CountPositions) AS Positions,
       SUM(TotalUnits) AS Units
FROM BI_DB_dbo.BI_DB_Stocks_HS125
WHERE Date = '2026-04-12'
GROUP BY InstrumentDisplayName, Symbol, ISINCode, SellCurrency
ORDER BY TotalNOP DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
```

### 7.3 Settled vs CFD Trend

```sql
SELECT Date, IsSettled,
       SUM(PositionValue) AS TotalNOP,
       SUM(CountPositions) AS Positions
FROM BI_DB_dbo.BI_DB_Stocks_HS125
WHERE Date >= '2026-01-01'
GROUP BY Date, IsSettled
ORDER BY Date, IsSettled
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 1 T1, 9 T2, 1 T3, 0 T4, 1 T5 | Elements: 13/13, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Stocks_HS125 | Type: Table | Production Source: BI_DB_PositionPnL via SP_Stocks_HS125*
