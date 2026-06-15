Select CONVERT (date,convert(char(8),a.DateID))[Date], 'EMIR CL' as [Report], a.[CID_BO], a.[Positions_BO], b.[CID_RG], b.[Position_RG]
from (
select DateID, Count(distinct CID) as [CID_BO], sum (CountInstruments) Positions_BO from (

SELECT  bdppl.DateID,bdppl.CID,
count( DISTINCT bdppl.InstrumentID) CountInstruments
FROM (SELECT fsc.RealCID
FROM [AZR-WE-DWH-02].[DWH].[dbo].[Fact_SnapshotCustomer] fsc
INNER JOIN [AZR-WE-DWH-02].[DWH].[dbo].[Dim_Range] dr ON fsc.DateRangeID = dr.DateRangeID 
                             AND CAST(CONVERT(VARCHAR(8), cast (getdate() -1 as date ), 112) AS INT) between dr.FromDateID AND dr.ToDateID 
                             AND fsc.RegulationID IN (1,2)
                             AND fsc.IsValidCustomer=1
                             AND fsc.VerificationLevelID in (2,3)
                             AND fsc.AccountTypeID not in (10,5,11,7,8)) c  
INNER JOIN [AZR-WE-DWH-02].[BI_DB].[dbo].[BI_DB_PositionPnL] bdppl ON c.RealCID=bdppl.CID 
                                            AND bdppl.DateID=CAST(CONVERT(VARCHAR(8), cast (getdate() -1 as date ), 112) AS INT) 

WHERE bdppl.IsSettled=0     
GROUP BY bdppl.DateID,bdppl.CID ) agg
group by DateID ) a

inner join (

Select DateID, Count (distinct CID) [CID_RG], Count([Level]) [Position_RG]
From [dbo].[EMIR2_Report]
where [Level] = 'P'
and FlippedReport = '0'
and DateID = CAST(CONVERT(VARCHAR(8), cast (getdate() -1 as date ), 112) AS INT)
Group by DateID )b

on a.DateID=b.DateID


UNION


Select CONVERT (date,convert(char(8),a.DateID))[Date], 'ASIC CL' as [Report], a.[CID_BO], a.[Positions_BO], b.[CID_RG], b.[Position_RG]
from (
select DateID, Count(distinct CID) as [CID_BO], sum (CountInstruments) Positions_BO from (

SELECT  bdppl.DateID,bdppl.CID,
count( DISTINCT bdppl.InstrumentID) CountInstruments
FROM (SELECT fsc.RealCID
FROM [AZR-WE-DWH-02].[DWH].[dbo].[Fact_SnapshotCustomer] fsc
INNER JOIN [AZR-WE-DWH-02].[DWH].[dbo].[Dim_Range] dr ON fsc.DateRangeID = dr.DateRangeID 
                             AND CAST(CONVERT(VARCHAR(8), cast (getdate() -1 as date ), 112) AS INT) between dr.FromDateID AND dr.ToDateID 
                             AND fsc.RegulationID IN (4,10)
                             AND fsc.IsValidCustomer=1
                             AND fsc.VerificationLevelID in (2,3)
                             AND fsc.AccountTypeID not in (10,5,11,7,8)) c  
INNER JOIN [AZR-WE-DWH-02].[BI_DB].[dbo].[BI_DB_PositionPnL] bdppl ON c.RealCID=bdppl.CID 
                                            AND bdppl.DateID=CAST(CONVERT(VARCHAR(8), cast (getdate() -1 as date ), 112) AS INT) 

WHERE bdppl.IsSettled=0     
GROUP BY bdppl.DateID,bdppl.CID ) agg
group by DateID ) a

inner join (

Select DateID, Count (distinct CID) [CID_RG], Count([Deal]) [Position_RG]
From [dbo].[ASIC_Positions_AGG]
where DateID = CAST(CONVERT(VARCHAR(8), cast (getdate() -1 as date ), 112) AS INT)
Group by DateID )b

on a.DateID=b.DateID

