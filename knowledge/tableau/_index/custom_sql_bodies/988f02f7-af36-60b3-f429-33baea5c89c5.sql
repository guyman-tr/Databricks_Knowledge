SELECT dd.FullDate
      ,b.CID AS 'CC_Activated_CID'
	  ,a.CID AS 'Tx_CID'
FROM DWH_dbo.Dim_Date dd WITH(NOLOCK)

LEFT JOIN(
SELECT CAST(mpfd.CardActivationTime AS DATE) AS 'CardActivationDATE'
      ,mpfd.CID
FROM eMoney_dbo.eMoney_Panel_FirstDates mpfd WITH(NOLOCK)
WHERE mpfd.CardActivationTime IS NOT NULL) b ON b.CardActivationDATE=dd.FullDate

LEFT JOIN(
SELECT mdt.TxLocalDate
	  ,mdt.CID
FROM eMoney_dbo.eMoney_Dim_Transaction mdt WITH(NOLOCK)
WHERE mdt.IsValidETM = 1
      AND mdt.TxLocalDateID >= 20201111
	  AND mdt.TxStatusID IN (1, 2)
	  AND mdt.TxTypeID IN (1, 2, 3, 4)
GROUP BY mdt.TxLocalDate
	    ,mdt.CID
) a ON a.TxLocalDate = dd.FullDate

WHERE dd.DateKey >= 20201111 AND dd.FullDate <= GETDATE()