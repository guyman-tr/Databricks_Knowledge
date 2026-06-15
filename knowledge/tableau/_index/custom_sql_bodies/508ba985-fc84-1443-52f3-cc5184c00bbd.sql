SELECT dse.ConversationEngagementId,MAX(to_timestamp(el.EventDateTime, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')) LastInputDate
  FROM main.crm.silver_crm_conversationdefinitioneventlog el
  INNER JOIN main.crm.silver_crm_conversationdefinitionsession de
  ON el.ParentId = de.Id
  INNER JOIN main.crm.silver_crm_conversationdefinitionsessionengagement dse
  ON de.Id = dse.SessionId
  WHERE LogType = 'InputMessage' and lower(el.EventLabel) not like '%end session'
  AND el.createddate>= current_date - INTERVAL '12 months'
  GROUP BY dse.ConversationEngagementId