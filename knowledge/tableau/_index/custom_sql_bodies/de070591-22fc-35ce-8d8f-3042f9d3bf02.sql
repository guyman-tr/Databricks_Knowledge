SELECT 
    FullDate,
    Region,
    Equity,
    Products_Combination,
    Total_Products,
    COUNT(DISTINCT CID) AS Num_Users
FROM #GroupedProducts
GROUP BY FullDate, Products_Combination, Total_Products,Equity,Region