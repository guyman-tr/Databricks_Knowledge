# Column Lineage: Dealing_dbo.Dealing_DealingDashboard_Clients

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_DealingDashboard_Clients` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Sources** | `DWH_dbo.Dim_Position`, `BI_DB_dbo.BI_DB_PositionPnL` |
| **ETL SP** | `Dealing_dbo.SP_DealingDashboard_Clients` |
| **Secondary Sources** | `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_Country`, `DWH_dbo.Dim_MifidCategorization`, `DWH_dbo.Dim_Range`, `DWH_dbo.Dim_Date` |
| **Author** | Jenia Simonovitch (2021-10-06), Adar (TicketFees SR-263106), Sarah (IsFuture SR-303782) |
| **Generated** | 2026-03-21 |

## Key Column Sources

| DWH Column | Transform | Computation Formula |
|-----------|-----------|---------------------|
| Date / DateID | ETL-computed | `@Date` SP parameter |
| HedgeServerID | passthrough | Dim_Position.HedgeServerID |
| InstrumentType, InstrumentName, InstrumentDisplayName, Symbol, SellCurrency, Exchange | join-enriched | From DWH_dbo.Dim_Instrument |
| Regulation | join-enriched | Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID |
| Country, Region | join-enriched | Dim_Country via Fact_SnapshotCustomer.CountryID |
| Mifid | ETL-computed | `CASE WHEN MifidCategorizationID IN (1,4) THEN 'Retail' WHEN IN (2,3) THEN 'Professional' ELSE Dim_MifidCategorization.Name END` |
| IsCopy | ETL-computed | `CASE WHEN MirrorID>0 THEN 1 ELSE 0 END` from Dim_Position |
| IsCFD | ETL-computed | `CASE WHEN IsSettled=1 THEN 0 ELSE 1 END` from Dim_Position |
| VolumeOnOpen | ETL-computed | Volume when OpenDateID=@DateID, else 0 |
| VolumeOnClose | ETL-computed | VolumeOnClose when CloseDateID=@DateID, else 0 |
| VolumeBuy | ETL-computed | Volume for buy direction (open buy + close sell) on @DateID |
| VolumeSell | ETL-computed | Volume for sell direction (open sell + close buy) on @DateID |
| NOP, LongOpenPositions, ShortOpenPositions | ETL-computed | From BI_DB_PositionPnL.NOP; split by IsBuy |
| UnitsNOP, UnitsBuy, UnitsSell | ETL-computed | From AmountInUnitsDecimal with direction sign |
| NumberOfPositions | ETL-computed | 1 per position (0 for partial close children) |
| RealizedZero, ChangeInUnrealizedZero, TotalZero | ETL-computed | eToro revenue aggregation from NetProfit, DailyPnL |
| FullCommission, FullCommissionOnOpen, FullCommissionOnClose | ETL-computed | From Dim_Position.FullCommission (fallback to Commission) |
| VariableSpread | ETL-computed | `Units*(Ask-Bid)*USDConversion` — depends on open/close timing |
| OverNightFee, OverNightFee_Long, OverNightFee_Short | ETL-computed | From DWH_dbo.Fact_OverNightFee |
| Dividend | ETL-computed | From DWH_dbo.Fact_DividendTransaction |
| TicketFees | ETL-computed | From DWH_dbo.Fact_TicketFee |
| IsFuture | passthrough | From Dim_Instrument.IsFuture |
| UpdateDate | ETL-computed | `GETDATE()` |
