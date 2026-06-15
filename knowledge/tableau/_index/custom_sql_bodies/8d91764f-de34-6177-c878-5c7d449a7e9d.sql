SELECT  bdppl.DateID,bdppl.CID,
count( DISTINCT bdppl.InstrumentID) CountInstruments
FROM (SELECT fsc.RealCID
FROM DWH..Fact_SnapshotCustomer fsc
INNER JOIN DWH..Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID 
                             AND CAST(CONVERT(VARCHAR(8), cast (getdate() -1 as date ), 112) AS INT) between dr.FromDateID AND dr.ToDateID 
                             AND fsc.RegulationID IN (1,2)
                             AND fsc.IsValidCustomer=1
                             AND fsc.VerificationLevelID = 3
                             AND fsc.AccountTypeID not in (10,5,11,7,8)) c  
INNER JOIN BI_DB..BI_DB_PositionPnL bdppl ON c.RealCID=bdppl.CID 
                                            AND bdppl.DateID=CAST(CONVERT(VARCHAR(8), cast (getdate() -1 as date ), 112) AS INT) 

WHERE bdppl.IsSettled=0     
GROUP BY bdppl.DateID,bdppl.CID

union
SELECT  bdppl.DateID,bdppl.CID,
count( DISTINCT bdppl.InstrumentID) CountInstruments
FROM (SELECT fsc.RealCID
FROM DWH..Fact_SnapshotCustomer fsc
INNER JOIN DWH..Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID 
                             AND CAST(CONVERT(VARCHAR(8), cast (getdate() -2 as date ), 112) AS INT) between dr.FromDateID AND dr.ToDateID 
                             AND fsc.RegulationID IN (1,2)
                             AND fsc.IsValidCustomer=1
                             AND fsc.VerificationLevelID = 3
                             AND fsc.AccountTypeID not in (10,5,11,7,8)) c  
INNER JOIN BI_DB..BI_DB_PositionPnL bdppl ON c.RealCID=bdppl.CID 
                                            AND bdppl.DateID=CAST(CONVERT(VARCHAR(8), cast (getdate() -2 as date ), 112) AS INT) 

WHERE bdppl.IsSettled=0     
GROUP BY bdppl.DateID,bdppl.CID

union
SELECT  bdppl.DateID,bdppl.CID,
count( DISTINCT bdppl.InstrumentID) CountInstruments
FROM (SELECT fsc.RealCID
FROM DWH..Fact_SnapshotCustomer fsc
INNER JOIN DWH..Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID 
                             AND CAST(CONVERT(VARCHAR(8), cast (getdate() -3 as date ), 112) AS INT) between dr.FromDateID AND dr.ToDateID 
                             AND fsc.RegulationID IN (1,2)
                             AND fsc.IsValidCustomer=1
                             AND fsc.VerificationLevelID = 3
                             AND fsc.AccountTypeID not in (10,5,11,7,8)) c  
INNER JOIN BI_DB..BI_DB_PositionPnL bdppl ON c.RealCID=bdppl.CID 
                                            AND bdppl.DateID=CAST(CONVERT(VARCHAR(8), cast (getdate() -3 as date ), 112) AS INT) 

WHERE bdppl.IsSettled=0     
GROUP BY bdppl.DateID,bdppl.CID