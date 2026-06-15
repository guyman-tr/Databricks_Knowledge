select coalesce(a.CID, b.CID) as CID,
       coalesce(a.CountryID, b.CountryID) as CountryID,
       coalesce(a.Country_Name, b.Country_Name) as Country_Name,
       coalesce(a.Region, b.Region) as Region,
       coalesce(a.PlayerLevelID, b.PlayerLevelID) as PlayerLevelID,
       coalesce(a.Club, b.Club) as Club,
       coalesce(a.guruStatusID, b.guruStatusID) as guruStatusID,
       coalesce(a.GuruStatusName, b.GuruStatusName) as GuruStatusName,
       coalesce(a.Regulation, b.Regulation) as Regulation,
       coalesce(a.MifidCategorizationID, b.MifidCategorizationID) as MifidCategorizationID,
       coalesce(a.Number_Of_Positions, 0) as YTD_Positions,
       coalesce(a.Number_of_Instruments, 0) as YTD_Instruments,
       coalesce(a.Volume, 0) as YTD_Volume,
       coalesce(a.Net_Profit, 0) as YTD_Net_Profit,
       coalesce(a.LastClose, CAST('1970-01-01 00:00:00' AS TIMESTAMP)) as YTD_LastClose,
       coalesce(b.Number_Of_Positions, 0) as W_Positions,
       coalesce(b.Number_of_Instruments, 0) as W_Instruments,
       coalesce(b.Volume, 0) as W_Volume,
       coalesce(b.Net_Profit, 0) as W_Net_Profit,
       coalesce(b.LastClose, CAST('1970-01-01 00:00:00' AS TIMESTAMP)) as W_LastClose
from (
    select CID,
           CountryID,
           Country_Name,
           Region, 
           PlayerLevelID, 
           Club,
           guruStatusID,
           GuruStatusName, 
           Regulation,
           MifidCategorizationID,
           count(PositionID) as Number_Of_Positions,
           count(distinct InstrumentID) as Number_of_Instruments,
           SUM(VolumeOnClose) as Volume,
           SUM(NetProfit) as Net_Profit,
           MAX(CloseOccurred) as LastClose
    from (
        select a.PositionID,
               a.CID,
               dc.CountryID,
               dc1.Name AS Country_Name,
               dc1.Region, 
               dc.PlayerLevelID, 
               dpl.Name AS Club, 
               dgs.guruStatusID, 
               dgs.GuruStatusName, 
               dr.Name AS Regulation,
               dc.MifidCategorizationID,
               a.InstrumentID,
               di.InstrumentTypeID,
               di.InstrumentType,
               di.Symbol,
               a.HedgeServerID,
               a.Leverage,
               a.AmountInUnitsDecimal,
               (a.UnitMargin/a.InitForexRate) as ConversionRate,
               (a.AmountInUnitsDecimal*a.EndForexRate*(a.UnitMargin/a.InitForexRate)) as VolumeOnClose,
               a.EndForexRate,
               a.NetProfit,
               a.IsBuy,
               a.IsSettled,
               a.CloseOccurred,
               a.MirrorID,
               a.EndExecutionID,
               a.IsComputeForHedge
        from main.trading.bronze_etoro_history_position_datafactory a
        join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di on a.InstrumentID = di.InstrumentID
        LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID = a.CID
        LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1 on dc.CountryID = dc1.CountryID
        LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr on dc.RegulationID = dr.DWHRegulationID
        LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl on dc.PlayerLevelID = dpl.PlayerLevelID
        LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus dgs on dc.GuruStatusID = dgs.GuruStatusID
        where ActionType = 16 
          and IsComputeForHedge = 1 
          and YEAR(CloseOccurred) = year(now())
          and CloseOccurred <= now()
    ) as BSL1
    group by CID, CountryID, Country_Name, Region, PlayerLevelID, Club, guruStatusID, GuruStatusName, Regulation, MifidCategorizationID
    order by Number_Of_Positions DESC
) as a
full join (
    select CID,
           CountryID,
           Country_Name,
           Region, 
           PlayerLevelID, 
           Club,
           guruStatusID,
           GuruStatusName, 
           Regulation,
           MifidCategorizationID,
           count(PositionID) as Number_Of_Positions,
           count(distinct InstrumentID) as Number_of_Instruments,
           SUM(VolumeOnClose) as Volume,
           SUM(NetProfit) as Net_Profit,
           MAX(CloseOccurred) as LastClose
    from (
        select a.PositionID,
               a.CID,
               dc.CountryID,
               dc1.Name AS Country_Name,
               dc1.Region, 
               dc.PlayerLevelID, 
               dpl.Name AS Club, 
               dgs.guruStatusID, 
               dgs.GuruStatusName, 
               dr.Name AS Regulation,
               dc.MifidCategorizationID,
               a.InstrumentID,
               di.InstrumentTypeID,
               di.InstrumentType,
               di.Symbol,
               a.HedgeServerID,
               a.Leverage,
               a.AmountInUnitsDecimal,
               (a.UnitMargin/a.InitForexRate) as ConversionRate,
               (a.AmountInUnitsDecimal*a.EndForexRate*(a.UnitMargin/a.InitForexRate)) as VolumeOnClose,
               a.EndForexRate,
               a.NetProfit,
               a.IsBuy,
               a.IsSettled,
               a.CloseOccurred,
               a.MirrorID,
               a.EndExecutionID,
               a.IsComputeForHedge
        from main.trading.bronze_etoro_history_position_datafactory a
        join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di on a.InstrumentID = di.InstrumentID
        LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID = a.CID
        LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1 on dc.CountryID = dc1.CountryID
        LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr on dc.RegulationID = dr.DWHRegulationID
        LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl on dc.PlayerLevelID = dpl.PlayerLevelID
        LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus dgs on dc.GuruStatusID = dgs.GuruStatusID
        where ActionType = 16 
          and IsComputeForHedge = 1 
          and CloseOccurred >= now() - INTERVAL 7 DAYS
          and CloseOccurred <= now()
    ) as BSL2
    group by CID, CountryID, Country_Name, Region, PlayerLevelID, Club, guruStatusID, GuruStatusName, Regulation, MifidCategorizationID
    order by Number_Of_Positions DESC
) as b
on a.CID = b.CID