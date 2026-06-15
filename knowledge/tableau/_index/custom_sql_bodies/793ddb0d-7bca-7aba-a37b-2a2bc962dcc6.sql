select Date, 
Instrument,
sum (Amount) Amount,
sum (Units) Units,
sum (NOP)NOP,
sum (UnitsSL)/ Sum(Units) as AvgSL,
sum (UnitsTP)/ Sum(Units) as AvgTP,
sum (PositionPnL)PositionPnL,
Sum(PositionPnL_Plus_Amount)PositionPnL_Plus_Amount,
Credit from BI_DB_BigCustomer
group by  Date, Instrument, Credit