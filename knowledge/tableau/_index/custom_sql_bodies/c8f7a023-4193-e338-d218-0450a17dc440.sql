SELECT [TradeSurveilliance_BO_Data+].[CID] AS [CID],
  [TradeSurveilliance_BO_Data+].[ParamType] AS [ParamType],
  [TradeSurveilliance_BO_Data+].[ParamValue] AS [ParamValue],
  [TradeSurveilliance_BO_Data+].[ParamGroupID] AS [ParamGroupID],
  [TradeSurveilliance_BO_Data+].[FirstDetectionTime] AS [FirstDetectionTime],
  [TradeSurveilliance_BO_Data+].[LastDetectionTime] AS [LastDetectionTime],
  [TradeSurveilliance_BO_Data+].[ExpirationTime] AS [ExpirationTime],
  [TradeSurveilliance_BO_Data+].[IdBlackListed] AS [IdBlackListed],
  [TradeSurveilliance_BO_Data+].[BlackListedTime] AS [BlackListedTime],
count ([TradeSurveilliance_BO_Data+].[ParamGroupID]) over (partition by [TradeSurveilliance_BO_Data+].[CID] ) as CID_Devices,
count ([TradeSurveilliance_BO_Data+].[CID]) over (partition by [TradeSurveilliance_BO_Data+].[ParamGroupID] ) as Device_CIDs,
max(LastDetectionTime)over (partition by [TradeSurveilliance_BO_Data+].[ParamGroupID] ) as MaxLastDetectionTime,
min(FirstDetectionTime)over (partition by [TradeSurveilliance_BO_Data+].[ParamGroupID] ) as MinFirstDetectionTime 
FROM [dbo].[TradeSurveilliance_BO_Data] [TradeSurveilliance_BO_Data+]
where ParamType=7