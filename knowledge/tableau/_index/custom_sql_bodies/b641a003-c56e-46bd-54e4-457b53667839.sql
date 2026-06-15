SELECT CID
       ,NewLevel
       ,DaysToCurrentClubFromFTD
FROM
(
 SELECT ccl.CID
       ,ccl.NewLevel
	   ,DATEDIFF(DAY,fd.FirstDepositDate,ccl.CreateDate) DaysToCurrentClubFromFTD
	   ,ROW_NUMBER() OVER (PARTITION BY ccl.CID,ccl.NewLevel ORDER BY ccl.CreateDate ) rn 
 FROM [BI_DB].[dbo].[BI_DB_ClubChangeLog] ccl WITH (NOLOCK)
 INNER JOIN [BI_DB].[dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)
 ON ccl.CID = fd.CID
 WHERE ccl.NewSort >1
 )q0
 WHERE rn = 1