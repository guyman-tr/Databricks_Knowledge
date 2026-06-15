SELECT 
      mdt.CID
    , mdt.TxType
    , mdt.TxTypeID
    , mdt.USDAmountApprox
    , mda.AccountSubProgramID
    , mda.AccountSubProgram
    , mda.Entity
    , mdt.TxLocalCountryNumericISO
    , mdt.ClubIDTxDate
    , mdt.ClubTxDate
    , mdt.TxStatusModificationDate
    , mdt.IsTxSettled
    , mdt.IsValidETM
    , mdt.CountryIDTxDate
    , mdt.CountryTxDate
    , mdt.TransactionID
	, case WHEN mda.AccountSubProgramID IN (13,14) THEN 'Australia' ELSE 'Denmark DKK' end AS 'Country (Based On SubProgram)' 
FROM eMoney_dbo.eMoney_Dim_Transaction mdt
JOIN eMoney_dbo.eMoney_Dim_Account mda 
     ON mdt.CID = mda.CID
WHERE mda.AccountSubProgramID IN (13,14,15,16)
  AND mda.GCID_Unique_Count = 1
  AND mda.IsValidETM = 1
  AND mda.IsTestAccount = 0
  AND mdt.IsValidETM = 1
  AND mdt.IsTxSettled = 1
  AND mdt.TxTypeID IN (5,6,7,8)