SELECT 
  base.CID,
  base.min_InstanceActivationDate,
  base.active_months_count,
  base.active_weeks_count,
  base.AccountSubProgram,
    
  -- Total months since activation (inclusive)
  DATEDIFF(MONTH, base.min_InstanceActivationDate, CAST(GETDATE() AS DATE)) + 1 AS total_months_since_activation,

  -- Total weeks since activation (inclusive)
  DATEDIFF(WEEK, base.min_InstanceActivationDate, CAST(GETDATE() AS DATE)) + 1 AS total_weeks_since_activation,

  -- Monthly usage flag
  CASE 
    WHEN base.active_months_count = DATEDIFF(MONTH, base.min_InstanceActivationDate, CAST(GETDATE() AS DATE)) + 1 
    THEN 1 ELSE 0 
  END AS is_monthly_usage,

  -- Weekly usage flag
  CASE 
    WHEN base.active_weeks_count = DATEDIFF(WEEK, base.min_InstanceActivationDate, CAST(GETDATE() AS DATE)) + 1 
    THEN 1 ELSE 0 
  END AS is_weekly_usage

FROM (
  SELECT 
    s.CID, 
    min(s.InstanceActivationDate) AS min_InstanceActivationDate,
	max(mda.AccountSubProgram) AS AccountSubProgram  ,
    COUNT(DISTINCT FORMAT(mdt.TxStatusModificationDate, 'yyyy-MM')) AS active_months_count,
   COUNT(DISTINCT DATENAME(week, mdt.TxStatusModificationDate) + '-' + DATENAME(year, mdt.TxStatusModificationDate))  AS active_weeks_count
  FROM 
   eMoney_dbo.eMoney_Card_Instance_Summary s 
   join eMoney_dbo.eMoney_Dim_Account mda
   ON s.CID=mda.CID 
   AND mda.GCID_Unique_Count=1 and mda.IsValidETM=1 
   left JOIN 
  (SELECT * FROM   eMoney_dbo.eMoney_Dim_Transaction a WITH(NOLOCK) 
   WHERE 
    a.IsValidETM = 1 
    AND a.IsTxSettled = 1 
        AND a.TxTypeID IN (1,2,3,4,13)
	) mdt  ON s.CID=mdt.CID  
	AND mdt.TxStatusModificationDate >= s.InstanceActivationDate 
  
  GROUP BY 
    s.CID
   ) base