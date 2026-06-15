select [CID]
      ,[AffiliateID]
      ,cast([FirstDepositDate] as date) as 'FirstDepositDate'
      ,[FirstDepositAmount]
      ,[Region]
      ,[Country]
      ,[Channel]
      ,[SubChannel]
      ,[FirstAction]
      ,cast([FirstActionDate] as date) as 'FirstActionDate'
      ,[FirstInstrument]

from [BI_DB].[dbo].[BI_DB_First5Actions]

where Country = 'United States' 
and cast(FirstActionDate as date) >= '2021-10-01'