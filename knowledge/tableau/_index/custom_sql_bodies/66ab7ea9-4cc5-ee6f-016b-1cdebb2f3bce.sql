SELECT sub1.Users
	  ,sub1.Positions
	  ,sub1.RedeemUnits
	  ,sub1.RedeemUSD
	  ,sub1.PeriodEnd
	  ,sub1.PeriodStart
	  ,sub1.CryptoName
	  ,sub2.[Users Since 13Sep23]
	  ,sub2.[Positions Since 13Sep23]
	  ,sub2.[Redeem Units Since 13Sep23]
	  ,sub2.[Redeem USD Since 13Sep23]
	   FROM 
(

SELECT 
    COUNT(DISTINCT efrr.[Wallet - RequestingGCID])Users
  , COUNT(efrr.PositionID) Positions
   ,SUM(efrr.[etoro - RedeemAmount]) RedeemUnits
  , SUM(efrr.[etoro - Amount] )RedeemUSD
  , DATEADD(dd, 6-(DATEPART(dw,CAST(efrr.[etoro - ModificationDate] AS DATE))),  CAST(efrr.[etoro - ModificationDate] AS DATE)) PeriodEnd
  , DATEADD(dd, -(DATEPART(dw, CAST(efrr.[etoro - ModificationDate] AS DATE)) ),  CAST(efrr.[etoro - ModificationDate] AS DATE))  PeriodStart
  , efrr.CryptoName
 FROM EXW.dbo.EXW_FactRedeemReconciliation efrr 
 JOIN EXW.dbo.EXW_DimUser edu ON edu.GCID =efrr.[Wallet - RequestingGCID]
 WHERE efrr.EntryAppears ='BothSidesEntry'
 AND CAST(efrr.[etoro - ModificationDate] AS DATE)>CAST(GETDATE()-60 AS DATE) 
 AND efrr.[etoro - RedeemStatus]='TransactionDone'
 AND edu.CountryID =79
 AND edu.IsValidCustomer =1 AND edu.IsTestAccount =0
 GROUP BY 
    DATEADD(dd, 6-(DATEPART(dw,CAST(efrr.[etoro - ModificationDate] AS DATE))),  CAST(efrr.[etoro - ModificationDate] AS DATE))  
  , DATEADD(dd, -(DATEPART(dw, CAST(efrr.[etoro - ModificationDate] AS DATE)) ),  CAST(efrr.[etoro - ModificationDate] AS DATE))
  , efrr.CryptoName
  ) sub1
  JOIN 
  (
  SELECT 
    COUNT(DISTINCT efrr.[Wallet - RequestingGCID])[Users Since 13Sep23]
  , COUNT(efrr.PositionID) [Positions Since 13Sep23]
   ,SUM(efrr.[etoro - RedeemAmount]) [Redeem Units Since 13Sep23]
  , SUM(efrr.[etoro - Amount] )[Redeem USD Since 13Sep23]
  , efrr.CryptoName
 FROM EXW.dbo.EXW_FactRedeemReconciliation efrr 
 JOIN EXW.dbo.EXW_DimUser edu ON edu.GCID =efrr.[Wallet - RequestingGCID]
 WHERE efrr.EntryAppears ='BothSidesEntry'
 AND efrr.[etoro - ModificationDateID] >=20230913
 AND efrr.[etoro - RedeemStatus]='TransactionDone'
 AND edu.CountryID =79
 AND edu.IsValidCustomer =1 AND edu.IsTestAccount =0
 GROUP BY 
     efrr.CryptoName) sub2 ON sub1.CryptoName =sub2.CryptoName