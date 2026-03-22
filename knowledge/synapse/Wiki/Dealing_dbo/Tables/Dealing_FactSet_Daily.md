# Dealing_dbo.Dealing_FactSet_Daily

## 1. Overview
Daily position-level portfolio snapshot sent to FactSet for People Investors (PIs) and Copy Portfolios (CPs). Contains one row per CID × InstrumentID reflecting each active PI/CP's holdings as of the report date. **STALE** — last data 2024-06-04.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (CID ASC) |
| **Row Count** | ~425.6K |
| **Date Range** | Historical → 2024-06-04 (STALE) |
| **Grain** | One row per CID × InstrumentID (position in PI/CP portfolio) |
| **Refresh** | None since 2024-06-04 — FactSet integration appears decommissioned |

## 2. Business Context
FactSet is a financial data platform that eToro used to expose PI and Copy Portfolio portfolios to institutional clients and data subscribers. Each day, this table was populated with a snapshot of every open position held by active PIs/CPs — essentially a data feed for external consumption. The table is controlled by `Dealing_FactSet_Management`, which tracks which PIs are active and whether their history/daily data has been sent. The SP uses TRUNCATE (not DELETE-INSERT) meaning the table always reflects the most recent snapshot only — no date-partitioned history. It also inserts special "Not a PI anymore" rows for PIs who deregistered the previous day, acting as a deactivation notification. The table has been stale since June 2024, likely because the FactSet integration was discontinued.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| Date | date | Yes | Report date | T2 | SP_FactSet_Daily: @Date parameter |
| CopyType | varchar(50) | Yes | 'PI' for People Investor or 'CP' for Copy Portfolio | T2 | DWH_dbo.Dim_GuruStatus lookup |
| Username | varchar(50) | Yes | PI/CP username | T2 | DWH_dbo.Fact_SnapshotCustomer |
| Tier | varchar(50) | Yes | PI/CP customer tier/level | T2 | DWH_dbo.Fact_SnapshotCustomer |
| LastNightRiskScore | int | Yes | Most recent risk score (1–10) | T2 | DWH_dbo.Fact_SnapshotCustomer |
| AUM | decimal(16,6) | Yes | Assets under management | T2 | BI_DB_dbo.BI_DB_CopyDailyData |
| CashBalance | decimal(16,6) | Yes | Cash balance in portfolio | T2 | DWH_dbo.V_Liabilities |
| InstrumentID | int | Yes | Instrument in open position | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| InstrumentName | varchar(100) | Yes | Instrument name | T2 | DWH_dbo.Dim_Instrument |
| InstrumentType | varchar(50) | Yes | Asset class | T2 | DWH_dbo.Dim_Instrument |
| ISIN | varchar(50) | Yes | International Securities Identification Number | T2 | DWH_dbo.Dim_Instrument |
| Units | decimal(16,6) | Yes | Units held in this position | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| Price | decimal(16,6) | Yes | EOD instrument price | T2 | DWH_dbo.Fact_CurrencyPriceWithSplit |
| Direction | varchar(20) | Yes | 'Buy' or 'Sell' | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| Leverage | int | Yes | Leverage multiplier | T2 | BI_DB_dbo.BI_DB_PositionPnL |
| UpdateDate | datetime | Yes | ETL metadata: row write timestamp | T2 | SP_FactSet_Daily: `GETDATE()` |
| CID | int | Yes | Customer ID (distribution key) | T2 | Dealing_FactSet_Management / Fact_SnapshotCustomer |
| Currency | varchar(20) | Yes | Instrument currency | T2 | DWH_dbo.Dim_Instrument |
| RETURN_D | float | Yes | Daily portfolio return percentage | T2 | BI_DB_dbo.DWH_GainDaily.Gain_d |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| Dealing_dbo.Dealing_FactSet_Management | Active PI/CP list | IsActive=1 AND DailyLastSentDate<@Date |
| DWH_dbo.Fact_SnapshotCustomer | Customer snapshot | CID, Date |
| BI_DB_dbo.BI_DB_CopyDailyData | AUM | CID, Date |
| BI_DB_dbo.BI_DB_PositionPnL | Portfolio positions | CID, Date |
| DWH_dbo.Fact_CurrencyPriceWithSplit | EOD prices | InstrumentID, Date |
| DWH_dbo.V_Liabilities | Cash balance | CID |
| BI_DB_dbo.DWH_GainDaily | Daily return | CID, Date |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_FactSet_Daily` |
| **Parameters** | `@Date DATE` |
| **Load Pattern** | TRUNCATE then INSERT (not DELETE-INSERT) — full snapshot replacement |
| **Population** | PIs/CPs in Dealing_FactSet_Management WHERE IsActive=1 AND DailyLastSentDate<@Date |
| **Special Rows** | "Not a PI anymore" rows for CIDs with GuruStatusID<2 on @Date−1 |
| **Key Logic** | 1) Read active PI/CP list from FactSet_Management. 2) Join Fact_SnapshotCustomer for profile. 3) Join BI_DB_PositionPnL for open positions. 4) Join Fact_CurrencyPriceWithSplit for prices. 5) TRUNCATE + INSERT full snapshot. 6) Insert deregistration notification rows. |

## 6. Data Lifecycle
- **Retention**: Table always contains a single-date snapshot (TRUNCATE pattern) — no historical data
- **Status**: STALE since 2024-06-04 — FactSet integration appears discontinued
- **Volume**: ~425.6K rows in final snapshot

## 7. Known Gaps
- STALE — data as of 2024-06-04 only
- TRUNCATE pattern means querying this table without knowing it's a single-date snapshot could be misleading
- "Not a PI anymore" rows have NULL position columns — consumers must handle gracefully

## 8. Quality Score
**6.5/10** — Well-documented portfolio snapshot for FactSet. Stale status limits usefulness. TRUNCATE pattern is an important operational characteristic.
