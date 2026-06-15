SELECT nm.RealCID
	  ,nm.GCID
	  ,nm.IsDepositor
	  ,nm.FTD_Date
	  ,nm.FTDDateID
	  ,nm.EOW_FTD
	  ,nm.EOM_FTD
	  ,nm.FTD_Amount
	  ,nm.RegulationID
	  ,nm.RegulationName
	  ,nm.RegionID
	  ,nm.RegionName
	  ,nm.CountryID
	  ,nm.CountryName
	  ,nm.RestrictionStatusDesc
	  ,nm.CFD_Status
	  ,nm.BlockDate
	  ,nm.BlockReasonID
	  ,nm.BlockReasonDesc
	  ,nm.ReleaseDate
	  ,nm.ReleaseReasonID
	  ,nm.ReleaseReasonDesc
	  ,nm.DateDiffBlockRelease
	  ,nm.AT_Date
	  ,nm.ApproprietnessScore_Status
	  ,nm.UpdateDate
	  ,nm.DesignatedRegulationName
	  ,nm.BlockSubReasonID
	  ,nm.BlockSubReasonDesc
	  ,dc.RegisteredReal
	  ,tr.Success
	  ,tr.OccurredAt
from BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market nm
INNER JOIN DWH_dbo.Dim_Customer dc on dc.RealCID = nm.RealCID AND dc.RegisteredReal>='2023-07-30' AND dc.RegulationID IN (4,10)
LEFT JOIN (SELECT tr.GCID
				 ,tr.Success
				 ,tr.OccurredAt
				 ,ROW_NUMBER() OVER (PARTITION BY tr.GCID ORDER BY tr.OccurredAt DESC) AS 'RN'
			FROM [BI_DB_dbo].[External_UserApiDB_ASIC_TestResults] tr
			WHERE tr.OccurredAt>='2023-07-30') tr ON dc.GCID=tr.GCID AND tr.RN=1