select 'Close' as Type,Sum(Commission) as Commission,max(OpenOccurred) as LastTime
from [AZR-W-REAL-DB-2-BIDBUser].etoro.History.Position
where OpenOccurred>cast(getdate() as date)
and CID not in (select CID from [AZR-W-REAL-DB-2-BIDBUser].etoro.Customer.Customer where PlayerLevelID=4)
union all
select 'Open' as Type,Sum(Commission) as Commission,max(Occurred) as LastTime
from [AZR-W-REAL-DB-2-BIDBUser].etoro.Trade.Position
where Occurred>cast(getdate() as date)
and CID not in (select CID from [AZR-W-REAL-DB-2-BIDBUser].etoro.Customer.Customer where PlayerLevelID=4)
union all
select 'Deposit' as Type,sum(Payment) as Commission,max(Occurred) as LastTime
from [AZR-W-REAL-DB-2-BIDBUser].etoro.History.Credit
where Occurred>cast(getdate() as date) 
and CreditTypeID=1