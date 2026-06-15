select InstrumentID, SymbolFull, DIFF_Pracentege
From dbo.Reg_Days_Price_Compare_Monitoring
Where ReportDate = Cast (getdate () -1  as date)
AND Regulation = 'MIFIR_CLIENT'