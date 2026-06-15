SELECT  
    cl.MonthID,
    cl.ClientLabel,
	cl.MonthEndDate,
    Region,
    Days_to_FirstFunded,
    Equity_Tier,
   -- Equity_Tier_Lag1Month,
    Player_Status,
    Seniority_Months,
    COUNT(*) AS Clients
FROM #ClientLabels cl
WHERE cl.ClientLabel !='Unfunded'
GROUP BY cl.MonthID,
    cl.ClientLabel,
	cl.MonthEndDate,
    Region,
    Days_to_FirstFunded,
    Equity_Tier,
   -- Equity_Tier_Lag1Month,
    Player_Status,
    Seniority_Months