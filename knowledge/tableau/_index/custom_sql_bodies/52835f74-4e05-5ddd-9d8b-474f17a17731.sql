/****** Script for SelectTopNRows command from SSMS  ******/
SELECT ch.[DateID]
      ,dd.FullDate AS Date
      ,ch.[CID]
      ,ch.[TicketID]
      ,ch.[TranscriptNumber]
      ,ch.[RequestTime]
      ,ch.[StartTime]
      ,ch.[EndTime]
      ,ch.[WaitTime]
      ,ch.[ChatDuration]
      ,ch.[Status]
      ,ch.[RegulationAtOpen]
      ,ch.[ClubTierAtOpen]
      ,ch.[Desk]
      ,ch.[Language]
      ,ch.[IsActiveCustomer]
      ,ch.[Manager]
      ,ch.[Source]
      ,ch.[Type]
      ,ch.[Priority]
      ,ch.[Product]
      ,ch.[SubType]
      ,ch.[SubType2]
      ,ch.[Phase]
  FROM [dbo].[BI_DB_SF_Chats] ch WITH (NOLOCK)
  INNER JOIN [DWH].[dbo].[Dim_Date] dd WITH (NOLOCK)
  ON ch.DateID = dd.DateKey