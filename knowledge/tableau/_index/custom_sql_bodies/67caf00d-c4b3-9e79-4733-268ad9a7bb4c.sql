SELECT  fsc.CountryID
	   ,dc.Name Country
	   ,fsc.RealCID
	   ,dr1.Name AS Regulation
	   ,dps.Name AS Player_Status
	   ,fsc.VerificationLevelID
	   ,bdcbcln.ClosingBalance 
FROM DWH_dbo.Fact_SnapshotCustomer fsc
JOIN DWH_dbo.Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID 
	AND CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT) BETWEEN dr.FromDateID AND dr.ToDateID
JOIN BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln
	ON bdcbcln.CID = fsc.RealCID 
	AND bdcbcln.Date = <[Parameters].[Parameter 2]>
	AND bdcbcln.ClosingBalance > 0
JOIN DWH_dbo.Dim_Country dc
	ON fsc.CountryID = dc.CountryID
JOIN DWH_dbo.Dim_Regulation dr1
	ON fsc.RegulationID = dr1.DWHRegulationID
JOIN DWH_dbo.Dim_PlayerStatus dps
	ON fsc.PlayerStatusID = dps.PlayerStatusID
WHERE fsc.RegulationID in (1,5)
	AND fsc.IsCreditReportValidCB = 1
	AND fsc.CountryID IN (1,243,2,3,4,5,6,7,239,8,9,10,11,12,14,203,15,16,17,18,20,21,22,23,24,245,25,26,27,28,31,33,34,36,37,38,39,40,42,43,44,45,46,47,48,49,56,50,51,
							35,53,246,58,59,60,62,63,64,65,66,68,70,69,71,75,77,204,78,80,81,83,84,86,87,242,88,89,90,91,212,92,93,96,97,98,99,244,101,103,104,233,105,
							106,107,108,152,190,109,110,111,113,114,115,116,120,73,121,122,123,124,125,127,129,130,132,133,134,135,136,238,137,138,139,140,141,142,234,
							145,146,147,148,149,150,151,153,155,156,157,235,158,159,160,161,162,163,166,167,236,169,170,247,172,173,174,248,220,171,177,178,232,179,180,
							237,181,182,183,249,186,187,188,175,192,193,194,240,195,198,199,200,201,202,61,205,206,207,208,209,210,211,176,213,215,216,217,218,219,189,
							221,222,223,225,226,30,214,227,229,230,231)
	AND fsc.PlayerStatusID NOT IN (2,4,13)
	AND fsc.VerificationLevelID=3