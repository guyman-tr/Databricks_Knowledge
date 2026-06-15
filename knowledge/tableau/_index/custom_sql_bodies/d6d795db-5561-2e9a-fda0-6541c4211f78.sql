select InstrumentType,
HedgeServerID, 
avg(NOP) [Last6Months_AVG_LPNOP]
 from BI_DB..BI_DB_NOP_LPandClients
where TranType='LP'
and Datediff(day,Date,getdate())<=180
group by 
InstrumentType,
HedgeServerID