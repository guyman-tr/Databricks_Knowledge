WITH TimeSlots AS (
    SELECT DISTINCT
        AgentId,
        DATE(TIMESTAMPADD(HOUR, 2, Time)) AS work_date,  -- Convert to Cyprus time
        HOUR(TIMESTAMPADD(HOUR, 2, Time)) AS work_hour
    FROM crm.silver_crm_livechattranscriptevent
    where Type='Transfer'
          AND MINUTE(TIMESTAMPADD(HOUR, 2, Time)) NOT BETWEEN 55 AND 59  -- Exclude 55-59 minutes

),
MergedSlots AS (
    SELECT 
        AgentId,
        work_date,
        work_hour,
        work_hour - ROW_NUMBER() OVER (PARTITION BY AgentId, work_date ORDER BY work_hour) AS grp
    FROM TimeSlots
),
GroupedSlots AS (
    SELECT 
        AgentId,
        work_date,
        MIN(work_hour) AS start_hour,
        MAX(work_hour) AS end_hour
    FROM MergedSlots
    GROUP BY AgentId, work_date, grp
)
SELECT DISTINCT
    CONCAT(a.FirstName, ' ', a.LastName) AS Agent,
    AgentId,
    Site,
    Subrole,
    work_date,
cast(work_date as date) as Date,
    CONCAT(LPAD(start_hour, 2, '0'), ':00-', LPAD(end_hour + 1, 2, '0'), ':00') AS time_slot
FROM GroupedSlots g
LEFT JOIN bi_output.bi_output_customer_customer_support_agent_user a 
    ON a.ID = g.AgentId AND YEAR(ToDate) = 9999
WHERE work_date >= '2025-01-01'
  AND AgentId IS NOT NULL
 and (Site is null or Site not in ('Australia','Integration','Philippines'))