SELECT
        dc.RealCID,
        DisplayName,
        CompletedDate,
        LastEvaluationData
    FROM BI_DB_dbo.External_ComplianceStateDB_Compliance_CustomerInteractions amt
	join DWH_dbo.Dim_Customer dc on dc.GCID=amt.GCID
	
    WHERE DisplayName IS NOT NULL