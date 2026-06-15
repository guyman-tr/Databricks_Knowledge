SELECT ch.[CaseId]      
      ,ch.[NewValue]
      ,MIN(ch.[CreatedDate]) CreatedDate
  FROM [BI_DB].[dbo].[BI_DB_SF_STG_CaseHistory] ch WITH (NOLOCK)
  LEFT JOIN [dbo].[BI_DB_SF_M_Users]  sfu WITH (NOLOCK)
  ON ch.NewValue = sfu.Id 
  WHERE Field = 'Owner'
  AND  (sfu.ReportsTo ='0051p000009Zj3lAAC' OR sfu.Id= '0050800000DiIFyAAN')
  GROUP BY ch.[CaseId]      
      ,ch.[NewValue]