SELECT bdgc.* 
,dgs.GuruStatusName AS PILevel
,CASE WHEN fsc2.AccountTypeID=9 THEN 'Copy Portfolio'
WHEN fsc2.GuruStatusID >= 2 THEN 'PI'
ELSE 'Copy Trader' END AS Type
FROM BI_DB..BI_DB_Guru_Copiers bdgc WITH (NOLOCK)
JOIN DWH..Fact_SnapshotCustomer fsc WITH (NOLOCK)
ON bdgc.CID= fsc.RealCID
JOIN DWH..Dim_Range dr WITH (NOLOCK)
ON fsc.DateRangeID = dr.DateRangeID
JOIN DWH..Fact_SnapshotCustomer fsc2 WITH (NOLOCK)
ON bdgc.ParentCID= fsc2.RealCID
JOIN DWH..Dim_Range dr2 WITH (NOLOCK)
ON fsc2.DateRangeID = dr2.DateRangeID
LEFT JOIN DWH..Dim_GuruStatus dgs
ON fsc2.GuruStatusID = dgs.GuruStatusID
WHERE bdgc.TimestampID = CONVERT(CHAR(8),DATEADD(DAY,1,<[Parameters].[Parameter 1]>),112)
AND CONVERT(CHAR(8),<[Parameters].[Parameter 1]>,112) BETWEEN dr.FromDateID AND dr.ToDateID
AND CONVERT(CHAR(8),<[Parameters].[Parameter 1]>,112) BETWEEN dr2.FromDateID AND dr2.ToDateID
AND fsc.RegulationID =7
AND fsc.IsDepositor=1
AND fsc.IsValidCustomer=1