SELECT *
FROM BI_DB.python.BI_DB_BigQueryGADataWeekly bdbqgw 
--WHERE bdbqgw.StartWeek<=(CAST((GETDATE()-5) AS DATE))