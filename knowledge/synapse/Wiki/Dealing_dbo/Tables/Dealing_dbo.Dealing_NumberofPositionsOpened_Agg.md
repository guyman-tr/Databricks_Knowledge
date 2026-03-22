# Dealing_dbo.Dealing_NumberofPositionsOpened_Agg

## 1. Overview
Daily aggregate counting the number of positions opened, broken down by instrument type and geographic region. Serves as a high-level summary of trading activity for the Dealing Dashboard.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (DateID ASC) |
| **Row Count** | ~173K |
| **Date Range** | 2022-01-01 → present |
| **Grain** | One row per DateID × InstrumentType × Region |
| **Refresh** | Daily, via SP_DealingDashboard_Clients |

## 2. Business Context
This table provides a quick view of how many positions clients opened each day, sliced by asset class (Stocks, Indices, ETF, Commodities, Currencies, Crypto) and by geographic region (21 distinct regions). It is a downstream aggregation of the `Dealing_DealingDashboard_Clients` table.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| DateID | int | Yes | Business date in YYYYMMDD integer format | T2 | SP_DealingDashboard_Clients: `dddc.DateID` |
| Date | date | Yes | Calendar date corresponding to DateID | T2 | SP_DealingDashboard_Clients: `Date` |
| InstrumentType | char(50) | Yes | Asset class name (e.g., Stocks, ETF, Indices, Commodities, Currencies, Crypto) | T2 | SP_DealingDashboard_Clients: `dddc.InstrumentType` |
| Region | char(50) | Yes | Geographic region label (21 distinct values, e.g., "Western Europe", "South & Central America", "Africa") | T2 | SP_DealingDashboard_Clients: `dddc.Region` |
| NumberOfPositionsOpened | int | Yes | Total count of positions opened for this InstrumentType + Region combination on the given date. Formula: `SUM(dddc.NumberOfPositionsOpened)` | T2 | SP_DealingDashboard_Clients: aggregated from Dealing_DealingDashboard_Clients |
| UpdateDate | datetime | Yes | Timestamp when the row was written. Formula: `GETDATE()` | T2 | SP_DealingDashboard_Clients |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| Dealing_dbo.Dealing_DealingDashboard_Clients | Source (aggregation parent) | DateID, InstrumentType, Region |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_DealingDashboard_Clients` |
| **Load Pattern** | DELETE + INSERT for @DateID |
| **Logic** | `SELECT DateID, Date, InstrumentType, Region, SUM(NumberOfPositionsOpened), GETDATE() FROM Dealing_DealingDashboard_Clients WHERE DateID=@DateID GROUP BY DateID, Date, InstrumentType, Region` |

## 6. Data Lifecycle
- **Retention**: No automated cleanup observed
- **Partitioning**: None (ROUND_ROBIN)

## 7. Known Gaps
- Inherits all data quality characteristics from Dealing_DealingDashboard_Clients
- Region mapping is derived from DWH_dbo.Dim_Country in the upstream SP

## 8. Quality Score
**7.5/10** — Simple aggregation table with clear lineage. All columns directly traced to SP code. Limited business logic complexity.
