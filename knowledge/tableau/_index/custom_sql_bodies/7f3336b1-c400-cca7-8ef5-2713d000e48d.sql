select ReportDate,  Regulation,InstrumentID,SymbolFull, DIFF_Pracentege
From dbo.Reg_MinMax_Price_Compare_Monitoring 
Where SellCurrencyID = 666
--AND ReportDate = Cast (getdate () -1  as date)