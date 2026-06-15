SELECT DISTINCT
        AgentId,
        DATE(TIMESTAMPADD(HOUR, 2, Time)) AS work_date,  -- Convert to Cyprus time
        LiveChatTranscriptId,
        l.Name AS ChatId,
        e.CreatedDate,
        l.AverageResponseTimeOperator,
        l.AverageResponseTimeVisitor,
        l.Original_Skillset__c,
        l.ChatDuration,
            Time,
        EndTime,
           timestampdiff(SECOND, Time, EndTime) AS seconds_diff,
    
         CONCAT(a.FirstName, ' ', a.LastName) AS Agent,
          Site,
    Subrole,
    a.Department
    
    FROM crm.silver_crm_livechattranscriptevent e 
   left join crm.silver_crm_livechattranscript l on e.LiveChatTranscriptId=l.ID
 LEFT JOIN bi_output.bi_output_customer_customer_support_agent_user a on a.ID=e.AgentID and
DATE(TIMESTAMPADD(HOUR, 2, Time)) < CAST(a.ToDate AS DATE)
and DATE(TIMESTAMPADD(HOUR, 2, Time)) >= CAST(a.FromDate AS DATE)

    WHERE e.Type in ('Accept','Transfer')
    and e.AgentID<>'0050800000HIGdOAAX'
    AND l.OwnerId<>'0050800000HIGdOAAX'
    and a.Department <> 'CS'
AND YEAR(Time) >=2024
--and l.Name='02694841'
and l.EndTime IS NOT NULL