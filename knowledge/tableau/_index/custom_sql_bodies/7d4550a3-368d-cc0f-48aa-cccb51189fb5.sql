SELECT da.RealCID 
      , da.GCID
      , dpl.Name AS Club
      , dc.Name  AS Country
      , CONCAT(agent.FirstName, ' ', agent.LastName) AS Name 
      , IFNULL(card.InstanceStatus, 'No Card') AS CardStatus
      , IFNULL(tc.InstrumentID,'No Choice Instrument') AS InstrumentID_Choice
      , IFNULL(tc.Date,'1999-31-01') AS submitted
      , IFNULL(tc.InstrumentDisplayName,'No Choise') AS Stock_Choise
      , IFNULL(tc_first.RegistrationDate,'1999-31-01') AS registration_date
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked da

LEFT JOIN bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account da1
       ON da.RealCID = da1.CID

LEFT JOIN (
        SELECT CID
             , ProviderHolderID
             , InstanceCreatedDate
             , ROW_NUMBER() OVER (PARTITION BY CID ORDER BY InstanceCreatedDate DESC) rn
             , InstanceStatus
             , StatusByHighestRNDasc
        FROM bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary
        WHERE IsValidETM = 1
          AND GCID_Unique_Count = 1
) card
       ON da.RealCID = card.CID
      AND card.rn = 1

LEFT JOIN bi_output.BI_OUTPUT_Customer_Customer_Support_Agent_User agent
       ON agent.AccountManagerID = da.AccountManagerID
      AND Position IN ('Senior Account Manager', 'RM', 'Account Manager', 'Team leader')

JOIN (
        SELECT a.GCID
             , di.InstrumentType
             , di.InstrumentDisplayName
             , di.InstrumentID
             , a.Action
             , TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') AS Date
             , ROW_NUMBER() OVER (
                    PARTITION BY a.GCID 
                    ORDER BY TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') DESC
               ) rn
        FROM main.sfmc.silver_sfmc_accountjourneylogtracking a
        JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
              ON di.InstrumentID = a.Message
        WHERE a.Journey_Name = '9037759373_CashBack_Log_BI'
          AND a.Action <> 'StockSelection'
) tc
       ON da.GCID = tc.GCID
      AND tc.rn = 1

LEFT JOIN (
        SELECT a.GCID
             , TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') AS RegistrationDate
             , ROW_NUMBER() OVER (
                    PARTITION BY a.GCID 
                    ORDER BY TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') ASC
               ) rn
        FROM main.sfmc.silver_sfmc_accountjourneylogtracking a
        WHERE a.Journey_Name = '9037759373_CashBack_Log_BI'
          AND a.Action <> 'StockSelection'
) tc_first
       ON da.GCID = tc_first.GCID
      AND tc_first.rn = 1

JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
     ON da.CountryID = dc.CountryID

JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
     ON da.PlayerLevelID = dpl.PlayerLevelID

WHERE da.IsValidCustomer = 1
  AND da.CountryID IN (74,218,19,119,135,57,72,95,143,154,196,165,191,54,
                       118,126,32,52,55,67,82,94,112,164,168,184,185,100,
                       13,79,117,197,102)
  AND da1.IsTestAccount = 0
  AND da1.GCID_Unique_Count = 1
  AND da1.IsValidETM = 1