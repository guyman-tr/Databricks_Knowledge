SELECT [Dealing_SelfCopyingPI].[CopyerAUM] AS [CopyerAUM],
  [Dealing_SelfCopyingPI].[CopyerIP] AS [CopyerIP],
  [Dealing_SelfCopyingPI].[DateInt] AS [DateInt],
  [Dealing_SelfCopyingPI].[Date] AS [Date],
  [Dealing_SelfCopyingPI].[ParentCID] AS [ParentCID],
  [Dealing_SelfCopyingPI].[ParentUserName] AS [ParentUserName],
  [Dealing_SelfCopyingPI].[PercentageOfAUM] AS [PercentageOfAUM],
  [Dealing_SelfCopyingPI].[TotalCopyAum] AS [TotalCopyAum],
  [Dealing_SelfCopyingPI].[UpdateDate] AS [UpdateDate],
a.GuruLevel
FROM [Dealing_dbo].[Dealing_SelfCopyingPI] [Dealing_SelfCopyingPI]
left join
(SELECT b.RealCID, c.GuruStatusName as GuruLevel FROM
DWH_dbo.Dim_Customer b 
join DWH_dbo.Dim_GuruStatus c on c.GuruStatusID = b.GuruStatusID) a
on a.RealCID = [Dealing_SelfCopyingPI].ParentCID