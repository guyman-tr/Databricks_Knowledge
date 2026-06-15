SELECT Distinct bdcdpfd.AccountManager
		,bdcdpfd.CID
		,bdcdpfd.ActiveDate DepositDate
		,bdcdpfd.TotalDeposits ContactedDeposit
		,bdcdpfd.EOD_Club
		,CAST(date_trunc('month',bdcdpfd.ActiveDate) AS DATE) AS BeginOfMonth
FROM  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata bdcdpfd
JOIN bi_output.bi_output_customer_customer_facing_agent_engagement bduts
ON bdcdpfd.CID = bduts.CID
AND bduts.ActionType in ('CompletedPhone','InboundEmail','ZoomCall','Whatsapp')
AND bduts.etr_ymd>=DATEADD(day,-30,bdcdpfd.ActiveDate)
AND bduts.etr_ymd<=bdcdpfd.ActiveDate
WHERE bdcdpfd.DateID>=20240801
AND bdcdpfd.TotalDeposits>0