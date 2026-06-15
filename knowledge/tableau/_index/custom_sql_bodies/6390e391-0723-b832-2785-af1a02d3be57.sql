SELECT a.*
        ,di.InstrumentDisplayName
FROM [AZR-N-REAL-DB-3-BIDBUser].etoro.Trade.PositionAirdropLog a
LEFT JOIN DWH..Dim_Instrument di
on di.InstrumentID = a.InstrumentID
where RequestOccurred >= '2022-03-01'