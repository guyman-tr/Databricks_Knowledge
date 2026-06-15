SELECT bdssch.Id
	  ,bdssch.IsDeleted
	  ,bdssch.CaseId
	  ,bdssch.CreatedById
	  ,bdssch.CreatedDate
	  ,bdssch.Field
	  ,bdssch.DataType
	  ,bdssch.OldValue
	  ,bdssch.NewValue
	  ,ISNULL(LEAD(bdssch.CreatedDate) OVER (PARTITION BY bdssch.CaseId ORDER BY bdssch.CreatedDate ASC),getdate()) CreatedDateLead
FROM BI_DB.dbo.BI_DB_SF_STG_CaseHistory bdssch
WHERE Field = 'Owner'
AND bdssch.DataType = 'Text'