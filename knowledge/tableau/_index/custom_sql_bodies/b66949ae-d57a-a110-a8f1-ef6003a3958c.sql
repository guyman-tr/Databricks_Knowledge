select Date,
case when ActionType='Copy' then 'Copy' else 'Manual' end as Copy_Manual,
Regulation,
count(*) as NumberOfTransactions
from main.dealing.bi_output_dealing_bestexecution_report
group by Date,
case when ActionType='Copy' then 'Copy' else 'Manual' end,
Regulation