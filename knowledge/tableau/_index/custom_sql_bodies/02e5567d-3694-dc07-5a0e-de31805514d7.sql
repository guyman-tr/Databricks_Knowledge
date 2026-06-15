SELECT CID,MAX(ApplicationDate) ApplicationDate
FROM [BI_DB].[dbo].[V_Professional_List_SF]
GROUP BY CID