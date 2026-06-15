select ReportDate,CID,Migration_Occurred,PrevRegulationID,RegulationID
	,sum(case when IsSettled=1 then 1 else 0 end) as NumOfMoved_Real_Positions
	,sum(case when IsSettled=0 then 1 else 0 end) as NumOfMoved_CFD_Positions
	,sum(case when [IsMifidByFCA]=1 then 1 else 0 end) as NumOfMoved_MifidUK_Instruments
	,sum(case when [IsMifid]=1 then 1 else 0 end) as NumOfMoved_MifidEU_Instruments
FROM [Reg_Regulation_Movments_Positions]

group by ReportDate,CID,Migration_Occurred,PrevRegulationID,RegulationID