Union

Select CONVERT (date,convert(char(8),a.DateID))[Date], 'EMIR CL' as [Report], a.[CID_BO], a.[Positions_BO], b.[CID_RG], b.[Position_RG]
from (
select DateID, Count(distinct CID) as [CID_BO], sum (CountInstruments) Positions_BO from (

SELECT  bdppl.DateID,bdppl.CID,
count( DISTINCT bdppl.InstrumentID) CountInstruments
FROM (SELECT fsc.RealCID
FROM [AZR-WE-DWH-02].[DWH].[dbo].[Fact_SnapshotCustomer] fsc
INNER JOIN [AZR-WE-DWH-02].[DWH].[dbo].[Dim_Range] dr ON fsc.DateRangeID = dr.DateRangeID 
                             AND CAST(CONVERT(VARCHAR(8), cast (getdate() -2 as date ), 112) AS INT) between dr.FromDateID AND dr.ToDateID 
                             AND fsc.RegulationID IN (1,2)
                             AND fsc.IsValidCustomer=1
                             AND fsc.VerificationLevelID in (2,3)
                             AND fsc.AccountTypeID not in (10,5,11,7,8)) c  
INNER JOIN [AZR-WE-DWH-02].[BI_DB].[dbo].[BI_DB_PositionPnL] bdppl ON c.RealCID=bdppl.CID 
                                            AND bdppl.DateID=CAST(CONVERT(VARCHAR(8), cast (getdate() -2 as date ), 112) AS INT) 

WHERE bdppl.IsSettled=0     
GROUP BY bdppl.DateID,bdppl.CID ) agg
group by DateID ) a

inner join (

Select DateID, Count (distinct CID) [CID_RG], Count([Level]) [Position_RG]
From [dbo].[EMIR2_Report]
where [Level] = 'P'
and FlippedReport = '0'
and DateID = CAST(CONVERT(VARCHAR(8), cast (getdate() -2 as date ), 112) AS INT)
Group by DateID )b

on a.DateID=b.DateID


UNION


Select CONVERT (date,convert(char(8),a.DateID))[Date], 'ASIC CL' as [Report], a.[CID_BO], a.[Positions_BO], b.[CID_RG], b.[Position_RG]
from (
select DateID, Count(distinct CID) as [CID_BO], sum (CountInstruments) Positions_BO from (

SELECT  bdppl.DateID,bdppl.CID,
count( DISTINCT bdppl.InstrumentID) CountInstruments
FROM (SELECT fsc.RealCID
FROM [AZR-WE-DWH-02].[DWH].[dbo].[Fact_SnapshotCustomer] fsc
INNER JOIN [AZR-WE-DWH-02].[DWH].[dbo].[Dim_Range] dr ON fsc.DateRangeID = dr.DateRangeID 
                             AND CAST(CONVERT(VARCHAR(8), cast (getdate() -2 as date ), 112) AS INT) between dr.FromDateID AND dr.ToDateID 
                             AND fsc.RegulationID IN (4,10)
                             AND fsc.IsValidCustomer=1
                             AND fsc.VerificationLevelID in (2,3)
                             AND fsc.AccountTypeID not in (10,5,11,7,8)) c  
INNER JOIN [AZR-WE-DWH-02].[BI_DB].[dbo].[BI_DB_PositionPnL] bdppl ON c.RealCID=bdppl.CID 
                                            AND bdppl.DateID=CAST(CONVERT(VARCHAR(8), cast (getdate() -2 as date ), 112) AS INT) 

WHERE bdppl.IsSettled=0     
GROUP BY bdppl.DateID,bdppl.CID ) agg
group by DateID ) a

inner join (

Select DateID, Count (distinct CID) [CID_RG], Count([Deal]) [Position_RG]
From [dbo].[ASIC_Positions_AGG]
where DateID = CAST(CONVERT(VARCHAR(8), cast (getdate() -2 as date ), 112) AS INT)
Group by DateID )b

on a.DateID=b.DateID