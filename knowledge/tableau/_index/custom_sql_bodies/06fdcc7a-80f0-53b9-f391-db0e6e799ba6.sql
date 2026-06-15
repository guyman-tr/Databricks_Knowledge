select 
hh.*, COALESCE(SUM(CASE WHEN fca1.ActionTypeID IN (7) THEN fca1.Amount END),0) as Deposit
,COALESCE(SUM(CASE WHEN fca1.ActionTypeID IN (8) THEN (-1*fca1.Amount) END),0) AS CashOut
FROM
(
			select vl.CID
				,dc.GCID
				,vl.Credit  Credit_20250301     
				, concat(dm.FirstName,' ', dm.LastName) AS Manager
			--	,a.Message
				,vl1.Credit  Current_Balance
        ,vl1.RealizedEquity  RealizedEquity_20250301
			--	,TO_DATE(TO_TIMESTAMP(a.Message, 'M/d/yyyy h:mm:ss a') ,'MM/dd/yyyy')   AS ActionDate
		--	,case when a.gcid is null then 0 else ROW_NUMBER() OVER (PARTITION BY a.GCID ORDER BY a.Message DESC)  end  rn 
		--	, case when hh.cid is null then 0 else 1 end as Investor_ind 
			,dpl.name Club
			,dc1.name Country
			,dc1.MarketingRegionManualName Region
      , aa.Team
				FROM    main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl
				INNER JOIN   main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked  dc
				ON dc.RealCID=vl.CID
				INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1
				ON dc1.CountryID=dc.CountryID
				LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm
				ON dc.AccountManagerID=dm.ManagerID
			--	full outer join  main.sfmc.silver_sfmc_accountjourneylogtracking a 
			--	on dc.GCID=a.GCID
				--and Journey_Name='6451190453_CG24Q4_TCsFormSubmissions'
		--		and  TO_DATE(TO_TIMESTAMP(a.Message, 'M/d/yyyy h:mm:ss a') ,'MM/dd/yyyy')<='2024-03-31'

			   join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
			ON dc.PlayerLevelID = dpl.PlayerLevelID
			join  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl1
			ON dc.RealCID=vl1.CID
			and vl1.dateid = DATE_FORMAT(current_date()-1,'yyyyMMdd')
      left join  bi_output.BI_OUTPUT_Customer_Customer_Support_Agent_User aa
      on dc.Accountmanagerid = aa.accountmanagerid
      and  ToDate = '9999-12-31T00:00:00.000Z'
			WHERE vl.DateID=20250301
			AND dc.IsValidCustomer=1
			AND dc.PlayerLevelID NOT IN (1)
			AND dc1.Name  NOT IN ('Afghanistan', 'Aland Islands', 'Albania', 'Anguilla', 'Bahamas', 'Barbados', 'Belarus', 'Bhutan', 'Bosnia and Herzegovina', 'Botswana',
		'Burundi', 'Cambodia', 'Canada', 'Cape Verde', 'Central African Republic', 'China', 'Congo', 'Congo Republic', 'Cook Islands', 
		'Cuba', 'East Timor', 'Equatorial Guinea', 'Ethiopia', 'Fiji', 'French Southern and Antarctic Territories', 'Gabon', 'Ghana', 'Grenada', 'Guam',
		'Guinea', 'Guinea-Bissau', 'Guyana, Haiti', 'Iran', 'Iraq', 'Israel', 'Jamaica', 'Japan', 'Kiribati', 'Laos', 'Lebanon', 'Liberia', 'Libya', 'Macedonia',
		'Mali', 'Marshall Islands', 'Martinique', 'Mauritania', 'Moldova', 'Montenegro', 'Montserrat', 'Myanmar', 'Namibia', 'Nauru','New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'Niue', 'North Korea', 'Northern Marianas', 'Pakistan', 'Palau', 'Panama', 'Papua New Guinea',
		'Saint Kitts and Nevis', 'Saint Pierre', 'Saint Vincent', 'Samoa', 'Sierra Leone', 'Solomon Islands', 'Somalia',  'Sri Lanka',
		'Sudan', 'Syria', 'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Uganda', 'United States of America', 'Vanuatu', 'Venezuela', 'Yemen',
		'Zimbabwe','Cote d''Ivoire')
) 
hh
left join  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca1 
on fca1.gcid=hh.gcid and fca1.ActionTypeID IN (7,8)
AND fca1.DateID>=20250301
AND fca1.DateID<=20250331

group by hh.CID
    ,hh.GCID
    ,hh.Credit_20250301    
    ,hh.RealizedEquity_20250301
    , hh.Manager
  --  ,hh.Message
    ,hh.Current_Balance
    --,hh.ActionDate
--,hh.rn 
--, hh.Investor_ind 
,hh.Club
,hh.Country
,hh.Region
,hh.team