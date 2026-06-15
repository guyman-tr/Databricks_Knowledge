SELECT a.Date,
       a.HedgeServerID,
       a.Copy,
       a.InstrumentID,
       b.Name as InstrumentName,
       b.InstrumentTypeID,
       a.RiskIndex,
       a.TreeSize_Units as Size,
       sum(RealizedCommission) as RealizedCommission,
       sum(RealizedZero) as RealizedZero,
       sum(ChangeInUnrealizedZero) as ChangeInUnrealizedZero,
       sum(TotalZero) as TotalZero,
       sum(NOP) as NOP,
       sum(OpenPositions) as OpenPositions,
       sum(Nop_Units) as Nop_Units
FROM [dbo].[BI_DB_DailyZero_TreeSize_NEW] a
left join DWH.dbo.Dim_Instrument b
on a.InstrumentID=b.InstrumentID
Group by a.Date,
         a.HedgeServerID,
         a.Copy,
         a.InstrumentID,
         b.Name,
         b.InstrumentTypeID,
         a.RiskIndex,
         a.TreeSize_Units