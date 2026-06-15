SELECT fn.ProcessName
	  ,fn.ProcessType
	  ,fn.ProcessStatus
	  ,fn.LastDate
	  ,fn.ErrorMessage
	  ,fn.FrequencySP
	  ,fn.DurationMinutes
	  ,fn.IsActive
FROM( 
SELECT os.ProcedureName AS 'ProcessName'
      ,CASE WHEN os.ProcedureName LIKE 'eMoney_dbo.SP%' THEN 'BI Process'
	        WHEN os.ProcedureName LIKE 'DE_dbo.%' THEN 'DE Synapse Process'
			WHEN os.ProcedureName LIKE 'Bronze/%' THEN 'DE Lake Process'
			ELSE 'Unknown Please Check' END AS 'ProcessType'
	  ,os.ObjectStatusDesc AS 'ProcessStatus'
	  ,DATEDIFF(MINUTE, os.StartDate, os.EndDate) AS 'DurationMinutes'
	  ,os.LastDate
	  ,os.ErrorMessage
	  ,os.FrequencySP
	  ,os.IsActive
	  ,ROW_NUMBER() OVER(PARTITION BY os.ProcedureName ORDER BY os.LastDate DESC) AS 'RN_DESC'
FROM(
SELECT osh.ProcedureName
      ,osd.ObjectStatusDesc
	  ,osh.LastDate
	  ,osh.ErrorMessage
	  ,osh.FrequencySP
	  ,osh.StartDate
	  ,osh.EndDate
	  ,osh.IsActive
FROM [DE_dbo].[ObjectsStatusHistory] osh WITH(NOLOCK)
LEFT JOIN [DE_dbo].[ObjectsStatusDic] osd WITH(NOLOCK) ON osh.ObjectStatus = osd.ObjectStatus
WHERE osh.LastDate >= <[Parameters].[Parameter 1]> AND LOWER(osh.ProcedureName) LIKE '%emoney%')
os)
fn
WHERE fn.RN_DESC = 1