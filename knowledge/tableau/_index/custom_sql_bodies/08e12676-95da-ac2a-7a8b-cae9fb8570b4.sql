SELECT bddcdr.* ,dd.FullDate,di.CUSIP
FROM BI_DB_Daily_CID_Dividend_TaxReport bddcdr
INNER JOIN DWH..Dim_Instrument di 
    ON di.InstrumentID=bddcdr.InstrumentID
INNER JOIN DWH..Dim_Date dd
    ON dd.FullDate = bddcdr.PaymentDate
where bddcdr.PaymentDate>='2020-01-01' AND bddcdr.RealCID=<[Parameters].[Parameter 2]>