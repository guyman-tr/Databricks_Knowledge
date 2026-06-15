SELECT da.RealCID 
      , da.GCID
      , dpl.Name Club
      , dc.Name Country
      , CONCAT(agent.FirstName, ' ', agent.LastName) Name 
     -- ,ifnull(card.InstanceStatus, 'No Card') CardStatus
      ,ifnull(tc.InstrumentID,'No Choice Instrument') InstrumentID_Choice
      ,ifnull(tc.Date,'1999-31-01') submitted
	  ,ifnull(tcreg.Date,'1999-31-01') registrated
      ,ifnull(tc.InstrumentDisplayName,'No Choise') Stock_Choise
from  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked da
join bi_output.BI_OUTPUT_Customer_Customer_Support_Agent_User agent
on agent.AccountManagerID=da.AccountManagerID
 join (
            select a.GCID
                  , di.InstrumentType
                  , di.InstrumentDisplayName
                  , di.InstrumentID
                  , a.Action
                   ,TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') Date
                  , row_number() over(partition by a.GCID order by TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') DESC) rn
            from main.sfmc.silver_sfmc_accountjourneylogtracking a
            join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
            on di.InstrumentID=a.Message
            where a.Journey_Name = '10027452589_1PerCashBack_Log_BI'
            and a.Action<>'StockSelection'
            and TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a')<'2025-12-08'
            ) tc

on da.GCID=tc.GCID
and tc.rn=1
LEFT JOIN  (
            select a.GCID
                  , di.InstrumentType
                  , di.InstrumentDisplayName
                  , di.InstrumentID
                  , a.Action
                   ,TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') Date
                  , row_number() over(partition by a.GCID order by TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') ASC) rn
            from main.sfmc.silver_sfmc_accountjourneylogtracking a
            join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
            on di.InstrumentID=a.Message
            where a.Journey_Name = '10027452589_1PerCashBack_Log_BI'
            and a.Action<>'StockSelection'
            and TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a')<'2025-12-08'
            ) tcreg
on da.GCID=tcreg.GCID
and tcreg.rn=1
join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
on da.CountryID=dc.CountryID
join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
on da.PlayerLevelID=dpl.PlayerLevelID
where da.IsValidCustomer=1
and da.CountryID in (12,74,218,19,119,135,57,72,95,143,154,196,165,191,54,118,126,32,52,55,67,82,94,112,164,168,184,185,100,13,79,117,197,102,217)