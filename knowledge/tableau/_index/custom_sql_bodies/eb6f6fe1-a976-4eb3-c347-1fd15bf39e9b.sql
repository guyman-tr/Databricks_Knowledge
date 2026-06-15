select  
        
        pos.InitialAmountCents/100 as Amount,
        pos.CID,
        pos.OpenOccurred,
        pos.CloseOccurred ,
        CASE WHEN pos.CloseDateID=0 THEN 1 ELSE 0 END AS IsOpen,
        inst.SymbolFull,
        inst.InstrumentDisplayName,
        inst.Exchange,
        --pos.Currency,
        pos.IsBuy,
        pos.IsSettled

        
from   DWH_dbo.Dim_Position     as pos 
inner join  DWH_dbo.Dim_Instrument as inst
on inst.InstrumentID = pos.InstrumentID
inner join DWH_dbo.Dim_Customer as dm
on dm.RealCID=pos.CID AND dm.IsValidCustomer=1

WHERE  pos.OpenDateID >= '20240101'

and isnull(pos.IsPartialCloseChild,0) = 0 
and pos.MirrorID = 0 
and inst.SymbolFull in 
(
'SPY',
'SPY.EXT',
'IVV',
'VOO',
'CSP1.L',
'SXR8.DE',
'IUSA.L',
'SPY5.L',
'SPYU',
'SPXS',
'SPXL',
'SH',
'SSO',
'UPRO',
'SPXU',
'SDS',
'DXS3.DE',
'RSP',
'SPX500'
)