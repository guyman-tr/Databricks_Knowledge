with cte as (
select *,
split(replace(CAST(cast(History_Price_Rate as FLOAT) as varchar(120)), '.', "a"), "a")[0] as PreDecimal,
split(replace(CAST(cast(History_Price_Rate as FLOAT) as varchar(120)), '.', "a"), "a")[1] as PostDecimal
from main.dealing.bi_output_dealing_bestexecution_report
),

cte2 as (
select *, 
LEN(CAST(PostDecimal AS VARCHAR(100))) AS digit_count
from cte),

cte3 as (
select *,
cast(PreDecimal as FLOAT) + cast(substring(PostDecimal, 1, digit_count) as FLOAT)/(power(10,digit_count)) AS History_Price_Rate_Rounded
from cte2
),


cte4 as (
select *,
(CASE WHEN IsOpen=0 THEN
       CASE WHEN IsBuy = 1 THEN 1 ELSE -1 END
     ELSE --IsOpen=1
       CASE WHEN IsBuy = 1 THEN -1 ELSE 1 END
END)*(ROUND(History_Price_Rate_Rounded, 4) - ForexRate) * AmountInUnitsDecimal * ConversionRate AS SlippageInDollar_Rounded
from cte3)


select *
from cte4