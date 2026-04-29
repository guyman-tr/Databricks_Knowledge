# BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks

> 197.6M-row daily Zero P&L snapshot for stocks and ETFs (InstrumentTypeID 5 & 6), covering 2019-01-01 to 2024-02-09. Each row aggregates eToro realized and unrealized revenue by date, hedge server, instrument, leverage, CFD flag, regulation, and MiFID category. Populated via a one-time migration from `Dealing_dbo.Dealing_DailyZeroPnL_Stocks`; the live version is maintained by `SP_DailyZeroPnL_Stocks` in Dealing_dbo and is dormant in this schema as of February 2024.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_DailyZeroPnL_Stocks (via Dealing_dbo.Dealing_DailyZeroPnL_Stocks migration) — dormant since 2024-02-09 |
| **Refresh** | Dormant — last loaded 2024-02-09; live version in Dealing_dbo refreshed daily |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline — Append, 1440 min) |

---

## 1. Business Meaning

197.6M rows covering 2019-01-01 to 2024-02-09. Daily eToro revenue (Zero P&L) aggregated by instrument for stocks and ETFs. Each row represents one combination of date, hedge server, instrument, leverage tier, CFD flag, regulation, MiFID category, and trading mode. Realized Zero comes from positions closed on the report date; Unrealized Zero reflects mark-to-market P&L on open positions. The table was migrated from `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` in September 2024 as a historical snapshot and is dormant — the active version with data through present is in Dealing_dbo. The underlying ETL SP (`SP_DailyZeroPnL_Stocks`, author: Amir Gurewitz, 2020-06-09) covers InstrumentTypeID IN (5, 6) only; forex, crypto, and commodities are excluded.

---

## 2. Business Logic

### 2.1 Zero P&L Formula

**What**: eToro's "Zero P&L" is the daily revenue the company earns on each stock/ETF position group.
**Columns Involved**: `RealizedZero`, `ChangeInUnrealizedZero`, `TotalZero`, `RealizedCommission`
**Rules**:
- RealizedZero = SUM(NetProfit + CommissionOnClose − PreviousDayPnL) for positions with CloseDateID = @RepDate
- ChangeInUnrealizedZero = SUM(DailyPnL + commission adjustment) for positions still open at EOD
- TotalZero = RealizedZero + ChangeInUnrealizedZero
- RealizedCommission = SUM of commission on positions closed on the report date

### 2.2 CFD vs Real Stocks Classification

