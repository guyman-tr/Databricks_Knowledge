select ReportDate
From dbo.Reg_Days_Price_Compare_Monitoring
Where ReportDate = Cast (getdate () -1  as date)