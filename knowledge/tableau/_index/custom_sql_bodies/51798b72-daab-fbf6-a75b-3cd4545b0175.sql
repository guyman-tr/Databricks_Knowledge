SELECT dt.CID
      ,dt.GCID
      ,dt.CountryTxDate
      ,da.Country
      ,dl.Name AS Language
      ,att.Name AS Account_Type
      ,dc.Email
      ,da.Club
      ,dt.HolderCurrencyDesc AS CardCurrency
      ,CASE WHEN dc.GuruStatusID > 1 THEN 'PI' ELSE 'Not PI' END AS PI
      ,TRUNC(dt.TxStatusModificationDate, 'MM') AS Transaction_Date
      ,IFNULL(tc.InstrumentID,'No Choice Instrument') AS InstrumentID_Choice
      ,IFNULL(tc.InstrumentDisplayName,'No Choise') AS Stock_Choise
      ,IFNULL(DATE(tc.Action),'1999-31-01') AS submitted
      ,IFNULL(tc_first.RegistrationDate,'1999-31-01') AS registration_date
      ,da.ProviderHolderID
, da.Club 

      ,SUM(CASE 
              WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                  6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                  8999,7994,7995,9754)
               AND dt.TxTypeID <> 4
              THEN (dt.HolderAmount) * -1 
           END) AS Part_OF_CashBack_Local

      ,SUM(CASE 
              WHEN st.Mcc IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                              6051,6010,6012,6211,6540,7299,7800,7801,7802,
                              8999,7994,7995,9754)
              THEN (dt.HolderAmount) * -1 
           END) AS Not_Part_OF_CashBack_Local

      ,SUM((dt.HolderAmount) * -1) AS Total_Use_Local

      ,SUM(CASE 
              WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                  6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                  8999,7994,7995,9754)
               AND dt.TxTypeID <> 4
              THEN ((dt.HolderAmount) * -1) * 0.04
           END) AS CashBack_Amount_4_Local

      ,SUM(CASE 
              WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                  6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                  8999,7994,7995,9754)
               AND dt.TxTypeID <> 4
              THEN ((dt.HolderAmount) * -1) * 0.0405
           END) AS CashBack_Amount_405_Local

      ,SUM(CASE WHEN dt.TxTypeID = 4 THEN (dt.HolderAmount) * -1 END) AS ATM_withdrawls_Local

      ,SUM(CASE 
              WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                  6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                  8999,7994,7995,9754)
               AND dt.TxTypeID <> 4
              THEN (dt.USDAmountApprox) * -1
           END) AS Part_OF_CashBack_USD

      ,SUM(CASE 
              WHEN st.Mcc IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                              6051,6010,6012,6211,6540,7299,7800,7801,7802,
                              8999,7994,7995,9754)
              THEN (dt.USDAmountApprox) * -1
           END) AS Not_Part_OF_CashBack_USD

      ,SUM((dt.USDAmountApprox) * -1) AS Total_Use_USD

      ,SUM(CASE 
              WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                  6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                  8999,7994,7995,9754)
               AND dt.TxTypeID <> 4
              THEN ((dt.USDAmountApprox) * -1) * 0.04
           END) AS CashBack_Amount_4_USD

      ,SUM(CASE 
              WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                  6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                  8999,7994,7995,9754)
               AND dt.TxTypeID <> 4
              THEN ((dt.USDAmountApprox) * -1) * 0.0405
           END) AS CashBack_Amount_405_USD

      ,SUM(CASE WHEN dt.TxTypeID = 4 THEN (dt.USDAmountApprox) * -1 END) AS ATM_withdrawls_USD
, 

CASE 
    WHEN da.Club IN ('Bronze','Silver','Gold','Platinum') THEN
        LEAST(
            SUM(CASE 
                  WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                      6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                      8999,7994,7995,9754)
                   AND dt.TxTypeID <> 4
                  THEN ((dt.HolderAmount) * -1) * 0.04
                END),
            100
        )

    WHEN da.Club IN ('Platinum Plus','Diamond') THEN
        LEAST(
            SUM(CASE 
                  WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                      6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                      8999,7994,7995,9754)
                   AND dt.TxTypeID <> 4
                  THEN ((dt.HolderAmount) * -1) * 0.04
                END),
            200
        )

    ELSE
        SUM(CASE 
              WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                  6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                  8999,7994,7995,9754)
               AND dt.TxTypeID <> 4
              THEN ((dt.HolderAmount) * -1) * 0.04
            END)
 END AS CashBack_Amount_4_Local_max_limit_applied , 


