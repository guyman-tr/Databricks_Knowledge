select 
max('Yesterday') as date_pick,
Symbol, 
COUNT(*) numOfMentions
from 
BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] a
where cast(ActionDate as date) = (select distinct   max(cast(ActionDate as date))  
     from BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] )
GROUP BY Symbol

UNION ALL

select 
max('Last Week') as date_pick,
Symbol, 
COUNT(*) numOfMentions
from 
BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] a
where a.ActionDate BETWEEN 
                      (SELECT DATEADD(DAY,-7,Yesterday)  FROM 
                      (select distinct   max(cast(ActionDate as date))  Yesterday
                      from BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] ) a )
				  AND (select distinct   max(cast(ActionDate as date))  
                      from BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] )
GROUP BY Symbol

UNION ALL

select 
max('Last Two Weeks') as date_pick,
Symbol, 
COUNT(*) numOfMentions
from 
BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] a
where a.ActionDate BETWEEN 
                      (SELECT DATEADD(DAY,-14,Yesterday)  FROM 
                      (select distinct   max(cast(ActionDate as date))  Yesterday
                      from BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] ) a )
				  AND (select distinct   max(cast(ActionDate as date))  
                      from BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] )
GROUP BY Symbol

UNION ALL

select 
max('Last 30 Days') as date_pick,
Symbol, 
COUNT(*) numOfMentions
from 
BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] a
where a.ActionDate BETWEEN 
                      (SELECT DATEADD(DAY,-30,Yesterday)  FROM 
                      (select distinct   max(cast(ActionDate as date))  Yesterday
                      from BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] ) a )
				  AND (select distinct   max(cast(ActionDate as date))  
                      from BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] )
GROUP BY Symbol

UNION ALL

select 
max('Last 90 Days') as date_pick,
Symbol, 
COUNT(*) numOfMentions
from 
BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] a
where a.ActionDate BETWEEN 
                      (SELECT DATEADD(DAY,-90,Yesterday)  FROM 
                      (select distinct   max(cast(ActionDate as date))  Yesterday
                      from BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] ) a )
				  AND (select distinct   max(cast(ActionDate as date))  
                      from BI_DB.[dbo].[BI_DB_Social_Activity_Instrument_Feed] )GROUP BY Symbol