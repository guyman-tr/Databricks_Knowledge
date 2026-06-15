select 
o.Account
,o.Earnings  
,o.Currency
,o.Lender_Earnings as BrokerEarnings 
,o.Platform_Broker_Earnings as eToroEarnings 
,o.Client_Net_Earnings as UsersEarnings 
,o.Start_Date
,o.End_Date
,o.etr_ymd
,dc.GCID
,dc.RealCID
,fsc.IsCreditReportValidCB
,fsc.IsValidCustomer
,fsc.RegulationID
,dr.Name Regulation
,fsc.CountryID
,c.Name Country
,fsc.PlayerLevelID
,g.Name Club
,fsc.MifidCategorizationID
,mc.Name MifidCategorization
,ac.Name AccountType
from   main.general.gold_equilendspire_etoro_spire_earningsbyaccountdaily o
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
ON o.Account = dc.EquiLendID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
ON dc.RealCID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
         ON fsc.DateRangeID = dr.DateRangeID 
         AND CAST(DATE_FORMAT(o.etr_ymd, 'yyyyMMdd') AS INT)
         BETWEEN dr.FromDateID AND dr.ToDateID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr 
ON fsc.RegulationID = dr.DWHRegulationID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c 
ON  c.CountryID = fsc.CountryID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel g 
ON fsc.PlayerLevelID = g.PlayerLevelID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization mc 
ON fsc.MifidCategorizationID = mc.MifidCategorizationID
left JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ac
ON fsc.AccountTypeID = ac.AccountTypeID
where  1=1
AND o.ACCOUNT<>'T'
and  (o.etr_ymd >=<[Parameters].[Parameter 2]> and o.etr_ymd <= <[Parameters].[Parameter 3]>)