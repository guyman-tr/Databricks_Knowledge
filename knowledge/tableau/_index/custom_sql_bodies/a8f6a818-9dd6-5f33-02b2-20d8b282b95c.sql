SELECT [CID]
        ,[Date] CreateDate
      ,[OldTier]
      ,[OldClub]
      ,[OldSort]
      ,[CurrentTier]
      ,[CurrentClub] 
      ,[CurrentSort]
      ,[PLChangeType]
      ,[UpdateDate]
  FROM [BI_DB_dbo].[BI_DB_ClubChangeLogProduct]
  WHERE Date>='2023-01-01'