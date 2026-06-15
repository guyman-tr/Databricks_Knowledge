SELECT f.*,f1.FA_Amount,f1.CO_date,f1.CO_amount
FROM #FTD f 
LEFT JOIN #final f1
ON f.RealCID = f1.RealCID