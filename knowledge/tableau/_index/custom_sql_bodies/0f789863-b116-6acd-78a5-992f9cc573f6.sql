select * from bi_output.bi_output_Finance_Tables_BI_DB_Sharelending_CollateralDetailesUK
where etr_ymd >=<[Parameters].[Parameter 1 1]>
and etr_ymd <=<[Parameters].[Parameter 2 1]>