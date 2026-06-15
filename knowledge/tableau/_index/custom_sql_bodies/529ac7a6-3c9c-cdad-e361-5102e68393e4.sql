select c.*,a.Rank_CID,a.CIDTotalCommission
from(select RealCID,UserName,InstrumentID,InstrumentName
 ,InstrumentType
,sum(VolumeOnClose + VolumeOnOpen) as Volume
,sum(FullCommissions) as FullCommissions
 from #comms
WHERE FullDate BETWEEN <[Parameters].[Parameter 1]> AND <[Parameters].[Parameter 2]>
GROUP BY RealCID,UserName,InstrumentID,InstrumentName
 ,InstrumentType
 )c
left join (
select a.RealCID, 
SUM(a.FullCommissions) AS CIDTotalCommission 
,ROW_NUMBER() OVER (ORDER BY SUM(a.FullCommissions) DESC) AS Rank_CID
from #comms a
WHERE  a.FullDate BETWEEN <[Parameters].[Parameter 1]> AND <[Parameters].[Parameter 2]>
GROUP BY a.RealCID
) a on a.RealCID=c.RealCID