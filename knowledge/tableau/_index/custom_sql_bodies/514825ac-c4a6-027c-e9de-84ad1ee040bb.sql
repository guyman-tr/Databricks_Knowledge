SELECT b.InstrumentID
	 , b.Name
	 , b.CommissionVersion
	 , b.InstrumentType
	 , b.IsSettled
	 , b.Leverage
	 , b.DLTOpen
	 , b.IsBuy
	 , b.DateID
	 , b.PositionCategory
	 , b.Regulation						
	 , b.Country						
	 , b.IsCreditReportValidCB						
	 , b.IsValidCustomer 
	 , b.OpenedAtDate
	 , sum(b.EstimateCloseFeeForCFD			) as EstimateCloseFeeForCFD			
	 , sum(b.EstimateCloseFeeOnOpenByUnits	) as EstimateCloseFeeOnOpenByUnits	
	 , sum(b.EstimateCloseFeeOnOpen			) as EstimateCloseFeeOnOpen			
	 , sum(b.Amount							) as Amount							
	 , sum(b.PositionPnL					) as PositionPnL					
	 , sum(b.AmountInUnitsDecimal			) as AmountInUnitsDecimal			
	 , sum(b.NOP							) as NOP							
	 , sum(b.Notional						) as Notional						

FROM 
(
SELECT a.*
  , dco.Name as Country
  , drg.Name as Regulation
  , fsc.IsCreditReportValidCB
  , fsc.IsValidCustomer
FROM 
(
SELECT 
	-- pnl.PositionID
    pnl.CID
  , i.InstrumentID
  , i.Name
 --  , hcs.ValueInAccountCurrency * (dp.AmountInUnitsDecimal / dp.InitialUnits) AS ProjectedTicketFeeClose -- pro rated to open fees
  , dp.CommissionVersion
 -- , CASE when COALESCE(fsc.DltStatusID,0) = 4 then 1 ELSE 0 END AS IsDLTUser
  , i.InstrumentType
  , dp.IsSettled
  , dp.Leverage
  , dp.DLTOpen
  , dp.IsBuy
  , pnl.DateID
  , case when hcs.PositionID is null then 'Legacy' else 'New' end as PositionCategory
  , case when dp.OpenDateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) then 1 else 0 end as OpenedAtDate
  , sum(pnl.EstimateCloseFeeForCFD			) as EstimateCloseFeeForCFD
  , sum(pnl.EstimateCloseFeeOnOpenByUnits	) as EstimateCloseFeeOnOpenByUnits
  , sum(pnl.EstimateCloseFeeOnOpen			) as EstimateCloseFeeOnOpen
  , sum(pnl.Amount					) as Amount
  , sum(pnl.PositionPnL				) as PositionPnL
  , sum(pnl.AmountInUnitsDecimal	) as AmountInUnitsDecimal
  , sum(pnl.NOP						) as NOP
  , SUM(case when pnl.IsBuy = 1 then pnl.NOP else -1 * pnl.NOP END) as Notional
FROM BI_DB_dbo.BI_DB_PositionPnL pnl
  join DWH_dbo.Dim_Instrument i
    on pnl.InstrumentID = i.InstrumentID  
		/*and i.InstrumentTypeID = 10*/ 
		AND i.Symbol NOT LIKE '%Drm.Crypto%' and i.Tradable = 1
		AND NOT (i.IsFuture = 1)
		AND NOT (i.InstrumentTypeID IN (5,6) AND pnl.IsSettled = 1)
  JOIN DWH_dbo.Dim_Position dp
	ON pnl.PositionID = dp.PositionID AND (dp.CloseDateID = 0 OR dp.CloseDateID > CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT))
  left join DWH_dbo.Fact_History_Cost hcs 
    on dp.PositionID = hcs.PositionID and hcs.CostSubTypeID = 4 and hcs.CalculationTypeID in (4,7) and OperationTypeID in (14, 24)
WHERE pnl.DateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
GROUP BY 
    pnl.CID
  , i.InstrumentID
  , i.Name
  , dp.CommissionVersion
  , i.InstrumentType
  , dp.IsSettled
  , dp.Leverage
  , dp.DLTOpen
  , dp.IsBuy
  , case when hcs.PositionID is null then 'Legacy' else 'New' end 
  , pnl.DateID
  , case when dp.OpenDateID = CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT) then 1 else 0 end
) a
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON a.CID = fsc.RealCID
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND a.DateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Country dco
		ON fsc.CountryID = dco.CountryID
	JOIN DWH_dbo.Dim_Regulation drg
		ON fsc.RegulationID = drg.DWHRegulationID
) b
GROUP BY b.InstrumentID
	 , b.Name
	 , b.CommissionVersion
	 , b.InstrumentType
	 , b.IsSettled
	 , b.Leverage
	 , b.DLTOpen
	 , b.IsBuy
	 , b.DateID
	 , b.PositionCategory
	 , b.Regulation						
	 , b.Country						
	 , b.IsCreditReportValidCB						
	 , b.IsValidCustomer
	 , b.OpenedAtDate