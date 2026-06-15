SELECT 
    CONCAT(FirstName, ' ', LastName) AS FullName,
CAST(TIMESTAMPADD(HOUR, 3, e.Occurred) AS DATE) AS Date,
    DATE_FORMAT(MIN(timestampadd(HOUR, 3, Occurred)), 'HH:mm:ss') AS FirstTouchTime,
DATE_FORMAT(MAX(timestampadd(HOUR, 3, Occurred)), 'HH:mm:ss') AS LastTouchTime,
    Subrole,
    Site
FROM 
    bi_output.bi_output_customer_customer_support_case_event e
LEFT JOIN  
    bi_output_stg.bi_output_customer_customer_support_agent_user a 
    ON e.DoneBy = a.Id 
    AND CAST(Occurred AS DATE) BETWEEN CAST(a.FromDate AS DATE) AND CAST(a.ToDate AS DATE)
WHERE 
    YEAR(Occurred) = 2024
    AND Position = 'Agent'
    AND Department = 'CS'
GROUP BY 
    CONCAT(FirstName, ' ', LastName), 
   CAST(TIMESTAMPADD(HOUR, 3, e.Occurred) AS DATE), 
    Subrole, 
    Site
HAVING 
    -- Exclude specific sites with touch times between 00:00 and 01:00
   NOT (
    Site IN ('Cyprus', 'Israel', 'Romania')
    AND (
        DATE_FORMAT(MIN(TIMESTAMPADD(HOUR, 3, Occurred)), 'HH:mm:ss') BETWEEN '00:00:00' AND '00:59:59'
        OR DATE_FORMAT(MAX(TIMESTAMPADD(HOUR, 3, Occurred)), 'HH:mm:ss') BETWEEN '00:00:00' AND '00:59:59'
    )
)