# Lineage: Dealing_dbo.Dealing_HedgeCost

## Source Objects

| Source Object | Source Type | Schema | How Used |
|--------------|------------|--------|----------|
| CopyFromLake.etoro_Hedge_ExecutionLog | Table (Lake copy) | CopyFromLake | LP execution data: units, rates, volume for liquidity provider fills |
| DWH_dbo.Dim_Instrument | Table | DWH_dbo | Instrument metadata: Name, SellCurrencyID, InstrumentTypeID filter (5,6) |
| DWH_dbo.Dim_Position | Table | DWH_dbo | Client position data: units, rates, volume, commissions for opens/closes |
| DWH_dbo.Dim_Customer | Table | DWH_dbo | Customer validity filter (IsValidCustomer=1) |
| DWH_dbo.Dim_PositionChangeLog | Table | DWH_dbo | IsSettled correction: retrieves PreviousIsSettled for positions changed after report date |
| Dealing_dbo.Dealing_DailyZeroPnL_Stocks | Table | Dealing_dbo | RealizedCommission aggregation by date, instrument, hedge server, CFD flag |
| BI_DB_dbo.BI_DB_VarCommission | Table | BI_DB_dbo | Variable spread (VarCommission) by date, instrument, IsSettled, hedge server |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Table | DWH_dbo | AskSpreaded price for HC (hedge cost) calculation |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| Date | SP parameter | @Date | Passthrough from SP parameter | Tier 2 |
| InstrumentID | DWH_dbo.Dim_Position / CopyFromLake.etoro_Hedge_ExecutionLog | InstrumentID | Passthrough (grouping key from #Clients and #LP) | Tier 2 |
| Name | DWH_dbo.Dim_Instrument | Name | Passthrough via final JOIN | Tier 1 |
| IsSettled | DWH_dbo.Dim_PositionChangeLog + DWH_dbo.Dim_Position | PreviousIsSettled / IsSettled | ETL-computed: CASE WHEN IsSettled=1 THEN 'Real' ELSE 'CFD'. Uses PositionChangeLog to get IsSettled state at report date (before later changes) | Tier 2 |
| Clients_Units | DWH_dbo.Dim_Position | AmountInUnitsDecimal, IsBuy | ETL-computed: SUM((IsBuy*2-1)*AmountInUnitsDecimal) -- net signed units across client positions | Tier 2 |
| AvgRateClientsNoSpread | DWH_dbo.Dim_Position | AmountInUnitsDecimal, InitForexRate/EndForexRate, FullCommissionByUnits/FullCommissionOnClose | ETL-computed: (NetUnits*AvgRate - FullCommission) / NULLIF(NetUnits, 0) -- commission-adjusted average rate | Tier 2 |
| VolumeMarket | DWH_dbo.Dim_Position | Volume | ETL-computed: SUM(Volume) from client positions | Tier 2 |
| LP_Executed_Units | CopyFromLake.etoro_Hedge_ExecutionLog | Units, IsBuy | ETL-computed: ISNULL(SUM(Units*(IsBuy*2-1)), 0) -- net signed LP execution units | Tier 2 |
| LP_Avg_Rate | CopyFromLake.etoro_Hedge_ExecutionLog | Units, IsBuy, ExecutionRate | ETL-computed: ISNULL(SUM(Units*(IsBuy*2-1)*ExecutionRate) / NULLIF(SUM(Units*(IsBuy*2-1)),0), 0) | Tier 2 |
| LP_Volume | CopyFromLake.etoro_Hedge_ExecutionLog | Units, ExecutionRate | ETL-computed: ISNULL(SUM(Units*ExecutionRate), 0) | Tier 2 |
| HC | DWH_dbo.Fact_CurrencyPriceWithSplit + #Final | AskSpreaded, NetUnits, AvgRate, FullCommission, LP_Executed_Units, LP_Avg_Rate | ETL-computed: (AskSpreaded*NetUnits - (NetUnits*AvgRate - FullCommission)) - (AskSpreaded*LP_Executed_Units - (LP_Executed_Units*LP_Avg_Rate)) | Tier 2 |
| UpdateDate | SP runtime | GETDATE() | ETL timestamp | Tier 3 |
| HedgeServerID | DWH_dbo.Dim_Position / CopyFromLake.etoro_Hedge_ExecutionLog | HedgeServerID | Passthrough (grouping key) | Tier 2 |
| FullCommission | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | RealizedCommission | Passthrough: SUM(RealizedCommission) from DailyZeroPnL_Stocks | Tier 2 |
| VariableSpread | BI_DB_dbo.BI_DB_VarCommission | VarCommission | Passthrough from BI_DB_VarCommission | Tier 2 |
