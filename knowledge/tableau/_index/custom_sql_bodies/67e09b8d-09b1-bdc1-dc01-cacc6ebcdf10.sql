with pop (
	SELECT 
		AccountNumber, cast(ProcessDate as date) ProcessDate, 
		TotalEquity, 
		NetBalance as CashEquity
	FROM  main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
	where OfficeCode IN ('4GS','5GU')
		and AccountNumber not in ('4GS43999',
			'4GS00100',
			'4GS00101',
			'4GS00103',
			'4GS00104')
		and ProcessDate in (
							SELECT 
									CASE WHEN  IsWeekend='Y' THEN 
											CASE WHEN DayNumberOfWeek_Sun_Start=7 THEN DATEADD(DAY, -1, FullDate) --SAT
													WHEN DayNumberOfWeek_Sun_Start=1 THEN DATEADD(DAY, -2, FullDate) --SUN
													END
									ELSE FullDate
									END AS AdjEoMDate
							FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date 
							WHERE IsLastDayOfMonth='Y'
								and DateKey between 20250101 AND CAST(DATE_FORMAT(now(), 'yyyyMMdd') AS INT)
						)
	group by AccountNumber, ProcessDate, TotalEquity, NetBalance
)

, pop_info (
	SELECT pop.AccountNumber, am.RegisteredRepCode, g.GCID, r.Name as Regulation
	FROM pop 
	JOIN main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
		on am.AccountNumber=pop.AccountNumber
	JOIN main.general.bronze_usabroker_apex_options op 
		ON pop.AccountNumber=op.OptionsApexID
	join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked g 
		ON op.GCID = g.GCID
			and g.IsValidCustomer=1
			and g.RegulationID in (2, 7, 8, 12)
	join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r  
		on r.ID = g.RegulationID
	group by pop.AccountNumber, am.RegisteredRepCode, g.GCID, r.Name
		
)

SELECT 
	pop.ProcessDate, pop_info.Regulation, 
	sum(pop.TotalEquity) Apex_4gs_TotalEquity,
	sum(pop.CashEquity) Apex_4gs_CashEquity
FROM pop
join pop_info 
	on pop.AccountNumber=pop_info.AccountNumber
group by pop.ProcessDate, pop_info.Regulation
--order by pop.ProcessDate, pop_info.Regulation