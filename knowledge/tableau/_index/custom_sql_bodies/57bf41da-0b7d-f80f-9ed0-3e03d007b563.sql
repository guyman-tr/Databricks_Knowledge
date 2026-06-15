SELECT eboccsau.AccountManagerID
      ,mp.AccountManager
		, cast(mp.ActiveDate as DATE)  ActiveDate
		,mp.cid
		,mp.TotalDeposits Deposits
		,mp.TotalCashouts Cashouts
		,mp.Revenue_Total Revenue
FROM main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata mp
JOIN bi_output.BI_OUTPUT_Customer_Customer_Support_Agent_User eboccsau
ON mp.AccountManager = CONCAT(eboccsau.FirstName, ' ', eboccsau.LastName) 
AND eboccsau.Position IN ('Sales','RM','Account Manager','Team leader','Senior Account Manager')
AND eboccsau.ToDate = '9999-12-31T00:00:00.000Z'
and eboccsau.IsActive = 'true'
WHERE mp.ActiveDate>='2024-08-01'