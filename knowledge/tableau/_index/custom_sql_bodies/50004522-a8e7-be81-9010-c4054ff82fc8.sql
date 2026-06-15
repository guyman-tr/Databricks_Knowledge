SELECT mda.GCID, mda.CurrencyBalanceID, mda.AccountSubProgram, mda.BankAccountIBAN, mda.BankAccountBIC, mda.BankAccountSortCode, mda.AccountCreateDate
from eMoney_dbo.eMoney_Dim_Account mda
WHERE mda.GCID_Unique_Count=1 AND mda.IsValidETM=1