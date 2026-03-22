# Dealing_FactSet_NewPIs_History

**Schema**: Dealing_dbo
**Object Type**: Table
**Data Status**: ⚠️ STALE — single snapshot 2024-06-04; FactSet daily feed stopped June 2024
**Row Count**: ~4.7M (all on 2024-06-04)
**Distribution**: ROUND_ROBIN
**Index**: CLUSTERED INDEX (Date)

---

## Purpose

Daily portfolio snapshot for **new Popular Investor (PI) candidates** sent to the FactSet external data provider. For each active PI tracked in [Dealing_FactSet_Management](Dealing_FactSet_Management.md), this table stores the complete position-level portfolio view for the day — instrument holdings, AUM, risk score, and daily return — in the format required by FactSet for their financial data feed.

The table operates on a **TRUNCATE-and-replace** pattern: the entire table is wiped each run and replaced with one day's data. At time of staling, the last run was 2024-06-04, meaning all 4.7M rows are from that single date.

---

## Writer SP

**`Dealing_dbo.SP_FactSet_NewPIs_History`** (not in OpsDB Service Broker; triggered externally)
- Not in regular SB_Daily orchestration — likely triggered by an external scheduler or on-demand

---

## ETL Sources

| Source | Type | Purpose |
|--------|------|---------|
| `Gold/Dealing/FactSet_stg/FactSet_PositionPnL_stg/*.parquet` (via external table `Dealing_dbo.FactSet_PositionPnL_stg`) | Lake / External Table | Portfolio positions for eligible PIs — open positions with units, prices, leverage |
| `Dealing_dbo.Dealing_FactSet_Management` | Control table | Filter: IsActive=1 AND HistorySendFlag=1 to select PIs needing history sent |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | DWH Fact | EOD prices (AskSpreaded for Long, BidSpreaded for Short) and FX rates |
| `DWH_dbo.Dim_Instrument` | DWH Dimension | InstrumentDisplayName, InstrumentType, ISINCode, SellCurrency |
| `DWH_dbo.Dim_Customer` | DWH Dimension | CID → UserName |
| `DWH_dbo.Fact_SnapshotCustomer` | DWH Snapshot | GuruStatusID for PI tier lookup |
| `DWH_dbo.Dim_GuruStatus` | DWH Dimension | GuruStatusID → GuruStatusName (Tier) |
| `DWH_dbo.V_Liabilities` | DWH View | StandardDeviation → LastNightRiskScore, TotalCash/RealizedEquity → CashBalance |
| `BI_DB_dbo.BI_DB_Guru_Copiers` | BI_DB | AUM components: Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL |
| `BI_DB_dbo.DWH_GainDaily` | BI_DB | RETURN_D = daily gain percentage |

---

## Column Descriptions

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Snapshot date (the @Date parameter passed to the SP) |
| PortfolioDate | date | Position date from the lake parquet source (the date the position was active) |
| CopyType | varchar(50) | PI type from FactSet_Management — typically 'PI' |
| Username | varchar(50) | eToro username of the PI |
| Tier | varchar(50) | PI tier from DWH_dbo.Dim_GuruStatus (e.g., 'Champion', 'Elite') |
| LastNightRiskScore | int | Volatility risk tier 1–10 based on StandardDeviation from DWH_dbo.V_Liabilities. Breakpoints: <0.0011=1, <0.0024=2, <0.004=3, <0.0055=4, <0.0079=5, <0.0111=6, <0.0158=7, <0.0316=8, <0.0475=9, ≥0.0475=10 |
| AUM | decimal(16,6) | Assets under management in USD: SUM(Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL) from BI_DB_Guru_Copiers for the prior day |
| CashBalance | decimal(16,6) | Cash as a fraction of realized equity: TotalCash / RealizedEquity from V_Liabilities |
| InstrumentID | int | FK to DWH_dbo.Dim_Instrument |
| InstrumentName | varchar(100) | Instrument display name from Dim_Instrument |
| InstrumentType | varchar(50) | Instrument type category (e.g., 'Stocks', 'ETF', 'Crypto Currencies') |
| ISIN | varchar(50) | International Securities Identification Number from Dim_Instrument |
| Units | decimal(16,6) | Net position size in units (AmountInUnitsDecimal from lake parquet) |
| Price | decimal(16,6) | EOD price: AskSpreaded for Long, BidSpreaded for Short (from Fact_CurrencyPriceWithSplit) |
| Direction | varchar(20) | 'Long' (IsBuy=1) or 'Short' (IsBuy=0) |
| Leverage | int | Position leverage multiplier |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline |
| CID | int | Customer ID of the PI |
| Currency | varchar(20) | Instrument's sell currency (SellCurrency from Dim_Instrument) |
| RETURN_D | float | Daily return percentage from BI_DB_dbo.DWH_GainDaily; ISNULL mapped to 0.0 when not available |

---

## Key Business Logic

- **TRUNCATE pattern**: `TRUNCATE TABLE Dealing_FactSet_NewPIs_History` runs every execution — the entire table is wiped and replaced with a single day's snapshot. This is not a typical daily append; it's a point-in-time replacement.
- **PI eligibility gate**: Only PIs with `IsActive=1 AND HistorySendFlag=1` in Dealing_FactSet_Management are included. `HistorySendFlag=1` means their history hasn't been sent to FactSet yet (first-time sends). Regular daily sends use a different mechanism.
- **LastNightRiskScore**: 10-tier volatility score based on daily portfolio standard deviation from the previous night's V_Liabilities snapshot. Lower score = lower risk.
- **DSR-4798 (2023-08-08)**: Added RETURN_D column (daily portfolio return).
- **Feed stopped**: FactSet_Management shows DailyLastSentDate=2024-06-04 and UpdateDate=2024-06-05 for all active PIs — the FactSet feed appears to have been discontinued in June 2024.

---

## Data Patterns

```sql
-- Single snapshot date (all rows on same date)
SELECT DISTINCT Date FROM Dealing_dbo.Dealing_FactSet_NewPIs_History
-- Returns: 2024-06-04 only

-- Row distribution
SELECT COUNT(*) FROM Dealing_dbo.Dealing_FactSet_NewPIs_History
-- ~4,775,144 rows
```

---

## Relationships

- **Depends on**: [Dealing_FactSet_Management](Dealing_FactSet_Management.md) (control/eligibility table)
- **Related**: [Dealing_FactSet_Daily](Dealing_FactSet_Daily.md) (daily portfolio feed, same FactSet program)
- **Upstream dimension**: DWH_dbo.Dim_Instrument, DWH_dbo.Dim_Customer, DWH_dbo.V_Liabilities
