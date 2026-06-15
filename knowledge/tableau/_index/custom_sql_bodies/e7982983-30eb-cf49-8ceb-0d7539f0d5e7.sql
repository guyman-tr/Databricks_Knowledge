SELECT sfc.Date Date
      ,sfc.CaseNumber CaseNumber
	  ,sfc.CID CID
      ,CASE WHEN sfc.ActionType IN ('Deposit','Deposits') THEN 'Deposits' ELSE sfc.ActionType END TicketType
FROM [BI_DB].[dbo].[BI_DB_SF_Cases_New] sfc WITH (NOLOCK)
WHERE sfc.DateID >=20210101
AND sfc.ActionType IN ('Withdrawal','Deposit','Deposits')
AND sfc.TicketStatus =  'created'