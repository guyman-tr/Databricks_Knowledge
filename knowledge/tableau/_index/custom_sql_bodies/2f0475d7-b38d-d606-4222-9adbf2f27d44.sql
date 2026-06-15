SELECT                    
EOMONTH (Occurred) AS 'Date'    
,YEAR(Occurred) * 100 + MONTH(Occurred) AS Year_Month
,CASE
WHEN InstrumentTypeID IN (10) THEN 'Crypto'
ELSE 'ECC'
END AS InstrumentGroup
,InstrumentType
,CASE WHEN ActionTypeID IN (1,4,39,40) THEN  'Manual' 
WHEN ActionTypeID IN (44,45) THEN 'IBAN' ELSE 'Copy' END AS 'ActionType'
,SUM (CASE WHEN ActionTypeID IN (1,2,3,39,4,5,6,28,40) THEN 1 ELSE 0 end ) TotalTrades
,SUM(CASE WHEN ActionTypeID IN (1,2,3,39) THEN -1 * fca.Amount WHEN ActionTypeID IN  (4,5,6,28,40) THEN   fca.Amount ELSE 0 END) AS  InvestedAmount
,SUM(CASE WHEN ActionTypeID IN (44,45) THEN ABS(fca.Amount) ELSE 0 end) Trade_from_IBAN_Amount
,CAST(GETDATE() AS DATE) AS LoadDate
FROM DWH_dbo.Fact_CustomerAction fca    
INNER JOIN DWH_dbo.Fact_SnapshotCustomer fsc WITH (NOLOCK)
ON fca.RealCID = fsc.RealCID
INNER JOIN DWH_dbo.Dim_Range dr WITH (NOLOCK)
ON fsc.DateRangeID = dr.DateRangeID
AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID    
JOIN DWH_dbo.Dim_Instrument di                    
ON di.InstrumentID=fca.InstrumentID    
WHERE                    
DateID>=20220101                    
AND DateID<= CAST(FORMAT( GETDATE()-1, 'yyyyMMdd') AS INT)
AND fsc.IsValidCustomer = 1    
AND ActionTypeID IN (1,2,3,39,4,5,6,28,40,44,45)        
GROUP BY                    
YEAR(Occurred) * 100 + MONTH(Occurred) 
,EOMONTH (Occurred)    
,CASE
WHEN InstrumentTypeID IN (10) THEN 'Crypto'
ELSE 'ECC'
END
,InstrumentType
,CASE WHEN ActionTypeID IN (1,4,39,40) THEN  'Manual' 
WHEN ActionTypeID IN (44,45) THEN 'IBAN' ELSE 'Copy' END