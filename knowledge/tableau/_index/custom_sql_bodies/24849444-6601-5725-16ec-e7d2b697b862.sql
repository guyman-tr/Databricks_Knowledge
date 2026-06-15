SELECT
	c.CID
	,c.AlertID
	,c.StatusType
	,c.StatusReason
	,c.CreationDate
	,c.RequestDate as CO_RequestDate
	,i.IP
	,i.CountryIDByIP
	,case when ri.AlertID is null then 'No' else 'Yes' end as 'Same IP used in the account with more than 7 days prior to the CO request'
	,case when p.AlertID is null then 'No' else 'Yes' end as 'Phone number change in the account 7 days prior to the Cashout request'
	,p.PhoneChangeDate
	,case when e.AlertID is null then 'No' else 'Yes' end as 'Email change in the account 72 H prior to the Cashout request'
	,e.EmailChangeDate
	,case when l.AlertID is null then 'No' else 'Yes' end as 'Language change in the account 72 H prior to the Cashout request'
	,l.LanguageChangeDate
	,case when l2.AlertID is null then 'No' else 'Yes' end as 'Communication Language change in the account 72 H prior to the Cashout request'
	,l2.CommunicationLanguageChangeDate
FROM 
	#cids c
LEFT JOIN 
	#phonechange7days p on p.AlertID = c.AlertID and p.RowNum = 1
LEFT JOIN 
	#emailchange3days e on e.AlertID = c.AlertID and e.RowNum = 1
LEFT JOIN 
	#languagechange3days l on l.AlertID = c.AlertID and l.RowNum = 1
LEFT JOIN 
	#commlanguagechange3days l2 on l2.AlertID = c.AlertID and l2.RowNum = 1
LEFT JOIN 
	#IP i on i.AlertID = c.AlertID and i.RN = 1
LEFT JOIN 
	#RepeatedIPs ri on ri.AlertID = c.AlertID