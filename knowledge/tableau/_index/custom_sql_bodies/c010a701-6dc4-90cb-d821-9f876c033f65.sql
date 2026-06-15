-- Open positions
SELECT dp.PositionID,
       dp.InstrumentID,
       di.Symbol,
       di.InstrumentTypeID,
       di.InstrumentType,
       CASE WHEN di.InstrumentID in (17,18,22,27,28,29,310) THEN 1 ELSE 0 end as MarginGroup,
       dp.Leverage,
       dc1.Region,
       dp.CID,
       dc1.Name AS Country,
       dp.MirrorID,
       CASE WHEN dp.MirrorID=0 THEN 0 ELSE 1 end as IsMirror,
       dp.AmountInUnitsDecimal,
       CASE WHEN di.InstrumentID=17 THEN dp.AmountInUnitsDecimal/100
	    WHEN di.InstrumentID=18 THEN dp.AmountInUnitsDecimal/10
            WHEN di.InstrumentID=22 THEN dp.AmountInUnitsDecimal/1000
            WHEN di.InstrumentID=27 THEN dp.AmountInUnitsDecimal/5
	    WHEN di.InstrumentID=28 THEN dp.AmountInUnitsDecimal/2
            WHEN di.InstrumentID=29 THEN dp.AmountInUnitsDecimal/0.5
            WHEN di.InstrumentID=310 THEN dp.AmountInUnitsDecimal/5
	         else 0 END AS Real_Futures,
       dp.OpenDateID,
       dp.CloseDateID,
       dp.Volume,
       dp.VolumeOnClose,
       dp.Volume / dp.Leverage AS Initial_invested,
       dr.Name AS Regulation,
       CASE 
           WHEN dp.OpenDateID BETWEEN 20240101 AND 20241231 
           THEN dp.Volume ELSE 0 
       END AS Total_Volume_Open,
       0 AS Total_Volume_Close,
       CASE 
           WHEN dp.OpenDateID BETWEEN 20240101 AND 20241231 
           THEN dp.Volume ELSE 0 
       END AS Total_Volume,
       CASE 
           WHEN dp.OpenDateID BETWEEN 20240101 AND 20241231 
           THEN 1 ELSE 0 
       END AS Total_clicks,
       CASE 
           WHEN dp.OpenDateID BETWEEN 20240101 AND 20241231 
           THEN dp.FullCommissionByUnits ELSE 0 
       END AS Commission,
       0 AS NetProfit,
       CASE WHEN dp.OpenDateID = dp.CloseDateID THEN 1 ELSE 0 END AS IsIntraDay,
       	   CASE WHEN --change to your own overmargin
        (dp.InstrumentID = 17 AND dp.Volume / dp.Leverage > 150)
        OR (dp.InstrumentID = 18 AND dp.Volume / dp.Leverage > 130)
        OR (dp.InstrumentID = 22 AND dp.Volume / dp.Leverage > 120)
        OR (dp.InstrumentID = 27 AND dp.Volume / dp.Leverage > 305)
        OR (dp.InstrumentID = 28 AND dp.Volume / dp.Leverage > 105)
        OR (dp.InstrumentID = 29 AND dp.Volume / dp.Leverage > 200)
        OR (dp.InstrumentID = 310 AND dp.Volume / dp.Leverage > 120) THEN 1 ELSE 0 END AS OverMargin,
CASE WHEN dp.Volume / dp.Leverage < 500 THEN '0-500'
     WHEN dp.Volume / dp.Leverage between 500 and 1000 then '500-1000'
     WHEN dp.Volume / dp.Leverage between 1000 and 1500 then '1000-1500'
     WHEN dp.Volume / dp.Leverage between 1500 and 2000 then '1500-2000'
     WHEN dp.Volume / dp.Leverage between 2000 and 2500 then '2000-2500'
     WHEN dp.Volume / dp.Leverage between 2500 and 3000 then '2500-3000'
     WHEN dp.Volume / dp.Leverage between 3000 and 3500 then '3000-3500'
     WHEN dp.Volume / dp.Leverage between 3500 and 4000 then '3500-4000'
     WHEN dp.Volume / dp.Leverage > 4000 then '4000-+' end as Initial_invested_Size
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Dim_Customer dc ON dp.CID = dc.RealCID
JOIN DWH_dbo.Dim_Regulation dr ON dc.RegulationID = dr.ID
JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID
WHERE dc.IsValidCustomer = 1
  AND dp.OpenDateID BETWEEN 20240101 AND 20241231
  AND (dp.CloseDateID=0 or dp.CloseDateID > 20241231) 
  --AND dp.InstrumentID IN (17,18,22,27,28,29,310)
  and di.InstrumentTypeID <> 5

UNION

