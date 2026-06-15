SELECT *
 FROM 
  main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation
where ReportDate >=<[Parameters].[Min Date for Report (copy) (copy)_1956251092966563847]>
and ReportDate <=<[Parameters].[MaxDateForReport (copy) (copy)_1956251092965957637]>