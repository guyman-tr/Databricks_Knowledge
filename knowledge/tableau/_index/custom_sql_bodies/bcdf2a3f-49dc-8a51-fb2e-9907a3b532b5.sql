SELECT 'Redeem' AS Activity,hra.Date
, hra.CryptoID
, hra.CryptoName
, hra.TotalRedeemTX AS CountTX
, hra.TotalRedeemUnits AS TotalUnits
, hra.ReportDate
, hra.UpdateDate
, hra.USDValue
FROM EXW_dbo.Hourly_RedeemActivity hra