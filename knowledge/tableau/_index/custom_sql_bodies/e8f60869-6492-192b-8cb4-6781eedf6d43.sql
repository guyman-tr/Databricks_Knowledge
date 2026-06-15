SELECT dc.RealCID,
			dc.RegisteredReal,
			dc.VerificationLevelID,
			dr.Name AS 'Regulation',
			dc1.Name as 'Country',
			dc.IsDepositor,
			MAX(slf.SelfieClassificationDate) AS 'MaxSelfieClassificationDate',
			MAX(slf.SelfieUploadDate) AS 'MaxSelfieUploadDate',
		    MAX(ISNULL(CAST(slf.SelfieCheck AS INT),-1)) AS 'MaxSelfieCheck'
FROM DWH_dbo.Dim_Customer dc
INNER JOIN DWH_dbo.Dim_Regulation dr ON dc.RegulationID=dr.ID
INNER JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID
LEFT JOIN BI_DB_dbo.External_ComplianceStateDB_Compliance_VerificationLevel3Evaluation slf ON dc.GCID = slf.GCID
WHERE dc.RegisteredReal>='2023-11-07' AND dc.CountryID IN (102,154,196,100,57)
GROUP BY dc.RealCID,
			dc.RegisteredReal,
			dc.VerificationLevelID,
			dr.Name,
			dc1.Name,
			dc.IsDepositor