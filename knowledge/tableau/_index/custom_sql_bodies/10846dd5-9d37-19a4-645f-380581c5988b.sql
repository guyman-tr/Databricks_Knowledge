SELECT 'Incoming' TicketStatus
      ,sfc.Source
      ,CONVERT(DATE,sfc.Date) TicketDate
      ,sfc.Phase
	  ,COUNT(*) IncomingTicket
FROM [BI_DB].[dbo].[BI_DB_SF_Cases] sfc WITH (NOLOCK)
WHERE sfc.TicketStatus = 'created'
AND sfc.Source != 'Email'
GROUP BY CONVERT(DATE,sfc.Date),sfc.Phase,sfc.Source

union

SELECT 'Solved' TicketStatus
      ,sfc.Source
      ,CONVERT(DATE,sfc.Date) TicketDate
      ,sfc.Phase
	  ,COUNT(*) IncomingTicket
FROM [BI_DB].[dbo].[BI_DB_SF_Cases] sfc WITH (NOLOCK)
WHERE sfc.TicketStatus = 'Solved'
AND sfc.Source != 'Email'
GROUP BY CONVERT(DATE,sfc.Date),sfc.Phase,sfc.Source