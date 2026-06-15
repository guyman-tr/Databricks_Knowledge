SELECT dc.RealCID,
	   dr.Name AS 'Current_Regulation',
	   dr1.Name AS 'Designated_Regulation',
	   dps.Name AS 'Current_Status'
	   
FROM DWH_dbo.Dim_Customer dc
INNER JOIN DWH_dbo.Dim_Regulation dr ON dc.RegulationID=dr.DWHRegulationID
INNER JOIN DWH_dbo.Dim_Regulation dr1 ON dc.DesignatedRegulationID=dr1.DWHRegulationID
INNER JOIN DWH_dbo.Dim_PlayerStatus dps ON dc.PlayerStatusID = dps.PlayerStatusID