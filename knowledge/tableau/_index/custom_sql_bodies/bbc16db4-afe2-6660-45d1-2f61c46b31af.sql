SELECT [Symbol],[Occurred],[PositionID],[CID],A.[InstrumentID],[HedgeServerID], AmountInUnitsDecimal,[DLTOpen] DLTFlag,IsSettled
 FROM  [AZR-W-REAL-DB-2-BIDBUser].[etoro].[Trade].[PositionForExternalUse]
A inner join  [dbo].[Reg_Instruments_Operation] B on A.[InstrumentID]=B.[InstrumentID]
where [DLTOpen]=1
and cast(Occurred as date)=cast (getdate()as date)

union
SELECT [Symbol],[CloseOccurred] Occurred,[PositionID],[CID],A.[InstrumentID],[HedgeServerID], AmountInUnitsDecimal,[DLTClose] DLTFlag,IsSettled
 FROM 
[AZR-W-REAL-DB-2-BIDBUser].[etoro].[History].[PositionForExternalUse]
A inner join  [dbo].[Reg_Instruments_Operation] B on A.[InstrumentID]=B.[InstrumentID]
where   [DLTClose]=1
and cast(CloseOccurred as date)=cast (getdate()as date)