SELECT 
vl.CID
,dc.RegulationID
,dr.Name AS 'Regulation'
,dc.VerificationLevelID
,dc.IsCreditReportValidCB

,MAX(CASE WHEN csa.CFD_Trading_Status IS NULL THEN 'NoMatch'
          WHEN csa.CFD_Trading_Status = 'CFD_Allowed' THEN 'CFD_Allowed'
	      WHEN csa.CFD_Trading_Status = 'CFD_Blocked' THEN 'CFD_Blocked'
	      WHEN csa.CFD_Trading_Status = 'Exempt' THEN 'Exempt'
	      ELSE 'Error'
END) AS 'Appropriateness_Indicator'

,MAX(CASE WHEN st.Suitable IS NULL THEN 'NoMatch'
          WHEN st.Suitable = 1 THEN 'Suitable'
	      WHEN st.Suitable = 0 THEN 'Not Suitable'
	      ELSE 'Error'
END) AS 'Suitability_Indicator'

,SUM(ISNULL(vl.Liabilities, 0) - ISNULL(vl.PositionPnL, 0) + ISNULL(vl.ActualNWA, 0)) AS 'Realized_Equity'
,SUM(ISNULL(vl.Liabilities, 0) + ISNULL(vl.ActualNWA, 0)) AS 'Unrealized_Equity'
,SUM(ISNULL(vl.ActualNWA, 0)) AS 'NonWithdrawal_Amount'
,SUM(ISNULL(vl.TotalPositionsAmount, 0)) AS 'Invested_Amount'
,SUM(ISNULL(vl.TotalMirrorPositionsAmount, 0)) AS 'Copy_Invested_Amount'

FROM DWH.dbo.V_Liabilities vl WITH(NOLOCK)

INNER JOIN DWH.dbo.Dim_Customer dc WITH(NOLOCK) ON vl.CID = dc.RealCID AND dc.IsValidCustomer = 1

INNER JOIN DWH.dbo.Dim_Regulation dr WITH(NOLOCK) ON dc.RegulationID = dr.DWHRegulationID

LEFT JOIN BI_DB.dbo.BI_DB_Compliance_Scored_Appropriateness csa WITH(NOLOCK) ON vl.CID = csa.CID

LEFT JOIN BI_DB.dbo.BI_DB_SuitabilityTestResults st WITH(NOLOCK) ON vl.CID = st.CID

WHERE vl.DateID = CAST(CONVERT(CHAR(8), (GETDATE()-1), 112) AS INT)

GROUP BY vl.CID, dc.RegulationID, dr.Name, dc.VerificationLevelID, dc.IsCreditReportValidCB