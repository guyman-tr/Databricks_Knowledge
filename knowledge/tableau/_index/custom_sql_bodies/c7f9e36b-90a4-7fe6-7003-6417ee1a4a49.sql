SELECT   dse.ConversationEngagementId,MAX(el.EventDateTime) LastInputDate
  FROM [dbo].[BI_DB_SF_STG_ConversationDefinitionEventLog] el WITH (NOLOCK)
  INNER JOIN [dbo].[BI_DB_SF_STG_ConversationDefinitionSession] de WITH (NOLOCK)
  ON el.ParentId = de.Id
  INNER JOIN [dbo].[BI_DB_SF_STG_ConversationDefinitionSessionEngagement] dse WITH (NOLOCK)
  ON de.Id = dse.SessionId
  WHERE [LogType] = 'InputMessage' 
  GROUP BY dse.ConversationEngagementId