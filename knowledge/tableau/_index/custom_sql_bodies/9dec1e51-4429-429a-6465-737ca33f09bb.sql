SELECT
	ReportDate,
[PositionID]
    ,[CID]
    ,[OpenOccurred]
    ,[CloseOccurred]
    ,[IsBuy]
,[IsSettled]
	,[Symbol]
    ,[Quantity]
    ,[OpenPrice]
    ,[ClosePrice]
    ,[EOD_Price]
FROM [Reg_Regulation_Movments_Positions]
where
	 PositionID is not null