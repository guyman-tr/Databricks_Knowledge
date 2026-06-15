SELECT 
    mcb.BalanceDate,
    dd.DayNumberOfWeek_Sun_Start,
    CASE 
        WHEN mcb.CurrencyIson = 826 THEN 'GBP'
        ELSE 'Euro' 
    END AS IBAN_Type,
    SUM(mcb.ClosingBalanceBO) AS BalanceAmount,
    SUM(mcb.ClosingBalanceBO * mcb.USDApproxRate) AS BalanceAmountUSD, 
    SUM(vl.Credit) AS TP_Credit_USD_Available_Cash
FROM eMoney_dbo.eMoneyClientBalance mcb 
INNER JOIN eMoney_dbo.eMoney_Dim_Account mda
    ON mcb.AccountId = mda.ProviderCurrencyBalanceID 
   AND mda.GCID_Unique_Count = 1
INNER JOIN DWH_dbo.Dim_Date dd 
    ON dd.DateKey = mcb.BalanceDateID
JOIN (
    SELECT 
        SUM(vl.Credit) AS Credit, 
        vl.CID, 
        vl.DateID 
    FROM DWH_dbo.V_Liabilities vl
    WHERE vl.DateID >= 20240401 
    GROUP BY vl.CID, vl.DateID
) vl 
    ON mcb.BalanceDateID = vl.DateID 
   AND mcb.CID = vl.CID 
WHERE mcb.BalanceDateID >= 20240401
  AND mda.IsValidETM = 1
GROUP BY 
    mcb.BalanceDate,
    dd.DayNumberOfWeek_Sun_Start,
    CASE 
        WHEN mcb.CurrencyIson = 826 THEN 'GBP'
        ELSE 'Euro' 
    END