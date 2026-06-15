select right (etr_ymd,10) Date, 
Case when [Other Counterparty ID] = '213800HFC5G4V293BN91' then 'IG' Else 'Marex/ED&F' end as 'LP' ,
[Message Type], 
Count (1) [Count] ,
Sum(cast(Notional as Decimal (28,10))) [Exposure],
Sum(cast([Mark to Market Value] as decimal (28,10))) [Valaution]
FROM [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[Una_EMIR_Live_UTIs]
where Isnumeric (Notional) = 1 and Isnumeric ([Mark to Market Value]) = 1
group by etr_ymd, [Other Counterparty ID],[Message Type]