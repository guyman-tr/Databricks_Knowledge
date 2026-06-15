SELECT CAST(sac.[ActionDate] AS DATE) ActionDate
      ,sact.[ActionName]
	  ,COUNT(distinct sac.RealCID) Users
	  ,COUNT(*) Actions
  FROM [BI_DB].[dbo].[BI_DB_Social_Activity] sac WITH (NOLOCK)
  INNER JOIN [BI_DB].[dbo].[BI_DB_Social_Activity_Type] sact WITH (NOLOCK)
  ON sac.[ActionTypeID] = sact.ActionID
  WHERE sac.ActionDateID >=20210801
  AND sact.ActionID != 5
  AND sac.RealCID != 5052186
  GROUP BY CAST(sac.[ActionDate] AS DATE)
      ,sact.[ActionName]