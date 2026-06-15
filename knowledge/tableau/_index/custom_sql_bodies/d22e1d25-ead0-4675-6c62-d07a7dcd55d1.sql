SELECT distinct di.InstrumentDisplayName, di.InstrumentID, dc.RealCID, reg.Name as Regulation, dc1.Name as Country,ppl.Amount, ppl.PositionID, ppl.PnLInDollars, ppl.OpenOccurred,
case when ppl.IsBuy = 1 then 'Long' when ppl.IsBuy = 0 then 'Short' else 'Unknown' end as Direction 
FROM DWH_dbo.Dim_Position ppl
JOIN DWH_dbo.Dim_Instrument di ON di.InstrumentID = ppl.InstrumentID
JOIN DWH_dbo.Dim_Customer dc ON ppl.CID = dc.RealCID
JOIN DWH_dbo.Dim_Regulation reg on reg.DWHRegulationID = dc.RegulationID
join DWH_dbo.Dim_Country dc1 on dc1.CountryID = dc.CountryID
Where di.InstrumentDisplayName = <[Parameters].[Parameter 2]> AND CloseDateID = 0 AND dc.IsValidCustomer = 1