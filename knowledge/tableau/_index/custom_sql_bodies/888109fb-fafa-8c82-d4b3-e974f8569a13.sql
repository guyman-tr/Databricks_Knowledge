SELECT 
    a.Gcid,
	mda.CID,
    d.CardStatus,
    c.CardId,
    c.Id,
    c.EventTimestamp,
    c.Created,
    c.partition_date,
    c.CardStatusId,
c.CardInstanceId
FROM eMoney_dbo.FiatAccount a
INNER JOIN eMoney_dbo.FiatCards b 
    ON a.Id = b.AccountId
INNER JOIN eMoney_dbo.FiatCardStatuses c 
    ON b.Id = c.CardId
INNER JOIN eMoney_dbo.eMoney_Dictionary_CardStatus d 
    ON c.CardStatusId = d.CardStatusID
INNER join eMoney_dbo.eMoney_Dim_Account mda ON a.Gcid=mda.GCID AND mda.GCID_Unique_Count=1 and mda.IsValidETM=1