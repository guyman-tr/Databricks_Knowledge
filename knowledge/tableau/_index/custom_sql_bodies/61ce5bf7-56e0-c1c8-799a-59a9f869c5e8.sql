SELECT YearMonth
     , InstrumentType
     , Regulation
     , PlayerLevel
     , PlayerStatus
     , IsCreditReportValidCB
     , MifidCategory
     , Country
     , Metric
     , Amount
    , ISNULL(IsRealFutures,0) as IsRealFutures
      , IsSettled 
from BI_DB_dbo.BI_DB_Finance_Audit_Auxillary_Datapoints
union all 
SELECT bdfaad.YearMonth
     , bdfaad.InstrumentType
     , bdfaad.Regulation
     , bdfaad.PlayerLevel
     , bdfaad.PlayerStatus
     , bdfaad.IsCreditReportValidCB
     , bdfaad.MifidCategory
     , bdfaad.Country
     , 'DDR_Revenue' as Metric
     ,    CASE WHEN bdfaad.Metric = 'FullTotalCommissionCFD' THEN        isnull(bdfaad.Amount,0) ELSE 0 END +
         CASE WHEN bdfaad.Metric = 'FullTotalCommissionReal' THEN    isnull(bdfaad.Amount,0) ELSE 0 END  +
         CASE WHEN bdfaad.Metric = 'TotalOvernightFee' THEN -1 *        isnull(bdfaad.Amount,0) ELSE 0 END - 
        CASE WHEN bdfaad.Metric = 'DividendPaid' THEN -1 *            isnull(bdfaad.Amount,0) ELSE 0 END  +
         CASE WHEN bdfaad.Metric = 'TotalCashoutFee' THEN            isnull(bdfaad.Amount,0) ELSE 0 END   +
         CASE WHEN bdfaad.Metric = 'TotalConversionFees' THEN        isnull(bdfaad.Amount,0) ELSE 0 END   +
         CASE WHEN bdfaad.Metric = 'TotalInterestFees' THEN            isnull(bdfaad.Amount,0) ELSE 0 END   +
         CASE WHEN bdfaad.Metric = 'TotalDormantFee' THEN            isnull(bdfaad.Amount,0) ELSE 0 END  +
         CASE WHEN bdfaad.Metric = 'TransferCoinFee' THEN            isnull(bdfaad.Amount,0) ELSE 0 END + 
        CASE WHEN bdfaad.Metric = 'TradingFees' THEN            isnull(bdfaad.Amount,0) ELSE 0 END  
    AS Amount
    , ISNULL(IsRealFutures,0) as IsRealFutures
    , IsSettled
FROM BI_DB_dbo.BI_DB_Finance_Audit_Auxillary_Datapoints bdfaad