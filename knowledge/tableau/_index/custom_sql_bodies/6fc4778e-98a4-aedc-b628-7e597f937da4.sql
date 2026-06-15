select CID, max(Occurred) CLDate
from  [AZR-W-REAL-DB-2-BIDBUser].[etoro].BackOffice.Bonus
where BonusTypeID = 71
and CID not in (select CID from [AZR-W-REAL-DB-2-BIDBUser].[etoro].[Trade].[BSLBlackList])
group by CID