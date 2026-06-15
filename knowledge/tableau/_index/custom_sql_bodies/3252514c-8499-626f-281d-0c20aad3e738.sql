Select [Trade Date], 
[Type],[UTI], 
[Reason #], 
[Reason 1], 
[Reason 2],  
[Reason 3]   
From

(select cast([Submission Date] as Date) [Trade Date],
'TRAX Rej' as [Type], 
[Transaction Reference Number][UTI], 
[Number Of Reasons][Reason #], 
[Description_1][Reason 1], 
[Description_2][Reason 2], 
[Description_3] [Reason 3] 
from [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[TR_Silver_CappitechMifiD2UK_TRAX_ARM_TRAN_RESP]
where [Transaction Status] = 'AREJ'
and cast([Submission Date] as Date) >= cast (getdate() - <[Parameters].[Trend Last Day Trade Date (copy)_5851020344607281156]>  as date)

union

select cast([Submission Date] as Date) [Trade Date],
'FCA Rej' as [Type], 
[Transaction Reference Number][UTI], 
[Number Of Reasons][Reason #], 
[Description_1] [Reason 1], 
[Description_2] [Reason 2],
[Description_3] [Reason 3]  
from [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[TR_Silver_CappitechMifiD2UK_TRAX_ARM_TRAN_RSTS]
where [Transaction Status] = 'RREJ'
and cast([Submission Date] as Date) >= cast (getdate() - <[Parameters].[Trend Last Day Trade Date (copy)_5851020344607281156]>  as date)

union

select cast([Submission Date] as Date) [Trade Date],
 'TRAX2 Rej' as [Type],
[Transaction Reference Number][UTI],
[Number Of Reasons] as [Reasons #], 
[Description_1] as [Reason 1], 
[Description_2] as [Reason 2], 
[Description_3] as [Reason 3]
from [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[TR_Silver_CappitechMifiD2UK_TRAX_ARM_TRAN_TSTS]
where [Transaction Status] = 'AREJ'
and cast([Submission Date] as Date) >= cast (getdate() - <[Parameters].[Trend Last Day Trade Date (copy)_5851020344607281156]>  as date)

union

select cast([Submission Date] as Date) [Trade Date],
 'FCA Pending' as [Type],
[Transaction Reference Number][UTI],
[Number Of Reasons] as [Reasons #] ,
[Description_1] as [Reason 1],
[Description_2] as [Reason 2],
[Description_3] as [Reason 3]
from [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[TR_Silver_CappitechMifiD2UK_TRAX_ARM_TRAN_RSTS]
where [Transaction Status] = 'NPND'
and cast([Submission Date] as Date) >= cast (getdate() - <[Parameters].[Trend Last Day Trade Date (copy)_5851020344607281156]>  as date)


union

select cast([Submission Date] as Date) [Trade Date],
 'TRAX Pending' as [Type],
[Transaction Reference Number][UTI],
[Number Of Reasons] as [Reasons #] ,
[Description_1] as [Reason 1],
 [Description_2] as [Reason 2], 
'Natural Person Details - NPD' as [Reason 3]
from [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[TR_Silver_CappitechMifiD2UK_TRAX_ARM_TRAN_RESP]
where [Transaction Status] = 'HELD'
and cast([Submission Date] as Date) >= cast (getdate() - <[Parameters].[Trend Last Day Trade Date (copy)_5851020344607281156]>  as date)


) a