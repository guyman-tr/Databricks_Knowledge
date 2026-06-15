WITH Chats AS (
  SELECT DISTINCT
 CAST(timestampadd(HOUR, 3, Time) AS DATE) AS CreatedDate,
    date_format(timestampadd(HOUR, 3, c.Time), 'HH:mm') AS EditTime,
    date_format(c.Time, 'MM/yy') AS Month_Year,
    c.LiveChatTranscriptId,
    CASE
      WHEN c.Detail LIKE '%US%' THEN 'US'
      WHEN c.Detail LIKE '%General Support%' THEN '1.General Support'
      WHEN c.Detail LIKE '%Financial Services%' THEN '2.Financial Services'
      WHEN c.Detail LIKE '%eToro Money%' THEN '3.eToro Money'
      WHEN c.Detail LIKE '%Hacked%' THEN '4.Hacked Accounts/Islamic/GDPR'
      WHEN c.Detail LIKE '%GDPR%' THEN '4.Hacked Accounts/Islamic/GDPR'
      WHEN c.Detail LIKE '%Islamic%' THEN '4.Hacked Accounts/Islamic/GDPR'
      WHEN c.Detail LIKE '%Trading Experience%' THEN '5.Trading Experience'
      WHEN c.Detail LIKE '%Technical%' THEN '6.Technical'
      WHEN c.Detail LIKE '%CS Marketing%' THEN '7.CS Marketing'
      WHEN c.Detail LIKE '%BU%' THEN '1.General Support'
      WHEN c.Detail LIKE '%Global%' THEN '1.General Support'
    END AS ChatSkill
  FROM crm.silver_crm_livechattranscriptevent c
  WHERE YEAR(c.Time)>  2024
    AND c.Detail NOT LIKE '%US%'
),

