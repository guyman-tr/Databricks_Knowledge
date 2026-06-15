SELECT DISTINCT 
        c.[CaseNumber],
        CAST(c.[CreatedDate] AS date) AS Date_,
        c.[ChatScore],
		c.[Status],
		c.[Origin],
        u.[FullName] as Agent,
        u.[Department],
        u.[Title] as AgentRole,
        u.[Site] as Country,
        c.[Sub_Type] ,
        u.[Manager] as TeamLeader,
        c.[NumberOfTouches],
        d.[Name] as TransferedTo,
        d.[Department] as TranferedtoDepartment,
        e.[cSATLast] AS cSAT
        
FROM [BI_DB].[dbo].[BI_DB_SF_STG_M_Case] c

    LEFT JOIN [BI_DB].[dbo].[BI_DB_SF_M_cSAT] e on c.CaseID=e.CaseID
    left JOIN [BI_DB].[dbo].[BI_DB_SF_M_Users] d ON c.[OwnerId]=d.[Id] and ToDate='9999-12-31'
    left JOIN [BI_DB].[dbo].[BI_DB_SF_Case_Event] f on c.CaseID = f.CaseID    
    left JOIN [BI_DB].[dbo].[BI_DB_SF_Users] u ON f.[DoneBy] = u.[Id]
 --   WHERE  c.Status in ('Solved','Closed')
   
WHERE Cast(c.CreatedDate as date)>= '2023-06-01'
AND f.DoneByRole='Customer Service'