**What**: Splits positions into CFD and real-stock buckets for regulatory and P&L reporting.
**Columns Involved**: `IsCFD`, `IsManual`
**Rules**:
- IsCFD = 0 when Dim_Position.IsSettled = 1 (real stock); IsCFD = 1 otherwise (CFD)
- IsManual = 1 when MirrorID = 0 (manual trade); IsManual = 0 for copy positions
- InstrumentType observed: `Stocks` (177.3M rows, 89.7%) / `ETF` (20.3M rows, 10.3%)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on `Date`. Always filter by `Date` first; range scans on the clustered index will be efficient. Avoid unbounded full-table scans on this 197M-row table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Daily total Zero revenue by regulation | `SELECT Date, Regulation, SUM(TotalZero) GROUP BY Date, Regulation ORDER BY Date DESC` |
| Weekly NOP by instrument type and CFD flag | `SELECT DATEPART(wk,Date), InstrumentType, IsCFD, SUM(NOP) GROUP BY ...` |
| Top instruments by realized zero on a date | `SELECT InstrumentDisplayName, SUM(RealizedZero) WHERE Date=@d GROUP BY InstrumentDisplayName ORDER BY 2 DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `InstrumentID = InstrumentID` | Enrich with ISIN, sector, asset class |
| Dealing_dbo.Dealing_DailyZeroPnL_Stocks | `Date = Date AND InstrumentID = InstrumentID` | Compare dormant BI_DB snapshot vs live Dealing data |
| BI_DB_dbo.BI_DB_IndexesMapping_Static | `InstrumentID = InstrumentID` | Validate StockIndex alignment |

### 3.4 Gotchas

- **Dormant data**: Last row is 2024-02-09. For current data use `Dealing_dbo.Dealing_DailyZeroPnL_Stocks`.
- **NOP sign**: `NOP_Units` is signed (positive = long, negative = short); `NOP` in money is the absolute USD value.
- **StockIndex nulls**: NULL means the instrument is not in any mapped index (not a data error).
- **Regulation `None`**: 6,910 rows with `Regulation = 'None'`; these are edge-case customers without a regulation assignment.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | ETL-computed or transformed by SP |
| Tier 3 | Batch-system metadata; no upstream traceability |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date for the zero P&L snapshot. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 2 | HedgeServerID | int | YES | Hedge server identifier for the position set. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 3 | Industry | varchar(250) | YES | Industry classification of the instrument (from Dim_Instrument). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 4 | InstrumentType | varchar(50) | YES | Instrument type string (Stocks / ETF); only values 5=Stocks and 6=ETF are present. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 5 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 6 | InstrumentDisplayName | varchar(250) | YES | Display name of the instrument. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 7 | StockIndex | varchar(50) | YES | Index membership (e.g., S&P500, NASDAQ) from the static mapping table; NULL if not in any index. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 8 | IsManual | tinyint | YES | Flag indicating manual (non-automated) trading positions. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 9 | Leverage | int | YES | Position leverage tier. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 10 | IsCFD | tinyint | YES | 1 = CFD position, 0 = Real stocks position. Derived from HedgeServerID or IsSettled flag. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 11 | Regulation | varchar(50) | YES | Regulatory jurisdiction of the customer (e.g., CySEC, FCA, ASIC & GAML, FSA Seychelles, ASIC, FinCEN+FINRA, BVI, FSRA, None). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 12 | MifID | int | YES | MiFID categorization ID of the customer snapshot (observed: 0, 1, 2, 3, 4, 5). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 13 | RealizedCommission | money | YES | Aggregate commission charged on positions closed on the report date. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 14 | RealizedZero | money | YES | Realized eToro revenue for positions closed on @RepDate: SUM(NetProfit + CommissionOnClose − PrevDayPnL). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 15 | ChangeInUnrealizedZero | money | YES | Change in unrealized eToro revenue for still-open positions: SUM(DailyPnL + commission adjustment). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 16 | TotalZero | money | YES | RealizedZero + ChangeInUnrealizedZero for the group. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 17 | NOP | money | YES | Net Open Position in USD for open positions in the group. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 18 | OpenPositions | money | YES | Count of open positions in the group (as money type). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 19 | NOP_Units | numeric(38,6) | YES | Net open position in instrument units (signed: positive=long, negative=short). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 20 | VolumeOnOpen | bigint | YES | Cumulative open-action volume for positions opened on the report date. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 21 | VolumeOnClose | bigint | YES | Cumulative close-action volume for positions closed on the report date. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 22 | OpenPositionValue | money | YES | Aggregated USD value of open positions (units × price). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 23 | UpdateDate | datetime | YES | Batch execution timestamp (GETDATE()). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 24 | InstrumentName | varchar(100) | YES | Short instrument name/ticker symbol. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 25 | Units | decimal(16,6) | YES | Net units held across the group's open positions (OpenUnits + CloseUnits). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 26 | Currency | varchar(50) | YES | Trade currency of the instrument (SellCurrency). (Tier 2 — SP_DailyZeroPnL_Stocks) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Date | @RepDate parameter | — | Report date |
| HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | GROUP BY |
| Industry | DWH_dbo.Dim_Instrument | Industry | GROUP BY |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | GROUP BY |
| InstrumentID | DWH_dbo.Dim_Position | InstrumentID | GROUP BY |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Direct join |
| StockIndex | BI_DB_dbo.BI_DB_IndexesMapping_Static | IndexName | LEFT JOIN |
| IsManual | DWH_dbo.Dim_Position | MirrorID | CASE WHEN MirrorID=0 THEN 1 ELSE 0 |
| Leverage | DWH_dbo.Dim_Position | Leverage | GROUP BY |
| IsCFD | DWH_dbo.Dim_Position | IsSettled | CASE WHEN IsSettled=1 THEN 0 ELSE 1 |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via Fact_SnapshotCustomer.RegulationID |
| MifID | DWH_dbo.Fact_SnapshotCustomer | MifidCategorizationID | GROUP BY |
| RealizedCommission | DWH_dbo.Dim_Position | FullCommissionOnClose / FullCommissionByUnits | SUM(TotalCommission) |
| RealizedZero | BI_DB_dbo.BI_DB_PositionPnL + Dim_Position | NetProfit + CommissionOnClose − PrevDayPnL | SUM (eToro zero formula) |
| ChangeInUnrealizedZero | BI_DB_dbo.BI_DB_PositionPnL | DailyPnL | SUM unrealized |
| TotalZero | Computed | RealizedZero + ChangeInUnrealizedZero | SUM(CalculatedZero) |
| NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM directional |
| OpenPositions | BI_DB_dbo.BI_DB_PositionPnL | OpenPosition | SUM |
| NOP_Units | BI_DB_dbo.BI_DB_PositionPnL | Units (AmountInUnitsDecimal) | SUM signed |
| VolumeOnOpen | DWH_dbo.Dim_Position | Volume | SUM where OpenDateID=@RepDate |
| VolumeOnClose | DWH_dbo.Dim_Position | VolumeOnClose | SUM where CloseDateID=@RepDate |
| OpenPositionValue | BI_DB_dbo.BI_DB_PositionPnL | Amount + PositionPnL | SUM |
| UpdateDate | GETDATE() | — | Batch timestamp |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | Direct join |
| Units | #Units temp table | OpenUnits + CloseUnits | SUM |
| Currency | DWH_dbo.Dim_Instrument | SellCurrency | Direct join |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position ──────────────────────────────────────────────┐
DWH_dbo.Fact_SnapshotCustomer ─────────────────────────────────────┤
DWH_dbo.Dim_Instrument ────────────────────────────────────────────┤
DWH_dbo.Dim_Regulation ────────────────────────────────────────────┤──► SP_DailyZeroPnL_Stocks (@dd)
BI_DB_dbo.BI_DB_PositionPnL ───────────────────────────────────────┤     (DELETE+INSERT by Date)
BI_DB_dbo.BI_DB_IndexesMapping_Static ─────────────────────────────┘
                                                                         ↓
                                               Dealing_dbo.Dealing_DailyZeroPnL_Stocks (~275M rows, live)
                                                                         ↓ (one-time migration 2024-09)
                                               BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks (197.6M rows, dormant 2024-02-09)
                                                                         ↓ Generic Pipeline (Append, daily 1440 min)
                                               bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzeropnl_stocks
```

