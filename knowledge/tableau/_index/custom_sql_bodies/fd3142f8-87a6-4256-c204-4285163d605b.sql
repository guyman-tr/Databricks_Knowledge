SELECT a.*
		,CASE WHEN fsc.IsValidCustomer = 1 THEN 'Yes' ELSE 'No' END AS 'IsValidCustomer'
		,CASE WHEN fsc.IsCreditReportValidCB = 1 THEN 'Yes' ELSE 'No' END AS 'IsCreditReportValidCB'
		,dr.Name AS 'RegulationName'
FROM EXE..EXE_Staking_Proposal_VS_Execution a
INNER JOIN DWH.dbo.Fact_SnapshotCustomer fsc 
		ON a.CID = fsc.RealCID
INNER JOIN DWH.dbo.Dim_Range dd 
		ON fsc.DateRangeID = dd.DateRangeID 
        AND (CAST(CONVERT(CHAR(8), a.StakingMonth, 112) AS INT)) BETWEEN dd.FromDateID AND dd.ToDateID
LEFT JOIN DWH.dbo.Dim_Regulation dr 
		ON fsc.RegulationID = dr.DWHRegulationID