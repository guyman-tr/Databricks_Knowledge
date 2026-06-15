SELECT ftp.GCID,
		ftp.RealCID,
		dc.RegisteredReal,
		dc.FirstDepositDate,
		ftp.PopUpsCount, 
		ftp.FirstInteractionDate, 
		ftp.LastInteractionDate,
		ftp.HasCompletedFTP,
	    ftp.CompletionFTPDate,
		MAX(CASE WHEN ISNULL(dp.PositionID,0)<>0 THEN 1 ELSE 0 END) AS 'HadOpenedCFD_AfterLastPopup',
		MIN(CASE WHEN ISNULL(dp.PositionID,0)<>0 THEN dp.OpenOccurred ELSE NULL END) AS 'FirstOpenOccuredCFD_AfterLastPopup',
		DATEDIFF(DAY,ftp.FirstInteractionDate,ftp.LastInteractionDate) as 'DaysFromFirstToLast'
FROM BI_DB_dbo.BI_DB_ApproperiatenessTest_FTP_CID_Level ftp
LEFT JOIN DWH_dbo.Dim_Customer dc ON ftp.GCID=dc.GCID
LEFT JOIN DWH_dbo.Dim_Position dp ON dc.RealCID=dp.CID AND ISNULL(dp.IsSettledOnOpen,dp.IsSettled)=0 AND dp.OpenOccurred>=ftp.LastInteractionDate
WHERE dc.FirstDepositDate>='2022-11-01'
GROUP BY ftp.GCID,
		ftp.RealCID,
		dc.RegisteredReal,
		dc.FirstDepositDate,
		ftp.PopUpsCount, 
		ftp.FirstInteractionDate, 
		ftp.LastInteractionDate,
		ftp.HasCompletedFTP,
	    ftp.CompletionFTPDate,
		DATEDIFF(DAY,ftp.FirstInteractionDate,ftp.LastInteractionDate)