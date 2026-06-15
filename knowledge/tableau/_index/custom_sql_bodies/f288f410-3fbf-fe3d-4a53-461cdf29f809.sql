SELECT distinct ma.*,
ea.NumberOfIbans,
ecb.eMoneyBalanceUSD
from BI_DB_dbo.BI_DB_OPS_MultipleAccounts ma
left join #eMoneyactive ea on ea.CID=ma.CID
left join #eMoneyCB  ecb on ecb.CID=ma.CID