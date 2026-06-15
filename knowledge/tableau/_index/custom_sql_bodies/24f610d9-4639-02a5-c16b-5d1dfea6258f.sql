SELECT
    date_format(c.CreatedDate, 'yyyy-MM') AS MonthYear,
    c.Agent_Under_Assessment__c AS Agent,
    AVG(c.Operational_a__c) AS Operational_A,
    AVG(c.Quality_a__c) AS Quality_A
FROM crm.silver_crm_surveytaker__c c
GROUP BY
    date_format(c.CreatedDate, 'yyyy-MM'),
    c.Agent_Under_Assessment__c