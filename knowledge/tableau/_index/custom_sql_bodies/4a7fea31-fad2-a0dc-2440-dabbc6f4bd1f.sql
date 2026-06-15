SELECT    mat.[Report_Date] ,
	   mat.[Report_Date_ID],
	   mat.[GCID] ,
	   mat.[CID] ,
	   mat.[Country],
	   mat.[Region] AS Old_Region,
	   mat.[Euro_Non_Euro],
	   mat.[Club] ,
	   mat.[Account_Manager] ,
	   mat.[Account_Manager_ID] ,
	   mat.[Attemp_Last_Date],
	   mat.[Contacted_Last_Date],
	   mat.[Value_TotalActions],
	   mat.[Value_eMoneyActions],
	   mat.[Value_OtherActions],
	   mat.[CNT_TotalActions],
	   mat.[CNT_eMoneyActions],
	   mat.[CNT_OtherActions],
	   mat.[Value_TotalActions_Targets],
	   mat.[Value_eMoneyActions_Targets],
	   mat.[Value_OtherActions_Targets],
	   mat.[CNT_TotalActions_Targets],
	   mat.[CNT_eMoneyActions_Targets],
	   mat.[CNT_OtherActions_Targets],
	   mat.[Value_TotalActions_Daily],
	   mat.[Value_eMoneyActions_Daily],
	   mat.[Value_OtherActions_Daily],
	   mat.[CNT_TotalActions_Daily],
	   mat.[CNT_eMoneyActions_Daily],
	   mat.[CNT_OtherActions_Daily],
	   mat.[UpdateDate]
      ,mda.AccountID
	  ,mda.AccountCreateDate
	  ,CASE WHEN mda.AccountID IS NOT NULL THEN 'Yes' ELSE 'No' END AS 'Has eTM account'
	  ,CASE WHEN mat.Country IN ('Portugal','Spain') THEN 'Spain'
	        WHEN mat.Country IN ('Norway','Sweden') THEN 'Nor Swe'
			WHEN mat.Country IN ('Finland','Denmark') THEN 'Fin Den'
			WHEN mat.Country IN ('Netherlands') THEN 'NL'
			WHEN mat.Country IN ('United Kingdom','Ireland') THEN 'UK'
			WHEN mat.Country IN ('Austria','Germany') THEN 'German'
			WHEN mat.Country IN ('Greece','Malta','Cyprus') THEN 'GLC Max'
			WHEN mat.Country IN ('Latvia','Estonia','Lithuania') THEN 'LEL Max'
			WHEN mat.Country IN ('Italy') THEN 'Italian'
			WHEN mat.Country IN ('Slovakia','Slovenia') THEN 'Slo Slo'
			WHEN mat.Country IN ('France','Luxembourg','Monaco','Belgium') THEN 'French'
			ELSE NULL END AS Region
FROM eMoney_dbo.eMoney_AM_Target mat
LEFT JOIN eMoney_dbo.eMoney_Dim_Account mda
ON mat.GCID = mda.GCID
    AND mda.IsValidETM=1
    AND mda.GCID_Unique_Count=1