GroupedChats AS (
  SELECT
  CreatedDate as IncomingDate,
    ChatSkill,
    COUNT(LiveChatTranscriptId) AS ChatsIncoming,
    Month_Year,
    CASE 
      WHEN EditTime BETWEEN '00:00' AND '00:59' THEN '00:00-01:00'
      WHEN EditTime BETWEEN '01:00' AND '01:59' THEN '01:00-02:00'
      WHEN EditTime BETWEEN '02:00' AND '02:59' THEN '02:00-03:00'
      WHEN EditTime BETWEEN '03:00' AND '03:59' THEN '03:00-04:00'
      WHEN EditTime BETWEEN '04:00' AND '04:59' THEN '04:00-05:00'
      WHEN EditTime BETWEEN '05:00' AND '05:59' THEN '05:00-06:00'
      WHEN EditTime BETWEEN '06:00' AND '06:59' THEN '06:00-07:00'
      WHEN EditTime BETWEEN '07:00' AND '07:59' THEN '07:00-08:00'
      WHEN EditTime BETWEEN '08:00' AND '08:59' THEN '08:00-09:00'
      WHEN EditTime BETWEEN '09:00' AND '09:59' THEN '09:00-10:00'
      WHEN EditTime BETWEEN '10:00' AND '10:59' THEN '10:00-11:00'
      WHEN EditTime BETWEEN '11:00' AND '11:59' THEN '11:00-12:00'
      WHEN EditTime BETWEEN '12:00' AND '12:59' THEN '12:00-13:00'
      WHEN EditTime BETWEEN '13:00' AND '13:59' THEN '13:00-14:00'
      WHEN EditTime BETWEEN '14:00' AND '14:59' THEN '14:00-15:00'
      WHEN EditTime BETWEEN '15:00' AND '15:59' THEN '15:00-16:00'
      WHEN EditTime BETWEEN '16:00' AND '16:59' THEN '16:00-17:00'
      WHEN EditTime BETWEEN '17:00' AND '17:59' THEN '17:00-18:00'
      WHEN EditTime BETWEEN '18:00' AND '18:59' THEN '18:00-19:00'
      WHEN EditTime BETWEEN '19:00' AND '19:59' THEN '19:00-20:00'
      WHEN EditTime BETWEEN '20:00' AND '20:59' THEN '20:00-21:00'
      WHEN EditTime BETWEEN '21:00' AND '21:59' THEN '21:00-22:00'
      WHEN EditTime BETWEEN '22:00' AND '22:59' THEN '22:00-23:00'
      WHEN EditTime BETWEEN '23:00' AND '23:59' THEN '23:00-00:00'
    END AS HourlyRange
  FROM Chats
  WHERE ChatSkill IS NOT NULL
  GROUP BY ChatSkill, Month_Year, HourlyRange,CreatedDate
  ORDER BY ChatSkill ASC
),
Cases AS (
SELECT DISTINCT
 CAST(timestampadd(HOUR, 3, CreatedDate) AS DATE) AS CreatedDate,
   date_format(timestampadd(HOUR, 3, c.CreatedDate), 'HH:mm') AS EditTime,
    date_format(c.CreatedDate, 'MM/yy') AS Month_Year,
c.CaseId,
CASE
WHEN c.NewValue LIKE '%US%' THEN 'US'
WHEN c.NewValue LIKE '%General Support%' THEN '1.General Support'
WHEN c.NewValue LIKE '%Financial Services%' THEN '2.Financial Services'
WHEN c.NewValue LIKE '%eToro Money%' THEN '3.eToro Money'
WHEN c.NewValue LIKE '%Hacked%' THEN '4.Hacked Accounts/Islamic/GDPR'
WHEN c.NewValue LIKE '%GDPR%' THEN '4.Hacked Accounts/Islamic/GDPR'
WHEN c.NewValue LIKE '%Islamic%' THEN '4.Hacked Accounts/Islamic/GDPR'
WHEN c.NewValue LIKE '%Trading Experience%' THEN '5.Trading Experience'
WHEN c.NewValue LIKE '%Technical%' THEN '6.Technical'
WHEN c.NewValue LIKE '%CS Marketing%' THEN '7.CS Marketing'
END AS Skill
FROM crm.silver_crm_casehistory c
WHERE year(c.CreatedDate)>2024
AND c.NewValue NOT LIKE '%US%'
),
GroupedCases AS (
SELECT
Skill,
COUNT(CaseId) AS CasesIncoming,
CreatedDate as IncomingDate,
Month_Year,
    CASE 
      WHEN EditTime BETWEEN '00:00' AND '00:59' THEN '00:00-01:00'
      WHEN EditTime BETWEEN '01:00' AND '01:59' THEN '01:00-02:00'
      WHEN EditTime BETWEEN '02:00' AND '02:59' THEN '02:00-03:00'
      WHEN EditTime BETWEEN '03:00' AND '03:59' THEN '03:00-04:00'
      WHEN EditTime BETWEEN '04:00' AND '04:59' THEN '04:00-05:00'
      WHEN EditTime BETWEEN '05:00' AND '05:59' THEN '05:00-06:00'
      WHEN EditTime BETWEEN '06:00' AND '06:59' THEN '06:00-07:00'
      WHEN EditTime BETWEEN '07:00' AND '07:59' THEN '07:00-08:00'
      WHEN EditTime BETWEEN '08:00' AND '08:59' THEN '08:00-09:00'
      WHEN EditTime BETWEEN '09:00' AND '09:59' THEN '09:00-10:00'
      WHEN EditTime BETWEEN '10:00' AND '10:59' THEN '10:00-11:00'
      WHEN EditTime BETWEEN '11:00' AND '11:59' THEN '11:00-12:00'
      WHEN EditTime BETWEEN '12:00' AND '12:59' THEN '12:00-13:00'
      WHEN EditTime BETWEEN '13:00' AND '13:59' THEN '13:00-14:00'
      WHEN EditTime BETWEEN '14:00' AND '14:59' THEN '14:00-15:00'
      WHEN EditTime BETWEEN '15:00' AND '15:59' THEN '15:00-16:00'
      WHEN EditTime BETWEEN '16:00' AND '16:59' THEN '16:00-17:00'
      WHEN EditTime BETWEEN '17:00' AND '17:59' THEN '17:00-18:00'
      WHEN EditTime BETWEEN '18:00' AND '18:59' THEN '18:00-19:00'
      WHEN EditTime BETWEEN '19:00' AND '19:59' THEN '19:00-20:00'
      WHEN EditTime BETWEEN '20:00' AND '20:59' THEN '20:00-21:00'
      WHEN EditTime BETWEEN '21:00' AND '21:59' THEN '21:00-22:00'
      WHEN EditTime BETWEEN '22:00' AND '22:59' THEN '22:00-23:00'
      WHEN EditTime BETWEEN '23:00' AND '23:59' THEN '23:00-00:00'
    END AS HourlyRange
FROM Cases
WHERE Skill IS NOT NULL

  GROUP BY Skill, Month_Year, HourlyRange,CreatedDate
ORDER BY Skill ASC
),
reopened AS (
SELECT DISTINCT
CASE
WHEN c.CaseSkills LIKE '%US%' THEN 'US'
WHEN c.CaseSkills LIKE '%General Support%' THEN '1.General Support'
WHEN c.CaseSkills LIKE '%Financial Services%' THEN '2.Financial Services'
WHEN c.CaseSkills LIKE '%eToro Money%' THEN '3.eToro Money'
WHEN c.CaseSkills LIKE '%Hacked%' THEN '4.Hacked Accounts/Islamic/GDPR'
WHEN c.CaseSkills LIKE '%GDPR%' THEN '4.Hacked Accounts/Islamic/GDPR'
WHEN c.CaseSkills LIKE '%Islamic%' THEN '4.Hacked Accounts/Islamic/GDPR'
WHEN c.CaseSkills LIKE '%Trading Experience%' THEN '5.Trading Experience'
WHEN c.CaseSkills LIKE '%Technical%' THEN '6.Technical'
WHEN c.CaseSkills LIKE '%CS Marketing%' THEN '7.CS Marketing'
END AS Skill,
CAST(timestampadd(HOUR, 3, ch.CreatedDate) AS DATE) AS CreatedDate,
     date_format(timestampadd(HOUR, 3, ch.CreatedDate), 'HH:mm') AS EditTime,
    date_format(ch.CreatedDate, 'MM/yy') AS Month_Year,
ch.CaseId
FROM crm.silver_crm_casehistory ch
LEFT JOIN bi_output.bi_output_customer_customer_support_case c
ON c.CaseID = ch.CaseId
WHERE Field = 'Counter_Routing__c'
AND YEAR(ch.CreatedDate)> 2024
AND c.CaseOwnerTitle <> 'Admin'
AND c.CaseSkills NOT LIKE '%US%'
AND ch.CreatedDate > c.CreatedDate
),
GroupedReopened AS (
SELECT
Skill,
COUNT(CaseId) AS ReopenedIncoming,
CAST(CreatedDate AS DATE) AS IncomingDate,
Month_Year,
    CASE 
      WHEN EditTime BETWEEN '00:00' AND '00:59' THEN '00:00-01:00'
      WHEN EditTime BETWEEN '01:00' AND '01:59' THEN '01:00-02:00'
      WHEN EditTime BETWEEN '02:00' AND '02:59' THEN '02:00-03:00'
      WHEN EditTime BETWEEN '03:00' AND '03:59' THEN '03:00-04:00'
      WHEN EditTime BETWEEN '04:00' AND '04:59' THEN '04:00-05:00'
      WHEN EditTime BETWEEN '05:00' AND '05:59' THEN '05:00-06:00'
      WHEN EditTime BETWEEN '06:00' AND '06:59' THEN '06:00-07:00'
      WHEN EditTime BETWEEN '07:00' AND '07:59' THEN '07:00-08:00'
      WHEN EditTime BETWEEN '08:00' AND '08:59' THEN '08:00-09:00'
      WHEN EditTime BETWEEN '09:00' AND '09:59' THEN '09:00-10:00'
      WHEN EditTime BETWEEN '10:00' AND '10:59' THEN '10:00-11:00'
      WHEN EditTime BETWEEN '11:00' AND '11:59' THEN '11:00-12:00'
      WHEN EditTime BETWEEN '12:00' AND '12:59' THEN '12:00-13:00'
      WHEN EditTime BETWEEN '13:00' AND '13:59' THEN '13:00-14:00'
      WHEN EditTime BETWEEN '14:00' AND '14:59' THEN '14:00-15:00'
      WHEN EditTime BETWEEN '15:00' AND '15:59' THEN '15:00-16:00'
      WHEN EditTime BETWEEN '16:00' AND '16:59' THEN '16:00-17:00'
      WHEN EditTime BETWEEN '17:00' AND '17:59' THEN '17:00-18:00'
      WHEN EditTime BETWEEN '18:00' AND '18:59' THEN '18:00-19:00'
      WHEN EditTime BETWEEN '19:00' AND '19:59' THEN '19:00-20:00'
      WHEN EditTime BETWEEN '20:00' AND '20:59' THEN '20:00-21:00'
      WHEN EditTime BETWEEN '21:00' AND '21:59' THEN '21:00-22:00'
      WHEN EditTime BETWEEN '22:00' AND '22:59' THEN '22:00-23:00'
      WHEN EditTime BETWEEN '23:00' AND '23:59' THEN '23:00-00:00'
    END AS HourlyRange
FROM reopened
WHERE Skill IS NOT NULL
GROUP BY Skill, CAST(CreatedDate AS DATE), Month_Year, HourlyRange
ORDER BY Skill ASC
)
SELECT DISTINCT
  COALESCE(g.Skill, gc.ChatSkill, gr.Skill) AS Skill,
  COALESCE(g.CasesIncoming, 0) + COALESCE(gr.ReopenedIncoming, 0) AS CasesIncoming,
  COALESCE(gc.ChatsIncoming, 0) AS ChatsIncoming,
  COALESCE(g.IncomingDate, gc.IncomingDate, gr.IncomingDate) AS IncomingDate,
  COALESCE(g.Month_Year, gc.Month_Year, gr.Month_Year) AS Month_Year,
  COALESCE(g.HourlyRange, gc.HourlyRange, gr.HourlyRange) AS HourlyRange
FROM GroupedCases g
FULL OUTER JOIN GroupedChats gc
  ON g.Skill = gc.ChatSkill
  AND g.IncomingDate = gc.IncomingDate
  AND g.HourlyRange = gc.HourlyRange
FULL OUTER JOIN GroupedReopened gr
  ON COALESCE(g.Skill, gc.ChatSkill) = gr.Skill
  AND COALESCE(g.IncomingDate, gc.IncomingDate) = gr.IncomingDate
  AND COALESCE(g.HourlyRange, gc.HourlyRange) = gr.HourlyRange