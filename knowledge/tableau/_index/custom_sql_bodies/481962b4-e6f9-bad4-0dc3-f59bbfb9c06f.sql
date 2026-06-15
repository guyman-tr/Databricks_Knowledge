SELECT dc.RealCID
	  ,dc.VerificationLevelID
	  ,bdfa.FirstAction
	  ,bdfa.FirstActionDate
	  ,bdfa.FirstInstrument
	  ,bdfa.UpdateDate
	  ,bdfa.LTV
	  ,bdfa.FirstLeverage
	  ,bdfa.FirstAction_Detailed
	  ,bdfa.Revenue1day
	  ,bdfa.Revenue7days
	  ,bdfa.Revenue14days
	  ,bdfa.Revenue30days
	  ,bdfa.Revenue60days
	  ,bdfa.Revenue90days
	  ,bdfa.Revenue180days
	  ,bdfa.Revenue360days
	  ,bdfa.Deposit1day
	  ,bdfa.Deposit7days
	  ,bdfa.Deposit14days
	  ,bdfa.Deposit30days
	  ,bdfa.Deposit60days
	  ,bdfa.Deposit90days
	  ,bdfa.Deposit180days
	  ,bdfa.Deposit360days
	  ,bdfa.Equity1day
	  ,bdfa.Equity7days
	  ,bdfa.Equity14days
	  ,bdfa.Equity30days
	  ,bdfa.Equity60days
	  ,bdfa.Equity90days
	  ,bdfa.Equity180days
	  ,bdfa.Equity360days
	  ,g1.country_code as country_code_g1
	  ,g1.registration_start_date as registration_start_date_g1
	  ,CASE when g1.asset_type IS NOT NULL THEN g1.asset_type ELSE 'CFD' END AS Asset_Type
	  ,dc.RegisteredReal
	  ,dc.CountryID
          ,CASE WHEN dc.CountryID=191 AND dc.RegisteredReal>='20250320' THEN 'Futures' ELSE 'CFD' END Product_Type
FROM DWH_dbo.Dim_Customer dc
LEFT JOIN BI_DB_dbo.BI_DB_First5Actions bdfa ON bdfa.CID=dc.RealCID
LEFT JOIN [BI_DB_dbo].[External_Fivetran_google_sheets_at_nm_setup_compliance] g1
	ON g1.country_code=dc.CountryID
	AND dc.RegisteredReal>=CAST(CONVERT(DATE, g1.registration_start_date, 103) AS DATE)
WHERE dc.VerificationLevelID>=2 AND dc.IsValidCustomer=1 AND dc.PlayerStatusID NOT IN (3,4)