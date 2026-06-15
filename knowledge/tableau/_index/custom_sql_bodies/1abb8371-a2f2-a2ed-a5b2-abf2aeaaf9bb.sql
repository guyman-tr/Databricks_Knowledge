select right (etr_ymd,10)Date, 
[ID of the other counterparty],
Case when [ID of the other counterparty] = '8IBZUGJ7JPLH368JE346' then 'Goldman Sachs'
     when [ID of the other counterparty] = 'BFM8T61CT2L1QCEMIK50' then 'UBS' end as [LP],
[Pairing Status],
 [Matching Status], Count (1) [Count], Sum (ABS(cast(Notional as decimal (28,10)))) [Exposure], 
 Sum(ABS(cast ([Value of contract]as decimal (28,10)))) Valuation
from [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[TR_DTCC_Silver_DTCC_P02502132]
Where [Trade / Allege] = 'Trade'
 and ISNUMERIC([Notional]) =1 and ISNUMERIC([Value of contract]) =1
Group BY right (etr_ymd,10) , 
[ID of the other counterparty],[Pairing Status], [Matching Status]