select  ini.toAccountId,ini.assetId, cast(ini.value as decimal(15,6))-cast(day1.value as decimal(15,6)) [availableBalance]
from TanganyDailyTransactions day1
join [TanganyInitialBalance] ini
on day1.fromAccountId=ini.toAccountId
and day1.assetId=ini.assetId