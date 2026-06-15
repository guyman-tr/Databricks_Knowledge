WITH PortalCases AS (
    SELECT
        CID__c,
        Category__c,
        to_timestamp(CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate,
        ROW_NUMBER() OVER (PARTITION BY CID__c, Category__c ORDER BY SystemModstamp DESC) AS rn
    FROM main.crm.silver_crm_case
    WHERE Origin = 'Portal'
),
DeflectedCases AS (
    SELECT
        c.CID__c,
        c.Category__c,
        c.CreatedDate,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM main.crm.silver_crm_case p
                WHERE p.Origin = 'Portal'
                      AND p.CID__c = c.CID__c
                      AND p.Category__c = c.Category__c
                      AND p.CreatedDate >> c.CreatedDate
                      AND p.CreatedDate <<= c.CreatedDate + INTERVAL '24 hour'
            ) THEN 1
            ELSE 0
        END AS IsDeflected
    FROM (
        SELECT DISTINCT
            CID__c,
            Category__c,
            to_timestamp(CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate
        FROM main.crm.silver_crm_case
    ) c
)
SELECT
    case1.id AS CaseId,
    case1.Case_Owner_Title__c,
    case1.CaseNumber,
    case1.CID__c,
    to_timestamp(case1.CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate,
    case1.SystemModstamp,
    case1.OwnerId AS CaseOwnerId,
    case1.Service_Desk__c,
    case1.Owner_role_name__c,
    case1.Owner_Sub_Role__c,
    case1.Club_Level_on_Creation__c,
    case1.Regulation__c,
    case1.Status,
    case1.Status_Reason__c,
    case1.Origin,
    case1.Phase__c,
    case1.CaseSkills__c,
    case1.Subject,
    case1.Category__c,
    case1.Type__c,
    case1.Sub_Type__c,
    case1.Sub_Type_2__c,
    case1.Product__c,
    case1.One_Touch__c,
    case1.Time_to_1st_Response__c,
    case1.Full_Resolution_Time__c,
    case1.Resolution_Time_From_1st_Response__c,
    case1.Verification_Level__c,
    case1.Chat_Score__c,
    case1.SLA_Score__c,
    case1.Score__c,
    case1.Counter_Routing__c,
    case1.Number_of_touches__c,
    case1.Country__c,
    case1.Lead_or_FTD__c,
    COALESCE(dc.IsDeflected, 0) AS IsDeflected
FROM main.crm.silver_crm_case case1
LEFT JOIN DeflectedCases dc ON case1.CID__c = dc.CID__c
                             AND case1.Category__c = dc.Category__c
                             AND case1.CreatedDate = dc.CreatedDate
WHERE 
    case1.SystemModstamp IN (
        SELECT MAX(SystemModstamp)
        FROM main.crm.silver_crm_case
        WHERE CID__c = case1.CID__c
          AND Category__c = case1.Category__c
          AND CaseNumber = case1.CaseNumber
    )
    AND case1.CreatedDate >>= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'