SP_DailyZeroPnL_Stocks loads Dealing_dbo daily; BI_DB schema holds a historical migration snapshot frozen at 2024-02-09.

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument master dimension |
| HedgeServerID | DWH_dbo.Dim_Position | Position hedge server |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name lookup |
| MifID | DWH_dbo.Fact_SnapshotCustomer | MiFID categorization |
| StockIndex | BI_DB_dbo.BI_DB_IndexesMapping_Static | Index membership |

### 6.2 Referenced By

| Downstream | Schema | Notes |
|------------|--------|-------|
| Dealing_Apex_PnL | Dealing_dbo | References Dealing version (live); BI_DB version not known to be consumed |
| Dealing_CFDs_Stocks_Credit_Risk | Dealing_dbo | References Dealing version |

---

## 7. Sample Queries

### Daily total Zero P&L by regulation for a given date

```sql
SELECT
    Regulation,
    SUM(RealizedZero)          AS RealizedZero,
    SUM(ChangeInUnrealizedZero) AS UnrealizedZero,
    SUM(TotalZero)              AS TotalZero
FROM [BI_DB_dbo].[BI_DB_DailyZeroPnL_Stocks]
WHERE Date = '2024-01-31'
GROUP BY Regulation
ORDER BY TotalZero DESC;
```

### Top 10 instruments by NOP on a given date, split by CFD flag

```sql
SELECT TOP 10
    InstrumentDisplayName,
    InstrumentType,
    IsCFD,
    SUM(NOP)       AS NOP_USD,
    SUM(NOP_Units) AS NOP_Units
FROM [BI_DB_dbo].[BI_DB_DailyZeroPnL_Stocks]
WHERE Date = '2024-01-31'
GROUP BY InstrumentDisplayName, InstrumentType, IsCFD
ORDER BY SUM(NOP) DESC;
```

---

## 8. Atlassian Knowledge Sources

- No Jira tickets or Confluence pages found directly referencing `BI_DB_DailyZeroPnL_Stocks`.
- Related Confluence context: "Zero Commission Stocks / Commission-Free Stocks" (CS space) explains the zero-commission model that underlies the Zero P&L concept.
- Business logic for the Zero formula documented in `Dealing_dbo.Dealing_DailyZeroPnL_Stocks.md` (Section 2).

---

*Generated: 2026-04-28 | Quality: 7.5/10 | Phases: 11/14*
*Tiers: 0 T1, 26 T2, 0 T3, 0 T4 | Elements: 26/26, Logic: 8/10*
*Object: BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks | Type: Table | Production Source: SP_DailyZeroPnL_Stocks (via Dealing_dbo migration) — dormant since 2024-02-09*
