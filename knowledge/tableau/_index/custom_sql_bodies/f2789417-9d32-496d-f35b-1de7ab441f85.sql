SELECT
       mdt.HolderCurrencyDesc                            AS Currency
      ,mda.Country
      ,mda.ClubCategory
      ,CASE 
    WHEN fca.ActionTypeID = 8 THEN 'To IBAN'
    WHEN fca.ActionTypeID = 7 THEN 'From IBAN' ELSE 'Other' 
END AS Direction
      

      ,SUM(CASE WHEN CAST(fca.Occurred AS DATE) >= CAST(GETDATE()-1  AS DATE) THEN 1 ELSE 0 END)  AS [Last 1 Day TXs]
      ,SUM(CASE WHEN CAST(fca.Occurred AS DATE) >= CAST(GETDATE()-7  AS DATE) THEN 1 ELSE 0 END)  AS [Last 7 Days TXs]
      ,SUM(CASE WHEN CAST(fca.Occurred AS DATE) >= CAST(GETDATE()-30 AS DATE) THEN 1 ELSE 0 END)  AS [Last 30 Days TXs]
      ,SUM(CASE WHEN CAST(fca.Occurred AS DATE) >= CAST(GETDATE()-365 AS DATE) THEN 1 ELSE 0 END) AS [Last 365 Days TXs]

      ,SUM(CASE WHEN CAST(fca.Occurred AS DATE) >= CAST(GETDATE()-1  AS DATE) THEN fca.Amount ELSE 0 END)  AS [Last 1 Day Amount]
      ,SUM(CASE WHEN CAST(fca.Occurred AS DATE) >= CAST(GETDATE()-7  AS DATE) THEN fca.Amount ELSE 0 END)  AS [Last 7 Days Amount]
      ,SUM(CASE WHEN CAST(fca.Occurred AS DATE) >= CAST(GETDATE()-30 AS DATE) THEN fca.Amount ELSE 0 END)  AS [Last 30 Days Amount]
      ,SUM(CASE WHEN CAST(fca.Occurred AS DATE) >= CAST(GETDATE()-365 AS DATE) THEN fca.Amount ELSE 0 END) AS [Last 365 Days Amount]

FROM DWH_dbo.Fact_CustomerAction fca

INNER JOIN eMoney_dbo.eMoney_Dim_Account mda 
       ON fca.GCID = mda.GCID

	   INNER JOIN 
	   (
SELECT max(s.HolderCurrencyDesc) AS HolderCurrencyDesc, s.CID AS CID 
from eMoney_dbo.eMoney_Dim_Transaction s
group BY s.CID
) mdt  ON fca.RealCID=mdt.CID
WHERE fca.ActionTypeID IN (7,8)
  AND fca.MoveMoneyReasonID = 6
  AND mda.IsValidETM = 1
  AND fca.FundingTypeID = 33

GROUP BY
        mdt.HolderCurrencyDesc 
      ,mda.Country
      ,mda.ClubCategory
      ,CASE 
    WHEN fca.ActionTypeID = 8 THEN 'To IBAN'
    WHEN fca.ActionTypeID = 7 THEN 'From IBAN'
            ELSE 'Other'
       END