SELECT p.CID,p.InstrumentID,
sum(CASE WHEN Frequency = 'Intra Hour'
THEN p.NetProfit+p.FullCommissionOnClose ELSE 0 END ) as IntraHourZero ,


SUM(CASE WHEN p.OpenOccurred BETWEEN <[Parameters].[Parameter 1]> AND <[Parameters].[Parameter 2]> 
				AND CloseOccurred BETWEEN <[Parameters].[Parameter 1]> AND <[Parameters].[Parameter 2]> 
			THEN p.NetProfit+p.FullCommissionOnClose --open and close
		WHEN 	( FrequencyInt = 1 OR p.CloseOccurred > <[Parameters].[Parameter 2]>) 
		THEN PnLInDollars + p.FullCommissionByUnits --only opened 
		WHEN   	FrequencyInt NOT IN (5,6) 
		THEN p.NetProfit +p.FullCommissionOnClose - p.FullCommissionByUnits --closed but opened not that far 
		ELSE p.NetProfit * (cast (DATEDIFF(DAY , <[Parameters].[Parameter 1]>,CloseOccurred)  AS FLOAT)/cast (DATEDIFF(DAY , OpenOccurred,CloseOccurred)  AS FLOAT))+
		p.FullCommissionOnClose - p.FullCommissionByUnits
		END )AS Zero_approx
			

FROM #pos p
WHERE  (p.OpenOccurred BETWEEN <[Parameters].[Parameter 1]> AND <[Parameters].[Parameter 2]>
OR p.CloseOccurred BETWEEN <[Parameters].[Parameter 1]> AND <[Parameters].[Parameter 2]>)
GROUP BY  p.CID,p.InstrumentID