SELECT * 
FROM general.gold_lukka_all_trades 
WHERE etr_ymd BETWEEN 
      DATE_ADD(CAST(<[Parameters].[Parameter 1]> AS DATE), 1)
  AND DATE_ADD(CAST(<[Parameters].[Parameter 2]>AS DATE), 1)