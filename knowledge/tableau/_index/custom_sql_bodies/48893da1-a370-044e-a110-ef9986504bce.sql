SELECT unpvt.Date
      ,unpvt.Revenue
	  ,unpvt.RevenueBreakdown
FROM (
SELECT DATEFROMPARTS(dd.CalendarYear,dd.MonthNumberOfYear,1) Date
      ,SUM(ddr.FullTotalCommission) FullTotalCommission
	  ,SUM(ddr.TotalCommission) TotalCommission
	  ,SUM(ISNULL(ddr.OvernightFee,0) - ISNULL(ddr.DividendsPaid,0)) OverNightFee
	  ,SUM(ddr.CashoutFee)CashoutFee
	  ,SUM(ddr.TransferCoinFees)TransferCoinFees
  FROM [BI_DB].[dbo].[BI_DB_DDR_CID_Level] ddr WITH (NOLOCK)
  INNER JOIN [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
  ON ddr.DateID = dd.DateKey
  WHERE ddr.IsValidCustomer = 1
  AND ddr.IsDepositor = 1
  GROUP BY DATEFROMPARTS(dd.CalendarYear,dd.MonthNumberOfYear,1)
)q0
UNPIVOT (
	Revenue FOR RevenueBreakdown IN (FullTotalCommission,TotalCommission,OverNightFee,CashoutFee,TransferCoinFees)
) unpvt