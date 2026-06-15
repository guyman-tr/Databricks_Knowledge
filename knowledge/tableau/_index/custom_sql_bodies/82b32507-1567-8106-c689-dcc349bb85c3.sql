SELECT mdt.AccountID
      ,mdt.TransactionID
	  ,mdt.TxStatusModificationTime
	  ,mdt.TxStatusModificationDate
	  ,mdt.TxLocalTime
	  ,mdt.TxLocalDate
	  ,mdt.TxTypeID
	  ,mdt.TxType
	  ,mdt.USDAmountApprox
	  ,mdt.CID
	  ,mdt.ClubTxDate AS Club
	  ,mdt.CountryTxDate AS Country
	  ,CASE WHEN LEFT (p.ExReferenceID,2) = 'TZ' THEN 'Volt'
	   WHEN LEFT (p.ExReferenceID,2) = 'TK' THEN 'Tink'
	   ELSE 'Other' END
	   AS Platform_
FROM eMoney_dbo.eMoney_Dim_Transaction mdt WITH(NOLOCK)
INNER JOIN BI_DB_dbo.External_MoneyTransfer_Billing_Transfers p  ON LOWER(p.ExReferenceID)=LOWER(mdt.ReferenceNumber) AND p.TransferStatusID=10
INNER JOIN eMoney_dbo.eMoney_Dim_Account mda WITH(NOLOCK) ON mda.CID=mdt.CID AND mda.IsValidETM=1 AND mda.GCID_Unique_Count=1
WHERE mdt.TxStatusID = 2
      AND mdt.TxTypeID = 7
      AND mdt.HolderAmount <> 0
	  AND mdt.TxStatusModificationDateID>=20241201