SELECT fnl.ProcessName
      ,CASE WHEN fnl.FirstStatus = 'Start' AND fnl.SecondStatus = 'Complete' THEN 'Success'
	    WHEN fnl.FirstStatus = 'Start' AND fnl.SecondStatus != 'Complete' AND fnl.LastStatus = 'Complete' THEN 'Partial Success'
	    WHEN fnl.FirstStatus = 'Start' AND fnl.SecondStatus != 'Complete' AND fnl.LastStatus != 'Complete' THEN 'Fail'
       ELSE 'Please Check' END AS 'StatusCheck'
      ,fnl.FirstStatus
      ,fnl.SecondStatus
      ,fnl.FirstStatusTime
      ,fnl.SecondStatusTime
      ,fnl.DDMinutes
      ,fnl.StatusChanges
      ,fnl.LastStatus
      ,fnl.LastStatusTime
      ,fnl.ErrorDescription
      ,fnl.ErrorRow
FROM(
SELECT osq.ProcessName
      ,osq.FirstStatus
      ,osq.SecondStatus
      ,osq.FirstStatusTime
      ,osq.SecondStatusTime
      ,DATEDIFF(MINUTE, osq.FirstStatusTime, osq.SecondStatusTime) AS 'DDMinutes'
      ,osq.StatusChanges
      ,osq.LastStatus
      ,osq.LastStatusTime
      ,osq.ErrorDescription
      ,CASE WHEN osq.ErrorDescription IS NULL THEN 'No' ELSE 'Yes' END AS 'ErrorRow'
FROM(
SELECT isq.ProcessName
      ,MAX(CASE WHEN isq.RN_ASC = 1 THEN isq.ProcessStatus ELSE NULL END) AS 'FirstStatus'
      ,MAX(CASE WHEN isq.RN_ASC = 2 THEN isq.ProcessStatus ELSE NULL END) AS 'SecondStatus'
      ,MAX(CASE WHEN isq.RN_ASC = 1 THEN isq.ProcessStatusTime ELSE NULL END) AS 'FirstStatusTime'
      ,MAX(CASE WHEN isq.RN_ASC = 2 THEN isq.ProcessStatusTime ELSE NULL END) AS 'SecondStatusTime'
      ,COUNT(1) AS 'StatusChanges'
      ,MAX(CASE WHEN isq.RN_DESC = 1 THEN isq.ProcessStatus ELSE NULL END) AS 'LastStatus'
      ,MAX(CASE WHEN isq.RN_DESC = 1 THEN isq.ProcessStatusTime ELSE NULL END) AS 'LastStatusTime'
      ,MAX(isq.ErrorDescription) AS 'ErrorDescription'
FROM(
SELECT psl.ProcessName
      ,psl.ProcessStatus
      ,psl.ProcessStatusTime
      ,psl.ErrorDescription
      ,ROW_NUMBER() OVER(PARTITION BY psl.ProcessName ORDER BY psl.ProcessStatusTime ASC) AS 'RN_ASC'
      ,ROW_NUMBER() OVER(PARTITION BY psl.ProcessName ORDER BY psl.ProcessStatusTime DESC) AS 'RN_DESC'
FROM eMoney.dbo.eMoneyProcessStatusLog psl WITH(NOLOCK)
WHERE psl.ProcessStatusDate = <[Parameters].[Parameter 1]>) isq
GROUP BY isq.ProcessName) osq
) fnl