-- Close positions
SELECT dp.PositionID,
       dp.InstrumentID,
       di.Symbol,
       di.InstrumentTypeID,
       di.InstrumentType,
       CASE WHEN di.InstrumentID in (17,18,22,27,28,29,310) THEN 1 ELSE 0 end as MarginGroup,
       dp.Leverage,
       dc1.Region,
       dp.CID,
       dc1.Name AS Country,
       dp.MirrorID,
       CASE WHEN dp.MirrorID =0 THEN 0 ELSE 1 end as IsMirror,
       CASE WHEN dp.OpenDateID between 20240101 AND 20241231 
       THEN dp.AmountInUnitsDecimal*2 
       ELSE AmountInUnitsDecimal END AS AmountInUnitsDecimal,
	CASE WHEN di.InstrumentID=17 AND dp.OpenDateID between 20240101 and 20241231
	           THEN (dp.AmountInUnitsDecimal/100) * 2
	     WHEN di.InstrumentID=17 AND dp.OpenDateID NOT between 20240101 and 20241231 
	          THEN dp.AmountInUnitsDecimal/100
	     WHEN di.InstrumentID=18 AND dp.OpenDateID between 20240101 and 20241231
                  THEN (dp.AmountInUnitsDecimal/10) *2
             WHEN di.InstrumentID=18 AND dp.OpenDateID NOT between 20240101 and 20241231
                  THEN dp.AmountInUnitsDecimal/10
             WHEN di.InstrumentID=22 AND dp.OpenDateID between 20240101 and 20241231
		  THEN (dp.AmountInUnitsDecimal/1000)*2
             WHEN di.InstrumentID=22 AND dp.OpenDateID NOT between 20240101 and 20241231
	          THEN (dp.AmountInUnitsDecimal/1000)
	     WHEN di.InstrumentID=27 AND dp.OpenDateID between 20240101 and 20241231
	          THEN (dp.AmountInUnitsDecimal/5)*2
	     WHEN di.InstrumentID=27 AND dp.OpenDateID NOT between 20240101 and 20241231
		  THEN (dp.AmountInUnitsDecimal/5)
	     WHEN di.InstrumentID=28 AND dp.OpenDateID between 20240101 and 20241231
		  THEN (dp.AmountInUnitsDecimal/2)*2
	     WHEN di.InstrumentID=28 AND dp.OpenDateID NOT between 20240101 and 20241231
                  THEN (dp.AmountInUnitsDecimal/2)
	     WHEN di.InstrumentID=29 AND dp.OpenDateID between 20240101 and 20241231
	          THEN (dp.AmountInUnitsDecimal/0.5)*2
	     WHEN di.InstrumentID=29 AND dp.OpenDateID NOT between 20240101 and 20241231
		  THEN (dp.AmountInUnitsDecimal/0.5)
	     WHEN di.InstrumentID=310 AND dp.OpenDateID between 20240101 and 20241231
	          THEN (dp.AmountInUnitsDecimal/5)*2
	     WHEN di.InstrumentID=310 AND dp.OpenDateID NOT between 20240101 and 20241231
		  THEN (dp.AmountInUnitsDecimal/5)
			ELSE 0 END AS Real_Futures,
       dp.OpenDateID,
       dp.CloseDateID,
       dp.Volume,
       dp.VolumeOnClose,
       dp.Volume / dp.Leverage AS Initial_invested,
       dr.Name AS Regulation,
       0 AS Total_Volume_Open,
       dp.VolumeOnClose AS Total_Volume_Close,
       CASE 
           WHEN dp.OpenDateID BETWEEN 20240101 AND 20241231 
           THEN dp.Volume + dp.VolumeOnClose ELSE dp.VolumeOnClose 
       END AS Total_Volume,
       CASE 
           WHEN dp.OpenDateID BETWEEN 20240101 AND 20241231 
           AND ISNULL(IsPartialCloseChild,0) = 0
           THEN 2 ELSE 1 
       END AS Total_clicks,
       CASE 
           WHEN dp.OpenDateID BETWEEN 20240101 AND 20241231 
           THEN dp.FullCommissionOnClose ELSE dp.FullCommissionOnClose - dp.FullCommissionByUnits 
       END AS Commission,
       dp.NetProfit,
       CASE WHEN dp.OpenDateID = dp.CloseDateID THEN 1 ELSE 0 END AS IsIntraDay,
       	   CASE WHEN --change to your own overmargin
        (dp.InstrumentID = 17 AND dp.Volume / dp.Leverage > 150)
        OR (dp.InstrumentID = 18 AND dp.Volume / dp.Leverage > 130)
        OR (dp.InstrumentID = 22 AND dp.Volume / dp.Leverage > 120)
        OR (dp.InstrumentID = 27 AND dp.Volume / dp.Leverage > 305)
        OR (dp.InstrumentID = 28 AND dp.Volume / dp.Leverage > 105)
        OR (dp.InstrumentID = 29 AND dp.Volume / dp.Leverage > 200)
        OR (dp.InstrumentID = 310 AND dp.Volume / dp.Leverage > 120) THEN 1 ELSE 0 END AS OverMargin,
CASE WHEN dp.Volume / dp.Leverage < 500 THEN '0-500'
     WHEN dp.Volume / dp.Leverage between 500 and 1000 then '500-1000'
     WHEN dp.Volume / dp.Leverage between 1000 and 1500 then '1000-1500'
     WHEN dp.Volume / dp.Leverage between 1500 and 2000 then '1500-2000'
     WHEN dp.Volume / dp.Leverage between 2000 and 2500 then '2000-2500'
     WHEN dp.Volume / dp.Leverage between 2500 and 3000 then '2500-3000'
     WHEN dp.Volume / dp.Leverage between 3000 and 3500 then '3000-3500'
     WHEN dp.Volume / dp.Leverage between 3500 and 4000 then '3500-4000'
     WHEN dp.Volume / dp.Leverage > 4000 then '4000-+' end as Initial_invested_Size
FROM DWH_dbo.Dim_Position dp
JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID = di.InstrumentID
JOIN DWH_dbo.Dim_Customer dc ON dp.CID = dc.RealCID
JOIN DWH_dbo.Dim_Regulation dr ON dc.RegulationID = dr.ID
JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID
WHERE dc.IsValidCustomer = 1
  AND dp.CloseDateID BETWEEN 20240101 AND 20241231
  --AND dp.InstrumentID IN (17,18,22,27,28,29,310)
  AND di.InstrumentTypeID <> 5