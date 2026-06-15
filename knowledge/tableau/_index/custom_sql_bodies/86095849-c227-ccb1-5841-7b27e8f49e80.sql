SELECT unpvt.DateID
		,unpvt.TimeRange
		,unpvt.Regulation
		,unpvt.IsCreditReportValidCB
		,unpvt.IsValidCustomer
		,unpvt.PlayerLevel
		,unpvt.Country
		,unpvt.Region
		,CalendarYearMonth
		,unpvt.RevenueCategory
		,SUM(unpvt.column_value) ColumnValue
,FullDate
  FROM(
  SELECT DateID
		,TimeRange
		,Regulation
		,IsCreditReportValidCB
		,IsValidCustomer
		,PlayerLevel
		,Country
		,Region
		,dd.CalendarYearMonth
,dd.FullDate
		,ISNULL(CONVERT(DECIMAL(26,9),ddr.TransferCoinFees    ),0)TransferCoinFees
		,ISNULL(CONVERT(DECIMAL(26,9),ddr.ConversionFees	  ),0)ConversionFees
		,ISNULL(CONVERT(DECIMAL(26,9),ddr.TotalCommission	  ),0)TotalCommission
		,ISNULL(CONVERT(DECIMAL(26,9),ddr.FullTotalCommission ),0)FullTotalCommission
		,ISNULL(CONVERT(DECIMAL(26,9),ddr.CashoutFee		  ),0)CashoutFee
		,ISNULL(CONVERT(DECIMAL(26,9),ISNULL(ddr.OvernightFee,0)-ISNULL(DividendsPaid,0)),0) OvernightFee
		,ISNULL(CONVERT(DECIMAL(26,9),ddr.DormantFee),0) DormantFee
		,ISNULL(CONVERT(DECIMAL(26,9),ddr.InterestFees),0) InterestFees
  FROM [BI_DB_dbo].[BI_DB_DDR_TimeRange_Aggregated_Country_Level] ddr WITH (NOLOCK)
  INNER JOIN DWH_dbo.Dim_Date dd WITH (NOLOCK)
  ON dd.DateKey = ddr.DateID
  WHERE IsCreditReportValidCB = 1
  AND IsValidCustomer = 1
  AND TimeRange = 'ThisMonth'
  AND DateID >=20230101
  AND dd.IsLastDayOfMonth = 'Y'
  )q0
  UNPIVOT (
  	column_value FOR RevenueCategory IN (TransferCoinFees,ConversionFees,TotalCommission,FullTotalCommission,CashoutFee,OvernightFee,DormantFee,InterestFees)
  ) unpvt
  GROUP BY unpvt.DateID
		,unpvt.TimeRange
		,unpvt.Regulation
		,unpvt.IsCreditReportValidCB
		,unpvt.IsValidCustomer
		,unpvt.PlayerLevel
		,unpvt.Country
		,unpvt.Region
		,CalendarYearMonth
		,unpvt.RevenueCategory
,FullDate