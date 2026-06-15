select  *
from BI_DB_First5Actions
where datediff (year,  cast (FirstDepositDate as date) , cast (getdate() as date))<=2