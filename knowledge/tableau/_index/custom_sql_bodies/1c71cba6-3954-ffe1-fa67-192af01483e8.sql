select *
from BI_DB_dbo.BI_DB_Daily_Open_Closed_Position
where Date<=<[Parameters].[Parameter 3]> and Date>=dateadd(dd,-30,<[Parameters].[Parameter 3]>)