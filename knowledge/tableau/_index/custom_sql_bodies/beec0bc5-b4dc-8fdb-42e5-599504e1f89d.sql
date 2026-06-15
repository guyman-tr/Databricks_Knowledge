SELECT nm.RealCID AS 'CID'
	  ,nm.GCID
	  ,dc.PlayerLevelID
	  ,dpl.Name AS 'Club'
	  ,dc.IsDepositor AS 'IsFTD'
	  ,dc.RegulationID
	  ,reg.Name AS 'Regulation'
	  ,nm.IsDepositor AS 'IsDepositor_NMTable'
	  ,nm.FTD_Date
	  ,nm.EOW_FTD
	  ,nm.EOM_FTD
	  ,nm.FTD_Amount
	  ,nm.RegulationID AS 'RegulationID_NMTable'
	  ,nm.RegulationName AS 'Regulation_NMTable'
	  ,nm.CountryID
	  ,nm.CountryName
	  ,nm.IsKYC_NM_Trading_Experience
	  ,nm.IsKYC_NM_Risk_Factor
	  ,nm.IsKYC_NM
	  ,nm.AT_Total_Score_KYC
	  ,nm.AT_Total_Max_Potential_Score
	  ,nm.IsKYC_AT_Passed
	  ,nm.RestrictionStatusDesc
	  ,nm.CFD_Status
	  ,nm.BlockDate AS 'BlockDateTime'
	  ,CAST(nm.BlockDate AS DATE) AS 'BlockDate'
	  ,nm.BlockReasonID
	  ,nm.BlockReasonDesc
	  ,nm.ReleaseDate AS 'ReleaseDateTime'
	  ,CAST(nm.ReleaseDate AS DATE) AS 'ReleaseDate'
      ,CASE WHEN nm.CFD_Status = 'CFD_Allowed' AND ISNULL(nm.BlockDate, '1900-01-01') > '1900-01-01' 
	        THEN 'CFD_Released' ELSE nm.CFD_Status END AS 'CFD_Status_BI_Definition'
      ,CASE WHEN nm.CFD_Status = 'CFD_Allowed' AND nm.ReleaseDate IS NOT NULL  
	        THEN 'CFD_Released' ELSE nm.CFD_Status END AS 'CFD_Status_OfirTesting_Definition'
	  ,nm.ReleaseReasonID
	  ,nm.ReleaseReasonDesc
	  ,nm.DateDiffBlockRelease
	  ,nm.AT_Date
	  ,nm.ApproprietnessScore_Status
	  ,nm.DesignatedRegulationName
	  ,nm.BlockSubReasonID
	  ,nm.BlockSubReasonDesc
	  ,nm.UpdateDate
	  ,CASE WHEN nm.BlockDate IS NOT NULL THEN 1 ELSE 0 END AS 'Indicator_WereBlocked'
	  ,CASE WHEN nm.ReleaseDate IS NOT NULL THEN 1 ELSE 0 END AS 'Indicator_WereReleased'
	  ,CASE WHEN nm.BlockDate IS NOT NULL AND nm.ReleaseDate IS NOT NULL 
	             AND nm.ReleaseDate < nm.BlockDate THEN 1 ELSE 0 END AS 'Indicator_ReleaseDateSmallerFromBlockDate'
FROM BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market nm
INNER JOIN DWH_dbo.Dim_Customer dc ON nm.RealCID = dc.RealCID
INNER JOIN DWH_dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN DWH_dbo.Dim_Regulation reg ON dc.RegulationID = reg.DWHRegulationID