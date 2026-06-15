SELECT *, CAST(CONCAT(YearMonth,'-','01') AS DATE) AS date 
From [BI_DB].python.[BI_DB_BigQueryGADataMonthly]