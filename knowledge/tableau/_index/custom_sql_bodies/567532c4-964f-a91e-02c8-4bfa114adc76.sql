select 
cid.RealCID, 
Amount as Amount, 
cid.Occurred as 'Time', 
--m.FirstName +' '+ m.LastName as Member, 
dc.Name as Regulation,
getdate() as UpdateDate

FROM DWH_dbo.Fact_CustomerAction cid
--left join DWH_dbo.Dim_Manager m on m.ManagerID=cid.ManagerID
join [DWH_dbo].[Dim_Customer] bc on cid.RealCID=bc.RealCID
JOIN [DWH_dbo].[Dim_Regulation] dc on bc.RegulationID=dc.ID
where 
cid.[ActionTypeID]=36 --Comepnsations
AND 
cid.Occurred >= convert(date, getdate()-180)
and cid.Amount>0
AND cid.RealCID in (
3400616,
10526243,
10842855,
11464063
)