select * 
from main.bi_output.bi_output_customer_investment_capital_guarantee_capital_guarantee_q42024_global
where DateID = (select max(DateID) 
from main.bi_output.bi_output_customer_investment_capital_guarantee_capital_guarantee_q42024_global
 where dateid <= cast(date_format(current_date() - interval 1 day, 'yyyyMMdd') as int))
and isvalidcustomer=1