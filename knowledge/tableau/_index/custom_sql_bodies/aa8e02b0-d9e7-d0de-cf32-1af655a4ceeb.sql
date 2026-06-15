SELECT cast('20200630' as Date)Date,di.InstrumentDisplayName,br.InstrumentID, SUM(br.Units* a.Bid) Redeem
FROM  [AZR-W-REAL-DB-2-BIDBUser].etoro.Billing.Redeem br 
join 
DWH..Dim_Instrument di
on br.InstrumentID=di.InstrumentID
JOIN
(
SELECT  
        InstrumentID  
       ,Ask  
       ,Bid  
      
FROM DWH.dbo.Fact_CurrencyPriceWithSplit a
WHERE InstrumentID>=100000
AND OccurredDateID =20200630
)a
ON a.InstrumentID=br.InstrumentID
WHERE RedeemStatusID=8 
AND br.InstrumentID>=100000 
AND br.LastModificationDate<'20200701'
GROUP BY di.InstrumentDisplayName,br.InstrumentID