SELECT
	Sum(fca.Amount) CashCompensationSL
 , last_day( fca.etr_ymd) ReportDate
 , fsc.VerificationLevelID
 , fsc.IsValidCustomer 
 , fsc.IsCreditReportValidCB 
--,fsc.RegulationID
,dr.Name Regulation
--,fsc.CountryID
,c.Name Country
--,fsc.PlayerLevelID
,g.Name Club
--,fsc.MifidCategorizationID
,mc.Name MifidCategorization
,ac.Name AccountType
 FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
	JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   fsc
		ON fca.RealCID = fsc.RealCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
         ON fsc.DateRangeID = dr.DateRangeID 
         AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
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

WHERE last_day( fca.etr_ymd) = <[Parameters].[Parameter 1]>
AND fca.ActionTypeID IN (36)
AND fca.CompensationReasonID = 119
group by all