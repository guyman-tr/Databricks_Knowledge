SELECT dc.GCID
      ,dc.RealCID
      ,dc.AffiliateID
      ,dc1.Name AS Country
      ,bb.InstrumentType
      ,bb.TradeAmount
      ,dc.FunnelFromID
      ,dc.FirstDepositAmount
      ,dc.VerificationLevelID
      ,dd.CompensationCategory
      ,dd.CompensationAmount
      ,cc.DepositAmount
      ,CAST(dc.FirstDepositDate AS DATE) AS FirstDepositDate
      ,CAST(dc.RegisteredReal AS DATE) AS RegistrationDate
      ,dc2.Channel
      ,dc2.SubChannel
      ,dps.IsBlocked
      ,fca.Amount AS CO
      ,fca1.Amount AS RAF
	  ,dr.Name AS Regulation
FROM DWH_dbo.Dim_Customer dc WITH (NOLOCK)
LEFT JOIN DWH_dbo.Fact_CustomerAction AS fca WITH (NOLOCK) ON dc.RealCID = fca.RealCID AND fca.ActionTypeID = 8 AND fca.DateID > 20230101
JOIN DWH_dbo.Dim_Country AS dc1 WITH (NOLOCK) ON dc.CountryID = dc1.CountryID
JOIN DWH_dbo.Dim_Regulation dr ON dc.RegulationID = dr.ID
LEFT JOIN DWH_dbo.Fact_CustomerAction fca1 WITH (NOLOCK) ON dc.RealCID = fca1.RealCID AND fca1.ActionTypeID = 36 AND fca1.DateID > 20230101 AND fca1.CompensationReasonID = 53
JOIN DWH_dbo.Dim_Channel AS dc2 WITH (NOLOCK) ON dc.SubChannelID = dc2.SubChannelID AND dc2.SubChannelID IN (20,21,31,44,41,42,39,40,4,5,11,22,32,33,34,35,36,37,38,45)
JOIN DWH_dbo.Dim_PlayerStatus AS dps WITH (NOLOCK) ON dc.PlayerStatusID = dps.PlayerStatusID
LEFT JOIN( SELECT aa.RealCID AS CID,
                  di.InstrumentType,
                  SUM(dp.Amount) AS TradeAmount
            FROM DWH_dbo.Dim_Customer AS aa WITH (NOLOCK)
            INNER JOIN DWH_dbo.Dim_Position AS dp WITH (NOLOCK) ON dp.CID = aa.RealCID
            LEFT JOIN DWH_dbo.Dim_Instrument AS di WITH (NOLOCK) ON dp.InstrumentID = di.InstrumentID
            WHERE  dp.OpenOccurred >= '2023-01-01'
                AND aa.FirstDepositDate >= '2023-01-01'
                AND aa.IsValidCustomer = 1
                AND IsDepositor = 1
                AND dp.IsSettled = 1
                AND dp.IsBuy =1 
                AND aa.SubChannelID IN (20,21,31,44,41,42,39,40,4,5,11,22,32,33,34,35,36,37,38,45)
                AND di.InstrumentType = 'Crypto Currencies' 
            GROUP BY  aa.RealCID, di.InstrumentType) bb ON bb.CID = dc.RealCID
LEFT JOIN (    SELECT fca.RealCID CID
                  ,SUM(Amount) AS DepositAmount 
            FROM DWH_dbo.Fact_CustomerAction fca WITH (NOLOCK)
            JOIN DWH_dbo.Dim_Customer  aa WITH (NOLOCK) ON aa.RealCID = fca.RealCID
            WHERE ActionTypeID = 7
                AND IsValidCustomer = 1
                AND IsDepositor = 1
                AND aa.SubChannelID IN (20,21,31,44,41,42,39,40,4,5,11,22,32,33,34,35,36,37,38,45)
                AND CAST(aa.FirstDepositDate AS DATE) >='2023-01-01'
            GROUP BY  fca.RealCID) AS cc ON cc.CID=dc.RealCID
LEFT JOIN ( SELECT fca.RealCID CID
                 ,a.Name AS CompensationCategory
                 ,SUM(Amount) AS CompensationAmount
            FROM DWH_dbo.Fact_CustomerAction AS fca WITH (NOLOCK)
            JOIN DWH_dbo.Dim_Customer AS aa WITH (NOLOCK) ON aa.RealCID = fca.RealCID
            JOIN DWH_dbo.Dim_CompensationReason AS a WITH (NOLOCK) ON a.CompensationReasonID=fca.CompensationReasonID
            WHERE ActionTypeID = 36
                AND IsValidCustomer = 1
                AND IsDepositor = 1
                AND aa.SubChannelID IN (20,21,31,44,41,42,39,40,4,5,11,22,32,33,34,35,36,37,38,45)
                AND fca.CompensationReasonID=20
                AND CAST(aa.FirstDepositDate AS DATE) >='2023-01-01'
            GROUP BY  fca.RealCID,a.Name) AS dd ON dd.CID = dc.RealCID
WHERE CAST(dc.FirstDepositDate AS DATE) >='2023-01-01'
      AND ((dc.FunnelFromID IN (66,69,62,60) AND dc.CountryID <> 217) OR (dc.AffiliateID IN (122042,122044,122045) AND dc.CountryID IN (217,12)))
      AND dc.IsValidCustomer=1
	  AND dc.CountryID IN (12,217,219)
	  AND YEAR(dc.RegisteredReal) >= 2023