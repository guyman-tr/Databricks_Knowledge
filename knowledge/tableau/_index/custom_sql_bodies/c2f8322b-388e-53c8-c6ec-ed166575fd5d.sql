select 
    EOMONTH(Date) as EoM, 
    bdcbcln.Regulation,
	p.StateName,
    p.StateShortName,
    SUM(CashoutFee) AS CashoutFee,
    SUM(COALESCE(TransferCoinFees,0)) AS TransferCoinFees,
    SUM(
      CASE WHEN bdcbcln.Regulation = 'FinCEN+FINRA' AND bdcbcln.Regulation <> FromRegulation 
        then COALESCE(ClientBalanceCommission,0) - COALESCE(ClientBalanceCommissionRealStocks,0) 
        ELSE COALESCE(ClientBalanceCommission,0) 
      END) AS ClientBalanceCommissionAdjusted,
    SUM(COALESCE(TicketFeeByPercent,0)) TicketFeeByPercent,
    SUM(
      CASE WHEN bdcbcln.Regulation = 'FinCEN+FINRA' 
        THEN COALESCE(UnrealizedCommissionChange,0) - COALESCE(UnrealizedCommissionChangeRealStocks,0) 
        ELSE COALESCE(UnrealizedCommissionChange,0) 
      END) AS UnrealizedCommissionChangeAdjusted
  from BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln
  
JOIN (				
	-- Final Step: Aggregate by the Continuity_Group_ID to get the Min/Max dates for the non-contiguous segments				
	  SELECT				
		RealCID,				
		--RegulationID,				
		StateShortName,				
		StateName,				
		MIN(FromDateID) AS FromDateID,				
		MAX(ToDateID) AS ToDateID				
	  FROM (				
			SELECT				
			*,				
			-- Sum the 'Is_New_Island' flags sequentially. This results in a stable ID				
			-- for all consecutive rows that share the same State**/regulation(removed)** combination.				
			SUM(Is_New_Island) OVER (PARTITION BY RealCID ORDER BY FromDateID) AS Continuity_Group_ID				
			FROM (				
				SELECT				
					*,				
					-- Use LAG to compare the current row's State **and Regulation (removed)** to the previous row's.				
					-- If either the state **or the regulation ID (removed)** changes, it marks the start of a new island (1).				
					-- Partitioning ensures comparison only happens within the same customer (RealCID).				
					CASE				
					WHEN LAG(StateShortName, 1, 'START') OVER (PARTITION BY RealCID ORDER BY FromDateID) = StateShortName				
					--AND LAG(RegulationID, 1, 0) OVER (PARTITION BY RealCID ORDER BY FromDateID) = RegulationID				
					THEN 0 -- Continuation of the previous state**/regulation(removed)**				
					ELSE 1 -- Start of a new state**/regulation(removed)** segment				
					END AS Is_New_Island				
				FROM (
					SELECT distinct
						dc.RealCID,
						dc.RegulationID,
						dr.FromDateID,
						dr.ToDateID,
						CASE
						WHEN dc.CountryID = 219 THEN COALESCE(dsap.ShortName,'No State')
						WHEN dc.CountryID IN (86,153,4,214,166) THEN dc1.Abbreviation --add:
						ELSE NULL
						END AS StateShortName,
						CASE
						WHEN dc.CountryID = 219 THEN COALESCE(dsap.Name, 'No State')
						WHEN dc.CountryID IN (86,153,4,214,166) THEN dc1.Name
						ELSE NULL
						END AS StateName
					FROM DWH_dbo.Fact_SnapshotCustomer dc
					INNER JOIN DWH_dbo.Dim_Range  dr
						ON dc.DateRangeID = dr.DateRangeID
						AND dr.ToDateID >= 20190101--date_format(add_months(current_date(), -6), 'yyyyMMdd')
					LEFT JOIN DWH_dbo.Dim_State_and_Province dsap
						ON dc.RegionID = dsap.RegionByIP_ID
					INNER JOIN DWH_dbo.Dim_Country dc1
						ON dc1.CountryID=dc.CountryID
					WHERE dc.VerificationLevelID=3
					and dc.IsValidCustomer=1
				)pop		
				where RegulationID in (6,7,8)		
				)IslandStarts				
		)GroupedIslands				
	  GROUP BY				
		RealCID,							
		--RegulationID,				
		StateShortName,				
		StateName,				
		Continuity_Group_ID--Magic happens here!				
	  --ORDER BY RealCID,FromDateID				
	) p 
		ON bdcbcln.CID=p.RealCID 
		AND bdcbcln.DateID BETWEEN p.FromDateID and p.ToDateID
  where bdcbcln.DateID>=20190101 --between 20250701 AND 20250831 --
      AND bdcbcln.IsCreditReportValidCB=1
      AND bdcbcln.IsValidCustomer=1
      AND bdcbcln.Regulation IN ('FinCEN', 'FinCEN+FINRA', 'eToroUS')
  GROUP BY 	 
    EOMONTH(Date) , bdcbcln.Regulation, p.StateName,
    p.StateShortName