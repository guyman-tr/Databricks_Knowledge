SELECT CID, VerificationLevel2Date FROM BI_DB.dbo.BI_DB_CIDFirstDates bdcd
WHERE bdcd.VerificationLevel2Date>=dateadd(month,-5,dateadd(month,datediff(month,0,getdate()),0))