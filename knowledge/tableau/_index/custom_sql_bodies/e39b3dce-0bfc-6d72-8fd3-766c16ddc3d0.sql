SELECT 
ROW_NUMBER() OVER(PARTITION BY cr.GCID ORDER BY cr.[Start_Date] DESC) AS 'GAP_Number'
,cr.Requirement_Name
,cr.Overview_Status_Name
,cr.Owner_Name
,cr.Status_Reason_Name
,cr.QuestionID
,cr.EntityTypeID
,ISNULL(ISNULL(qna.QuestionText, deuf.ExtendedUserFieldName), '-') AS 'Question'
,cr.[Start_Date]
,cr.[Close_Date]

FROM(

SELECT 
ccr.GCID
,ccr.[Requirement Name] AS 'Requirement_Name'
,ccr.[Overview Status Name] AS 'Overview_Status_Name'
,ccr.[Owner name] AS 'Owner_Name'
,ccr.[Status Reason Name] AS 'Status_Reason_Name'
,ccr.QuestionId AS 'QuestionID'
,ccr.EntityTypeID
,CAST(ccr.StartDate AS DATE) AS 'Start_Date'
,CAST(ccr.CloseDate AS DATE) AS 'Close_Date' 
FROM DWH.dbo.Dim_Customer dc WITH(NOLOCK)
LEFT JOIN BI_DB.dbo.BI_DB_CustomerRequirments ccr WITH(NOLOCK) ON dc.GCID = ccr.GCID
WHERE dc.RealCID IN (<[Parameters].[Parameter 1]>)

UNION ALL 

SELECT 
hccr.GCID
,hccr.[Requirement Name] AS 'Requirement_Name'
,hccr.[Overview Status Name] AS 'Overview_Status_Name'
,hccr.[Owner name] AS 'Owner_Name'
,hccr.[Status Reason Name] AS 'Status_Reason_Name'
,hccr.QuestionId AS 'QuestionID'
,hccr.EntityTypeID
,CAST(hccr.StartDate AS DATE) AS 'Start_Date'
,CAST(hccr.CloseDate AS DATE) AS 'Close_Date' 
FROM DWH.dbo.Dim_Customer dc WITH(NOLOCK) 
LEFT JOIN BI_DB.dbo.BI_DB_CustomerRequirmentsHistory hccr WITH(NOLOCK) ON dc.GCID = hccr.GCID
WHERE dc.RealCID IN (<[Parameters].[Parameter 1]>)

) cr

LEFT JOIN 
(SELECT qna.QuestionId, qna.QuestionText, MAX(qna.AnswerId) AS 'AnswerId'
FROM BI_DB.dbo.BI_DB_KYC_Questions_Answers qna
GROUP BY qna.QuestionId, qna.QuestionText
)qna ON cr.QuestionID = qna.QuestionId AND cr.EntityTypeID = 1

LEFT JOIN 
(SELECT deuf.FieldID, deuf.ExtendedUserFieldName
FROM DWH.dbo.Dim_ExtendedUserField deuf
) deuf ON cr.QuestionID = deuf.FieldID AND cr.EntityTypeID = 2