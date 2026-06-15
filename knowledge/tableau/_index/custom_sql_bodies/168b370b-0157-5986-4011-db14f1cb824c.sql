SELECT rlf.GCID
	  ,rlf.Country
	  ,rlf.Club
	  ,rlf.IsValidForFunnel
	  ,rlf.IsVerifiedFTD
	  ,rlf.IsVerifiedFTDPlus2Weeks
	  ,rlf.IsActiveMIMO
	  ,mda.RegCountry
	  ,mda.AccountProgram
	  ,rlf.IseMoneyAccount
	  ,rlf.IsFMI
	  ,rlf.IsFMO
	  ,rlf.IsCardCreated
	  ,rlf.IsCardActivated
	  ,rlf.IsCardFirstTx
	  ,IIF(fds.CID IS NOT NULL, 1, 0) AS 'IseMoneyActive'
FROM eMoney.dbo.eMoney_Reports_AcquisitionFunnel rlf WITH(NOLOCK)
LEFT JOIN eMoney.dbo.eMoney_Dim_Account mda WITH(NOLOCK) ON rlf.GCID = mda.GCID
LEFT JOIN eMoney.dbo.eMoney_Panel_FirstDates fds WITH(NOLOCK) ON mda.AccountID = fds.AccountID 
AND (fds.LastIBANSettledTXDate > DATEADD(MONTH, -3, EOMONTH(GETDATE())) OR fds.LastCardSettledTXDate > DATEADD(MONTH, -3, EOMONTH(GETDATE())))