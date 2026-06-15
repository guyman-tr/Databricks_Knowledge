SELECT 
dc.RealCID AS CID,
dc.GCID,
dc1.Name AS Country,
dc.VerificationLevelID,
dps.Name AS PlayerStatus,
dc.IsAddressProof,
dc.IsIDProof,
dr.Name AS DesignatedRegulation,
cast(dc.RegisteredReal as date) as RegistrationDate

FROM DWH_dbo.Dim_Customer dc
LEFT JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID=dc1.CountryID
LEFT JOIN DWH_dbo.Dim_PlayerStatus dps ON dps.PlayerStatusID=dc.PlayerStatusID
LEFT JOIN DWH_dbo.Dim_Regulation dr ON dr.ID=dc.DesignatedRegulationID

WHERE dc.VerificationLevelID=2
and ((dc.IsAddressProof=1 or dc.IsIDProof=1))
AND dc.PlayerStatusID IN (1,13) --Normal,PendingVerification
and dc.CountryID in (40,32,52,226,81,162,188)--Bulgaria, Croatia, Vietnam, Gibraltar, Philippines, South Africa, Cayman Islands