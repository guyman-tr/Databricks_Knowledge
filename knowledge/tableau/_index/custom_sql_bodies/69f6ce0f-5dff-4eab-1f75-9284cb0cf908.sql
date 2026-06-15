SELECT a.*,
       CASE 
            WHEN MostUsedContactType_60 = MostUsedContactType_90 
                 AND MostUsedContactType_90 = MostUsedContactType_180 
            THEN MostUsedContactType_60 
            ELSE 'Contact_Type_Changed' 
       END AS One_MostUsedContactType
FROM [BI_DB_dbo].[BI_DB_Engagement_Score] a