CASE 
    WHEN da.Club IN ('Bronze','Silver','Gold','Platinum') THEN
        LEAST(
            SUM(CASE 
                  WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                      6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                      8999,7994,7995,9754)
                   AND dt.TxTypeID <> 4
                  THEN ((dt.USDAmountApprox) * -1) * 0.0405
                END),
           100 * MAX_BY(dt.USDRateApprox, dt.TxStatusModificationDate)

        )

    WHEN da.Club IN ('Platinum Plus','Diamond') THEN
        LEAST(
            SUM(CASE 
                  WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                      6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                      8999,7994,7995,9754)
                   AND dt.TxTypeID <> 4
                  THEN ((dt.USDAmountApprox) * -1) * 0.0405
                END),
            200 * MAX_BY(dt.USDRateApprox, dt.TxStatusModificationDate)

        )

    ELSE
        SUM(CASE 
              WHEN st.Mcc NOT IN (4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,
                                  6051,6010,6012,6211,6540,7299,7800,7801,7802,
                                  8999,7994,7995,9754)
               AND dt.TxTypeID <> 4
              THEN ((dt.USDAmountApprox) * -1) * 0.0405
            END)
END AS CashBack_Amount_405_USD_max_limit_applied




FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction dt

JOIN SettlementsTransactions st
  ON dt.ProviderTransactionID = st.TransactionId
 AND dt.ProviderCurrencyBalanceID = st.AccountId

JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account da
  ON dt.CID = da.CID

LEFT JOIN (
        SELECT a.GCID
             , di.InstrumentType
             , di.InstrumentDisplayName
             , di.InstrumentID
             , TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') AS Action
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
  ON dt.GCID = tc.GCID
 AND tc.rn = 1

LEFT JOIN (
        SELECT a.GCID
             , DATE(TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a')) AS RegistrationDate
             , ROW_NUMBER() OVER (
                    PARTITION BY a.GCID
                    ORDER BY TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') ASC
               ) rn
        FROM main.sfmc.silver_sfmc_accountjourneylogtracking a
        WHERE a.Journey_Name = '9037759373_CashBack_Log_BI'
          AND a.Action <> 'StockSelection'
) tc_first
  ON dt.GCID = tc_first.GCID
 AND tc_first.rn = 1

JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  ON dt.CID = dc.RealCID

JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype att
  ON att.AccountTypeID = dc.AccountTypeID

JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dl
  ON dl.LanguageID = dc.LanguageID

WHERE dt.IsTxSettled = 1
  AND da.IsValidCustomer = 1
  AND da.IsTestAccount = 0
  AND da.IsValidETM = 1
  AND da.GCID_Unique_Count = 1
  AND dt.TxTypeID IN (1,2,3,4)
  AND dt.TxStatusID IN (1,2)
  AND da.AccountSubProgramID IN (2,1,4,6,7,9,11,12)
  AND dt.TxStatusModificationDate >= '2025-03-01'

GROUP BY dt.CID
        ,dt.GCID
        ,dt.CountryTxDate
        ,da.Country
        ,dl.Name
        ,att.Name
        ,dc.Email
        ,da.Club
        ,dt.HolderCurrencyDesc
        ,CASE WHEN dc.GuruStatusID > 1 THEN 'PI' ELSE 'Not PI' END
        ,TRUNC(dt.TxStatusModificationDate, 'MM')
        ,IFNULL(tc.InstrumentID,'No Choice Instrument')
        ,IFNULL(tc.InstrumentDisplayName,'No Choise')
        ,IFNULL(DATE(tc.Action),'1999-31-01')
        ,IFNULL(tc_first.RegistrationDate,'1999-31-01')
        ,da.ProviderHolderID