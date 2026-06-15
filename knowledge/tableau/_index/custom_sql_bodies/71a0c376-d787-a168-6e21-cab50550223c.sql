SELECT [TradeSurveilliance_Client_Vector].[CID] AS [CID],
  [TradeSurveilliance_Client_Vector].[Post_Events] AS [Post_Events],
  [TradeSurveilliance_Client_Vector].[Comment_Events] AS [Comment_Events],
  [TradeSurveilliance_Client_Vector].[Like_Events] AS [Like_Events],
  [TradeSurveilliance_Client_Vector].[Share_eToro_Event] AS [Share_eToro_Event],
  [TradeSurveilliance_Client_Vector].[Devices_Count] AS [Devices_Count],
  [TradeSurveilliance_Client_Vector].[UpdateDate] AS [UpdateDate]
FROM [dbo].[TradeSurveilliance_Client_Vector] [TradeSurveilliance_Client_Vector]

where [TradeSurveilliance_Client_Vector].[CID] in
 (SELECT distinct [TradeSurveilliance_BO_Data+].[CID] AS [CID]
FROM [dbo].[TradeSurveilliance_BO_Data] [TradeSurveilliance_BO_Data+]
where ParamType=7
and ParamGroupID in (-2146287117,
-2146286877,
-2146286869))