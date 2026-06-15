select max(OpenDDate) latest_date, 'Account Opened' as date_cat from main.general.bronze_sodreconciliation_apex_ext765_accountmaster 

union

select max(ProcessDate) latest_date, 'Apex FTD' as date_cat from main.finance.bronze_sodreconciliation_apex_ext869_cashactivity 
where PayTypeCode = 'C' 
      AND EnteredBy IN ('ACH','WRD')

union

select max(ProcessDate) latest_date, 'Apex FA' as date_cat from main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity 
--where RegisteredRepCode='UK1'