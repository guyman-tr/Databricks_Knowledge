WITH Chats AS (
    SELECT DISTINCT 
        c.Time,
        c.LiveChatTranscriptId ,
        CASE 
            WHEN c.Detail LIKE '%US%' THEN 'US'
            WHEN c.Detail LIKE '%General Support%' THEN 'General Support'
            WHEN c.Detail LIKE '%Financial Services%' THEN 'Financial Services'
            WHEN c.Detail LIKE '%eToro Money%' THEN 'eToro Money'
            WHEN c.Detail LIKE '%Hacked%' THEN 'Hacked Accounts'
            WHEN c.Detail LIKE '%GDPR%' THEN 'Islamic/GDPR'
            WHEN c.Detail LIKE '%Islamic%' THEN 'Islamic/GDPR'
            WHEN c.Detail LIKE '%Club Issues%' THEN 'Club Issues'
            WHEN c.Detail LIKE '%Trading Experience%' THEN 'Trading Experience'
            WHEN c.Detail LIKE '%Technical%' THEN 'Technical'
            WHEN c.Detail LIKE '%CS Marketing%' THEN 'CS Marketing'
            WHEN c.Detail LIKE '%BU%' THEN 'General Support'
            WHEN c.Detail LIKE '%Global%' THEN 'General Support'
        END AS ChatSkill
    FROM crm.silver_crm_livechattranscriptevent c
    WHERE YEAR(c.Time) >= 2025
      AND c.Detail NOT LIKE '%US%'
      AND c.Detail NOT LIKE '%Cashout%'
      AND c.Detail NOT LIKE '%Deposit%'
), Asynchronous AS (
    SELECT DISTINCT 
        c.CreatedDate AS Time,
        c.MessagingSessionId AS LiveChatTranscriptId,
        CASE 
            WHEN c.NewValue LIKE '%US%' THEN 'US'
            WHEN c.NewValue LIKE '%General%' THEN 'General Support'
            WHEN c.NewValue LIKE '%Financial%' THEN 'Financial Services'
            WHEN c.NewValue LIKE '%eToro%' THEN 'eToro Money'
            WHEN c.NewValue LIKE '%Hacked%' THEN 'Hacked Accounts'
            WHEN c.NewValue LIKE '%GDPR%' THEN 'Islamic/GDPR'
            WHEN c.NewValue LIKE '%Islamic%' THEN 'Islamic/GDPR'
            WHEN c.NewValue LIKE '%Club%' THEN 'Club Issues'
            WHEN c.NewValue LIKE '%Trading%' THEN 'Trading Experience'
            WHEN c.NewValue LIKE '%Technical%' THEN 'Technical'
            WHEN c.NewValue LIKE '%Marketing%' THEN 'CS Marketing'
            WHEN c.NewValue LIKE '%BU%' THEN 'General Support'
            WHEN c.NewValue LIKE '%Global%' THEN 'General Support'
        END AS ChatSkill
    FROM crm.silver_crm_messagingsessionhistory c
    WHERE YEAR(c.CreatedDate) >= 2025
      AND c.NewValue NOT LIKE '%US%'
      AND c.NewValue NOT LIKE '%Cashout%'
      AND c.NewValue NOT LIKE '%Deposit%'
), Combined AS (
    SELECT Time, LiveChatTranscriptId, ChatSkill FROM Chats
    UNION ALL
    SELECT Time, LiveChatTranscriptId, ChatSkill FROM Asynchronous)
    select * from Combined
    where ChatSkill is not null