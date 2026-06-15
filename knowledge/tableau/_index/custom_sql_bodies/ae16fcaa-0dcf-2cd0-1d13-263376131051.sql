SELECT CAST(f5a.FirstActionDate AS DATE) [Date]
        ,f5a.FirstActionTypeNew [First Action]
		,f5a.FirstCrossNew [First Cross]
        ,COUNT(*) [Actions]
 FROM [BI_DB].[dbo].[BI_DB_First5Actions] f5a WITH (NOLOCK)
WHERE f5a.FirstActionTypeNew is not null
 GROUP BY CAST(f5a.FirstActionDate AS DATE)
        ,f5a.FirstActionTypeNew
		,f5a.FirstCrossNew