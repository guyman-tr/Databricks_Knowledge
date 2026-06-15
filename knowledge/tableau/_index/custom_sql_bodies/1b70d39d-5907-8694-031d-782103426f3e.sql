SELECT mdt.CID, mdt.TxType, mdt.TxTypeID, mdt.USDAmountApprox, mda.AccountSubProgramID, mda.AccountSubProgram, mda.Entity,
mdt.TxLocalCountryNumericISO, mdt.ClubIDTxDate, mdt.ClubTxDate, mdt.TxStatusModificationDate, mdt.IsTxSettled, mdt.IsValidETM
, mdt.CountryIDTxDate, mdt.CountryTxDate, mdt.TransactionID
from eMoney_dbo.eMoney_Dim_Transaction mdt
join eMoney_dbo.eMoney_Dim_Account mda on mdt.CID = mda.CID 
WHERE  mda.AccountSubProgramID IN (13,14)  AND mda.GCID_Unique_Count=1 AND mda.IsValidETM=1 
AND  mdt.IsValidETM=1 and mdt.IsTxSettled=1 AND mda.IsTestAccount=0 
and mdt.TxTypeID IN (5,6,7,8)