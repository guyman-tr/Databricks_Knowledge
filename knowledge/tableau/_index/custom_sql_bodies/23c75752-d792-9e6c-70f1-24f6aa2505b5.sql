SELECT q0.CID
	  ,q0.CreatedDate
	  ,q0.LogID
	  ,q0.TicketStatus
	  ,q0.SubType
	  ,q0.SubType2
	  ,q0.Phase
	  ,q0.ActionType
	  ,q0.Source
FROM 
(
SELECT sfc.CID
	  ,CONVERT(DATE,sfc.CreatedDate) CreatedDate
	  ,sfc.LogID
	  ,sfc.TicketStatus
	  ,sfc.SubType
	  ,sfc.SubType2
	  ,sfc.Phase
	  ,sfc.ActionType
	  ,sfc.Source
     ,ROW_NUMBER() OVER (PARTITION BY sfc.LogID ORDER BY sfc.Date DESC) rn
FROM [BI_DB].[dbo].[BI_DB_SF_Cases] sfc WITH (NOLOCK)
WHERE sfc.Phase IN ('Phase 3','Phase 2','Complaint')
AND sfc.Source != 'Email'

)q0
WHERE q0.rn = 1