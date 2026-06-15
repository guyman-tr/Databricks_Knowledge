SELECT DISTINCT fa.AccountNumber, g.GCID, g.RealCID, fa.TaxIDNumber, ps.Name as PlayerStatus, g.VerificationLevelID,
--fa.CodeDescription, fa.AccountType, 
fa.OpenDate, fa.AccountName1
FROM  main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation fa
--left join bronze_usabroker_apex_options op on op.OptionsApexID=fa.AccountNumber
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked g ON fa.AccountNumber = g.ApexID 
left join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps on ps.PlayerStatusID=g.PlayerStatusID
where --fa.OpenDate ='2024-05-20' and 
fa.RepCode='ETA'