SELECT fsc.RealCID
	  ,fsc.GCID
	  ,dc.RegisteredReal
	  ,dc.FirstDepositDate
	  ,dc2.Name AS 'CountryAtBeginTime'
	  ,dr2.Name AS 'RegulationAtBeginTime'
	  ,atnm.Restriction_Status
	  ,atnm.BeginTime
	  ,atnm.EndTime
	  ,atnm.RestrictionStatusReasonID
	  ,atnm.Restriction_Status_Reason
	  ,g1.country_code as country_code_g1
	  ,g1.registration_start_date as registration_start_date_g1
	  ,CASE when g1.asset_type IS NOT NULL THEN g1.asset_type ELSE 'CFD' END AS Asset_Type
	  ,dc.CountryID
          ,CASE WHEN dc.CountryID=191 AND dc.RegisteredReal>='20250320' THEN 'Futures' ELSE 'CFD' END Product_Type 
FROM 
(
	SELECT hist.GCID, 
		   dr.Name 'Restriction_Status', 
		   hist.BeginTime,
		   hist.EndTime,
		   hist.RestrictionStatusReasonID,
		   drr.Name 'Restriction_Status_Reason'
	FROM BI_DB_dbo.External_ComplianceStateDB_History_UserTradingData hist
	INNER JOIN BI_DB_dbo.External_ComplianceStateDB_Dictionary_RestrictionStatus dr ON hist.CFDRestrictionStatusID = dr.RestrictionStatusID
	LEFT JOIN BI_DB_dbo.External_ComplianceStateDB_Dictionary_RestrictionStatusReason drr ON hist.RestrictionStatusReasonID = drr.RestrictionStatusReasonID
	WHERE hist.RestrictionStatusReasonID=12
	
		UNION ALL
	
	SELECT CR.GCID,
	        ASS.[Name] AS 'Restriction_Status',
			CR.BeginTime,
			CR.EndTime,
			RSR.RestrictionStatusReasonID,
			RSR.[Name] AS 'Restriction_Status_Reason'
	FROM [BI_DB_dbo].External_ComplianceStateDB_History_CustomerRestrictions CR
	INNER JOIN [BI_DB_dbo].[External_ComplianceStateDB_Dictionary_RestrictionStatus] ASS ON ASS.RestrictionStatusID=CR.RestrictionStatusID
	INNER JOIN [BI_DB_dbo].[External_ComplianceStateDB_Dictionary_RestrictionStatusReason] RSR ON RSR.RestrictionStatusReasonID=CR.RestrictionStatusReasonID
	WHERE CR.RestrictionStatusReasonID=14
)atnm
INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON atnm.GCID=fsc.GCID
INNER JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID
							AND CAST(FORMAT(CAST(atnm.BeginTime AS DATE),'yyyyMMdd') as INT) BETWEEN dr.FromDateID AND dr.ToDateID
INNER JOIN DWH_dbo.Dim_Customer dc ON fsc.GCID = dc.GCID
INNER JOIN DWH_dbo.Dim_Country dc2 ON fsc.CountryID = dc2.CountryID
INNER JOIN DWH_dbo.Dim_Regulation dr2 ON fsc.RegulationID=dr2.ID
LEFT JOIN [BI_DB_dbo].[External_Fivetran_google_sheets_at_nm_setup_compliance] g1
	ON g1.country_code=dc.CountryID
	AND dc.RegisteredReal>=CAST(CONVERT(DATE, g1.registration_start_date, 103) AS DATE)
where fsc.RealCID=<[Parameters].[Parameter 1]>