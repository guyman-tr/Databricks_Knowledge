select right (etr_ymd,10) Date, 
Case when [Other Counterparty ID] = '213800HFC5G4V293BN91' then 'IG' Else 'Marex/ED&F' end as 'LP' ,
[Message Type], [Action Type], Count (1) [Count]FROM 
[SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[Una_EMIR_Submissions]
group by etr_ymd, [Other Counterparty ID],[Message Type], [Action Type]