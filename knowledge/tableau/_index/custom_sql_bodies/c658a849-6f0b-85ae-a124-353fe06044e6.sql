select 
  c.Year
  ,c.Month
  ,c.Category
  ,c.Amount
from  
  main.bi_output_stg.bi_output_operations_cost_import_file c
WHERE 
  c.Category in (
'Trulioo Global',
'Trulioo USA',
'GBG (USD Converted)',
'Melissa',
'DataZoo2',
'IDMerit','Prove')