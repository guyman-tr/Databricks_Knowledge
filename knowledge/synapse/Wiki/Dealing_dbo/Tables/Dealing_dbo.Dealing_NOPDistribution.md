# Dealing_dbo.Dealing_NOPDistribution

## 1. Overview
Daily NOP distribution showing how much exposure each Popular Investor (PI) or CopyPortfolio (CopyFund) parent has per instrument, aggregated across all their copiers' positions. Provides a view of copy trading concentration risk.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (DateID ASC) |
| **Row Count** | ~382M |
| **Date Range** | 2022-01-01 → present |
| **Grain** | One row per DateID × InstrumentID × ParentCID |
| **Refresh** | Daily, via SP_NOPDistribution |

## 2. Business Context
When clients copy a Popular Investor, their positions mirror the PI's trades. This table aggregates the NOP of all copier positions under each PI/CopyFund parent, showing how much total exposure flows through each PI per instrument. The `PI/CP` column distinguishes between regular Popular Investors and CopyPortfolios (AccountTypeID=9). The `GuruStatusName` column tracks the PI's current tier (e.g., Cadet, Champion, Elite).

**Author**: Graham Ellinson (created 2021-11-21). SR-224145 (2023-12-28) by Adar: removed MirrorID column, reducing rows from ~14M to ~200K per day.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| Date | date | Yes | Business date | T2 | SP_NOPDistribution: `@Date` parameter |
| DateID | int | Yes | Business date as YYYYMMDD integer | T2 | SP_NOPDistribution: `DateToDateID(@Date)` |
| InstrumentID | int | Yes | eToro instrument identifier | T2 | SP_NOPDistribution: from BI_DB_PositionPnL |
| InstrumentType | varchar(max) | Yes | Asset class name | T2 | SP_NOPDistribution: `di.InstrumentType` |
| NOP | money | Yes | Net open position in USD for this PI/CP + instrument combination. Formula: `SUM((2*IsBuy-1)*NOP)` — signed, aggregated across all copier positions | T2 | SP_NOPDistribution |
| ParentUserName | varchar(max) | Yes | PI or CopyPortfolio parent username | T2 | SP_NOPDistribution: `dm.ParentUserName` from Dim_Mirror |
| ParentCID | int | Yes | PI or CopyPortfolio parent customer ID | T2 | SP_NOPDistribution: `dm.ParentCID` from Dim_Mirror |
| PI/CP | varchar(20) | Yes | Distinguishes Popular Investor vs CopyPortfolio. Values: 'PI' (regular) or 'CopyFund' (AccountTypeID=9) | T2 | SP_NOPDistribution: `CASE WHEN dc.AccountTypeID=9 THEN 'CopyFund' ELSE 'PI' END` |
| SymbolFull | varchar(max) | Yes | Full instrument symbol (e.g., "AAPL.NQ") | T2 | SP_NOPDistribution: `di.SymbolFull` |
| UpdateDate | datetime | Yes | Row write timestamp | T2 | SP_NOPDistribution: `GETDATE()` |
| GuruStatusName | varchar(max) | Yes | PI tier/status (e.g., Cadet, Rising Star, Champion, Elite, Elite Pro). From Dim_GuruStatus joined via Fact_SnapshotCustomer | T2 | SP_NOPDistribution: `dgs.GuruStatusName` |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| BI_DB_dbo.BI_DB_PositionPnL | Copier positions | CID, DateID, InstrumentID, MirrorID |
| DWH_dbo.Dim_Mirror | Copy relationship → parent | MirrorID → ParentCID, ParentUserName |
| DWH_dbo.Dim_Instrument | Instrument metadata | InstrumentID |
| DWH_dbo.Fact_SnapshotCustomer | Customer validation + AccountTypeID | ParentCID=RealCID, DateRangeID |
| DWH_dbo.Dim_GuruStatus | PI tier lookup | GuruStatusID |
| DWH_dbo.Dim_Range | Date range filter | DateRangeID |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_NOPDistribution` |
| **Parameters** | `@Date DATE` |
| **Load Pattern** | DELETE + INSERT for @DateINT |
| **Key Logic** | 1) Pull all copier positions from BI_DB_PositionPnL for @DateID. 2) Join to Dim_Mirror to get ParentCID/ParentUserName. 3) Include non-valid customers if AccountTypeID=9 (CopyFund). 4) GROUP BY InstrumentID, ParentCID with `SUM((2*IsBuy-1)*NOP)`. 5) Join to Fact_SnapshotCustomer → Dim_GuruStatus for PI tier. |

## 6. Data Lifecycle
- **Volume**: Very high (~200K rows/day × 1400+ days = 382M)
- **Retention**: No automated cleanup

## 7. Known Gaps
- The join to Fact_SnapshotCustomer uses Dim_Range for SCD2 date filtering
- CopyFund accounts (AccountTypeID=9) bypass IsValidCustomer=1 filter intentionally

## 8. Quality Score
**7.5/10** — Clear copy-trading NOP aggregation logic. NOP sign convention `(2*IsBuy-1)` consistently applied. Large table with well-understood grain.
